//
// PCILeech FPGA.
//
// Top module for the NeTV2 Artix-7 board.
//
// (c) Ulf Frisk, 2019
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_netv2_top #(
    // DEVICE IDs as follows:
    // 0 = SP605, 1 = PCIeScreamer R1, 2 = AC701, 3 = PCIeScreamer R2, 4 = PCIeScreamer M2, 5 = NeTV2
    parameter       PARAM_DEVICE_ID = 5,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 4,
    parameter       PARAM_VERSION_NUMBER_MINOR = 0,
    parameter       PARAM_UDP_STATIC_ADDR = 32'hc0a800de
) (
    // SYS
    input clk50,
    
    // SYSTEM LEDs and BUTTONs
    output led00,
    output led01,
    output led10,
    output led11,
    output led20,
    output led21,
    
    // PCI-E FABRIC
    output  [0:0]   pcie_tx_p,
    output  [0:0]   pcie_tx_n,
    input   [0:0]   pcie_rx_p,
    input   [0:0]   pcie_rx_n,
    input           pcie_clk_p,
    input           pcie_clk_n,
    input           pcie_rst_n,
      
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
    wire clk;               // 100MHz
    wire rst = 1'b0;
    
    // FIFO CTL <--> ETH
    wire [31:0]     eth_dout;
    wire            eth_dout_valid;
    wire [255:0]    eth_din;
    wire            eth_din_wr_en;
    wire            eth_din_ready;
    
    // PCIe <--> FIFOs
    IfPCIeCfgFifo   dcfg();
    IfPCIeTlpFifo   dtlp();
    
    // ----------------------------------------------------
    // CLK 50MHz -> 100MHz:
    // ----------------------------------------------------
       
    clk_wiz i_clk_wiz(
        .clkwiz_in_50       ( clk50                 ),
        .clkwiz_out_100     ( clk                   )
    );

    // ----------------------------------------------------
    // ETH (Buffered)
    // ----------------------------------------------------
    
    pcileech_eth_buf #(
        .PARAM_UDP_STATIC_ADDR  ( PARAM_UDP_STATIC_ADDR )    
    ) i_pcileech_eth_buf(
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
        .led_state_red      ( led20                 ),  // ->
        .led_state_green    ( led21                 ),  // ->
        .led_state_txdata   ( led10                 ),  // ->
        // TO/FROM FIFO
        .dout               ( eth_dout              ),  // -> [31:0]
        .dout_valid         ( eth_dout_valid        ),  // ->
        .din                ( eth_din               ),  // <- [255:0]
        .din_wr_en          ( eth_din_wr_en         ),  // <-
        .din_ready          ( eth_din_ready         )   // ->       

    );
    
    // ----------------------------------------------------
    // FIFO CTL
    // ----------------------------------------------------
    
    pcileech_fifo #(
        .PARAM_DEVICE_ID            ( PARAM_DEVICE_ID               ),
        .PARAM_VERSION_NUMBER_MAJOR ( PARAM_VERSION_NUMBER_MAJOR    ),
        .PARAM_VERSION_NUMBER_MINOR ( PARAM_VERSION_NUMBER_MINOR    )    
    ) i_pcileech_fifo (
        .clk                ( clk                   ),
        .rst                ( rst                   ),
        // FIFO CTL <--> FT601 CTL
        .ft601_rx_data      ( eth_dout              ),
        .ft601_rx_wren      ( eth_dout_valid        ),
        // FIFO CTL <--> RAM FIFO
        .ft601_tx_data      ( eth_din               ),
        .ft601_tx_valid     ( eth_din_wr_en         ),
        .ft601_tx_rd_en     ( eth_din_ready         ),
        // PCIe <--> FIFOs
        .dcfg               ( dcfg.mp_fifo          ),
        .dtlp               ( dtlp.mp_fifo          )
    );
    
    // ----------------------------------------------------
    // PCIe
    // ----------------------------------------------------
    
    pcileech_pcie_a7 i_pcileech_pcie_a7(
        .clk_100            ( clk                   ),
        // PCIe fabric
        .pcie_tx_p          ( pcie_tx_p             ),
        .pcie_tx_n          ( pcie_tx_n             ),
        .pcie_rx_p          ( pcie_rx_p             ),
        .pcie_rx_n          ( pcie_rx_n             ),
        .pcie_clk_p         ( pcie_clk_p            ),
        .pcie_clk_n         ( pcie_clk_n            ),
        .pcie_rst_n         ( pcie_rst_n | ~rst     ),
        // State and Activity LEDs
        .led_state          ( led00                 ),
        // PCIe <--> FIFOs
        .dfifo_cfg          ( dcfg.mp_pcie          ),
        .dfifo_tlp          ( dtlp.mp_pcie          )
    );

endmodule
