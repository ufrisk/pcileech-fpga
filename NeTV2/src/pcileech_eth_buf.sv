//
// PCILeech FPGA RMII ETHERNET.
//
//
// (c) Ulf Frisk, 2019
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps

module pcileech_eth_buf #(
    parameter           PARAM_UDP_STATIC_ADDR = 32'hc0a800de,   // 192.168.0.222
    parameter           PARAM_UDP_PORT = 16'h6f3a,              // 28473
    parameter           PARAM_UDP_STATIC_FORCE = 0              // don't force static address - try dhcp for 10s before fallback to static
) (
    // SYS
    input               clk,                // 100MHz CLK
    input               rst,
    
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
    
    // State and Activity LEDs
    output              led_state_red,
    output              led_state_green,
    output              led_state_txdata,
    
    // TO/FROM FIFO
    output [31:0]       dout,
    output              dout_valid,
    input [255:0]       din,
    input               din_wr_en,
    output              din_ready
    
    );
    
    wire [31:0] eth_din;
    wire        eth_din_empty;
    wire        eth_din_wr_en;
    wire        eth_din_ready;
    
    wire [31:0] fram_din;
    wire fram_almost_full;
    wire fram_wr_en;
    wire out_buffer1_almost_full;
    fifo_32_32_deep i_fifo_32_32_deep_out_buffer2(
        .clk                ( clk                   ),
        .srst               ( rst                   ),
        .din                ( fram_din              ),
        .wr_en              ( fram_wr_en            ),
        .rd_en              ( eth_din_ready         ),
        .dout               ( eth_din               ),
        .full               (                       ),
        .almost_full        ( fram_almost_full      ),
        .empty              ( eth_din_empty         ),
        .valid              ( eth_din_wr_en         )
    );
    fifo_256_32 i_fifo_256_32_out_buffer1(
        .clk                ( clk                   ),
        .srst               ( rst                   ),
        .din                ( din                   ),
        .wr_en              ( din_wr_en             ),
        .rd_en              ( ~fram_almost_full     ),
        .dout               ( fram_din              ),
        .full               (                       ),
        .almost_full        ( out_buffer1_almost_full ),
        .empty              (                       ),
        .valid              ( fram_wr_en            )
    );
    assign din_ready = ~out_buffer1_almost_full;
    OBUF led_ld3_obuf(.O( led_state_txdata ), .I( ~eth_din_empty ));
    
    // ----------------------------------------------------
    // UDP Ethernet Below:
    // ----------------------------------------------------
    
   
    pcileech_eth #(
        .PARAM_UDP_STATIC_ADDR  ( PARAM_UDP_STATIC_ADDR     ),
        .PARAM_UDP_PORT         ( PARAM_UDP_PORT            ),
        .PARAM_UDP_STATIC_FORCE ( PARAM_UDP_STATIC_FORCE    )
    ) i_pcileech_eth(
        // SYS
        .clk                ( clk                   ),
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
        // State and Activity LEDs
        .led_state_red      ( led_state_red         ),  // ->
        .led_state_green    ( led_state_green       ),  // ->
        // TO/FROM FIFO
        .dout               ( dout                  ),  // -> [31:0]
        .dout_valid         ( dout_valid            ),  // ->
        .din                ( eth_din               ),  // <- [31:0]
        .din_empty          ( eth_din_empty         ),  // <-
        .din_wr_en          ( eth_din_wr_en         ),  // <-
        .din_ready          ( eth_din_ready         )   // ->       

    );

endmodule
