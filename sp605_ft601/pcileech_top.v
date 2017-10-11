//
// PCILeech for Spartan6 SP605 with FTDI FT601.
//
// Top module.
//
// (c) Ulf Frisk, 2017
// Author: Ulf Frisk, pcileech@frizk.net
// Special thanks to: Dmytro Oleksiuk @d_olex
//

module pcileech_top (
   // PCI-E FABRIC
   output            pci_exp_txp,
   output            pci_exp_txn,
   input             pci_exp_rxp,
   input             pci_exp_rxn,

   // PCIe CLK AND RESET
   input             sys_clk_p,
   input             sys_clk_n,
   input             sys_reset_n,

   // DIAGNOSTIC LEDs
   output [3:0]      SYS_LED,

   // TO/FROM FT601 PADS
   input             FT601_RESET_N,
   input             FT601_CLK,
   inout [31:0]      FT601_DATA,
   inout [3:0]       FT601_BE,
   input             FT601_RXF_N,
   input             FT601_TXE_N,
   output            FT601_WR_N,
   output            FT601_SIWU_N,
   output            FT601_RD_N,
   output            FT601_OE_N
);
   wire              sys_reset_n_c;
   wire              led_activity;

   // PCIe common
   wire              user_clk;
   wire              user_reset;
   wire              user_lnk_up;

   // FT601/FT245 <--> FIFOs
   wire [31:0]       ft601_rx_data;
   wire              ft601_rx_wren;
   wire [31:0]       ft601_tx_data;
   wire              ft601_tx_empty;
   wire              ft601_tx_almost_empty;
   wire              ft601_tx_valid;
   wire              ft601_tx_rden;
   
   // PCIe <--> FIFOs
   wire [63:0]       pcie_tlp_tx_data;
   wire              pcie_tlp_tx_valid;
   wire              pcie_tlp_tx_ready;
   wire [63:0]       pcie_tlp_rx_data;
   wire              pcie_tlp_rx_valid;
   wire              pcie_tlp_rx_ready;
   wire [63:0]       pcie_cfg_tx_data;
   wire              pcie_cfg_tx_valid;
   wire              pcie_cfg_tx_ready;
   wire [63:0]       pcie_cfg_rx_data;
   wire              pcie_cfg_rx_valid;
   wire              pcie_cfg_rx_ready;

   // Buffer for LEDs
   OBUF led_0_obuf(.O( SYS_LED[0] ), .I( ~sys_reset_n_c ));
   OBUF led_1_obuf(.O( SYS_LED[1] ), .I( user_reset ));
   OBUF led_2_obuf(.O( SYS_LED[2] ), .I( user_lnk_up ));
   OBUF led_3_obuf(.O( SYS_LED[3] ), .I( led_activity ));

   pcileech_ft601 i_pcileech_ft601(
      .FT601_CLK              ( FT601_CLK             ),
      .FT601_RESET_N          ( FT601_RESET_N         ),
      // TO/FROM FT601 PADS
      .FT601_DATA             ( FT601_DATA            ),
      .FT601_BE               ( FT601_BE              ),
      .FT601_TXE_N            ( FT601_TXE_N           ),
      .FT601_RXF_N            ( FT601_RXF_N           ),
      .FT601_SIWU_N           ( FT601_SIWU_N          ),
      .FT601_WR_N             ( FT601_WR_N            ),
      .FT601_RD_N             ( FT601_RD_N            ),
      .FT601_OE_N             ( FT601_OE_N            ),
      // FT601 CTL <--> FIFOs
      .fifo_rx_data           ( ft601_rx_data         ),
      .fifo_rx_wr             ( ft601_rx_wren         ),
      .fifo_tx_data           ( ft601_tx_data         ),
      .fifo_tx_empty          ( ft601_tx_empty        ),
      .fifo_tx_almost_empty   ( ft601_tx_almostempty  ),
      .fifo_tx_valid          ( ft601_tx_valid        ),
      .fifo_tx_rd             ( ft601_tx_rden         ),
      // Activity  LED
      .led_activity           ( led_activity          )
   );

   pcileech_fifo i_pcileech_fifo(
      .FT601_CLK              ( FT601_CLK             ),
      .FT601_RESET_N          ( FT601_RESET_N         ),
      .CLK                    ( user_clk              ),
      .RESET                  ( user_reset            ),
      // FT601 CTL <--> FIFOs
      .ft601_rx_data          ( ft601_rx_data         ),
      .ft601_rx_wren          ( ft601_rx_wren         ),
      .ft601_tx_data          ( ft601_tx_data         ),
      .ft601_tx_empty         ( ft601_tx_empty        ),
      .ft601_tx_almost_empty  ( ft601_tx_almostempty  ),
      .ft601_tx_valid         ( ft601_tx_valid        ),
      .ft601_tx_rden          ( ft601_tx_rden         ),
      // PCIe <--> FIFOs
      .pcie_tlp_tx_data       ( pcie_tlp_tx_data      ),
      .pcie_tlp_tx_valid      ( pcie_tlp_tx_valid     ),
      .pcie_tlp_tx_ready      ( pcie_tlp_tx_ready     ),
      .pcie_tlp_rx_data       ( pcie_tlp_rx_data      ),
      .pcie_tlp_rx_valid      ( pcie_tlp_rx_valid     ),
      .pcie_tlp_rx_ready      ( pcie_tlp_rx_ready     ),
      .pcie_cfg_tx_data       ( pcie_cfg_tx_data      ),
      .pcie_cfg_tx_valid      ( pcie_cfg_tx_valid     ),
      .pcie_cfg_tx_ready      ( pcie_cfg_tx_ready     ),
      .pcie_cfg_rx_data       ( pcie_cfg_rx_data      ),
      .pcie_cfg_rx_valid      ( pcie_cfg_rx_valid     ),
      .pcie_cfg_rx_ready      ( pcie_cfg_rx_ready     )
   );
   
   pcileech_pcie i_pcileech_pcie(
      // TO/FROM SYSTEM
      .pci_exp_txp            ( pci_exp_txp           ),
      .pci_exp_txn            ( pci_exp_txn           ),
      .pci_exp_rxp            ( pci_exp_rxp           ),
      .pci_exp_rxn            ( pci_exp_rxn           ),
      .user_clk               ( user_clk              ),
      .user_reset             ( user_reset            ),
      .user_lnk_up            ( user_lnk_up           ),
      .sys_reset_n_c          ( sys_reset_n_c         ),
      .sys_clk_p              ( sys_clk_p             ),
      .sys_clk_n              ( sys_clk_n             ),
      .sys_reset_n            ( sys_reset_n           ),
      // PCIe <--> FIFOs
      .pcie_tlp_tx_data       ( pcie_tlp_tx_data      ),
      .pcie_tlp_tx_valid      ( pcie_tlp_tx_valid     ),
      .pcie_tlp_tx_ready      ( pcie_tlp_tx_ready     ),
      .pcie_tlp_rx_data       ( pcie_tlp_rx_data      ),
      .pcie_tlp_rx_valid      ( pcie_tlp_rx_valid     ),
      .pcie_tlp_rx_ready      ( pcie_tlp_rx_ready     ),
      .pcie_cfg_tx_data       ( pcie_cfg_tx_data      ),
      .pcie_cfg_tx_valid      ( pcie_cfg_tx_valid     ),
      .pcie_cfg_tx_ready      ( pcie_cfg_tx_ready     ),
      .pcie_cfg_rx_data       ( pcie_cfg_rx_data      ),
      .pcie_cfg_rx_valid      ( pcie_cfg_rx_valid     ),
      .pcie_cfg_rx_ready      ( pcie_cfg_rx_ready     )
   );
endmodule
