//
// PCILeech Buffered Communication Core for either:
//   - FT601 USB3.
//   - FPGA RMII ETHERNET.
//
//
// (c) Ulf Frisk, 2019-2020
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
//`define ENABLE_ETH
`define ENABLE_FT601

module pcileech_com (
    // SYS
    input               clk,                // 100MHz SYSTEM CLK
    input               clk_com,            // COMMUNICATION CORE CLK
    input               rst,
    output              led_state_txdata,
    input               led_state_invert,

    // TO/FROM FIFO
    IfComToFifo.mp_com  dfifo,

`ifdef ENABLE_FT601
    // FT601
    inout   [31:0]      ft601_data,
    output  [3:0]       ft601_be,
    input               ft601_rxf_n,
    input               ft601_txe_n,
    output              ft601_wr_n,
    output              ft601_siwu_n,
    output              ft601_rd_n,
    output              ft601_oe_n
`endif /* ENABLE_FT601 */    
`ifdef ENABLE_ETH
    // ETH
    output              eth_clk50,
    output              eth_rst_n,
    input   [1:0]       eth_rx_data,
    input               eth_crs_dv,
    output              eth_tx_en,
    output  [1:0]       eth_tx_data,
    output              eth_mdc,
    inout               eth_mdio,
    input               eth_rx_err,
    input   [31:0]      eth_cfg_static_addr,
    input               eth_cfg_static_force,
    input   [15:0]      eth_cfg_port,
    output              eth_led_state_red,
    output              eth_led_state_green
`endif /* ENABLE_ETH */
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
    // 1: convert 32-bit signal into 64-bit signal using logic.
    // 2: change clock domain from clk_com to clk using a very shallow fifo.
    //    due to previous 32->64 conversion this will be fine if: 2*clk_com < clk. 
    // ----------------------------------------------------------------------------
    
    wire [31:0] com_rx_data32;
    wire        com_rx_valid32;
    reg [63:0]  com_rx_data64;
    reg [1:0]   com_rx_valid64_dw;
    wire        com_rx_valid64 = com_rx_valid64_dw[0] & com_rx_valid64_dw[1];
    wire [63:0] com_rx_dout;
    wire        com_rx_valid;
   
    always @ ( posedge clk_com )
        if ( rst | (~com_rx_valid32 & com_rx_valid64_dw[0] & com_rx_valid64_dw[1]) )
            com_rx_valid64_dw <= 2'b00;
        else if ( com_rx_valid32 && (com_rx_data32 == 32'h66665555) && (com_rx_data64[31:0] == 32'h66665555) )
            // resync logic to allow the host to send resync data that will
            // allow bitstream to sync to proper 32->64-bit sequence in case
            // it should have happen to get out of sync at startup/shutdown.
            com_rx_valid64_dw <= 2'b00;
        else if ( com_rx_valid32 )
            begin
                com_rx_data64 <= (com_rx_data64 << 32) | com_rx_data32;
                com_rx_valid64_dw <= (com_rx_valid64_dw == 2'b01) ? 2'b11 : 2'b01;
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
       
    wire [31:0] core_din;
    wire        core_din_empty;
    wire        core_din_wr_en;
    wire        core_din_ready;
    
    wire [31:0] com_tx_data;
    wire        com_tx_wr_en;
    wire        com_tx_almost_full;
    wire        com_tx_prog_full;
    wire        com_tx_prog_empty;
    
    wire        ft601_bug_workaround;
    wire        out_buffer1_almost_full;

    assign dfifo.com_din_ready = ~out_buffer1_almost_full;
    OBUF led_ld3_obuf(.O( led_state_txdata ), .I( com_tx_prog_full ^ led_state_invert ));
    
    fifo_32_32_clk1_comtx i_fifo_32_32_clk1_comtx(
        .clk            ( clk_com                   ),
        .srst           ( rst                       ),
        .din            ( ft601_bug_workaround ? 32'h66665555 : com_tx_data ),
        .wr_en          ( com_tx_wr_en | ft601_bug_workaround ),
        .rd_en          ( core_din_ready            ),
        .dout           ( core_din                  ),
        .full           (                           ),
        .almost_full    ( com_tx_almost_full        ),
        .empty          ( core_din_empty            ),
        .prog_empty     ( com_tx_prog_empty         ),  // threshold = 3
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
    // FT601 USB3 BELOW:
    // ----------------------------------------------------
`ifdef ENABLE_FT601

    reg  __d_ft601_txe_n;
    always @ ( posedge clk_com )
        __d_ft601_txe_n <= ft601_txe_n;
    // FTDI have a bug ( in chip or driver ) which doesn't terminate transfer if
    // even multiple of 1024 bytes are transmitted. Always insert five (5) MAGIC
    // DWORD (0x66665555) in beginning of stream to mitigate this.  Since normal
    // data size is always a multiple of 32-bytes/256-bits this will resolve the
    // issue. 
    assign ft601_bug_workaround = com_tx_prog_empty & __d_ft601_txe_n & ~com_tx_wr_en;
    
    pcileech_ft601 i_pcileech_ft601(
        // SYS
        .clk                ( clk_com               ),
        .rst                ( rst                   ),
        // TO/FROM FT601 PADS
        .FT601_DATA         ( ft601_data            ),
        .FT601_BE           ( ft601_be              ),
        .FT601_TXE_N        ( ft601_txe_n           ),
        .FT601_RXF_N        ( ft601_rxf_n           ),
        .FT601_SIWU_N       ( ft601_siwu_n          ),
        .FT601_WR_N         ( ft601_wr_n            ),
        .FT601_RD_N         ( ft601_rd_n            ),
        .FT601_OE_N         ( ft601_oe_n            ),
        // TO/FROM FIFO
        .dout               ( com_rx_data32         ),  // -> [31:0]
        .dout_valid         ( com_rx_valid32        ),  // ->        
        .din                ( core_din              ),  // <- [31:0]
        .din_empty          ( core_din_empty        ),  // <-
        .din_wr_en          ( core_din_wr_en        ),  // <-
        .din_req_data       ( core_din_ready        )   // ->
    );
