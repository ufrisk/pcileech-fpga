//
// PCILeech for Spartan6 SP605 with FTDI FT601.
//
// FIFO network / control.
//
// (c) Ulf Frisk, 2017
// Author: Ulf Frisk, pcileech@frizk.net
// Special thanks to: Dmytro Oleksiuk @d_olex
//

module pcileech_fifo(
   input          FT601_CLK,
   input          FT601_RESET_N,
   input          CLK,
   input          RESET,
   
   input [31:0]   ft601_rx_data,
   input          ft601_rx_wren,
   
   output [31:0]  ft601_tx_data,
   output         ft601_tx_empty,
   output         ft601_tx_almost_empty,
   output         ft601_tx_valid,
   input          ft601_tx_rden,
   
   input [63:0]   pcie_tlp_tx_data,
   input          pcie_tlp_tx_valid,
   output         pcie_tlp_tx_ready,
   
   output [63:0]  pcie_tlp_rx_data,
   output         pcie_tlp_rx_valid,
   input          pcie_tlp_rx_ready,
   
   input [63:0]   pcie_cfg_tx_data,
   input          pcie_cfg_tx_valid,
   output         pcie_cfg_tx_ready,
   
   output [63:0]  pcie_cfg_rx_data,
   output         pcie_cfg_rx_valid,
   input          pcie_cfg_rx_ready
   );

   // ----------------------------------------------------------------------------
   // RX FROM USB/FT601/FT245 BELOW:
   // ----------------------------------------------------------------------------
   // Tiny FIFO receives 32-bit data from FT601 and always clock it out when
   // 64-bits are avaiable regardless if receiving FIFOs are full or not. 
   // The actual data contains a MAGIC which tells which receiving FIFO should
   // accept the data. Receiving FIFOs are: PCIe TLP, PCIe CFG, Loopback, Command.
   //
   //                                              /---------------------------\
   //                                         /--> | 64->  PCIe TLP FIFO  ->64 | -> PCIe TLP
   //                                         |    \---------------------------/
   //                                         |
   //          /------------------------\     |    /---------------------------\
   // FT601 -> | 32->  FT601 FIFO  ->64 | ->--+--> | 64->  PCIe CFG FIFO  ->64 | -> PCIe CFG
   //          \------------------------/     |    \---------------------------/
   //                                         |
   //                                         +--> LOOPBACK
   //                                         |
   //                                         \--> COMMAND
   //                                              
   //

   // --------------------------------------------------------
   // Receive 32-bit data from FT245 and convert it into 64-bit
   // data which is forwarded into different 64-bit FIFO which
   // depends on bit mask of read control bytes in data stream.
   // FIFO is assumed to never be full since read enable, rd_en
   // is always active.
   // --------------------------------------------------------
   wire [63:0] __ft245_rx_dout;
   wire        __ft245_rx_valid;
   fifo_32_64 i_fifo_rx245(
      .wr_rst     ( ~FT601_RESET_N           ),
      .rd_rst     ( RESET                    ),
      .wr_clk     ( FT601_CLK                ),
      .rd_clk     ( CLK                      ),
      .din        ( ft601_rx_data            ), 
      .wr_en      ( ft601_rx_wren            ),
      .rd_en      ( 1'b1                     ),
      .dout       ( __ft245_rx_dout          ),
      .full       (                          ),
      .empty      (                          ),
      .valid      ( __ft245_rx_valid         )
   );

   // --------------------------------------------------------
   // Fetch incoming 64-bit data from the FT601/FT245 FIFO if
   // data maches the correct signature. The FIFO is assumed
   // never to be full. If it's full data will be dropped.
   // FIFO forwards data to the PCIe TLP interface.
   // --------------------------------------------------------
   wire        __tlp_rx_wren;
   fifo_64_64 i_fifo_pcie_tlp_rx(
      .clk        ( CLK                      ),
      .rst        ( RESET | ~FT601_RESET_N   ),
      .din        ( __ft245_rx_dout          ),
      .wr_en      ( __tlp_rx_wren            ),
      .rd_en      ( pcie_tlp_rx_ready        ),
      .dout       ( pcie_tlp_rx_data         ),
      .full       (                          ),
      .almost_full(                          ),
      .empty      (                          ),
      .valid      ( pcie_tlp_rx_valid        )
   );

   // --------------------------------------------------------
   // Fetch incoming 64-bit data from the FT601/FT245 FIFO if
   // data maches the correct signature. The FIFO is assumed
   // never to be full. If it's full data will be dropped.
   // FIFO forwards data to the PCIe CFG interface.
   // --------------------------------------------------------
   wire        __cfg_rx_wren;
   fifo_64_64_thin i_fifo_pcie_cfg_rx(
      .clk        ( CLK                      ),
      .rst        ( RESET | ~FT601_RESET_N   ),
      .din        ( __ft245_rx_dout          ),
      .wr_en      ( __cfg_rx_wren            ),
      .rd_en      ( pcie_cfg_rx_ready        ),
      .dout       ( pcie_cfg_rx_data         ),
      .full       (                          ),
      .almost_full(                          ),
      .empty      (                          ),
      .valid      ( pcie_cfg_rx_valid        )
   );

   wire        __loop_rx_wren;
   wire        __cmd_rx_wren;
  
   `define CHECK_MAGIC     ((__ft245_rx_dout[7:0] == 8'h77) ? 1'b1 : 1'b0)
   `define CHECK_TYPE_TLP  ((__ft245_rx_dout[9:8] == 2'b11) ? 1'b1 : 1'b0)
   `define CHECK_TYPE_CFG  ((__ft245_rx_dout[9:8] == 2'b00) ? 1'b1 : 1'b0)
   `define CHECK_TYPE_LOOP ((__ft245_rx_dout[9:8] == 2'b01) ? 1'b1 : 1'b0)
   `define CHECK_TYPE_CMD  ((__ft245_rx_dout[9:8] == 2'b10) ? 1'b1 : 1'b0)

   assign __tlp_rx_wren    = __ft245_rx_valid & `CHECK_MAGIC & `CHECK_TYPE_TLP;
   assign __cfg_rx_wren    = __ft245_rx_valid & `CHECK_MAGIC & `CHECK_TYPE_CFG;
   assign __loop_rx_wren   = __ft245_rx_valid & `CHECK_MAGIC & `CHECK_TYPE_LOOP;
   assign __cmd_rx_wren    = __ft245_rx_valid & `CHECK_MAGIC & `CHECK_TYPE_CMD;

   // ----------------------------------------------------------------------------
   // TX TO USB/FT601/FT245 BELOW:
   // ----------------------------------------------------------------------------

   assign pcie_tlp_tx_ready = ~__tlp_tx_almost_full;
   assign pcie_cfg_tx_ready = ~__cfg_tx_almost_full;

   // --------------------------------------------------------
   // Receive 64-bit data from incoming FIFO queues by priority
   // (1) PCIe TLP, (2) PCIe CFG, (3) Loopback.
   // Transmit 32-bit data to FT245 on request.
   // --------------------------------------------------------
   wire [63:0] __ft245_tx_din;
   wire        __ft245_tx_wren;
   wire        __ft245_tx_almost_full;
   fifo_64_32 i_fifo_tx245(
      .wr_clk     ( CLK                      ),
      .wr_rst     ( RESET                    ),
      .rd_clk     ( FT601_CLK                ),
      .rd_rst     ( ~FT601_RESET_N           ),
      .rd_en      ( ft601_tx_rden            ),
      .dout       ( ft601_tx_data            ),
      .din        ( __ft245_tx_din           ),
      .wr_en      ( __ft245_tx_wren          ),
      .full       (                          ),
      .almost_full( __ft245_tx_almost_full   ),
      .empty      ( ft601_tx_empty           ),
      .almost_empty( ft601_tx_almost_empty   ),
      .valid      ( ft601_tx_valid           )
   );

   // --------------------------------------------------------
   // Receive PCIe TLP data from PCIe core and put it into this
   // large FIFO. This FIFO maxes out most BRAM on the SP605
   // for performance reasons.
   //
   // TODO: replace this FIFO with an even larger vFIFO backed
   // by the on-board DDR3 memory for higher total bandwidth
   // and transfer speeds.
   // --------------------------------------------------------
   wire [63:0] __tlp_tx_dout;
   wire        __tlp_tx_rden;
   wire        __tlp_tx_almost_full;
   wire        __tlp_tx_empty;
   wire        __tlp_tx_wren;
   wire [33:0] __tlp_tx_din34;
   wire [33:0] __tlp_tx_dout34;
   wire        __tlp_tx_valid;
   assign      __tlp_tx_wren = pcie_tlp_tx_valid & ((pcie_tlp_tx_data[7:0] == 8'h77)?1'b1:1'b0);
   // shrink/expand 64->34->64 bits
   //(to save BRAM space)
   assign      __tlp_tx_din34[31:0] = pcie_tlp_tx_data[63:32]; // PCIe TLP data
   assign      __tlp_tx_din34[32]   = pcie_tlp_tx_data[10];    // Last PCIe TLP DWORD
   assign      __tlp_tx_din34[33]   = pcie_tlp_tx_data[11];    // BusMasterEnable
   assign      __tlp_tx_dout[7:0]   = 8'h77;
   assign      __tlp_tx_dout[9:8]   = 2'b11;
   assign      __tlp_tx_dout[10]    = __tlp_tx_dout34[32];
   assign      __tlp_tx_dout[11]    = __tlp_tx_dout34[33];
   assign      __tlp_tx_dout[31:12] = 20'h0;
   assign      __tlp_tx_dout[63:32] = __tlp_tx_dout34[31:0];
   fifo_34_34_deep i_fifo_pcie_tlp_tx(
      .clk        ( CLK                      ),
      .rst        ( RESET | ~FT601_RESET_N   ),
      .din        ( __tlp_tx_din34           ),
      .wr_en      ( __tlp_tx_wren            ),
      .rd_en      ( __tlp_tx_rden            ),
      .dout       ( __tlp_tx_dout34          ),
      .full       (                          ),
      .almost_full( __tlp_tx_almost_full     ),
      .empty      ( __tlp_tx_empty           ),
      .valid      ( __tlp_tx_valid           )
   );

   // --------------------------------------------------------
   // Receive incoming data from the PCIe configuration space
   // interface and put it into this FIFO.
   // --------------------------------------------------------
   wire [63:0] __cfg_tx_dout;
   wire        __cfg_tx_rden;
   wire        __cfg_tx_almost_full;
   wire        __cfg_tx_empty;
   wire        __cfg_tx_valid;
   assign      __cfg_tx_wren = pcie_cfg_tx_valid & ((pcie_cfg_tx_data[7:0] == 8'h77)?1'b1:1'b0);
   fifo_64_64_thin i_fifo_pcie_cfg_tx(
      .clk        ( CLK                      ),
      .rst        ( RESET | ~FT601_RESET_N   ),
      .din        ( pcie_cfg_tx_data         ),
      .wr_en      ( __cfg_tx_wren            ),
      .rd_en      ( __cfg_tx_rden            ),
      .dout       ( __cfg_tx_dout            ),
      .full       (                          ),
      .almost_full( __cfg_tx_almost_full     ),
      .empty      ( __cfg_tx_empty           ),
      .valid      ( __cfg_tx_valid           )
   );

   // --------------------------------------------------------
   // Fetch incoming 64-bit data from the FT601/FT245 FIFO if
   // data maches the correct signature. The FIFO is assumed
   // never to be full. If it's full data will be dropped.
   // FIFO forwards data onto the FT601 64/32 FIFO on request.
   // --------------------------------------------------------
   wire [63:0] __loop_tx_dout;
   wire        __loop_tx_rden;
   wire        __loop_tx_empty;
   wire        __loop_tx_valid;
   fifo_64_64_thin i_fifo_loop_tx(
      .clk        ( CLK                      ),
      .rst        ( RESET | ~FT601_RESET_N   ),
      .din        ( __ft245_rx_dout          ),
      .wr_en      ( __loop_rx_wren           ),
      .rd_en      ( __loop_tx_rden           ),
      .dout       ( __loop_tx_dout           ),
      .full       (                          ),
      .almost_full(                          ),
      .empty      ( __loop_tx_empty          ),
      .valid      ( __loop_tx_valid          )
   );
   
   // --------------------------------------------------------
   // Various control/command data that should be sent towards
   // the FT601 ends up in this FIFO before being sent onwards.
   // --------------------------------------------------------
   reg [63:0]  __cmd_tx_din_r;
   reg         __cmd_rx_wren_r;
   wire [63:0] __cmd_tx_dout;
   wire        __cmd_tx_rden;
   wire        __cmd_tx_empty;
   wire        __cmd_tx_valid;
   fifo_64_64_thin i_fifo_cmd_tx(
      .clk        ( CLK                      ),
      .rst        ( RESET | ~FT601_RESET_N   ),
      .din        ( __cmd_tx_din_r           ),
      .wr_en      ( __cmd_rx_wren_r          ),
      .rd_en      ( __cmd_tx_rden            ),
      .dout       ( __cmd_tx_dout            ),
      .full       (                          ),
      .almost_full(                          ),
      .empty      ( __cmd_tx_empty           ),
      .valid      ( __cmd_tx_valid           )
   );   

   // ASSIGNMENT LOGIC
   // Write to 64->32 bit FIFO is any of the supplying FIFOs have data.
   // Priority (1) PCIe TLP, (2) PCIe CFG, (3) Loopback, (4) Command.
   // *) 34-bit PCIe TLP FIFO to save BRAM space, 32-bit PCIe data +
   //    flags: (1) last PCIe TLP DWORD and (2) bus master are stored.
   //
   //             /---------------------------\ 1st priority
   // PCIe TLP -> | 34*-> PCIe TLP FIFO ->34* | ->--\
   //             \---------------------------/     |
   //                                               |
   //             /---------------------------\ 2nd |    /------------------------\
   // PCIe CFG -> | 64->  PCIe CFG FIFO  ->64 | ->--+--> | 64->  FT601 FIFO  ->32 | -> FT601
   //             \---------------------------/     |    \------------------------/
   //                                               |
   //             /---------------------------\ 3rd | priority
   // FT601    -> | 64->  Loopback FIFO  ->64 | ->--/
   //             \---------------------------/     | 
   //                                               |
   //             /---------------------------\ 4th | priority
   // VARIOUS  -> | 64->  Command FIFO   ->64 | ->--/
   //             \---------------------------/
   //
   assign __ft245_tx_wren  = __tlp_tx_valid | __cfg_tx_valid | __loop_tx_valid | __cmd_tx_valid;
   assign __ft245_tx_din   = __tlp_tx_valid ? __tlp_tx_dout : 
                                             (__cfg_tx_valid ? __cfg_tx_dout : 
                                                              (__loop_tx_valid ? __loop_tx_dout : __cmd_tx_dout));
   assign __tlp_tx_rden    = ~__tlp_tx_empty & ~__ft245_tx_almost_full;
   assign __cfg_tx_rden    = ~__cfg_tx_empty & __tlp_tx_empty & ~__ft245_tx_almost_full;
   assign __loop_tx_rden   = ~__loop_tx_empty & __cfg_tx_empty & __tlp_tx_empty & ~__ft245_tx_almost_full;
   assign __cmd_tx_rden    = ~__cmd_tx_empty & __loop_tx_empty & __cfg_tx_empty & __tlp_tx_empty & ~__ft245_tx_almost_full;
   
   // ----------------------------------------------------------------------------
   // LOGIC FOR COMMAND / CONTROL FIFO BELOW:
   // ----------------------------------------------------------------------------
   
   `define CHECK_CMD_VERSION  ((__ft245_rx_dout[31:24] == 8'h00) ? 1'b1 : 1'b0)
   
   always @ ( posedge CLK )
      if ( RESET | ~FT601_RESET_N )
         __cmd_rx_wren_r <= 1'b0;
      else
         begin
            __cmd_rx_wren_r <= __cmd_rx_wren & `CHECK_CMD_VERSION;
            if ( __cmd_rx_wren & `CHECK_CMD_VERSION )
               begin
                  __cmd_tx_din_r[63:48]   <= 16'h0001;   // VERSION number = 0001
                  __cmd_tx_din_r[47:32]   <= 16'hfeef;   // MAGIC
                  __cmd_tx_din_r[31:0]    <= __ft245_rx_dout[31:0];
               end
         end
         
endmodule
