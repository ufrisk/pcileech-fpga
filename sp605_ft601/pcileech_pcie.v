//
// PCILeech for Spartan6 SP605 with FTDI FT601.
//
// PCIe controller module.
//
// Author: Ulf Frisk, pcileech@frizk.net
// Special thanks to: Dmytro Oleksiuk @d_olex
//

// MIT License
//
// Copyright (c) 2017 Ulf Frisk
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

module pcileech_pcie(
   // PCIe fabric
   output         pci_exp_txp,
   output         pci_exp_txn,
   input          pci_exp_rxp,
   input          pci_exp_rxn,
   output         user_clk,
   output         user_reset,
   output         user_lnk_up,
   output         sys_reset_n_c,
   input          sys_clk_p,
   input          sys_clk_n,
   input          sys_reset_n,
   
   // Tx tlp data (to FT601/FIFOs)
   output [33:0]  pcie_tlp_tx_data,
   output         pcie_tlp_tx_valid,
   input          pcie_tlp_tx_ready,
   
   // Rx tlp data (from FT601/FIFOs)
   input [33:0]   pcie_tlp_rx_data,
   input          pcie_tlp_rx_valid,
   output         pcie_tlp_rx_ready,
   
   // Tx cfg data (to FT601/FIFOs)
   output [63:0]  pcie_cfg_tx_data,
   output         pcie_cfg_tx_valid,
   
   // Rx cfg data (from FT601/FIFOs)
   input [33:0]   pcie_cfg_rx_data,
   input          pcie_cfg_rx_valid,
   output         pcie_cfg_rx_ready
   );
   
   // ----------------------------------------------------------------------------
   // PCIe DEFINES AND WIRES BELOW
   // ----------------------------------------------------------------------------
   
   localparam PCI_EXP_EP_OUI = 24'h000A35;
   localparam PCI_EXP_EP_DSN_1 = { { 8'h1 }, PCI_EXP_EP_OUI };
   localparam PCI_EXP_EP_DSN_2 = 32'h00000001;
   wire [63:0]    cfg_dsn;
   assign cfg_dsn = { PCI_EXP_EP_DSN_2, PCI_EXP_EP_DSN_1 };

   // system interface
   wire           sys_clk_c;
   
   // PCIe TX
   wire           s_axis_tx_tready;    // ->
   wire [31:0]    s_axis_tx_tdata;     // <-
   wire [3:0]     s_axis_tx_tkeep;     // <-
   wire           s_axis_tx_tlast;     // <-
   wire           s_axis_tx_tvalid;    // <-
   
   // PCIe RX
   wire [31:0]    m_axis_rx_tdata;     // ->
   wire           m_axis_rx_tlast;     // ->
   wire           m_axis_rx_tvalid;    // ->
   wire           m_axis_rx_tready;    // <-
   
   // PCIe cfg/command registers
   wire [7:0]     cfg_bus_number;      // ->
   wire [4:0]     cfg_device_number;   // ->
   wire [2:0]     cfg_function_number; // ->
   wire [15:0]    cfg_command;         // ->
   
   wire [31:0]    cfg_do;              // ->
   wire           cfg_rd_wr_done;      // ->
   wire [9:0]     cfg_dwaddr;          // <-
   wire           cfg_rd_en;           // <-
   
   wire cfg_command_interrupt_disable;
   wire cfg_command_serr_en;
   wire cfg_command_bus_master_enable;
   wire cfg_command_mem_enable;
   wire cfg_command_io_enable;
   assign cfg_command_interrupt_disable   = cfg_command[10];
   assign cfg_command_serr_en             = cfg_command[8];
   assign cfg_command_bus_master_enable   = cfg_command[2];
   assign cfg_command_mem_enable          = cfg_command[1];
   assign cfg_command_io_enable           = cfg_command[0];  

   // Buffer for differential system clock
   IBUFDS refclk_ibuf(.O( sys_clk_c ), .I( sys_clk_p ), .IB( sys_clk_n ));
   
   // Buffer for system reset
   IBUF sys_reset_n_ibuf(.O( sys_reset_n_c ), .I( sys_reset_n ));

   // ----------------------------------------------------------------------------
   // PCIe TLP RX/TX <--> FIFO below
   // ----------------------------------------------------------------------------
   assign pcie_tlp_tx_valid = m_axis_rx_tvalid; 
   assign pcie_tlp_tx_data[32] = m_axis_rx_tlast;
   assign pcie_tlp_tx_data[33] = cfg_command_bus_master_enable;
   assign pcie_tlp_tx_data[31:0] = m_axis_rx_tdata;
   assign m_axis_rx_tready = pcie_tlp_tx_ready;
   
   assign s_axis_tx_tvalid = pcie_tlp_rx_valid;  
   assign s_axis_tx_tdata = pcie_tlp_rx_data[31:0];
   assign s_axis_tx_tlast = pcie_tlp_rx_data[32];
   assign s_axis_tx_tkeep = 4'hf;
   assign pcie_tlp_rx_ready = s_axis_tx_tready;
   
   // ----------------------------------------------------------------------------
   // PCIe CFG RX/TX <--> FIFO below
   // ----------------------------------------------------------------------------
   assign pcie_cfg_tx_valid = cfg_rd_wr_done;
   assign pcie_cfg_tx_data[07:00] = 8'h77;									// MAGIC
   assign pcie_cfg_tx_data[09:08] = 2'b00;									// 00=cfg, 11=pcie
   assign pcie_cfg_tx_data[10:10] = 1'b00;
   assign pcie_cfg_tx_data[11:11] = cfg_command_bus_master_enable;
   assign pcie_cfg_tx_data[12:12] = cfg_command_interrupt_disable;
   assign pcie_cfg_tx_data[13:13] = cfg_command_serr_en;
   assign pcie_cfg_tx_data[14:14] = cfg_command_mem_enable;
   assign pcie_cfg_tx_data[15:15] = cfg_command_io_enable;
   assign pcie_cfg_tx_data[23:16] = cfg_bus_number;
   assign pcie_cfg_tx_data[28:24] = cfg_device_number;
   assign pcie_cfg_tx_data[31:29] = cfg_function_number;
   assign pcie_cfg_tx_data[63:32] = cfg_do;
   
   assign pcie_cfg_rx_ready = 1'b1;
   assign cfg_dwaddr = pcie_cfg_rx_data[9:0];
   assign cfg_rd_en = pcie_cfg_rx_valid;

   // ----------------------------------------------------------------------------
   // PCIe CORE BELOW
   // ----------------------------------------------------------------------------
   parameter FAST_TRAIN = "FALSE";
   
   s6_pcie_v2_4 #(
      .FAST_TRAIN               ( FAST_TRAIN           )
   ) i_s6_pcie_v2_4 (
      // PCIe fabric
      .pci_exp_txp              ( pci_exp_txp          ),
      .pci_exp_txn              ( pci_exp_txn          ),
      .pci_exp_rxp              ( pci_exp_rxp          ),
      .pci_exp_rxn              ( pci_exp_rxn          ),
      // common clock & reset
      .user_lnk_up              ( user_lnk_up          ),
      .user_clk_out             ( user_clk             ),
      .user_reset_out           ( user_reset           ),
      // common flow control
      .fc_sel                   ( 3'b0                 ),
      .fc_nph                   (                      ),
      .fc_npd                   (                      ),
      .fc_ph                    (                      ),
      .fc_pd                    (                      ),
      .fc_cplh                  (                      ),
      .fc_cpld                  (                      ),
      // transaction Tx
      .s_axis_tx_tready         ( s_axis_tx_tready     ), 
      .s_axis_tx_tdata          ( s_axis_tx_tdata      ),
      .s_axis_tx_tkeep          ( s_axis_tx_tkeep      ),
      .s_axis_tx_tuser          ( 4'b0                 ),
      .s_axis_tx_tlast          ( s_axis_tx_tlast      ),
      .s_axis_tx_tvalid         ( s_axis_tx_tvalid     ),
      .tx_err_drop              (                      ),
      .tx_buf_av                (                      ),
      .tx_cfg_req               (                      ),
      .tx_cfg_gnt               ( 1'b1                 ),
      // transaction Rx
      .m_axis_rx_tdata          ( m_axis_rx_tdata      ),
      .m_axis_rx_tkeep          (                      ),
      .m_axis_rx_tlast          ( m_axis_rx_tlast      ),
      .m_axis_rx_tvalid         ( m_axis_rx_tvalid     ),
      .m_axis_rx_tready         ( m_axis_rx_tready     ),
      .m_axis_rx_tuser          (                      ),
      .rx_np_ok                 ( 1'b1                 ),
      // configuration space access
      .cfg_do                   ( cfg_do               ), // ->
      .cfg_rd_wr_done           ( cfg_rd_wr_done       ), // ->
      .cfg_dwaddr               ( cfg_dwaddr           ), // <-
      .cfg_rd_en                ( cfg_rd_en            ), // <-
      // error reporting
      .cfg_err_ur               ( 1'b0                 ),
      .cfg_err_cor              ( 1'b0                 ),
      .cfg_err_ecrc             ( 1'b0                 ),
      .cfg_err_cpl_timeout      ( 1'b0                 ),
      .cfg_err_cpl_abort        ( 1'b0                 ),
      .cfg_err_posted           ( 1'b0                 ),
      .cfg_err_locked           ( 1'b0                 ),
      .cfg_err_tlp_cpl_header   ( 48'h0                ),
      .cfg_err_cpl_rdy          (                      ),
      // interrupt generation
      .cfg_interrupt            ( 1'b0                 ),
      .cfg_interrupt_rdy        (                      ),
      .cfg_interrupt_assert     ( 1'b0                 ),
      .cfg_interrupt_do         (                      ),
      .cfg_interrupt_di         ( 8'b0                 ),
      .cfg_interrupt_mmenable   (                      ),
      .cfg_interrupt_msienable  (                      ),
      // power management signaling
      .cfg_turnoff_ok           ( 1'b0                 ),
      .cfg_to_turnoff           (                      ),
      .cfg_pm_wake              ( 1'b0                 ),
      .cfg_pcie_link_state      (                      ),
      .cfg_trn_pending          ( 1'b0                 ),
      // system configuration and status
      .cfg_dsn                  ( cfg_dsn              ), // <-
      .cfg_bus_number           ( cfg_bus_number       ), // ->
      .cfg_device_number        ( cfg_device_number    ), // ->
      .cfg_function_number      ( cfg_function_number  ), // ->
      .cfg_status               (                      ), // ->
      .cfg_command              ( cfg_command          ), // ->
      .cfg_dstatus              (                      ), // ->
      .cfg_dcommand             (                      ), // ->
      .cfg_lstatus              (                      ), // ->
      .cfg_lcommand             (                      ), // ->
      // system interface
      .sys_clk                  ( sys_clk_c            ),
      .sys_reset                ( !sys_reset_n_c       ),
      .received_hot_reset       (                      )
  );

endmodule
