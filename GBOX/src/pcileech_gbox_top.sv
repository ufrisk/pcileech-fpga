//
// PCILeech FPGA.
//
// Top module for PCILeech TB
//
// (c) Ulf Frisk, 2019-2024
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_gbox_top #(
    // DEVICE IDs as follows:
    parameter       PARAM_DEVICE_ID = 18,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 4,
    parameter       PARAM_VERSION_NUMBER_MINOR = 15,
    parameter       PARAM_CUSTOM_VALUE = 32'hffffffff
) (
    // SYS
    input           clk_in,
    
    // SYSTEM LEDs and BUTTONs
    output          pcie_led,
    input           power_sw,
    
    // TO/FROM FPGA IO BRIDGE
    input   [36:0]  BUS_DO,
    output  [68:0]  BUS_DI,
    input           BUS_DI_PROG_FULL,
    
    // PCI-E FABRIC
    output  [3:0]   pcie_tx_p,
    output  [3:0]   pcie_tx_n,
    input   [3:0]   pcie_rx_p,
    input   [3:0]   pcie_rx_n,
    input           pcie_clk_p,
    input           pcie_clk_n,
    input           pcie_present,
	input           pcie_perst_n
    );

    // SYS
    wire rst;
    wire clk;
    wire clk_com;
    
    // FIFO CTL <--> COM CTL
    wire [63:0]     com_dout;
    wire            com_dout_valid;
    wire [255:0]    com_din;
    wire            com_din_wr_en;
    wire            com_din_ready;
    
    // FIFO CTL <--> COM CTL
    IfComToFifo     dcom_fifo();
	
    // FIFO CTL <--> PCIe
    IfPCIeFifoCfg   dcfg();
    IfPCIeFifoTlp   dtlp();
    IfPCIeFifoCore  dpcie();
    IfShadow2Fifo   dshadow2fifo();
    
    // ----------------------------------------------------
    // CLK: INPUT (clkin): 50MHz
    //      COM (clk_com): 125MHz
    //      SYS (clk):     125MHz
    // ----------------------------------------------------

    wire clk_locked, clk_out1, clk_out2;
    clk_wiz_0 i_clk_wiz_0(
        .clk_in1    ( clk_in        ),  // <- 50MHz
        .clk_out1   ( clk_out1      ),  // -> 150MHz
        .clk_out2   ( clk_out2      ),  // -> 125MHz
        .locked     ( clk_locked    )
    );
    
    BUFG i_BUFG_1 ( .I( clk_locked ? clk_out1 : clk_in ), .O( clk_com ) );
    BUFG i_BUFG_2 ( .I( clk_locked ? clk_out2 : clk_in ), .O( clk ) );
    
    // ----------------------------------------------------
    // TickCount64 CLK
    // ----------------------------------------------------

    time tickcount64 = 0;
    always @ ( posedge clk )
        tickcount64 <= tickcount64 + 1;
    assign rst = (tickcount64 < 64) ? 1'b1 : 1'b0;
    
    wire            led_pcie;
    OBUF led_ld1_obuf(.O(pcie_led), .I(led_pcie));
	
    // ----------------------------------------------------
    // BUFFERED COMMUNICATION DEVICE (FPGA IO BRIDGE)
    // ----------------------------------------------------
    
    pcileech_com i_pcileech_com (
        // SYS
        .clk                ( clk                   ),
        .clk_com            ( clk_com               ),
        .rst                ( rst                   ),
        // TO/FROM FPGA IO BRIDGE
        .BUS_DO             ( BUS_DO                ),
        .BUS_DI             ( BUS_DI                ),
        .BUS_DI_PROG_FULL   ( BUS_DI_PROG_FULL      ),
        // FIFO CTL <--> COM CTL
        .com_dout           ( dcom_fifo.com_dout        ),
        .com_dout_valid     ( dcom_fifo.com_dout_valid  ),
        .com_din_ready      ( dcom_fifo.com_din_ready   ),
        .com_din            ( dcom_fifo.com_din         ),
        .com_din_wr_en      ( dcom_fifo.com_din_wr_en   )
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
