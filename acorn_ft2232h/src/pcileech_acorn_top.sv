//
// PCILeech FPGA.
//
// Top module for the acorn Artix-7 board.
//
// (c) Ulf Frisk, 2018-2021
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_acorn_top #(
    // DEVICE IDs as follows:
    // 0 = SP605, 1 = PCIeScreamer R1, 2 = AC701,   3 = PCIeScreamer R2, 4 = Screamer M2,
    // 5 = NeTV2, 6-7 = RaptorDMA.     8 = FT2232H, 
    parameter       PARAM_DEVICE_ID = 8,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 4,
    parameter       PARAM_VERSION_NUMBER_MINOR = 9,
    parameter       PARAM_CUSTOM_VALUE = 32'hffffffff
) (
    // SYS
	input			clk_sys_p,
	input			clk_sys_n,
    input           ft245_clk,

    // SYSTEM LEDs and BUTTONs
    output          led_1,

    // PCI-E FABRIC
    output  [0:0]   pcie_tx_p,
    output  [0:0]   pcie_tx_n,
    input   [0:0]   pcie_rx_p,
    input   [0:0]   pcie_rx_n,
    input           pcie_clk_p,
    input           pcie_clk_n,
    input           pcie_perst_n,

    // TO/FROM FT601 PADS
    inout   [7:0]   ft245_data,
    input           ft245_rxf_n,
    input           ft245_txe_n,
    output          ft245_rd_n,
    output          ft245_wr_n,
    output          ft245_siwu_n,
    output          ft245_oe_n
    );
    
    // SYS
	wire            clk;                // 100MHz
    wire 			rst;
    
    // FIFO CTL <--> COM CTL
    IfComToFifo     dcom_fifo();
    
    // PCIe <--> FIFOs
    IfPCIeFifoCfg   dcfg();
    IfPCIeFifoTlp   dtlp();
    IfPCIeFifoCore  dpcie();
    IfShadow2Fifo   dshadow2fifo();
	
    // ----------------------------------------------------
    // CLK 200MHz -> 100MHz:
    // ----------------------------------------------------
       
    clk_wiz i_clk_wiz(
        .clk_in1_p          ( clk_sys_p             ),
		.clk_in1_n          ( clk_sys_n             ),
        .clkwiz_out_100     ( clk                   )
    );
    
    // ----------------------------------------------------
    // TickCount64 CLK and LED OUTPUT
    // ----------------------------------------------------

    time tickcount64 = 0;
    always @ ( posedge clk )
        tickcount64 <= tickcount64 + 1;

    assign rst = (tickcount64 < 64) ? 1'b1 : 1'b0;
    
    // ----------------------------------------------------
    // BUFFERED COMMUNICATION DEVICE (FT245/FT2232h)
    // ----------------------------------------------------
    
    pcileech_com i_pcileech_com (
        // SYS
        .clk                ( clk                   ),
        .clk_com            ( ft245_clk             ),
        .rst                ( rst                   ),
        .led_state_txdata   (                       ),  // ->
        .led_state_invert   ( 1'b0                  ),  // <-
        // FIFO CTL <--> COM CTL
        .dfifo              ( dcom_fifo.mp_com      ),
        // TO/FROM FT245 PADS
        .ft245_data         ( ft245_data            ),  // <> [7:0]
        .ft245_rxf_n        ( ft245_rxf_n           ),  // <-
        .ft245_txe_n        ( ft245_txe_n           ),  // <-
        .ft245_rd_n         ( ft245_rd_n            ),  // ->
        .ft245_wr_n         ( ft245_wr_n            ),  // ->
        .ft245_siwu_n       ( ft245_siwu_n          ),  // ->
        .ft245_oe_n         ( ft245_oe_n            )   // ->
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
        .pcie_present       ( 1'b1                  ),
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
    
    pcileech_pcie_a7 i_pcileech_pcie_a7(
        .clk_100            ( clk                   ),
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
        .led_state          ( led_1                 ),
        // FIFO CTL <--> PCIe
        .dfifo_cfg          ( dcfg.mp_pcie          ),
        .dfifo_tlp          ( dtlp.mp_pcie          ),
        .dfifo_pcie         ( dpcie.mp_pcie         ),
        .dshadow2fifo_src   ( dshadow2fifo.src      ),
        .dshadow2fifo_tlp   ( dshadow2fifo.tlp      )
    );

endmodule
