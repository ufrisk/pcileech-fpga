//
// PCILeech FPGA.
//
// Top module for the AC701 Artix-7 board.
//
// (c) Ulf Frisk, 2018-2019
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_ac701_top #(
    // DEVICE IDs as follows:
    // 0 = SP605, 1 = PCIeScreamer R1, 2 = AC701, 3 = PCIeScreamer R2, 4 = PCIeScreamer M2, 5 = NeTV2
    parameter       PARAM_DEVICE_ID = 2,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 4,
    parameter       PARAM_VERSION_NUMBER_MINOR = 0
) (
    // SYSTEM CLK (100MHz)
    input           clk,

    // SYSTEM LEDs and BUTTONs
    input           gpio_sw_south,
    input           gpio_sw_north,
    output  [2:0]   gpio_led,

    // PCI-E FABRIC
    output  [0:0]   pcie_tx_p,
    output  [0:0]   pcie_tx_n,
    input   [0:0]   pcie_rx_p,
    input   [0:0]   pcie_rx_n,
    input           pcie_clk_p,
    input           pcie_clk_n,
    input           pcie_rst_n,

    // TO/FROM FT601 PADS
    input           ft601_rst_n,
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
    wire rst = gpio_sw_north;
    
    // FIFO CTL <--> ETH
    wire [31:0]     ft601_dout;
    wire            ft601_dout_valid;
    wire [255:0]    ft601_din;
    wire            ft601_din_wr_en;
    wire            ft601_din_ready;
    
    // PCIe <--> FIFOs
    IfPCIeCfgFifo   dcfg();
    IfPCIeTlpFifo   dtlp();
    
    // ----------------------------------------------------
    // TickCount64 CLK and LED OUTPUT
    // ----------------------------------------------------

    time tickcount64 = 0;
    always @ ( posedge clk )
        tickcount64 <= tickcount64 + 1;
    OBUF led0_obuf(.O( gpio_led[0] ), .I( gpio_sw_south | gpio_sw_north | tickcount64[26] ));
    
    // ----------------------------------------------------
    // FT601 (Buffered)
    // ----------------------------------------------------
    
    pcileech_ft601_buf i_pcileech_ft601_buf(
        // SYS
        .clk                ( clk                   ),
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
        // State and Activity LEDs
        .led_state_invert   ( gpio_sw_south         ),  // <-
        .led_state_txdata   ( gpio_led[1]           ),  // ->
        // TO/FROM FIFO
        .dout               ( ft601_dout            ),  // -> [31:0]
        .dout_valid         ( ft601_dout_valid      ),  // ->
        .din                ( ft601_din             ),  // <- [255:0]
        .din_wr_en          ( ft601_din_wr_en       ),  // <-
        .din_ready          ( ft601_din_ready       )   // ->       
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
        .ft601_rx_data      ( ft601_dout            ),
        .ft601_rx_wren      ( ft601_dout_valid      ),
        // FIFO CTL <--> RAM FIFO
        .ft601_tx_data      ( ft601_din             ),
        .ft601_tx_valid     ( ft601_din_wr_en       ),
        .ft601_tx_rd_en     ( ft601_din_ready       ),
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
        .pcie_tx_p          ( pcie_tx_p[0]          ),
        .pcie_tx_n          ( pcie_tx_n[0]          ),
        .pcie_rx_p          ( pcie_rx_p[0]          ),
        .pcie_rx_n          ( pcie_rx_n[0]          ),
        .pcie_clk_p         ( pcie_clk_p            ),
        .pcie_clk_n         ( pcie_clk_n            ),
        .pcie_rst_n         ( pcie_rst_n | ~rst     ),
        // State and Activity LEDs
        .led_state          ( gpio_led[2]           ),
        // PCIe <--> FIFOs
        .dfifo_cfg          ( dcfg.mp_pcie          ),
        .dfifo_tlp          ( dtlp.mp_pcie          )
    );

endmodule
