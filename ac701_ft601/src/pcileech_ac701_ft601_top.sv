//
// PCILeech FPGA.
//
// Top module for the AC701 Artix-7 board (200t676).
//
// (c) Ulf Frisk, 2019-2024
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_ac701_ft601_top #(
    parameter       PARAM_DEVICE_ID = 2,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 4,
    parameter       PARAM_VERSION_NUMBER_MINOR = 15,
    parameter       PARAM_CUSTOM_VALUE = 32'hffffffff
) (
    // SYS
	input			sysclk_p,
	input			sysclk_n,
    input           ft601_clk,
    
    // SYSTEM LEDs and BUTTONs
    input           gpio_sw_south,
    input           gpio_sw_north,
    output  [2:0]   gpio_led,
    
    // PCI-E FABRIC
    output  [3:0]   pcie_tx_p,
    output  [3:0]   pcie_tx_n,
    input   [3:0]   pcie_rx_p,
    input   [3:0]   pcie_rx_n,
    input           pcie_clk_p,
    input           pcie_clk_n,
    input           pcie_perst_n,
    output reg      pcie_wake_n = 1'b1,
    
    // TO/FROM FT601 PADS
    output          ft601_rst_n,
    
    inout   [31:0]  ft601_data,
    output  [3:0]   ft601_be,
    input           ft601_rxf_n,
    input           ft601_txe_n,
    output          ft601_wr_n,
    output          ft601_siwu_n,
    output          ft601_rd_n,
    output          ft601_oe_n
    );
    
    // SYS
    wire            clk;
    wire            rst;
    
    // FIFO CTL <--> COM CTL
    wire [63:0]     com_dout;
    wire            com_dout_valid;
    wire [255:0]    com_din;
    wire            com_din_wr_en;
    wire            com_din_ready;
    wire            led_com;
    wire            led_pcie;
    
    // FIFO CTL <--> COM CTL
    IfComToFifo     dcom_fifo();
	
    // FIFO CTL <--> PCIe
    IfPCIeFifoCfg   dcfg();
    IfPCIeFifoTlp   dtlp();
    IfPCIeFifoCore  dpcie();
    IfShadow2Fifo   dshadow2fifo();
    
    // ----------------------------------------------------
    // CLK 200MHz -> 100MHz:
    // ----------------------------------------------------
       
    clk_wiz i_clk_wiz(
        .clk_in1_p          ( sysclk_p              ),
		.clk_in1_n          ( sysclk_n              ),
        .clkwiz_out_100     ( clk                   )
    );
	
    // ----------------------------------------------------
    // TickCount64 CLK
    // ----------------------------------------------------
    
    time tickcount64 = 0;
    always @ ( posedge clk )
        tickcount64 <= tickcount64 + 1;
    
    OBUF led_ld0_obuf(.O( gpio_led[0] ), .I( gpio_sw_south ^ gpio_sw_north ^ tickcount64[26] ));
    OBUF led_ld1_obuf(.O( gpio_led[2] ), .I( ~led_pcie ));
    OBUF led_ld2_obuf(.O( gpio_led[1] ), .I( ~led_com ));
    
    assign rst = gpio_sw_north | ((tickcount64 < 64) ? 1'b1 : 1'b0);
    assign ft601_rst_n = ~rst;
    
    // ----------------------------------------------------
    // BUFFERED COMMUNICATION DEVICE (FT601)
    // ----------------------------------------------------
    
    pcileech_com i_pcileech_com (
        // SYS
        .clk                ( clk                   ),
        .clk_com            ( ft601_clk             ),
        .rst                ( rst                   ),
        .led_state_txdata   ( led_com               ),  // ->
        .led_state_invert   ( gpio_sw_south         ),  // <-
        // FIFO CTL <--> COM CTL
        .dfifo              ( dcom_fifo.mp_com      ),
        // TO/FROM FT601 PADS
        .ft601_data         ( ft601_data            ),  // <> [31:0]
        .ft601_be           ( ft601_be              ),  // -> [3:0]
        .ft601_txe_n        ( ft601_txe_n           ),  // <-
        .ft601_rxf_n        ( ft601_rxf_n           ),  // <-
        .ft601_siwu_n       ( ft601_siwu_n          ),  // ->
        .ft601_wr_n         ( ft601_wr_n            ),  // ->
        .ft601_rd_n         ( ft601_rd_n            ),  // ->
        .ft601_oe_n         ( ft601_oe_n            )   // ->
    );
    
    // ----------------------------------------------------
    // FIFO CTL
    // ----------------------------------------------------
    
    pcileech_fifo #(
        .PARAM_DEVICE_ID            ( PARAM_DEVICE_ID               ),
        .PARAM_VERSION_NUMBER_MAJOR ( PARAM_VERSION_NUMBER_MAJOR    ),
        .PARAM_VERSION_NUMBER_MINOR ( PARAM_VERSION_NUMBER_MINOR    ),
        .PARAM_CUSTOM_VALUE         ( PARAM_CUSTOM_VALUE            )
    ) i_pcileech_fifo (
        .clk                ( clk                   ),
        .rst                ( rst                   ),
        .rst_cfg_reload     ( 1'b0                  ),
        .pcie_present       ( pcie_present          ),
        .pcie_perst_n       ( pcie_perst_n          ),
        // FIFO CTL <--> COM CTL
        .dcom               ( dcom_fifo.mp_fifo     ),
        // FIFO CTL <--> PCIe
        .dcfg               ( dcfg.mp_fifo          ),
        .dtlp               ( dtlp.mp_fifo          ),
        .dpcie              ( dpcie.mp_fifo         ),
        .dshadow2fifo       ( dshadow2fifo.fifo     )
    );
    
    // ----------------------------------------------------
    // PCIe
    // ----------------------------------------------------
    
    pcileech_pcie_a7x4 i_pcileech_pcie_a7x4(
        .clk_sys            ( clk                   ),
        .rst                ( rst                   ),
        // PCIe fabric
        .pcie_tx_p          ( pcie_tx_p             ),
        .pcie_tx_n          ( pcie_tx_n             ),
        .pcie_rx_p          ( pcie_rx_p             ),
        .pcie_rx_n          ( pcie_rx_n             ),
        .pcie_clk_p         ( pcie_clk_p            ),
        .pcie_clk_n         ( pcie_clk_n            ),
        .pcie_perst_n       ( pcie_perst_n          ),
        // State and Activity LEDs
        .led_state          ( led_pcie              ),
        // FIFO CTL <--> PCIe
        .dfifo_cfg          ( dcfg.mp_pcie          ),
        .dfifo_tlp          ( dtlp.mp_pcie          ),
        .dfifo_pcie         ( dpcie.mp_pcie         ),
        .dshadow2fifo       ( dshadow2fifo.shadow   )
    );

endmodule
