//
// PCILeech FPGA.
//
// PCIe module for Artix-7.
//
// (c) Ulf Frisk, 2018-2024
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_pcie_a7(
    input                   clk_sys,
    input                   rst,

    // PCIe fabric
    output  [0:0]           pcie_tx_p,
    output  [0:0]           pcie_tx_n,
    input   [0:0]           pcie_rx_p,
    input   [0:0]           pcie_rx_n,
    input                   pcie_clk_p,
    input                   pcie_clk_n,
    input                   pcie_perst_n,
    
    // State and Activity LEDs
    output                  led_state,
    
    // PCIe <--> FIFOs
    IfPCIeFifoCfg.mp_pcie   dfifo_cfg,
    IfPCIeFifoTlp.mp_pcie   dfifo_tlp,
    IfPCIeFifoCore.mp_pcie  dfifo_pcie,
    IfShadow2Fifo.shadow    dshadow2fifo
    );
       
    // ----------------------------------------------------------------------------
    // PCIe DEFINES AND WIRES
    // ----------------------------------------------------------------------------
    
    IfPCIeSignals           ctx();
    IfPCIeTlpRxTx           tlp_tx();
    IfPCIeTlpRxTx           tlp_rx();
    IfAXIS128               tlps_tx();
    IfAXIS128               tlps_rx();
    
    IfAXIS128               tlps_static();       // static tlp transmit from cfg->tlp
    wire [15:0]             pcie_id;
    wire                    user_lnk_up;
    
    // system interface
    wire pcie_clk_c;
    wire clk_pcie;
    wire rst_pcie_user;
    wire rst_subsys = rst || rst_pcie_user || dfifo_pcie.pcie_rst_subsys;
    wire rst_pcie = rst || ~pcie_perst_n || dfifo_pcie.pcie_rst_core;
       
    // Buffer for differential system clock
    IBUFDS_GTE2 refclk_ibuf (.O(pcie_clk_c), .ODIV2(), .I(pcie_clk_p), .CEB(1'b0), .IB(pcie_clk_n));
    
    // ----------------------------------------------------
    // TickCount64 PCIe REFCLK and LED OUTPUT
    // ----------------------------------------------------

    time tickcount64_pcie_refclk = 0;
    always @ ( posedge pcie_clk_c )
        tickcount64_pcie_refclk <= tickcount64_pcie_refclk + 1;
    assign led_state = user_lnk_up || tickcount64_pcie_refclk[25];
    
    // ----------------------------------------------------------------------------
    // PCIe CFG RX/TX <--> FIFO below
    // ----------------------------------------------------------------------------
    
    pcileech_pcie_cfg_a7 i_pcileech_pcie_cfg_a7(
        .rst                        ( rst_subsys                ),
        .clk_sys                    ( clk_sys                   ),
        .clk_pcie                   ( clk_pcie                  ),
        .dfifo                      ( dfifo_cfg                 ),        
        .ctx                        ( ctx                       ),
        .tlps_static                ( tlps_static.source        ),
        .pcie_id                    ( pcie_id                   )   // -> [15:0]
    );
    
    // ----------------------------------------------------------------------------
    // PCIe TLP RX/TX <--> FIFO below
    // ----------------------------------------------------------------------------
    
    pcileech_tlps128_src64 i_pcileech_tlps128_src64(
        .rst                        ( rst_subsys                ),
        .clk_pcie                   ( clk_pcie                  ),
        .tlp_rx                     ( tlp_rx.sink               ),
        .tlps_out                   ( tlps_rx.source_lite       )
    );
    
    pcileech_pcie_tlp_a7 i_pcileech_pcie_tlp_a7(
        .rst                        ( rst_subsys                ),
        .clk_pcie                   ( clk_pcie                  ),
        .clk_sys                    ( clk_sys                   ),
        .dfifo                      ( dfifo_tlp                 ),
        .tlps_tx                    ( tlps_tx.source            ),       
        .tlps_rx                    ( tlps_rx.sink_lite         ),
        .tlps_static                ( tlps_static.sink          ),
        .dshadow2fifo               ( dshadow2fifo              ),
        .pcie_id                    ( pcie_id                   )   // <- [15:0]
    );
    
    pcileech_tlps128_dst64 i_pcileech_tlps128_dst64(
        .rst                        ( rst                       ),
        .clk_pcie                   ( clk_pcie                  ),
        .tlp_tx                     ( tlp_tx.source             ),
        .tlps_in                    ( tlps_tx.sink              )
    );
    
    // ----------------------------------------------------------------------------
    // PCIe CORE BELOW
    // ---------------------------------------------------------------------------- 
      
    pcie_7x_0 i_pcie_7x_0 (
        // pcie_7x_mgt
        .pci_exp_txp                ( pcie_tx_p                 ),  // ->
        .pci_exp_txn                ( pcie_tx_n                 ),  // ->
        .pci_exp_rxp                ( pcie_rx_p                 ),  // <-
        .pci_exp_rxn                ( pcie_rx_n                 ),  // <-
        .sys_clk                    ( pcie_clk_c                ),  // <-
        .sys_rst_n                  ( ~rst_pcie                 ),  // <-
    
        // s_axis_tx (transmit data)
        .s_axis_tx_tdata            ( tlp_tx.data               ),  // <- [63:0]
        .s_axis_tx_tkeep            ( tlp_tx.keep               ),  // <- [7:0]
        .s_axis_tx_tlast            ( tlp_tx.last               ),  // <-
        .s_axis_tx_tready           ( tlp_tx.ready              ),  // ->
        .s_axis_tx_tuser            ( 4'b0                      ),  // <- [3:0]
        .s_axis_tx_tvalid           ( tlp_tx.valid              ),  // <-
    
        // s_axis_rx (receive data)
        .m_axis_rx_tdata            ( tlp_rx.data               ),  // -> [63:0]
        .m_axis_rx_tkeep            ( tlp_rx.keep               ),  // -> [7:0]
        .m_axis_rx_tlast            ( tlp_rx.last               ),  // -> 
        .m_axis_rx_tready           ( tlp_rx.ready              ),  // <-
        .m_axis_rx_tuser            ( tlp_rx.user               ),  // -> [21:0]
        .m_axis_rx_tvalid           ( tlp_rx.valid              ),  // ->
    
        // pcie_cfg_mgmt
        .cfg_mgmt_dwaddr            ( ctx.cfg_mgmt_dwaddr       ),  // <- [9:0]
        .cfg_mgmt_byte_en           ( ctx.cfg_mgmt_byte_en      ),  // <- [3:0]
        .cfg_mgmt_do                ( ctx.cfg_mgmt_do           ),  // -> [31:0]
        .cfg_mgmt_rd_en             ( ctx.cfg_mgmt_rd_en        ),  // <-
        .cfg_mgmt_rd_wr_done        ( ctx.cfg_mgmt_rd_wr_done   ),  // ->
        .cfg_mgmt_wr_readonly       ( ctx.cfg_mgmt_wr_readonly  ),  // <-
        .cfg_mgmt_wr_rw1c_as_rw     ( ctx.cfg_mgmt_wr_rw1c_as_rw ), // <-
        .cfg_mgmt_di                ( ctx.cfg_mgmt_di           ),  // <- [31:0]
        .cfg_mgmt_wr_en             ( ctx.cfg_mgmt_wr_en        ),  // <-
    
        // special core config
        //.pcie_cfg_vend_id           ( dfifo_pcie.pcie_cfg_vend_id       ),  // <- [15:0]
        //.pcie_cfg_dev_id            ( dfifo_pcie.pcie_cfg_dev_id        ),  // <- [15:0]
        //.pcie_cfg_rev_id            ( dfifo_pcie.pcie_cfg_rev_id        ),  // <- [7:0]
        //.pcie_cfg_subsys_vend_id    ( dfifo_pcie.pcie_cfg_subsys_vend_id ), // <- [15:0]
        //.pcie_cfg_subsys_id         ( dfifo_pcie.pcie_cfg_subsys_id     ),  // <- [15:0]
    
        // pcie2_cfg_interrupt
        .cfg_interrupt_assert       ( ctx.cfg_interrupt_assert          ),  // <-
        .cfg_interrupt              ( ctx.cfg_interrupt                 ),  // <-
        .cfg_interrupt_mmenable     ( ctx.cfg_interrupt_mmenable        ),  // -> [2:0]
        .cfg_interrupt_msienable    ( ctx.cfg_interrupt_msienable       ),  // ->
        .cfg_interrupt_msixenable   ( ctx.cfg_interrupt_msixenable      ),  // ->
        .cfg_interrupt_msixfm       ( ctx.cfg_interrupt_msixfm          ),  // ->
        .cfg_pciecap_interrupt_msgnum ( ctx.cfg_pciecap_interrupt_msgnum ), // <- [4:0]
        .cfg_interrupt_rdy          ( ctx.cfg_interrupt_rdy             ),  // ->
        .cfg_interrupt_do           ( ctx.cfg_interrupt_do              ),  // -> [7:0]
        .cfg_interrupt_stat         ( ctx.cfg_interrupt_stat            ),  // <-
        .cfg_interrupt_di           ( ctx.cfg_interrupt_di              ),  // <- [7:0]
        
        // pcie2_cfg_control
        .cfg_ds_bus_number          ( ctx.cfg_bus_number                ),  // <- [7:0]
        .cfg_ds_device_number       ( ctx.cfg_device_number             ),  // <- [4:0]
        .cfg_ds_function_number     ( ctx.cfg_function_number           ),  // <- [2:0]
        .cfg_dsn                    ( ctx.cfg_dsn                       ),  // <- [63:0]
        .cfg_pm_force_state         ( ctx.cfg_pm_force_state            ),  // <- [1:0]
        .cfg_pm_force_state_en      ( ctx.cfg_pm_force_state_en         ),  // <-
        .cfg_pm_halt_aspm_l0s       ( ctx.cfg_pm_halt_aspm_l0s          ),  // <-
        .cfg_pm_halt_aspm_l1        ( ctx.cfg_pm_halt_aspm_l1           ),  // <-
        .cfg_pm_send_pme_to         ( ctx.cfg_pm_send_pme_to            ),  // <-
        .cfg_pm_wake                ( ctx.cfg_pm_wake                   ),  // <-
        .rx_np_ok                   ( ctx.rx_np_ok                      ),  // <-
        .rx_np_req                  ( ctx.rx_np_req                     ),  // <-
        .cfg_trn_pending            ( ctx.cfg_trn_pending               ),  // <-
        .cfg_turnoff_ok             ( ctx.cfg_turnoff_ok                ),  // <-
        .tx_cfg_gnt                 ( ctx.tx_cfg_gnt                    ),  // <-
        
        // pcie2_cfg_status
        .cfg_command                ( ctx.cfg_command                   ),  // -> [15:0]
        .cfg_bus_number             ( ctx.cfg_bus_number                ),  // -> [7:0]
        .cfg_device_number          ( ctx.cfg_device_number             ),  // -> [4:0]
        .cfg_function_number        ( ctx.cfg_function_number           ),  // -> [2:0]
        .cfg_root_control_pme_int_en( ctx.cfg_root_control_pme_int_en   ),  // ->
        .cfg_bridge_serr_en         ( ctx.cfg_bridge_serr_en            ),  // ->
        .cfg_dcommand               ( ctx.cfg_dcommand                  ),  // -> [15:0]
        .cfg_dcommand2              ( ctx.cfg_dcommand2                 ),  // -> [15:0]
        .cfg_dstatus                ( ctx.cfg_dstatus                   ),  // -> [15:0]
        .cfg_lcommand               ( ctx.cfg_lcommand                  ),  // -> [15:0]
        .cfg_lstatus                ( ctx.cfg_lstatus                   ),  // -> [15:0]
        .cfg_pcie_link_state        ( ctx.cfg_pcie_link_state           ),  // -> [2:0]
        .cfg_pmcsr_pme_en           ( ctx.cfg_pmcsr_pme_en              ),  // ->
        .cfg_pmcsr_pme_status       ( ctx.cfg_pmcsr_pme_status          ),  // ->
        .cfg_pmcsr_powerstate       ( ctx.cfg_pmcsr_powerstate          ),  // -> [1:0]
        .cfg_received_func_lvl_rst  ( ctx.cfg_received_func_lvl_rst     ),  // ->
        .cfg_status                 ( ctx.cfg_status                    ),  // -> [15:0]
        .cfg_to_turnoff             ( ctx.cfg_to_turnoff                ),  // ->
        .tx_buf_av                  ( ctx.tx_buf_av                     ),  // -> [5:0]
        .tx_cfg_req                 ( ctx.tx_cfg_req                    ),  // ->
        .tx_err_drop                ( ctx.tx_err_drop                   ),  // ->
        .cfg_vc_tcvc_map            ( ctx.cfg_vc_tcvc_map               ),  // -> [6:0]
        .cfg_aer_rooterr_corr_err_received          ( ctx.cfg_aer_rooterr_corr_err_received             ),  // ->
        .cfg_aer_rooterr_corr_err_reporting_en      ( ctx.cfg_aer_rooterr_corr_err_reporting_en         ),  // ->
        .cfg_aer_rooterr_fatal_err_received         ( ctx.cfg_aer_rooterr_fatal_err_received            ),  // ->
        .cfg_aer_rooterr_fatal_err_reporting_en     ( ctx.cfg_aer_rooterr_fatal_err_reporting_en        ),  // ->
        .cfg_aer_rooterr_non_fatal_err_received     ( ctx.cfg_aer_rooterr_non_fatal_err_received        ),  // ->
        .cfg_aer_rooterr_non_fatal_err_reporting_en ( ctx.cfg_aer_rooterr_non_fatal_err_reporting_en    ),  // ->
        .cfg_root_control_syserr_corr_err_en        ( ctx.cfg_root_control_syserr_corr_err_en           ),  // ->
        .cfg_root_control_syserr_fatal_err_en       ( ctx.cfg_root_control_syserr_fatal_err_en          ),  // ->
        .cfg_root_control_syserr_non_fatal_err_en   ( ctx.cfg_root_control_syserr_non_fatal_err_en      ),  // ->
        .cfg_slot_control_electromech_il_ctl_pulse  ( ctx.cfg_slot_control_electromech_il_ctl_pulse     ),  // ->
        
        // PCIe core PHY
        .pl_initial_link_width      ( ctx.pl_initial_link_width         ),  // -> [2:0]
        .pl_phy_lnk_up              ( ctx.pl_phy_lnk_up                 ),  // ->
        .pl_lane_reversal_mode      ( ctx.pl_lane_reversal_mode         ),  // -> [1:0]
        .pl_link_gen2_cap           ( ctx.pl_link_gen2_cap              ),  // ->
        .pl_link_partner_gen2_supported ( ctx.pl_link_partner_gen2_supported ),  // ->
        .pl_link_upcfg_cap          ( ctx.pl_link_upcfg_cap             ),  // ->
        .pl_sel_lnk_rate            ( ctx.pl_sel_lnk_rate               ),  // ->
        .pl_sel_lnk_width           ( ctx.pl_sel_lnk_width              ),  // -> [1:0]
        .pl_ltssm_state             ( ctx.pl_ltssm_state                ),  // -> [5:0]
        .pl_rx_pm_state             ( ctx.pl_rx_pm_state                ),  // -> [1:0]
        .pl_tx_pm_state             ( ctx.pl_tx_pm_state                ),  // -> [2:0]
        .pl_directed_change_done    ( ctx.pl_directed_change_done       ),  // ->
        .pl_received_hot_rst        ( ctx.pl_received_hot_rst           ),  // ->
        .pl_directed_link_auton     ( ctx.pl_directed_link_auton        ),  // <-
        .pl_directed_link_change    ( ctx.pl_directed_link_change       ),  // <- [1:0]
        .pl_directed_link_speed     ( ctx.pl_directed_link_speed        ),  // <-
        .pl_directed_link_width     ( ctx.pl_directed_link_width        ),  // <- [1:0]
        .pl_upstream_prefer_deemph  ( ctx.pl_upstream_prefer_deemph     ),  // <-
        .pl_transmit_hot_rst        ( ctx.pl_transmit_hot_rst           ),  // <-
        .pl_downstream_deemph_source( ctx.pl_downstream_deemph_source   ),  // <-
        
        // DRP - clock domain clk_100 - write should only happen when core is in reset state ...
        .pcie_drp_clk               ( clk_sys                           ),  // <-
        .pcie_drp_en                ( dfifo_pcie.drp_en                 ),  // <-
        .pcie_drp_we                ( dfifo_pcie.drp_we                 ),  // <-
        .pcie_drp_addr              ( dfifo_pcie.drp_addr               ),  // <- [8:0]
        .pcie_drp_di                ( dfifo_pcie.drp_di                 ),  // <- [15:0]
        .pcie_drp_rdy               ( dfifo_pcie.drp_rdy                ),  // ->
        .pcie_drp_do                ( dfifo_pcie.drp_do                 ),  // -> [15:0]
    
        // user interface
        .user_clk_out               ( clk_pcie                          ),  // ->
        .user_reset_out             ( rst_pcie_user                     ),  // ->
        .user_lnk_up                ( user_lnk_up                       ),  // ->
        .user_app_rdy               (                                   )   // ->
    );

endmodule


// ------------------------------------------------------------------------
// TLP STREAM SINK:
// Convert a 128-bit TLP-AXI-STREAM to a 64-bit PCIe core AXI-STREAM.
// ------------------------------------------------------------------------
module pcileech_tlps128_dst64(
    input                   rst,
    input                   clk_pcie,
    IfPCIeTlpRxTx.source    tlp_tx,
    IfAXIS128.sink          tlps_in
);

    bit [63:0]  d1_tdata;
    bit         d1_tkeepdw2;
    bit         d1_tlast;
    bit         d1_tvalid = 0;
    
    assign tlps_in.tready = tlp_tx.ready && !(tlps_in.tvalid && tlps_in.tkeepdw[2]);
    
    wire tkeepdw2       = d1_tvalid ? d1_tkeepdw2 : tlps_in.tkeepdw[1];
    assign tlp_tx.data  = d1_tvalid ? d1_tdata : tlps_in.tdata[63:0];
    assign tlp_tx.last  = d1_tvalid ? d1_tlast : (tlps_in.tlast && !tlps_in.tkeepdw[2]);
    assign tlp_tx.keep  = tkeepdw2 ? 8'hff : 8'h0f;
    assign tlp_tx.valid = d1_tvalid || tlps_in.tvalid;
    
    always @ ( posedge clk_pcie ) begin
        d1_tvalid    <= !rst && tlps_in.tvalid && tlps_in.tkeepdw[2];
        d1_tdata     <= tlps_in.tdata[127:64];
        d1_tlast     <= tlps_in.tlast;
        d1_tkeepdw2  <= tlps_in.tkeepdw[3];
    end

endmodule


// ------------------------------------------------------------------------
// TLP STREAM SOURCE:
// Convert a 64-bit PCIe core AXIS to a 128-bit TLP-AXI-STREAM 
// ------------------------------------------------------------------------
module pcileech_tlps128_src64(
    input                   rst,
    input                   clk_pcie,
    IfPCIeTlpRxTx.sink      tlp_rx,
    IfAXIS128.source_lite   tlps_out
);

    bit [127:0] tdata;
    bit         first       = 1;
    bit         tlast       = 0;
    bit [3:0]   len         = 0;
    bit [6:0]   bar_hit     = 0;
    wire        tvalid      = tlast || (len>2);
    
    assign tlp_rx.ready     = 1'b1;
    assign tlps_out.tdata   = tdata;
    assign tlps_out.tkeepdw = {(len>3), (len>2), (len>1), 1'b1};
    assign tlps_out.tlast   = tlast;   
    assign tlps_out.tvalid  = tvalid; 
    assign tlps_out.tuser[0]    = first;
    assign tlps_out.tuser[1]    = tlast;
    assign tlps_out.tuser[8:2]  = bar_hit;
    
    wire [3:0]  next_base   = (tlast || tvalid) ? 0 : len;
    wire [3:0]  next_len    = next_base + 1 + tlp_rx.keep[4];

    always @ ( posedge clk_pcie )
        if ( rst ) begin
            first   <= 1;
            tlast   <= 0;
            len     <= 0;
            bar_hit <= 0;
        end
        else if ( tlp_rx.valid ) begin
            tdata[(32*next_base)+:64] <= tlp_rx.data;
            first   <= tvalid ? tlast : first;
            tlast   <= tlp_rx.last;
            len     <= next_len;
            bar_hit <= tlp_rx.user[8:2];
        end
        else if ( tvalid ) begin 
            first   <= tlast;
            tlast   <= 0;
            len     <= 0;
            bar_hit <= 0;
        end
    
endmodule
