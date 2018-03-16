//
// PCILeech for Spartan6 SP605 with FTDI FT601.
//
// FIFO network / control.
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

module pcileech_fifo #(
    parameter       PARAM_DEVICE_ID = 0,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 0,
    parameter       PARAM_VERSION_NUMBER_MINOR = 0
) (
   input          clk,
   input          clk_pcie,
   input          rst,
   input          rst_pcie,
   input          pcie_lnk_up,
   
   input [31:0]   ft601_rx_data,
   input          ft601_rx_wren,
   
   output [255:0] ft601_tx_data,
   output         ft601_tx_valid,
   
   input [33:0]   pcie_tlp_tx_data,
   input          pcie_tlp_tx_valid,
   output         pcie_tlp_tx_ready,
   
   output [33:0]  pcie_tlp_rx_data,
   output         pcie_tlp_rx_valid,
   input          pcie_tlp_rx_ready,
   
   input [63:0]   pcie_cfg_tx_data,
   input          pcie_cfg_tx_valid,
   
   output [33:0]  pcie_cfg_rx_data,
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
   // Some control/status data is not required and is thrown away before data is
   // put into receiver 34-bit FIFO.
   //
   //                                              /---------------------------\
   //                                         /--> | 34->  PCIe TLP FIFO  ->34 | -> PCIe TLP
   //                                         |    \---------------------------/
   //                                         |
   //          /------------------------\     |    /---------------------------\
   // FT601 -> | 32->  FT601 FIFO  ->64 | ->--+--> | 34->  PCIe CFG FIFO  ->34 | -> PCIe CFG
   //          \------------------------/     |    \---------------------------/
   //                                         |
   //                                         +--> LOOPBACK
   //                                         |
   //                                         \--> COMMAND
   //                                              
   //

   // ----------------------------------------------------------
   // Receive 32-bit data from FT245 and convert it into 64-bit
   // data which is forwarded into different 64-bit FIFO which
   // depends on bit mask of read control bytes in data stream.
   // FIFO is assumed to never be full since read enable, rd_en
   // is always active.
   // ----------------------------------------------------------
   wire [63:0] _ft245_rx_dout;
   wire [33:0] _ft245_rx_data34;
   wire        _ft245_rx_valid;
   assign _ft245_rx_data34[31:0]   = _ft245_rx_dout[63:32];
   assign _ft245_rx_data34[33:32]  = _ft245_rx_dout[11:10];
   fifo_32_64 i_fifo_rx245(
      .rst           ( rst                      ),
      .wr_clk        ( clk                      ),
      .rd_clk        ( clk                      ),
      .din           ( ft601_rx_data            ), 
      .wr_en         ( ft601_rx_wren            ),
      .rd_en         ( 1'b1                     ),
      .dout          ( _ft245_rx_dout           ),
      .full          (                          ),
      .empty         (                          ),
      .valid         ( _ft245_rx_valid          )
   );
   
   // --------------------------------------------------------
   // Fetch incoming 64-bit data from the FT601/FT245 FIFO if
   // data maches the correct signature. The FIFO is assumed
   // never to be full. If it's full data will be dropped.
   // FIFO forwards data to the PCIe TLP interface.
   // --------------------------------------------------------
   wire        _tlp_rx_wren;
   fifo_34_34_deep i_fifo_pcie_tlp_rx(
      .rst           ( rst | rst_pcie           ),
      .wr_clk        ( clk                      ),
      .rd_clk        ( clk_pcie                 ),
      .din           ( _ft245_rx_data34         ),
      .wr_en         ( _tlp_rx_wren             ),
      .rd_en         ( pcie_tlp_rx_ready        ),
      .dout          ( pcie_tlp_rx_data         ),
      .full          (                          ),
      .almost_full   (                          ),
      .empty         (                          ),
      .valid         ( pcie_tlp_rx_valid        )
   );
   
   // --------------------------------------------------------
   // Fetch incoming 64-bit data from the FT601/FT245 FIFO if
   // data maches the correct signature. The FIFO is assumed
   // never to be full. If it's full data will be dropped.
   // FIFO forwards data to the PCIe CFG interface.
   // --------------------------------------------------------
   wire        _cfg_rx_wren;
   fifo_34_34 i_fifo_pcie_cfg_rx(
      .rst           ( rst | rst_pcie           ),
      .wr_clk        ( clk                      ),
      .rd_clk        ( clk_pcie                 ),
      .din           ( _ft245_rx_data34         ),
      .wr_en         ( _cfg_rx_wren             ),
      .rd_en         ( pcie_cfg_rx_ready        ),
      .dout          ( pcie_cfg_rx_data         ),
      .full          (                          ),
      .almost_full   (                          ),
      .empty         (                          ),
      .valid         ( pcie_cfg_rx_valid        )
   );
 
   `define CHECK_MAGIC     (_ft245_rx_dout[7:0] == 8'h77)
   `define CHECK_TYPE_TLP  (_ft245_rx_dout[9:8] == 2'b00)
   `define CHECK_TYPE_CFG  (_ft245_rx_dout[9:8] == 2'b01)
   `define CHECK_TYPE_LOOP (_ft245_rx_dout[9:8] == 2'b10)
   `define CHECK_TYPE_CMD  (_ft245_rx_dout[9:8] == 2'b11)

   wire     _loop_rx_wren;
   wire     _cmd_rx_wren;
   assign   _tlp_rx_wren    = _ft245_rx_valid & `CHECK_MAGIC & `CHECK_TYPE_TLP;
   assign   _cfg_rx_wren    = _ft245_rx_valid & `CHECK_MAGIC & `CHECK_TYPE_CFG;
   assign   _loop_rx_wren   = _ft245_rx_valid & `CHECK_MAGIC & `CHECK_TYPE_LOOP;
   assign   _cmd_rx_wren    = _ft245_rx_valid & `CHECK_MAGIC & `CHECK_TYPE_CMD;

   // ----------------------------------------------------------------------------
   // TX TO USB/FT601/FT245 BELOW:
   // ----------------------------------------------------------------------------
   //
   //                                           MULTIPLEXER
   //                                           ===========
   //             /---------------------------\ 1st priority
   // PCIe TLP -> | 34->  PCIe TLP FIFO  ->34 | ->--\
   //             \---------------------------/     |
   //                                               |
   //             /---------------------------\ 2nd |    /-----------------------------------------\
   // PCIe CFG -> | 64->  PCIe CFG FIFO  ->32 | ->--+--> | 256-> BUFFER FIFO (NATIVE OR DRAM) ->32 | -> FT601
   //             \---------------------------/     |    \-----------------------------------------/
   //                                               |
   //             /---------------------------\ 3rd | priority
   // FT601    -> | 34->  Loopback FIFO  ->34 | ->--/
   //             \---------------------------/     | 
   //                                               |
   //             /---------------------------\ 4th | priority
   // COMMAND  -> | 34->  Command FIFO   ->34 | ->--/
   //             \---------------------------/
   //

   // ----------------------------------------------------------
   // PCIe TLP FIFO:
   // Receive PCIe TLP data from PCIe core and put it into FIFO
   // 32-bit data and TLAST/BUSMASTER signals.
   // ----------------------------------------------------------
   wire              _tlp_tx_almost_full;
   wire [33:0]       _tlp_tx_dout;
   wire              _tlp_tx_valid;
   wire              _tlp_tx_empty;
   wire              _tlp_tx_rd_en;
   assign pcie_tlp_tx_ready = ~_tlp_tx_almost_full;
   fifo_34_34 i_fifo_pcie_tlp_tx(
      .wr_clk        ( clk_pcie                 ),
      .rd_clk        ( clk                      ),
      .rst           ( rst                      ),
      .rd_en         ( _tlp_tx_rd_en            ),
      .dout          ( _tlp_tx_dout             ),
      .din           ( pcie_tlp_tx_data         ),
      .wr_en         ( pcie_tlp_tx_valid        ),
      .full          (                          ),
      .almost_full   ( _tlp_tx_almost_full      ),
      .empty         ( _tlp_tx_empty            ),
      .valid         ( _tlp_tx_valid            )
   );
   
   // ----------------------------------------------------------
   // PCIe CFG FIFO:
   // Receive PCIe CFG data & metadata from PCIe core.
   // ----------------------------------------------------------
   wire [31:0]       _cfg_tx_dout;
   wire              _cfg_tx_valid;
   wire              _cfg_tx_empty;
   wire              _cfg_tx_rd_en;
   fifo_64_32 i_fifo_pcie_cfg_tx(
      .wr_clk        ( clk_pcie                 ),
      .rd_clk        ( clk                      ),
      .rst           ( rst                      ),
      .rd_en         ( _cfg_tx_rd_en            ),
      .dout          ( _cfg_tx_dout             ),
      .din           ( pcie_cfg_tx_data         ),
      .wr_en         ( pcie_cfg_tx_valid        ),
      .full          (                          ),
      .almost_full   (                          ),
      .empty         ( _cfg_tx_empty            ),
      .valid         ( _cfg_tx_valid            )
   );
   
   // ----------------------------------------------------------
   // LOOPBACK FIFO:
   // ----------------------------------------------------------
   wire [33:0]       _loop_dout;
   wire              _loop_valid;
   wire              _loop_empty;
   wire              _loop_rd_en;
   fifo_34_34 i_fifo_loop_tx(
      .wr_clk        ( clk                      ),
      .rd_clk        ( clk                      ),
      .rst           ( rst                      ),
      .rd_en         ( _loop_rd_en              ),
      .dout          ( _loop_dout               ),
      .din           ( _ft245_rx_data34         ),
      .wr_en         ( _loop_rx_wren            ),
      .full          (                          ),
      .almost_full   (                          ),
      .empty         ( _loop_empty              ),
      .valid         ( _loop_valid              )
   );
   
   // ----------------------------------------------------------
   // COMMAND FIFO:
   // ----------------------------------------------------------
   wire [33:0]       _cmd_dout;
   wire              _cmd_valid;
   wire              _cmd_empty;
   wire              _cmd_rd_en;
   reg               _cmd_wr_en;
   reg [33:0]        _cmd_din;
   fifo_34_34 i_fifo_cmd_tx(
      .wr_clk        ( clk                      ),
      .rd_clk        ( clk                      ),
      .rst           ( rst                      ),
      .rd_en         ( _cmd_rd_en               ),
      .dout          ( _cmd_dout                ),
      .din           ( _cmd_din                 ),
      .wr_en         ( _cmd_wr_en               ),
      .full          (                          ),
      .almost_full   (                          ),
      .empty         ( _cmd_empty               ),
      .valid         ( _cmd_valid               )
   );

   // ----------------------------------------------------------
   // MULTIPLEXER
   // ----------------------------------------------------------
   pcileech_mux i_pcileech_mux(
      .clk           ( clk                      ),
      .rst           ( rst                      ),
      // output
      .dout          ( ft601_tx_data            ),
      .valid         ( ft601_tx_valid           ),
      // port0: PCIe TLP (highest priority)
      .p0_din        ( _tlp_tx_dout[31:0]       ),
      .p0_ctx        ( _tlp_tx_dout[33:32]      ),
      .p0_wr_en      ( _tlp_tx_valid            ),
      .p0_has_data   ( ~_tlp_tx_empty           ),
      .p0_req_data   ( _tlp_tx_rd_en            ),
      // port1: PCIe CFG
      .p1_din        ( _cfg_tx_dout             ),
      .p1_ctx        ( 2'b00                    ),
      .p1_wr_en      ( _cfg_tx_valid            ),
      .p1_has_data   ( ~_cfg_tx_empty           ),
      .p1_req_data   ( _cfg_tx_rd_en            ),
      // port2: LOOPBACK
      .p2_din        ( _loop_dout[31:0]         ),
      .p2_ctx        ( _loop_dout[33:32]        ),
      .p2_wr_en      ( _loop_valid              ),
      .p2_has_data   ( ~_loop_empty             ),
      .p2_req_data   ( _loop_rd_en              ),
      // port3: COMMAND (lowest priority)
      .p3_din        ( _cmd_dout[31:0]          ),
      .p3_ctx        ( _cmd_dout[33:32]         ),
      .p3_wr_en      ( _cmd_valid               ),
      .p3_has_data   ( ~_cmd_empty              ),
      .p3_req_data   ( _cmd_rd_en               )
   );
   
    // ----------------------------------------------------------------------------
    // LOGIC FOR COMMAND / CONTROL FIFO BELOW:
    // ----------------------------------------------------------------------------
    `define CHECK_CMD_VERSION_MAJOR     (_ft245_rx_dout[31:24] == 8'h01)
    `define CHECK_CMD_STATUS            (_ft245_rx_dout[31:24] == 8'h02)
    // DEVICE IDs as follows:
    // 00 = SP605/FT601
    // 01 = PCIeScreamer (artix7-35t)
    // 02 = AC701/FT601
    `define CHECK_CMD_DEVICE_ID         (_ft245_rx_dout[31:24] == 8'h03)
    `define CHECK_CMD_VERSION_MINOR     (_ft245_rx_dout[31:24] == 8'h05)
    
    always @ ( posedge clk )
        if ( rst )
            _cmd_wr_en <= 1'b0;
        else
            begin
                _cmd_wr_en <= _cmd_rx_wren & (`CHECK_CMD_VERSION_MAJOR | `CHECK_CMD_VERSION_MINOR | `CHECK_CMD_DEVICE_ID | `CHECK_CMD_STATUS);
                if ( `CHECK_CMD_VERSION_MAJOR )
                    _cmd_din[33:0] <= 34'h00000001 | (PARAM_VERSION_NUMBER_MAJOR << 24);
                if ( `CHECK_CMD_VERSION_MINOR )
                    _cmd_din[33:0] <= 34'h00000005 | (PARAM_VERSION_NUMBER_MINOR << 24);
                if ( `CHECK_CMD_STATUS )
                    _cmd_din[33:0] <= 34'h00000002 | (pcie_lnk_up << 16) | (pcie_lnk_up << 16);
                if ( `CHECK_CMD_DEVICE_ID )
                    _cmd_din[33:0] <= 34'h00000003 | (PARAM_DEVICE_ID << 24);
            end
         
endmodule
