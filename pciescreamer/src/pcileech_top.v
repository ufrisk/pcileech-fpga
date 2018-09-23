//
// PCILeech FPGA.
//
// Top module for the PCIeScreamer Artix-7 board.
//
// (c) Ulf Frisk, 2018
// Author: Ulf Frisk, pcileech@frizk.net
//

module pcileech_pciescreamer_top #(
    // DEVICE IDs as follows:
    // 0 = SP605, 1 = PCIeScreamer, 2 = AC701
    parameter       PARAM_DEVICE_ID = 1,
    parameter       PARAM_VERSION_NUMBER_MAJOR = 3,
    parameter       PARAM_VERSION_NUMBER_MINOR = 3
) (
    // SYSTEM CLK (100MHz)
    input           clk,

    // SYSTEM LEDs and BUTTONs
    input           user_btn_sw3_n,
    input           user_btn_sw4_n,
    output          user_led_ld1,
    output          user_led_ld2,

    // PCI-E FABRIC
    output  [0:0]   pci_exp_txp,
    output  [0:0]   pci_exp_txn,
    input   [0:0]   pci_exp_rxp,
    input   [0:0]   pci_exp_rxn,
    input           sys_clk_p,
    input           sys_clk_n,
    input           sys_rst_n,
    
    // DDR
    output [13:0]   DDR3_addr,
    output [2:0]    DDR3_ba,
    output          DDR3_cas_n,
    output [0:0]    DDR3_ck_n,
    output [0:0]    DDR3_ck_p,
    output [0:0]    DDR3_cke,
    output [1:0]    DDR3_dm,
    inout [15:0]    DDR3_dq,
    inout [1:0]     DDR3_dqs_n,
    inout [1:0]     DDR3_dqs_p,
    output [0:0]    DDR3_odt,
    output          DDR3_ras_n,
    output          DDR3_reset_n,
    output          DDR3_we_n,
    //output [0:0]    DDR3_cs_n,

    // TO/FROM FT601 PADS
    output          ft601_rst_n_pciescr,
    inout   [31:0]  ft601_data,
    inout   [3:0]   ft601_be,
    input           ft601_rxf_n,
    input           ft601_txe_n,
    output          ft601_wr_n,
    output          ft601_siwu_n,
    output          ft601_rd_n,
    output          ft601_oe_n
    );
    
    wire            rst;
    assign          rst = ~user_btn_sw4_n;
    assign          ft601_rst_n_pciescr = ~rst;

    wire            led_activity;
    
    // PCIe common
    wire            user_lnk_up;
    
    // FT601/FT245 --> FIFO CTL
    wire [31:0]     ft601_rx_data;
    wire            ft601_rx_wren;
    
    // vFIFO --> FT601/FT245
    wire [31:0]     ft601_tx_data;
    wire            ft601_tx_empty;
    wire            ft601_tx_valid;
    wire            ft601_tx_rden;
    
    // FIFO CTL --> vFIFO
    wire [255:0]    vfifo_0_in_data;
    wire            vfifo_0_in_valid;
    wire            vfifo_0_in_ready;
    
    // PCIe <--> FIFOs
    wire [31:0]     pcie_tlp_tx_data;
    wire            pcie_tlp_tx_last;
    wire            pcie_tlp_tx_valid;
    
    wire [31:0]     pcie_tlp_rx_data;
    wire            pcie_tlp_rx_last;
    wire            pcie_tlp_rx_valid;
    wire            pcie_tlp_rx_empty;
    wire            pcie_tlp_rx_rd_en;
    
    wire [63:0]     pcie_cfg_tx_data;
    wire            pcie_cfg_tx_valid;
    
    wire [31:0]     pcie_cfg_rx_data;
    wire            pcie_cfg_rx_valid;
    wire            pcie_cfg_rx_empty;
    wire            pcie_cfg_rx_rd_en;
    
    // Buffer for LEDs
    OBUF led_ld1_obuf(.O( user_led_ld1 ), .I( led_activity ^ ~user_btn_sw3_n));
    OBUF led_ld2_obuf(.O( user_led_ld2 ), .I( user_lnk_up ));
    
    pcileech_ft601 i_pcileech_ft601(
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
        // FT601 CTL <--> FIFO CTL
        .dout               ( ft601_rx_data         ),
        .dout_valid         ( ft601_rx_wren         ),
        // FT601 CTL <--> MAIN OUTPUT FIFO  
        .din                ( ft601_tx_data         ),
        .din_empty          ( ft601_tx_empty        ),
        .din_wr_en          ( ft601_tx_valid        ),
        .din_req_data       ( ft601_tx_rden         ),
        // Activity LED
        .led_activity       ( led_activity          )
    );
    
    pcileech_vfifo_ctl i_pcileech_vfifo_ctl(
        .clk                ( clk                   ),
        .rst                ( rst                   ),
        // DDR
        .DDR3_addr          ( DDR3_addr             ),
        .DDR3_ba            ( DDR3_ba               ),
        .DDR3_cas_n         ( DDR3_cas_n            ),
        .DDR3_ck_n          ( DDR3_ck_n             ),
        .DDR3_ck_p          ( DDR3_ck_p             ),
        .DDR3_cke           ( DDR3_cke              ),
        .DDR3_dm            ( DDR3_dm               ),
        .DDR3_dq            ( DDR3_dq               ),
        .DDR3_dqs_n         ( DDR3_dqs_n            ),
        .DDR3_dqs_p         ( DDR3_dqs_p            ),
        .DDR3_odt           ( DDR3_odt              ),
        .DDR3_ras_n         ( DDR3_ras_n            ),
        .DDR3_reset_n       ( DDR3_reset_n          ),
        .DDR3_we_n          ( DDR3_we_n             ),
        //.DDR3_cs_n          ( DDR3_0_cs_n           ),
        // vFIFO --> FT601        
        .ft601_txe_n        ( ft601_txe_n           ),
        .ft601_tx_dout      ( ft601_tx_data         ),
        .ft601_tx_rden      ( ft601_tx_rden         ),
        .ft601_tx_valid     ( ft601_tx_valid        ),
        .ft601_tx_empty     ( ft601_tx_empty        ),
        // FIFO CTL --> vFIFO
        .vfifo_0_in_data    ( vfifo_0_in_data       ),  // <- [255:0]
        .vfifo_0_in_valid   ( vfifo_0_in_valid      ),  // <- (NB! valid must not be asserted two CLKs in a row)
        .vfifo_0_in_ready   ( vfifo_0_in_ready      )   // ->
    );
    
    pcileech_fifo #(
        .PARAM_DEVICE_ID            ( PARAM_DEVICE_ID               ),
        .PARAM_VERSION_NUMBER_MAJOR ( PARAM_VERSION_NUMBER_MAJOR    ),
        .PARAM_VERSION_NUMBER_MINOR ( PARAM_VERSION_NUMBER_MINOR    )    
    ) i_pcileech_fifo (
        .clk                ( clk                   ),
        .rst                ( rst                   ),
        .pcie_lnk_up        ( user_lnk_up           ),
        // FT601 --> FIFO CTL
        .ft601_rx_data      ( ft601_rx_data         ),
        .ft601_rx_wren      ( ft601_rx_wren         ),
        // FIFO CTL --> vFIFO
        .ft601_tx_data      ( vfifo_0_in_data       ),  // -> [255:0]
        .ft601_tx_valid     ( vfifo_0_in_valid      ),  // ->
        .ft601_tx_rd_en     ( vfifo_0_in_ready      ),  // <-
        // PCIe <--> FIFOs
        .pcie_tlp_tx_data   ( pcie_tlp_tx_data      ),  // -> [31:0]
        .pcie_tlp_tx_last   ( pcie_tlp_tx_last      ),  // ->
        .pcie_tlp_tx_valid  ( pcie_tlp_tx_valid     ),  // ->
        
        .pcie_tlp_rx_data   ( pcie_tlp_rx_data      ),  // <- [31:0]
        .pcie_tlp_rx_last   ( pcie_tlp_rx_last      ),  // <-
        .pcie_tlp_rx_valid  ( pcie_tlp_rx_valid     ),  // <-
        .pcie_tlp_rx_empty  ( pcie_tlp_rx_empty     ),  // <-
        .pcie_tlp_rx_rd_en  ( pcie_tlp_rx_rd_en     ),  // ->  
        
        .pcie_cfg_tx_data   ( pcie_cfg_tx_data      ),  // -> [63:0]
        .pcie_cfg_tx_valid  ( pcie_cfg_tx_valid     ),  // ->
        
        .pcie_cfg_rx_data   ( pcie_cfg_rx_data      ),  // <- [31:0]
        .pcie_cfg_rx_valid  ( pcie_cfg_rx_valid     ),  // <-
        .pcie_cfg_rx_empty  ( pcie_cfg_rx_empty     ),  // <-
        .pcie_cfg_rx_rd_en  ( pcie_cfg_rx_rd_en     )   // ->
    );
    
    pcileech_pcie_a7 i_pcileech_pcie_a7(
        .clk                ( clk                   ),
        // TO/FROM SYSTEM
        .pci_exp_txp        ( pci_exp_txp           ),
        .pci_exp_txn        ( pci_exp_txn           ),
        .pci_exp_rxp        ( pci_exp_rxp           ),
        .pci_exp_rxn        ( pci_exp_rxn           ),
        .user_lnk_up        ( user_lnk_up           ),
        .sys_clk_p          ( sys_clk_p             ),
        .sys_clk_n          ( sys_clk_n             ),
        .sys_rst_n          ( sys_rst_n | user_btn_sw4_n ),
        // PCIe <--> FIFOs
        .pcie_tlp_tx_data   ( pcie_tlp_tx_data      ),  // <- [31:0]
        .pcie_tlp_tx_last   ( pcie_tlp_tx_last      ),  // <-
        .pcie_tlp_tx_valid  ( pcie_tlp_tx_valid     ),  // <-
        
        .pcie_tlp_rx_data   ( pcie_tlp_rx_data      ),  // -> [31:0]
        .pcie_tlp_rx_last   ( pcie_tlp_rx_last      ),  // ->
        .pcie_tlp_rx_valid  ( pcie_tlp_rx_valid     ),  // ->
        .pcie_tlp_rx_empty  ( pcie_tlp_rx_empty     ),  // ->
        .pcie_tlp_rx_rd_en  ( pcie_tlp_rx_rd_en     ),  // <-  
        
        .pcie_cfg_tx_data   ( pcie_cfg_tx_data      ),  // <- [63:0]
        .pcie_cfg_tx_valid  ( pcie_cfg_tx_valid     ),  // <-
        
        .pcie_cfg_rx_data   ( pcie_cfg_rx_data      ),  // -> [31:0]
        .pcie_cfg_rx_valid  ( pcie_cfg_rx_valid     ),  // ->
        .pcie_cfg_rx_empty  ( pcie_cfg_rx_empty     ),  // ->
        .pcie_cfg_rx_rd_en  ( pcie_cfg_rx_rd_en     )   // <-
    );

endmodule
