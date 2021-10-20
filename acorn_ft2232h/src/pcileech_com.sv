//
// PCILeech Buffered Communication Core for FT245/FT2232h
//
// (c) Ulf Frisk, 2021
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps

module pcileech_com (
    // SYS
    input               clk,                // 100MHz SYSTEM CLK
    input               clk_com,            // COMMUNICATION CORE CLK
    input               rst,
    output              led_state_txdata,
    input               led_state_invert,

    // TO/FROM FIFO
    IfComToFifo.mp_com  dfifo,

    // FT245
    inout   [7:0]       ft245_data,
    input               ft245_rxf_n,
    input               ft245_txe_n,
    output              ft245_rd_n,
    output              ft245_wr_n,
    output              ft245_siwu_n,
    output              ft245_oe_n
    );

    // ----------------------------------------------------------------------------
    // COMMUNICATION CORE INITIAL ON-BOARD DEFAULT RX-DATA
    // Sometimes there is a need to perform actions - such as setting DRP-related
    // values before the PCIe core is brought online. This is possible by specify
    // "virtual" COM-core initial transmitted values below.
    // ----------------------------------------------------------------------------
    
    bit [63:0] initial_rx [5] = '{
            // Modify data below to set own actions - examples:
            // - send some initial TLP on core startup.
            // - set initial VID/PID if PCIe core has been modified.
            // - write to DRP memory space to alter the core.
            // replace / expand on dummy values below - for syntax of each 64-bit word
            // please consult sources and also device_fpga.c in the LeechCore project.
            64'h00000000_00000000,
            64'h00000000_00000000,
            64'h00000000_00000000,
            64'h00000000_00000000,
            // Bring the PCIe core online from initial hot-reset state. This is done by
            // setting control bit in PCIleech FOFO CMD register. This should ideally be
            // done after DRP&Config actions are completed - but before sending PCIe TLPs.
            64'h00000003_80182377
        };
        
    time tickcount64 = 0;
    always @ ( posedge clk )
        tickcount64 <= rst ? 0 : tickcount64 + 1;
        
    time tickcount64_com = 0;
    always @ ( posedge clk_com )
        tickcount64_com <= rst ? 0 : tickcount64_com + 1;
            
    wire        initial_rx_valid    = ~rst & (tickcount64 >= 16) & (tickcount64 < $size(initial_rx) + 16);
    wire [63:0] initial_rx_data     = initial_rx_valid ? initial_rx[tickcount64 - 16] : 64'h0;
    
    // ----------------------------------------------------------------------------
    // COMMUNICATION CORE RX DATA BELOW:
    // 1: convert 8-bit signal into 64-bit signal using logic.
    // 2: change clock domain from clk_com to clk using a very shallow fifo. 
    // ----------------------------------------------------------------------------
    
    wire [7:0]  com_rx_data8;
    wire        com_rx_valid8;
    
    reg [63:0]  com_rx_data64;
    reg [7:0]   com_rx_valid64_dw;
    wire        com_rx_valid64 = (com_rx_valid64_dw == 8'b11111111);
    wire [63:0] com_rx_dout;
    wire        com_rx_valid;
   
    always @ ( posedge clk_com )
        if ( rst || (~com_rx_valid8 & (com_rx_valid64_dw == 8'b11111111)) )
            com_rx_valid64_dw <= 8'b00000000;
        else if ( com_rx_valid8 && (com_rx_data8 == 8'h55) && (com_rx_data64[55:0] == 56'h66665555666655) )
            // resync logic to allow the host to send resync data that will
            // allow bitstream to sync to proper 32->64-bit sequence in case
            // it should have happen to get out of sync at startup/shutdown.
            com_rx_valid64_dw <= 8'b00000000;
        else if ( com_rx_valid8 )
            begin
                com_rx_data64       <= (com_rx_data64 << 8) | com_rx_data8;
                if ( com_rx_valid64 )
                    com_rx_valid64_dw   <= {7'b0000000, com_rx_valid8 };
                else
                    com_rx_valid64_dw   <= (com_rx_valid64_dw << 1) | com_rx_valid8;
            end
    
    fifo_64_64_clk2_comrx i_fifo_64_64_clk2_comrx(
        .rst            ( rst | (tickcount64_com<2) ),
        .wr_clk         ( clk_com                   ),
        .rd_clk         ( clk                       ),
        .din            ( com_rx_data64             ),
        .wr_en          ( com_rx_valid64            ),
        .rd_en          ( 1'b1                      ),
        .dout           ( com_rx_dout               ),
        .full           (                           ),
        .empty          (                           ),
        .valid          ( com_rx_valid              )
    );
    
    assign dfifo.com_dout = initial_rx_valid ? initial_rx_data : com_rx_dout;
    assign dfifo.com_dout_valid = initial_rx_valid | com_rx_valid;
    
    // ----------------------------------------------------------------------------
    // COMMUNICATION CORE TX DATA BELOW:
    // ----------------------------------------------------------------------------
       
    wire [7:0]  core_din;
    wire        core_din_empty;
    wire        core_din_wr_en;
    wire        core_din_ready;
    
    wire [31:0] com_tx_data;
    wire        com_tx_wr_en;
    wire        com_tx_almost_full;
    wire        com_tx_prog_full;
    
    wire        out_buffer1_almost_full;

    assign dfifo.com_din_ready = ~out_buffer1_almost_full;
    OBUF led_ld3_obuf(.O( led_state_txdata ), .I( tickcount64_com[26] ^ /* com_tx_prog_full ^ */ led_state_invert ));

    fifo_32_8_clk1_comtx i_fifo_32_8_clk1_comtx(
        .clk            ( clk_com                   ),
        .srst           ( rst                       ),
        .din            ( com_tx_data               ),
        .wr_en          ( com_tx_wr_en              ),
        .rd_en          ( core_din_ready            ),
        .dout           ( core_din                  ),
        .full           (                           ),
        .almost_full    ( com_tx_almost_full        ),
        .empty          ( core_din_empty            ),
        .prog_full      ( com_tx_prog_full          ),  // threshold = 6
        .valid          ( core_din_wr_en            )
    );
    fifo_256_32_clk2_comtx i_fifo_256_32_clk2_comtx(
        .rd_clk         ( clk_com                   ),
        .wr_clk         ( clk                       ),
        .rst            ( rst                       ),
        .din            ( dfifo.com_din             ),
        .wr_en          ( dfifo.com_din_wr_en       ),
        .rd_en          ( ~com_tx_almost_full       ),
        .dout           ( com_tx_data               ),
        .full           (                           ),
        .almost_full    ( out_buffer1_almost_full   ),
        .empty          (                           ),
        .valid          ( com_tx_wr_en              )
    );

    // ----------------------------------------------------
    // FT245/2232h BELOW:
    // ----------------------------------------------------

    reg  __d_ft245_txe_n;
    always @ ( posedge clk_com )
        __d_ft245_txe_n <= ft245_txe_n;
    
    pcileech_ft245 i_pcileech_ft245(
        // SYS
        .clk                ( clk_com               ),
        .rst                ( rst                   ),
        // TO/FROM FT245 PADS
        .FT245_DATA         ( ft245_data            ),
        .FT245_TXE_N        ( ft245_txe_n           ),
        .FT245_RXF_N        ( ft245_rxf_n           ),
        .FT245_SIWU_N       ( ft245_siwu_n          ),
        .FT245_WR_N         ( ft245_wr_n            ),
        .FT245_RD_N         ( ft245_rd_n            ),
        .FT245_OE_N         ( ft245_oe_n            ),
        // TO/FROM FIFO
        .dout               ( com_rx_data8          ),  // -> [7:0]
        .dout_valid         ( com_rx_valid8         ),  // ->        
        .din                ( core_din              ),  // <- [7:0]
        .din_empty          ( core_din_empty        ),  // <-
        .din_wr_en          ( core_din_wr_en        ),  // <-
        .din_req_data       ( core_din_ready        )   // ->
    );


endmodule
