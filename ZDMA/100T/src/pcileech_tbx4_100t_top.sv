//
// PCILeech FPGA.
//
// Top module for PCILeech TB x4
//
// (c) Ulf Frisk, 2019-2024
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_tbx4_100t_top #(
    // DEVICE IDs as follows:
    parameter       PARAM_DEVICE_ID = 17,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 4,
    parameter       PARAM_VERSION_NUMBER_MINOR = 17,
    parameter       PARAM_CUSTOM_VALUE = 32'hffffffff,
    parameter       POWER_SW_MODE = 0,                 // disable_pcie_on_thunderbolt_noconnect_not_enabled(0), disable_pcie_on_thunderbolt_noconnect_enabled(1)
    parameter       POWER_SW_TIME = 60*125_000_000     // detection sample time in ticks of 125MHz (125M=1s)
) (
    // SYS
    input           clk_in,
    
    // SYSTEM LEDs and BUTTONs
    output          pcie_led,
    
    // TO/FROM FPGA IO BRIDGE
    input   [40:0]  BUS_DO,
    input           BUS_DO_CLK,
    output  [66:0]  BUS_DI,
	input           TB_CONNECT,
    input           BUS_DI_PROG_FULL,
    
    // PCI-E FABRIC
    output  [3:0]   pcie_tx_p,
    output  [3:0]   pcie_tx_n,
    input   [3:0]   pcie_rx_p,
    input   [3:0]   pcie_rx_n,
    input           pcie_clk_p,
    input           pcie_clk_n,
    input           pcie_present1,
    input           pcie_present2,
	input           pcie_perst1_n,
	input           pcie_perst2_n
    );

    // SYS
    wire rst;
    wire clk;
    wire clk_com;
    wire clk_comrx;
    reg  rst_sw = 0;
    
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
    
    // PCIe
    wire pcie_present = pcie_present1 && pcie_present2;
    wire pcie_perst_n = pcie_perst1_n && pcie_perst2_n && ~rst_sw;
    
    // ----------------------------------------------------
    // CLK: INPUT (clkin): 50MHz
    //      COMTX (clk_comtx): 200MHz
    //      SYS (clk):         125MHz
	//      COMRX (clk_comrx): 150MHz
    // ----------------------------------------------------

    wire clk_locked, clk_out1, clk_out2, clk_out3;
    clk_wiz_0 i_clk_wiz_0(
        .clk_in1    ( clk_in        ),  // <- 50MHz
        .clk_out1   ( clk_out1      ),  // -> 200MHz
        .clk_out2   ( clk_out2      ),  // -> 125MHz
        .clk_out3   ( clk_out3      ),  // -> 150MHz
        .locked     ( clk_locked    )
    );
    
    BUFG i_BUFG_1 ( .I( clk_locked ? clk_out1 : clk_in ), .O( clk_comtx ) );
    BUFG i_BUFG_2 ( .I( clk_locked ? clk_out2 : clk_in ), .O( clk ) );
    BUFG i_BUFG_3 ( .I( clk_locked ? clk_out3 : clk_in ), .O( clk_comrx ) );
    
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
    // POWER SWITCH MODE (DISABLE PCIE WHEN THUNDERBOLT NOT CONNECTED)
    // ----------------------------------------------------
	
    always @ ( posedge clk ) begin
        if ( rst ) begin
            rst_sw    <= 0;
        end
        else if ( (POWER_SW_MODE == 1) && (tickcount64 == POWER_SW_TIME) ) begin
            rst_sw    <= ~TB_CONNECT; 
        end
    end
	
    // ----------------------------------------------------
    // BUFFERED COMMUNICATION DEVICE (FPGA IO BRIDGE)
    // ----------------------------------------------------
    
    pcileech_com i_pcileech_com (
        // SYS
        .clk                ( clk                   ),
        .clk_comtx          ( clk_comtx             ),
        .clk_comrx          ( clk_comrx             ),
        .rst                ( rst                   ),
        // TO/FROM FPGA IO BRIDGE
        .BUS_DO             ( BUS_DO                ),
        .BUS_DO_CLK         ( BUS_DO_CLK            ),
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
