//
// PCILeech for Spartan6 SP605 with FTDI FT601.
//
// Top module.
//
// Author: Ulf Frisk, pcileech@frizk.net
// Special thanks to: Dmytro Oleksiuk @d_olex
//
// NB! The alternative RAM FIFO is commented out of this design, it's working
// but it won't give any considerable speed increases due to other bottlenecks
// in the design - mostly related to the PCIe interface and the synchronous
// access pattern from the PCILeech program running on the PC.

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

module pcileech_top #(
   // DEVICE IDs as follows:
   // 0 = SP605, 1 = PCIeScreamer, 2 = AC701
   parameter       PARAM_DEVICE_ID = 0,
   parameter       PARAM_VERSION_NUMBER_MAJOR = 2,
   parameter       PARAM_VERSION_NUMBER_MINOR = 2
) (
   // TO/FROM SYSTEM MEMORY CONTROLLER
   /*
   inout  [15:0]     mcb3_dram_dq,
   output [12:0]     mcb3_dram_a,
   output [2:0]      mcb3_dram_ba,
   output            mcb3_dram_ras_n,
   output            mcb3_dram_cas_n,
   output            mcb3_dram_we_n,
   output            mcb3_dram_odt,
   output            mcb3_dram_reset_n,
   output            mcb3_dram_cke,
   output            mcb3_dram_dm,
   inout             mcb3_dram_udqs,
   inout             mcb3_dram_udqs_n,
   inout             mcb3_rzq,
   inout             mcb3_zio,
   output            mcb3_dram_udm,
   input             c3_sys_clk_p,
   input             c3_sys_clk_n,
   input             c3_sys_rst_i,
   output            c3_calib_done,
   output            c3_clk0,
   output            c3_rst0,
   inout             mcb3_dram_dqs,
   inout             mcb3_dram_dqs_n,
   output            mcb3_dram_ck,
   output            mcb3_dram_ck_n,
   */
   
   // PCI-E FABRIC
   output            pci_exp_txp,
   output            pci_exp_txn,
   input             pci_exp_rxp,
   input             pci_exp_rxn,

   // PCIe CLK AND RESET
   input             sys_clk_p,
   input             sys_clk_n,
   input             sys_reset_n,

   // DIAGNOSTIC LEDs
   output [3:0]      SYS_LED,

   // TO/FROM FT601 PADS
   input             FT601_RESET_N,
   input             FT601_CLK,
   inout [31:0]      FT601_DATA,
   inout [3:0]       FT601_BE,
   input             FT601_RXF_N,
   input             FT601_TXE_N,
   output            FT601_WR_N,
   output            FT601_SIWU_N,
   output            FT601_RD_N,
   output            FT601_OE_N
);
   wire              sys_reset_n_c;
   wire              led_activity;

   // PCIe common
   wire              user_clk;
   wire              user_reset;
   wire              user_lnk_up;

   // FT601/FT245 <--> FIFO CTL
   wire [31:0]       ft601_rx_data;
   wire              ft601_rx_wren;
   
   // FT601/FT245 <--> RAM FIFO
   wire [31:0]       ft601_tx_data;
   wire              ft601_tx_empty;
   wire              ft601_tx_valid;
   wire              ft601_tx_rden;
   
   // RAM FIFO <--> FIFO CTL
   wire [255:0]      fifo_tx_data;
   wire              fifo_tx_valid;
   
   // PCIe <--> FIFOs
   wire [33:0]       pcie_tlp_tx_data;
   wire              pcie_tlp_tx_valid;
   wire              pcie_tlp_tx_ready;
   wire [33:0]       pcie_tlp_rx_data;
   wire              pcie_tlp_rx_valid;
   wire              pcie_tlp_rx_ready;
   wire [63:0]       pcie_cfg_tx_data;
   wire              pcie_cfg_tx_valid;
   wire [33:0]       pcie_cfg_rx_data;
   wire              pcie_cfg_rx_valid;
   wire              pcie_cfg_rx_ready;

   // Buffer for LEDs
   OBUF led_0_obuf(.O( SYS_LED[0] ), .I( ~sys_reset_n_c ));
   OBUF led_1_obuf(.O( SYS_LED[1] ), .I( user_reset ));
   OBUF led_2_obuf(.O( SYS_LED[2] ), .I( user_lnk_up ));
   OBUF led_3_obuf(.O( SYS_LED[3] ), .I( led_activity ));

   pcileech_ft601 i_pcileech_ft601(
      .clk                 ( FT601_CLK          ),
      .rst                 ( ~FT601_RESET_N     ),
      // TO/FROM FT601 PADS
      .FT601_DATA          ( FT601_DATA         ),
      .FT601_BE            ( FT601_BE           ),
      .FT601_TXE_N         ( FT601_TXE_N        ),
      .FT601_RXF_N         ( FT601_RXF_N        ),
      .FT601_SIWU_N        ( FT601_SIWU_N       ),
      .FT601_WR_N          ( FT601_WR_N         ),
      .FT601_RD_N          ( FT601_RD_N         ),
      .FT601_OE_N          ( FT601_OE_N         ),
      // FT601 CTL <--> FIFO CTL
      .dout                ( ft601_rx_data      ),
      .dout_valid          ( ft601_rx_wren      ),
      // FT601 CTL <--> MAIN OUTPUT FIFO  
      .din                 ( ft601_tx_data      ),
      .din_empty           ( ft601_tx_empty     ),
      .din_wr_en           ( ft601_tx_valid     ),
      .din_req_data        ( ft601_tx_rden      ),
      // Activity LED
      .led_activity        ( led_activity       )
   );

   /*
   pcileech_fifo_ram i_pcileech_out_buffer_ram(
      .clk                 ( FT601_CLK          ),
      .rst                 ( ~FT601_RESET_N     ),
      .din                 ( fifo_tx_data       ),
      .wr_en               ( fifo_tx_valid      ),
      .rd_en               ( ft601_tx_rden      ),
      .dout                ( ft601_tx_data      ),
      .full                (                    ),
      .almost_full         (                    ),
      .empty               ( ft601_tx_empty     ),
      .valid               ( ft601_tx_valid     ),
      // TO/FROM SYSTEM MEMORY CONTROLLER
      .mcb3_dram_dq        ( mcb3_dram_dq       ),
      .mcb3_dram_a         ( mcb3_dram_a        ),
      .mcb3_dram_ba        ( mcb3_dram_ba       ),
      .mcb3_dram_ras_n     ( mcb3_dram_ras_n    ),
      .mcb3_dram_cas_n     ( mcb3_dram_cas_n    ),
      .mcb3_dram_we_n      ( mcb3_dram_we_n     ),
      .mcb3_dram_odt       ( mcb3_dram_odt      ),
      .mcb3_dram_reset_n   ( mcb3_dram_reset_n  ),
      .mcb3_dram_cke       ( mcb3_dram_cke      ),
      .mcb3_dram_dm        ( mcb3_dram_dm       ),
      .mcb3_dram_udqs      ( mcb3_dram_udqs     ),
      .mcb3_dram_udqs_n    ( mcb3_dram_udqs_n   ),
      .mcb3_rzq            ( mcb3_rzq           ),
      .mcb3_zio            ( mcb3_zio           ),
      .mcb3_dram_udm       ( mcb3_dram_udm      ),
      .c3_sys_clk_p        ( c3_sys_clk_p       ),
      .c3_sys_clk_n        ( c3_sys_clk_n       ),
      .c3_sys_rst_i        ( c3_sys_rst_i       ),
      .c3_calib_done       ( c3_calib_done      ),
      .c3_clk0             ( c3_clk0            ),
      .c3_rst0             ( c3_rst0            ),
      .mcb3_dram_dqs       ( mcb3_dram_dqs      ),
      .mcb3_dram_dqs_n     ( mcb3_dram_dqs_n    ),
      .mcb3_dram_ck        ( mcb3_dram_ck       ),
      .mcb3_dram_ck_n      ( mcb3_dram_ck_n     )
   );
   */
   
   wire [31:0] fram_din;
   wire fram_almost_full;
   wire fram_wr_en;
   wire fram_prog_empty;
   wire out_buffer1_almost_full;
   // FTDI have a bug ( in chip or driver ) which doesn't terminate transfer if
   // even multiple of 1024 bytes are transmitted. Always insert five (5) MAGIC
   // DWORD (0x66665555) in beginning of stream to mitigate this.  Since normal
   // data size is always a multiple of 32-bytes/256-bits this will resolve the
   // issue.
   reg ft601_txe_n_d1;
   always @ ( posedge FT601_CLK )
      ft601_txe_n_d1 <= FT601_TXE_N;
   wire ftdi_bug_workaround = fram_prog_empty & ft601_txe_n_d1 & ~fram_wr_en;
   fifo_32_32_deep i_pcileech_out_buffer2(
      .clk                ( FT601_CLK             ),
      .rst                ( ~FT601_RESET_N        ),
      .din                ( ftdi_bug_workaround ? 32'h66665555 : fram_din ),
      .wr_en              ( fram_wr_en | ftdi_bug_workaround ),
      .rd_en              ( ft601_tx_rden         ),
      .dout               ( ft601_tx_data         ),
      .full               (                       ),
      .almost_full        ( fram_almost_full      ),
      .empty              ( ft601_tx_empty        ),
      .prog_empty         ( fram_prog_empty       ),
      .valid              ( ft601_tx_valid        )
   );
   fifo_256_32 i_pcileech_out_buffer1(
      .wr_clk             ( FT601_CLK             ),
      .rd_clk             ( FT601_CLK             ),
      .rst                ( ~FT601_RESET_N        ),
      .din                ( fifo_tx_data          ),
      .wr_en              ( fifo_tx_valid         ),
      .rd_en              ( ~fram_almost_full     ),
      .dout               ( fram_din              ),
      .full               (                       ),
      .almost_full        ( out_buffer1_almost_full ),
      .empty              (                       ),
      .valid              ( fram_wr_en            )
   );
   assign fifo_tx_rd_en = ~out_buffer1_almost_full;
   
    pcileech_fifo #(
        .PARAM_DEVICE_ID            ( PARAM_DEVICE_ID               ),
        .PARAM_VERSION_NUMBER_MAJOR ( PARAM_VERSION_NUMBER_MAJOR    ),
        .PARAM_VERSION_NUMBER_MINOR ( PARAM_VERSION_NUMBER_MINOR    )    
    ) i_pcileech_fifo (
      .clk                 ( FT601_CLK          ),
      .clk_pcie            ( user_clk           ),
      .rst                 ( ~FT601_RESET_N     ),
      .rst_pcie            ( user_reset | ~sys_reset_n_c ),
      .pcie_lnk_up         ( user_lnk_up        ),
      // FIFO CTL <--> FT601 CTL
      .ft601_rx_data       ( ft601_rx_data      ),
      .ft601_rx_wren       ( ft601_rx_wren      ),
      // FIFO CTL <--> RAM FIFO
      .ft601_tx_data       ( fifo_tx_data       ),
      .ft601_tx_valid      ( fifo_tx_valid      ),
      // PCIe <--> FIFOs
      .pcie_tlp_tx_data    ( pcie_tlp_tx_data   ),
      .pcie_tlp_tx_valid   ( pcie_tlp_tx_valid  ),
      .pcie_tlp_tx_ready   ( pcie_tlp_tx_ready  ),
      .pcie_tlp_rx_data    ( pcie_tlp_rx_data   ),
      .pcie_tlp_rx_valid   ( pcie_tlp_rx_valid  ),
      .pcie_tlp_rx_ready   ( pcie_tlp_rx_ready  ),
      .pcie_cfg_tx_data    ( pcie_cfg_tx_data   ),
      .pcie_cfg_tx_valid   ( pcie_cfg_tx_valid  ),
      .pcie_cfg_rx_data    ( pcie_cfg_rx_data   ),
      .pcie_cfg_rx_valid   ( pcie_cfg_rx_valid  ),
      .pcie_cfg_rx_ready   ( pcie_cfg_rx_ready  )
   );
   
   pcileech_pcie i_pcileech_pcie(
      // TO/FROM SYSTEM
      .pci_exp_txp         ( pci_exp_txp        ),
      .pci_exp_txn         ( pci_exp_txn        ),
      .pci_exp_rxp         ( pci_exp_rxp        ),
      .pci_exp_rxn         ( pci_exp_rxn        ),
      .user_clk            ( user_clk           ),
      .user_reset          ( user_reset         ),
      .user_lnk_up         ( user_lnk_up        ),
      .sys_reset_n_c       ( sys_reset_n_c      ),
      .sys_clk_p           ( sys_clk_p          ),
      .sys_clk_n           ( sys_clk_n          ),
      .sys_reset_n         ( sys_reset_n        ),
      // PCIe <--> FIFOs
      .pcie_tlp_tx_data    ( pcie_tlp_tx_data   ),
      .pcie_tlp_tx_valid   ( pcie_tlp_tx_valid  ),
      .pcie_tlp_tx_ready   ( pcie_tlp_tx_ready  ),
      .pcie_tlp_rx_data    ( pcie_tlp_rx_data   ),
      .pcie_tlp_rx_valid   ( pcie_tlp_rx_valid  ),
      .pcie_tlp_rx_ready   ( pcie_tlp_rx_ready  ),
      .pcie_cfg_tx_data    ( pcie_cfg_tx_data   ),
      .pcie_cfg_tx_valid   ( pcie_cfg_tx_valid  ),
      .pcie_cfg_rx_data    ( pcie_cfg_rx_data   ),
      .pcie_cfg_rx_valid   ( pcie_cfg_rx_valid  ),
      .pcie_cfg_rx_ready   ( pcie_cfg_rx_ready  )
   );

endmodule
