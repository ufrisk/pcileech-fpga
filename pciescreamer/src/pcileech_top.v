//
// PCILeech FPGA.
//
// Top module for the PCIeScreamer Artix-7 board.
//
// (c) Ulf Frisk, 2018
// Author: Ulf Frisk, pcileech@frizk.net
//

module pcileech_pciescreamer_top(
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
    
    // FT601/FT245 <--> FIFO CTL
    wire [31:0]     ft601_rx_data;
    wire            ft601_rx_wren;
    
    // FT601/FT245 <--> RAM FIFO
    wire [31:0]     ft601_tx_data;
    wire            ft601_tx_empty;
    wire            ft601_tx_valid;
    wire            ft601_tx_rden;
    wire            ft601_xfer_prio_rx;
    
    // RAM FIFO <--> FIFO CTL
    wire [255:0]    fifo_tx_data;
    wire            fifo_tx_valid;
    wire            fifo_tx_rd_en;
    
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
        .fifo_rx_data       ( ft601_rx_data         ),
        .fifo_rx_wr         ( ft601_rx_wren         ),
        // FT601 CTL <--> MAIN OUTPUT FIFO
        .fifo_tx_data       ( ft601_tx_data         ),
        .fifo_tx_empty      ( ft601_tx_empty        ),
        .fifo_tx_valid      ( ft601_tx_valid        ),
        .fifo_tx_rd         ( ft601_tx_rden         ),
        // Activity LED
        .led_activity       ( led_activity          ),
        // Transfer Strategy
        .xfer_prio_rx       ( ft601_xfer_prio_rx    )
    );
    
    wire [31:0] fram_din;
    wire fram_almost_full;
    wire fram_wr_en;
    wire fram_prog_empty;
    wire out_buffer1_almost_full;
    // FTDI have a bug ( in chip or driver ) which doesn't terminate transfer if
    // even multiple of 1024 bytes are transmitted. Always insert five (5) MAGIC
    // DWORD (0x66665555) in beginning of stream to mitigate this.  Since normal
    // data size is always a multiple of 32-bytes/256-bits this will resolve the
    // issue. 
    wire ftdi_bug_workaround = fram_prog_empty & ft601_txe_n & ~fram_wr_en;
    fifo_32_32_deep i_pcileech_out_buffer2(
        .clk                ( clk                   ),
        .srst               ( rst                   ),
        .din                ( ftdi_bug_workaround ? 32'h66665555 : fram_din ),
        .wr_en              ( fram_wr_en | ftdi_bug_workaround ),
        .rd_en              ( ft601_tx_rden         ),
        .dout               ( ft601_tx_data         ),
        .full               (                       ),
        .almost_full        ( fram_almost_full      ),
        .empty              ( ft601_tx_empty        ),
        .prog_empty         ( fram_prog_empty       ),
        .valid              ( ft601_tx_valid        )
    );
    fifo_256_32 i_pcileech_out_buffer1(
        .clk                ( clk                   ),
        .srst               ( rst                   ),
        .din                ( fifo_tx_data          ),
        .wr_en              ( fifo_tx_valid         ),
        .rd_en              ( ~fram_almost_full     ),
        .dout               ( fram_din              ),
        .full               (                       ),
        .almost_full        ( out_buffer1_almost_full ),
        .empty              (                       ),
        .valid              ( fram_wr_en            )
    );
    assign fifo_tx_rd_en = ~out_buffer1_almost_full;
    
    pcileech_fifo i_pcileech_fifo(
        .clk                ( clk                   ),
        .rst                ( rst                   ),
        .pcie_lnk_up        ( user_lnk_up           ),
        // FIFO CTL <--> FT601 CTL
        .ft601_rx_data      ( ft601_rx_data         ),
        .ft601_rx_wren      ( ft601_rx_wren         ),
        .ft601_xfer_prio_rx ( ft601_xfer_prio_rx    ),
        // FIFO CTL <--> RAM FIFO
        .ft601_tx_data      ( fifo_tx_data          ),
        .ft601_tx_valid     ( fifo_tx_valid         ),
        .ft601_tx_rd_en     ( fifo_tx_rd_en         ),
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
