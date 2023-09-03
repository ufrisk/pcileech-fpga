//
// PCILeech FPGA.
//
// Top module for the NeTV2 Artix-7 board.
//
// (c) Ulf Frisk, 2019-2023
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_netv2_top #(
    // DEVICE IDs as follows:
    // 0 = SP605, 1 = PCIeScreamer R1, 2 = AC701, 3 = PCIeScreamer R2, 4 = Screamer M2, 5 = NeTV2
    parameter       PARAM_DEVICE_ID = 5,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 4,
    parameter       PARAM_VERSION_NUMBER_MINOR = 12,
    parameter       PARAM_CUSTOM_VALUE = 32'hffffffff,
    parameter       PARAM_UDP_STATIC_ADDR = 32'hc0a800de,   // 192.168.0.222
    parameter       PARAM_UDP_STATIC_FORCE = 1'b0,
    parameter       PARAM_UDP_PORT = 16'h6f3a               // 28474
) (
    // SYS
    input           clk50,
    
    // SYSTEM LEDs and BUTTONs
    output          led00,
    output          led01,
    output          led10,
    output          led11,
    output          led20,
    output          led21,
    
    // PCI-E FABRIC
    output  [0:0]   pcie_tx_p,
    output  [0:0]   pcie_tx_n,
    input   [0:0]   pcie_rx_p,
    input   [0:0]   pcie_rx_n,
    input           pcie_clk_p,
    input           pcie_clk_n,
    input           pcie_perst_n,
    output reg      pcie_wake_n = 1'b1,
      
    // ETH
    output          eth_clk50,
    output          eth_rst_n,
    input   [1:0]   eth_rx_data,
    input           eth_crs_dv,
    output          eth_tx_en,
    output  [1:0]   eth_tx_data,
    output          eth_mdc,
    inout           eth_mdio,
    input           eth_rx_err
        
    );
    
    // SYS
    wire            clk;                // 100MHz
    wire            rst;
    
    // FIFO CTL <--> COM CTL
    IfComToFifo     dcom_fifo();
    
    // FIFO CTL <--> PCIe
    IfPCIeFifoCfg   dcfg();
    IfPCIeFifoTlp   dtlp();
    IfPCIeFifoCore  dpcie();
    IfShadow2Fifo   dshadow2fifo();
	
    // ----------------------------------------------------
    // TickCount64 CLK
    // ----------------------------------------------------

    time tickcount64 = 0;
    always @ ( posedge clk ) begin
        tickcount64 <= tickcount64 + 1;
    end

    assign rst = ((tickcount64 < 64) ? 1'b1 : 1'b0);
    
    // ----------------------------------------------------
    // CLK 50MHz -> 100MHz:
    // ----------------------------------------------------
       
    clk_wiz i_clk_wiz(
        .clkwiz_in_50       ( clk50                 ),
        .clkwiz_out_100     ( clk                   )
    );

    // ----------------------------------------------------
    // BUFFERED COMMUNICATION DEVICE (ETH)
    // ----------------------------------------------------
    
    pcileech_com i_pcileech_com (
        // SYS
        .clk                ( clk                   ),
        .clk_com            ( clk                   ),
        .rst                ( rst                   ),
        .led_state_txdata   ( led10                 ),  // ->
        .led_state_invert   ( 1'b0                  ),  // <-
        // FIFO CTL <--> COM CTL
        .dfifo              ( dcom_fifo.mp_com      ),
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
        .eth_cfg_static_addr ( PARAM_UDP_STATIC_ADDR    ),  // <- [31:0]
        .eth_cfg_static_force ( PARAM_UDP_STATIC_FORCE  ),  // <-
        .eth_cfg_port       ( PARAM_UDP_PORT        ),  // <- [15:0]
        .eth_led_state_red  ( led20                 ),  // ->
        .eth_led_state_green( led21                 )   // ->
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
        .led_state          ( led00                 ),
        // FIFO CTL <--> PCIe
        .dfifo_cfg          ( dcfg.mp_pcie          ),
        .dfifo_tlp          ( dtlp.mp_pcie          ),
        .dfifo_pcie         ( dpcie.mp_pcie         ),
        .dshadow2fifo_src   ( dshadow2fifo.src      ),
        .dshadow2fifo_tlp   ( dshadow2fifo.tlp      )
    );

endmodule