`endif /* ENABLE_FT601 */

    // ----------------------------------------------------
    // UDP Ethernet Below:
    // ----------------------------------------------------
`ifdef ENABLE_ETH
    assign ft601_bug_workaround = 1'b0;

    pcileech_eth i_pcileech_eth(
        // SYS
        .clk                ( clk_com               ),
        .rst                ( rst                   ),
        // MAC/RMII
        .eth_clk50          ( eth_clk50             ),
        .eth_rst_n          ( eth_rst_n             ),
        .eth_crs_dv         ( eth_crs_dv            ),
        .eth_rx_data        ( eth_rx_data           ),
        .eth_rx_err         ( eth_rx_err            ),
        .eth_tx_en          ( eth_tx_en             ),
        .eth_tx_data        ( eth_tx_data           ),
        .eth_mdc            ( eth_mdc               ),
        .eth_mdio           ( eth_mdio              ),
        // CFG
        .cfg_static_addr    ( eth_cfg_static_addr   ),  // <- [31:0]
        .cfg_static_force   ( eth_cfg_static_force  ),  // <-
        .cfg_port           ( eth_cfg_port          ),  // <- [15:0]
        // State and Activity LEDs
        .led_state_red      ( eth_led_state_red     ),  // ->
        .led_state_green    ( eth_led_state_green   ),  // ->
        // TO/FROM FIFO
        .dout               ( com_rx_data32         ),  // -> [31:0]
        .dout_valid         ( com_rx_valid32        ),  // ->
        .din                ( core_din              ),  // <- [31:0]
        .din_empty          ( core_din_empty        ),  // <-
        .din_wr_en          ( core_din_wr_en        ),  // <-
        .din_ready          ( core_din_ready        )   // ->       
    );
`endif /* ENABLE_ETH */

endmodule
