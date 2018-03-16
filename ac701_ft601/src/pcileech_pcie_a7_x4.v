//
// PCILeech FPGA.
//
// PCIe module for Artix-7.
//
// (c) Ulf Frisk, 2018
// Author: Ulf Frisk, pcileech@frizk.net
//

module pcileech_pcie_a7_x4(
    input           clk,

    // PCIe fabric
    output  [1:0]   pci_exp_txp,
    output  [1:0]   pci_exp_txn,
    input   [1:0]   pci_exp_rxp,
    input   [1:0]   pci_exp_rxn,
    input           sys_clk_p,
    input           sys_clk_n,
    input           sys_rst_n,
    
    output          user_lnk_up,
    
    // receive TLPs to transmit from FT601
    input   [31:0]  pcie_tlp_tx_data,
    input           pcie_tlp_tx_last,
    input           pcie_tlp_tx_valid,
    
    // transmit received TLPs to FT601
    output  [31:0]  pcie_tlp_rx_data,
    output          pcie_tlp_rx_last,
    output          pcie_tlp_rx_valid,
    output          pcie_tlp_rx_empty,
    input           pcie_tlp_rx_rd_en,
    
    // receive CFG from FT601
    input   [63:0]  pcie_cfg_tx_data,
    input           pcie_cfg_tx_valid,
    
    // transmit CFG to FT601
    output  [31:0]  pcie_cfg_rx_data,
    output          pcie_cfg_rx_valid,
    output          pcie_cfg_rx_empty,
    input           pcie_cfg_rx_rd_en
    );

    // ----------------------------------------------------------------------------
    // PCIe DEFINES AND WIRES BELOW
    // ----------------------------------------------------------------------------
    localparam PCI_EXP_EP_OUI = 24'h000A35;
    localparam PCI_EXP_EP_DSN_1 = { { 8'h1 }, PCI_EXP_EP_OUI };
    localparam PCI_EXP_EP_DSN_2 = 32'h00000001;
    wire [63:0]    cfg_dsn;
    assign cfg_dsn = { PCI_EXP_EP_DSN_2, PCI_EXP_EP_DSN_1 };
    
    // system interface
    (* dont_touch = "true" *) wire sys_clk_c;
    wire user_clk;
    wire user_reset;
       
    // Buffer for differential system clock
    IBUFDS_GTE2 refclk_ibuf (.O(sys_clk_c), .ODIV2(), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));
    
    // ----------------------------------------------------------------------------
    // PCIe CFG RX/TX <--> FIFO below
    // ----------------------------------------------------------------------------
    wire [7:0]      cfg_bus_number;
    wire [4:0]      cfg_device_number;
    wire [2:0]      cfg_function_number;
    wire [15:0]     cfg_command;
    
    wire [31:0]     cfg_do;
    wire            cfg_rd_wr_done;
    wire [9:0]      cfg_dwaddr;
    wire            cfg_rd_en;
    wire [31:0]     cfg_di;
    wire            cfg_wr_en;
    wire [3:0]      cfg_byte_en;
    
    wire [2:0]      pl_initial_link_width;
    wire            pl_phy_lnk_up;
    wire [1:0]      pl_lane_reversal_mode;
    wire            pl_link_gen2_cap;
    wire            pl_link_partner_gen2_supported;
    wire            pl_link_upcfg_cap;
    wire            pl_sel_lnk_rate;
    wire [1:0]      pl_sel_lnk_width;
    wire [5:0]      pl_ltssm_state;
    wire [1:0]      pl_rx_pm_state;
    wire [2:0]      pl_tx_pm_state;
    wire            pl_directed_change_done;
    wire            pl_received_hot_rst;
    wire            pl_directed_link_auton;
    wire [1:0]      pl_directed_link_change;
    wire            pl_directed_link_speed;
    wire [1:0]      pl_directed_link_width;
    wire            pl_upstream_prefer_deemph;
    wire            pl_transmit_hot_rst;
    wire            pl_downstream_deemph_source;
    
    pcileech_pcie_cfg_a7 i_pcileech_pcie_cfg_a7(
        .rst                        ( user_reset | ~sys_rst_n   ),
        .clk                        ( clk                       ),
        .clk_pcie                   ( user_clk                  ),

        .pcie_cfg_tx_data           ( pcie_cfg_tx_data          ),  // <- [63:0]
        .pcie_cfg_tx_valid          ( pcie_cfg_tx_valid         ),  // <-
        
        .pcie_cfg_rx_data           ( pcie_cfg_rx_data          ),  // -> [31:0]
        .pcie_cfg_rx_valid          ( pcie_cfg_rx_valid         ),  // ->
        .pcie_cfg_rx_empty          ( pcie_cfg_rx_empty         ),  // ->
        .pcie_cfg_rx_rd_en          ( pcie_cfg_rx_rd_en         ),  // <-
        
        .cfg_bus_number             ( cfg_bus_number            ),  // <-  [7:0]
        .cfg_device_number          ( cfg_device_number         ),  // <-  [4:0]
        .cfg_function_number        ( cfg_function_number       ),  // <-  [2:0]
        .cfg_command                ( cfg_command               ),  // <-  [15:0]
        
        .cfg_do                     ( cfg_do                    ),  // <- [31:0]
        .cfg_rd_wr_done             ( cfg_rd_wr_done            ),  // <-
        .cfg_dwaddr                 ( cfg_dwaddr                ),  // -> [9:0]
        .cfg_rd_en                  ( cfg_rd_en                 ),  // ->
        .cfg_di                     ( cfg_di                    ),  // -> [31:0]
        .cfg_wr_en                  ( cfg_wr_en                 ),  // ->
        .cfg_byte_en                ( cfg_byte_en               ),   // -> [3:0]
        
        // PCIe core PHY
        .pl_initial_link_width      ( pl_initial_link_width     ),  // <- [2:0]
        .pl_phy_lnk_up              ( pl_phy_lnk_up             ),  // <-
        .pl_lane_reversal_mode      ( pl_lane_reversal_mode     ),  // <- [1:0]
        .pl_link_gen2_cap           ( pl_link_gen2_cap          ),  // <-
        .pl_link_partner_gen2_supported ( pl_link_partner_gen2_supported ),  // <-
        .pl_link_upcfg_cap          ( pl_link_upcfg_cap         ),  // <-
        .pl_sel_lnk_rate            ( pl_sel_lnk_rate           ),  // <-
        .pl_sel_lnk_width           ( pl_sel_lnk_width          ),  // <- [1:0]
        .pl_ltssm_state             ( pl_ltssm_state            ),  // <- [5:0]
        .pl_rx_pm_state             ( pl_rx_pm_state            ),  // <- [1:0]
        .pl_tx_pm_state             ( pl_tx_pm_state            ),  // <- [2:0]
        .pl_directed_change_done    ( pl_directed_change_done   ),  // <-
        .pl_received_hot_rst        ( pl_received_hot_rst       ),  // <-
        .pl_directed_link_auton     ( pl_directed_link_auton    ),  // ->
        .pl_directed_link_change    ( pl_directed_link_change   ),  // -> [1:0]
        .pl_directed_link_speed     ( pl_directed_link_speed    ),  // ->
        .pl_directed_link_width     ( pl_directed_link_width    ),  // -> [1:0]
        .pl_upstream_prefer_deemph  ( pl_upstream_prefer_deemph ),  // ->
        .pl_transmit_hot_rst        ( pl_transmit_hot_rst       ),  // ->
        .pl_downstream_deemph_source( pl_downstream_deemph_source ) // ->
    );
    
    // ----------------------------------------------------------------------------
    // PCIe TLP RX/TX <--> FIFO below
    // ----------------------------------------------------------------------------
    wire [63:0]     s_axis_tx_tdata;
    wire [7:0]      s_axis_tx_tkeep;
    wire            s_axis_tx_tlast;
    wire            s_axis_tx_tready;
    wire            s_axis_tx_tvalid;
    
    wire [63:0]     m_axis_rx_tdata;
    wire [7:0]      m_axis_rx_tkeep;
    wire            m_axis_rx_tlast;
    wire            m_axis_rx_tready;
    wire            m_axis_rx_tvalid;
    
    pcileech_pcie_tlp_a7 i_pcileech_pcie_tlp_a7(
        .rst                        ( user_reset | ~sys_rst_n   ),
        .clk                        ( clk                       ),
        .clk_pcie                   ( user_clk                  ),

        .pcie_tlp_tx_data           ( pcie_tlp_tx_data          ),  // <- [31:0]
        .pcie_tlp_tx_last           ( pcie_tlp_tx_last          ),  // <-
        .pcie_tlp_tx_valid          ( pcie_tlp_tx_valid         ),  // <-
        
        .pcie_tlp_rx_data           ( pcie_tlp_rx_data          ),  // -> [31:0]
        .pcie_tlp_rx_last           ( pcie_tlp_rx_last          ),  // ->
        .pcie_tlp_rx_valid          ( pcie_tlp_rx_valid         ),  // ->
        .pcie_tlp_rx_empty          ( pcie_tlp_rx_empty         ),  // ->
        .pcie_tlp_rx_rd_en          ( pcie_tlp_rx_rd_en         ),  // <-

        .s_axis_tx_tdata            ( s_axis_tx_tdata           ),  // -> [63:0]
        .s_axis_tx_tkeep            ( s_axis_tx_tkeep           ),  // -> [7:0]
        .s_axis_tx_tlast            ( s_axis_tx_tlast           ),  // ->
        .s_axis_tx_tready           ( s_axis_tx_tready          ),  // <-
        .s_axis_tx_tvalid           ( s_axis_tx_tvalid          ),  // ->

        .m_axis_rx_tdata            ( m_axis_rx_tdata           ),  // <- [63:0]
        .m_axis_rx_tkeep            ( m_axis_rx_tkeep           ),  // <- [7:0]
        .m_axis_rx_tlast            ( m_axis_rx_tlast           ),  // <-
        .m_axis_rx_tready           ( m_axis_rx_tready          ),  // ->
        .m_axis_rx_tvalid           ( m_axis_rx_tvalid          )   // <-
    );
    
    // ----------------------------------------------------------------------------
    // PCIe CORE BELOW
    // ----------------------------------------------------------------------------
    pcie_7x_0 i_pcie_7x_0 (
        // pcie_7x_mgt
        .pci_exp_txp                ( pci_exp_txp               ),  // ->
        .pci_exp_txn                ( pci_exp_txn               ),  // ->
        .pci_exp_rxp                ( pci_exp_rxp               ),  // <-
        .pci_exp_rxn                ( pci_exp_rxn               ),  // <-
        .sys_clk                    ( sys_clk_c                 ),  // <-
        .sys_rst_n                  ( sys_rst_n                 ),  // <-
    
        // s_axis_tx (transmit data)
        .s_axis_tx_tdata            ( s_axis_tx_tdata           ),  // <- [63:0]
        .s_axis_tx_tkeep            ( s_axis_tx_tkeep           ),  // <- [7:0]
        .s_axis_tx_tlast            ( s_axis_tx_tlast           ),  // <-
        .s_axis_tx_tready           ( s_axis_tx_tready          ),  // ->
        .s_axis_tx_tuser            ( 4'b0                      ),  // <- [3:0]
        .s_axis_tx_tvalid           ( s_axis_tx_tvalid          ),  // <-
    
        // s_axis_rx (receive data)
        .m_axis_rx_tdata            ( m_axis_rx_tdata           ),  // -> [63:0]
        .m_axis_rx_tkeep            ( m_axis_rx_tkeep           ),  // -> [7:0]
        .m_axis_rx_tlast            ( m_axis_rx_tlast           ),  // -> 
        .m_axis_rx_tready           ( m_axis_rx_tready          ),  // <-
        .m_axis_rx_tuser            (                           ),  // -> [21:0]
        .m_axis_rx_tvalid           ( m_axis_rx_tvalid          ),  // ->
    
        // pcie_cfg_mgmt
        .cfg_mgmt_dwaddr            ( cfg_dwaddr                ),  // <- [9:0]
        .cfg_mgmt_byte_en           ( cfg_byte_en               ),  // <- [3:0]
        .cfg_mgmt_do                ( cfg_do                    ),  // -> [31:0]
        .cfg_mgmt_rd_en             ( cfg_rd_en                 ),  // <-
        .cfg_mgmt_rd_wr_done        ( cfg_rd_wr_done            ),  // ->
        .cfg_mgmt_wr_readonly       ( 1'b0                      ),  // <-
        .cfg_mgmt_wr_rw1c_as_rw     ( 1'b1                      ),  // <-
        .cfg_mgmt_di                ( cfg_di                    ),  // <- [31:0]
        .cfg_mgmt_wr_en             ( cfg_wr_en                 ),  // <-
    
        // pcie2_cfg_interrupt
        .cfg_interrupt_assert       ( 1'b0                      ),  // <-
        .cfg_interrupt              ( 1'b0                      ),  // <-
        .cfg_interrupt_mmenable     (                           ),  // -> [2:0]
        .cfg_interrupt_msienable    (                           ),  // ->
        .cfg_interrupt_msixenable   (                           ),  // ->
        .cfg_interrupt_msixfm       (                           ),  // ->
        .cfg_pciecap_interrupt_msgnum ( 5'b00000                ),  // <- [4:0]
        .cfg_interrupt_rdy          (                           ),  // ->
        .cfg_interrupt_do           (                           ),  // -> [7:0]
        .cfg_interrupt_stat         ( 1'b0                      ),  // <-
        .cfg_interrupt_di           ( 8'b0                      ),  // <- [7:0]
        
        // pcie2_cfg_control
        .cfg_ds_bus_number          ( cfg_bus_number            ),  // <- [7:0]
        .cfg_ds_device_number       ( cfg_device_number         ),  // <- [4:0]
        .cfg_ds_function_number     ( cfg_function_number       ),  // <- [2:0]
        .cfg_dsn                    ( cfg_dsn                   ),  // <- [63:0]
        .cfg_pm_force_state         ( 2'b00                     ),  // <- [1:0]
        .cfg_pm_force_state_en      ( 1'b0                      ),  // <-
        .cfg_pm_halt_aspm_l0s       ( 1'b0                      ),  // <-
        .cfg_pm_halt_aspm_l1        ( 1'b0                      ),  // <-
        .cfg_pm_send_pme_to         ( 1'b0                      ),  // <-
        .cfg_pm_wake                ( 1'b0                      ),  // <-
        .rx_np_ok                   ( 1'b1                      ),  // <-
        .rx_np_req                  ( 1'b1                      ),  // <-
        .cfg_trn_pending            ( 1'b0                      ),  // <-
        .cfg_turnoff_ok             ( 1'b0                      ),  // <-
        .tx_cfg_gnt                 ( 1'b1                      ),  // <-
        
        // pcie2_cfg_status
        .cfg_command                ( cfg_command               ),  // -> [15:0]
        .cfg_bus_number             ( cfg_bus_number            ),  // -> [7:0]
        .cfg_device_number          ( cfg_device_number         ),  // -> [4:0]
        .cfg_function_number        ( cfg_function_number       ),  // -> [2:0]
        .cfg_aer_rooterr_corr_err_received      (               ),  // ->
        .cfg_aer_rooterr_corr_err_reporting_en  (               ),  // ->
        .cfg_aer_rooterr_fatal_err_received     (               ),  // ->
        .cfg_aer_rooterr_fatal_err_reporting_en (               ),  // ->
        .cfg_aer_rooterr_non_fatal_err_received (               ),  // ->
        .cfg_aer_rooterr_non_fatal_err_reporting_en (           ),  // ->
        .cfg_bridge_serr_en         (                           ),  // ->
        .cfg_dcommand               (                           ),  // -> [15:0]
        .cfg_dcommand2              (                           ),  // -> [15:0]
        .cfg_dstatus                (                           ),  // -> [15:0]
        .cfg_lcommand               (                           ),  // -> [15:0]
        .cfg_lstatus                (                           ),  // -> [15:0]
        .cfg_pcie_link_state        (                           ),  // -> [2:0]
        .cfg_pmcsr_pme_en           (                           ),  // ->
        .cfg_pmcsr_pme_status       (                           ),  // ->
        .cfg_pmcsr_powerstate       (                           ),  // -> [1:0]
        .cfg_received_func_lvl_rst  (                           ),  // ->
        .cfg_root_control_pme_int_en(                           ),  // ->
        .cfg_root_control_syserr_corr_err_en        (           ),  // ->
        .cfg_root_control_syserr_fatal_err_en       (           ),  // ->
        .cfg_root_control_syserr_non_fatal_err_en   (           ),  // ->
        .cfg_slot_control_electromech_il_ctl_pulse  (           ),  // ->
        .cfg_status                 (                           ),  // -> [15:0]
        .cfg_to_turnoff             (                           ),  // ->
        .tx_buf_av                  (                           ),  // -> [5:0]
        .tx_cfg_req                 (                           ),  // ->
        .tx_err_drop                (                           ),  // ->
        .cfg_vc_tcvc_map            (                           ),  // -> [6:0]
        
        // PCIe core PHY
        .pl_initial_link_width      ( pl_initial_link_width     ),  // -> [2:0]
        .pl_phy_lnk_up              ( pl_phy_lnk_up             ),  // ->
        .pl_lane_reversal_mode      ( pl_lane_reversal_mode     ),  // -> [1:0]
        .pl_link_gen2_cap           ( pl_link_gen2_cap          ),  // ->
        .pl_link_partner_gen2_supported ( pl_link_partner_gen2_supported ),  // ->
        .pl_link_upcfg_cap          ( pl_link_upcfg_cap         ),  // ->
        .pl_sel_lnk_rate            ( pl_sel_lnk_rate           ),  // ->
        .pl_sel_lnk_width           ( pl_sel_lnk_width          ),  // -> [1:0]
        .pl_ltssm_state             ( pl_ltssm_state            ),  // -> [5:0]
        .pl_rx_pm_state             ( pl_rx_pm_state            ),  // -> [1:0]
        .pl_tx_pm_state             ( pl_tx_pm_state            ),  // -> [2:0]
        .pl_directed_change_done    ( pl_directed_change_done   ),  // ->
        .pl_received_hot_rst        ( pl_received_hot_rst       ),  // ->
        .pl_directed_link_auton     ( pl_directed_link_auton    ),  // <-
        .pl_directed_link_change    ( pl_directed_link_change   ),  // <- [1:0]
        .pl_directed_link_speed     ( pl_directed_link_speed    ),  // <-
        .pl_directed_link_width     ( pl_directed_link_width    ),  // <- [1:0]
        .pl_upstream_prefer_deemph  ( pl_upstream_prefer_deemph ),  // <-
        .pl_transmit_hot_rst        ( pl_transmit_hot_rst       ),  // <-
        .pl_downstream_deemph_source( pl_downstream_deemph_source ),// <-
    
        // user interface
        .user_clk_out               ( user_clk                  ),  // ->
        .user_reset_out             ( user_reset                ),  // ->
        .user_lnk_up                ( user_lnk_up               ),  // ->
        .user_app_rdy               (                           )   // ->
    );

endmodule
