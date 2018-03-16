//
// PCILeech FPGA.
//
// FIFO network / control.
//
// (c) Ulf Frisk, 2017-2018
// Author: Ulf Frisk, pcileech@frizk.net
// Special thanks to: Dmytro Oleksiuk @d_olex
//

module pcileech_fifo #(
    parameter       PARAM_DEVICE_ID = 0,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 0,
    parameter       PARAM_VERSION_NUMBER_MINOR = 0
) (
    input           clk,
    input           rst,
    input           pcie_lnk_up,
    
    input   [31:0]  ft601_rx_data,
    input           ft601_rx_wren,
    
    output  [255:0] ft601_tx_data,
    output          ft601_tx_valid,
    input           ft601_tx_rd_en,
    
    output  [31:0]  pcie_tlp_tx_data,
    output          pcie_tlp_tx_last,
    output          pcie_tlp_tx_valid,
    
    input   [31:0]  pcie_tlp_rx_data,
    input           pcie_tlp_rx_last,
    input           pcie_tlp_rx_valid,
    input           pcie_tlp_rx_empty,
    output          pcie_tlp_rx_rd_en,
    
    output  [63:0]  pcie_cfg_tx_data,
    output          pcie_cfg_tx_valid,
    
    input  [31:0]   pcie_cfg_rx_data,
    input           pcie_cfg_rx_valid,
    input           pcie_cfg_rx_empty,
    output          pcie_cfg_rx_rd_en
    );
   
   // ----------------------------------------------------------------------------
   // RX FROM USB/FT601/FT245 BELOW:
   // ----------------------------------------------------------------------------
   // Incoming data received from FT601 is converted from 32-bit to 64-bit.
   // This always happen regardless whether receiving FIFOs are full or not.
   // The actual data contains a MAGIC which tells which receiving FIFO should
   // accept the data. Receiving TYPEs are: PCIe TLP, PCIe CFG, Loopback, Command.
   //
   //                        /--> PCIe TLP (32-bit)
   //                        |
   // FT601 -->(32->64) -->--+--> PCIe CFG (64-bit)
   //                        |
   //                        +--> LOOPBACK (32-bit)
   //                        |
   //                        \--> COMMAND  (64-bit)
   //

   // ----------------------------------------------------------
   // Convert 32-bit incoming FT601 data to 64-bit below:
   // ----------------------------------------------------------
    reg [63:0]  ft601_rx_data64;
    reg [1:0]   ft601_rx_valid64_dw;
    wire        ft601_rx_valid64 = ft601_rx_valid64_dw[0] & ft601_rx_valid64_dw[1];
   
    always @ ( posedge clk )
        if ( rst | (~ft601_rx_wren & ft601_rx_valid64_dw[0] & ft601_rx_valid64_dw[1]) )
            ft601_rx_valid64_dw <= 2'b00;
        else if ( ft601_rx_wren )
            begin
                ft601_rx_data64 <= (ft601_rx_data64 << 32) | ft601_rx_data;
                ft601_rx_valid64_dw <= (ft601_rx_valid64_dw == 2'b01) ? 2'b11 : 2'b01;
            end
            
    // ----------------------------------------------------------
    // Route 64-bit incoming FT601 data to correct receiver below:
    // ----------------------------------------------------------
    `define CHECK_MAGIC     (ft601_rx_data64[7:0] == 8'h77)
    `define CHECK_TYPE_TLP  (ft601_rx_data64[9:8] == 2'b00)
    `define CHECK_TYPE_CFG  (ft601_rx_data64[9:8] == 2'b01)
    `define CHECK_TYPE_LOOP (ft601_rx_data64[9:8] == 2'b10)
    `define CHECK_TYPE_CMD  (ft601_rx_data64[9:8] == 2'b11)
    
    wire     _loop_rx_wren;
    wire     _cmd_rx_wren;
    assign   pcie_tlp_tx_valid   = ft601_rx_valid64 & `CHECK_MAGIC & `CHECK_TYPE_TLP;
    assign   pcie_cfg_tx_valid   = ft601_rx_valid64 & `CHECK_MAGIC & `CHECK_TYPE_CFG;
    assign   _loop_rx_wren       = ft601_rx_valid64 & `CHECK_MAGIC & `CHECK_TYPE_LOOP;
    assign   _cmd_rx_wren        = ft601_rx_valid64 & `CHECK_MAGIC & `CHECK_TYPE_CMD;
    
    // Incoming TLPs are forwarded to PCIe core logic.
    assign pcie_tlp_tx_data = ft601_rx_data64[63:32];
    assign pcie_tlp_tx_last = ft601_rx_data64[10];
    // Incoming CFGs are forwarded to PCIe core logic.
    assign pcie_cfg_tx_data = ft601_rx_data64;

    // ----------------------------------------------------------------------------
    // TX TO USB/FT601/FT245 BELOW:
    // ----------------------------------------------------------------------------
    //
    //                                         MULTIPLEXER
    //                                         ===========
    //                                         1st priority
    // PCIe TLP ->(32-bit) --------------------->--\
    //                                         2nd |    /-----------------------------------------\
    // PCIe CFG ->(32-bit)---------------------->--+--> | 256-> BUFFER FIFO (NATIVE OR DRAM) ->32 | -> FT601
    //                                             |    \-----------------------------------------/
    //            /--------------------------\ 3rd |
    // FT601   -> | 34->  Loopback FIFO ->34 | ->--/
    //            \--------------------------/     | 
    //                                             |
    //            /--------------------------\ 4th |
    // COMMAND -> | 34->  Command FIFO  ->34 | ->--/
    //            \--------------------------/
    //
   
    // ----------------------------------------------------------
    // LOOPBACK FIFO:
    // ----------------------------------------------------------
    wire [33:0]       _loop_dout;
    wire              _loop_valid;
    wire              _loop_empty;
    wire              _loop_rd_en;
    fifo_34_34 i_fifo_loop_tx(
        .clk            ( clk                       ),
        .srst           ( rst                       ),
        .rd_en          ( _loop_rd_en               ),
        .dout           ( _loop_dout                ),
        .din            ( {ft601_rx_data64[11:10], ft601_rx_data64[63:32]} ),
        .wr_en          ( _loop_rx_wren             ),
        .full           (                           ),
        .empty          ( _loop_empty               ),
        .valid          ( _loop_valid               )
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
        .clk            ( clk                       ),
        .srst           ( rst                       ),
        .rd_en          ( _cmd_rd_en                ),
        .dout           ( _cmd_dout                 ),
        .din            ( _cmd_din                  ),
        .wr_en          ( _cmd_wr_en                ),
        .full           (                           ),
        .empty          ( _cmd_empty                ),
        .valid          ( _cmd_valid                )
    );

    // ----------------------------------------------------------
    // MULTIPLEXER
    // ----------------------------------------------------------
    pcileech_mux i_pcileech_mux(
        .clk            ( clk                       ),
        .rst            ( rst                       ),
        // output
        .dout           ( ft601_tx_data             ),
        .valid          ( ft601_tx_valid            ),
        .rd_en          ( ft601_tx_rd_en            ),
        // port0: PCIe TLP (highest priority)
        .p0_din         ( pcie_tlp_rx_data          ),
        .p0_ctx         ( {1'b0, pcie_tlp_rx_last}  ),
        .p0_wr_en       ( pcie_tlp_rx_valid         ),
        .p0_has_data    ( ~pcie_tlp_rx_empty        ),
        .p0_req_data    ( pcie_tlp_rx_rd_en         ),
        // port1: PCIe CFG
        .p1_din         ( pcie_cfg_rx_data          ),
        .p1_ctx         ( 2'b00                     ),
        .p1_wr_en       ( pcie_cfg_rx_valid         ),
        .p1_has_data    ( ~pcie_cfg_rx_empty        ),
        .p1_req_data    ( pcie_cfg_rx_rd_en         ),
        // port2: LOOPBACK
        .p2_din         ( _loop_dout[31:0]          ),
        .p2_ctx         ( _loop_dout[33:32]         ),
        .p2_wr_en       ( _loop_valid               ),
        .p2_has_data    ( ~_loop_empty              ),
        .p2_req_data    ( _loop_rd_en               ),
        // port3: COMMAND (lowest priority)
        .p3_din         ( _cmd_dout[31:0]           ),
        .p3_ctx         ( _cmd_dout[33:32]          ),
        .p3_wr_en       ( _cmd_valid                ),
        .p3_has_data    ( ~_cmd_empty               ),
        .p3_req_data    ( _cmd_rd_en                )
    );
   
    // ----------------------------------------------------------------------------
    // LOGIC FOR COMMAND / CONTROL FIFO BELOW:
    // ----------------------------------------------------------------------------
    `define CHECK_CMD_VERSION_MAJOR     (ft601_rx_data64[31:24] == 8'h01)
    `define CHECK_CMD_STATUS            (ft601_rx_data64[31:24] == 8'h02)
    // DEVICE IDs as follows:
    // 00 = SP605/FT601
    // 01 = PCIeScreamer (artix7-35t)
    // 02 = AC701/FT601
    `define CHECK_CMD_DEVICE_ID         (ft601_rx_data64[31:24] == 8'h03)
    `define CHECK_CMD_VERSION_MINOR     (ft601_rx_data64[31:24] == 8'h05)
    
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
                    _cmd_din[33:0] <= 34'h00000002 | (pcie_lnk_up << 16);
                if ( `CHECK_CMD_DEVICE_ID )
                    _cmd_din[33:0] <= 34'h00000003 | (PARAM_DEVICE_ID << 24);
            end

endmodule
