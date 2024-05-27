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

module pcileech_pcie_a7x4(
    input                   clk_sys,
    input                   rst,

    // PCIe fabric
    output  [3:0]           pcie_tx_p,
    output  [3:0]           pcie_tx_n,
    input   [3:0]           pcie_rx_p,
    input   [3:0]           pcie_rx_n,
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
    IfAXIS128               tlp_tx();
    IfPCIeTlpRx128          tlp_rx();
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
    
    pcileech_tlps128_src128 i_pcileech_tlps128_src128(
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
    
    pcileech_tlps128_dst128 i_pcileech_tlps128_dst128(
        .rst                        ( rst_subsys                ),
        .clk_pcie                   ( clk_pcie                  ),
        .tlps_in                    ( tlps_tx.sink              ),
        .tlps_out                   ( tlp_tx.source             )
    );
    
    wire [15:0] tlp_tx_tkeep;
    assign tlp_tx_tkeep[3:0]   = tlp_tx.tkeepdw[0] ? 4'hf : 4'h0;
    assign tlp_tx_tkeep[7:4]   = tlp_tx.tkeepdw[1] ? 4'hf : 4'h0;
    assign tlp_tx_tkeep[11:8]  = tlp_tx.tkeepdw[2] ? 4'hf : 4'h0;
    assign tlp_tx_tkeep[15:12] = tlp_tx.tkeepdw[3] ? 4'hf : 4'h0;
    
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

        // s_axis_tx (transmit data) - 128-bit AXIS
        .s_axis_tx_tdata            ( tlp_tx.tdata              ),  // <- [127:0]
        .s_axis_tx_tkeep            ( tlp_tx_tkeep              ),  // <- [15:0]
        .s_axis_tx_tlast            ( tlp_tx.tlast              ),  // <-
        .s_axis_tx_tready           ( tlp_tx.tready             ),  // ->
        .s_axis_tx_tuser            ( 4'b0000                   ),  // <- [3:0]
        .s_axis_tx_tvalid           ( tlp_tx.tvalid             ),  // <-
        // s_axis_rx (receive data) - 128-bit AXIS
        .m_axis_rx_tdata            ( tlp_rx.data               ),  // -> [127:0]
        .m_axis_rx_tkeep            (                           ),  // -> [15:0]
        .m_axis_rx_tlast            (                           ),  // -> 
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
        
        // DRP - clock domain clk - write should only happen when core is in reset state ...
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
// Convert a 128-bit TLP-AXI-STREAM to a 128-bit PCIe core AXI-STREAM.
// ------------------------------------------------------------------------
module pcileech_tlps128_dst128(
    input                   rst,
    input                   clk_pcie,
    IfAXIS128.source        tlps_out,
    IfAXIS128.sink          tlps_in
);

    bit [127:0] d_tdata;
    bit [3:0]   d_tkeepdw;
    bit         d_tlast;
    bit         d_tvalid;    
    always @ ( posedge clk_pcie ) begin
        if ( rst ) begin
            d_tvalid    <= 0;
        end
        else if ( tlps_in.tvalid ) begin
            d_tdata     <= tlps_in.tdata;
            d_tkeepdw   <= tlps_in.tkeepdw;
            d_tlast     <= tlps_in.tlast;
            d_tvalid    <= !tlps_out.tready;
        end
        else if ( tlps_out.tready ) begin
            d_tvalid    <= 0;
        end
    end
    
    assign tlps_in.tready   = tlps_out.tready && !d_tvalid;
    assign tlps_out.tdata   = d_tvalid ? d_tdata    : tlps_in.tdata;
    assign tlps_out.tkeepdw = d_tvalid ? d_tkeepdw  : tlps_in.tkeepdw;
    assign tlps_out.tlast   = d_tvalid ? d_tlast    : tlps_in.tlast;
    assign tlps_out.tvalid  = d_tvalid || tlps_in.tvalid;
    
endmodule

// ------------------------------------------------------------------------
// TLP STREAM SOURCE:
// Convert a 128-bit PCIe core AXIS to a 128-bit TLP-AXI-STREAM 
// ------------------------------------------------------------------------
module pcileech_tlps128_src128(
    input                   rst,
    input                   clk_pcie,
    IfPCIeTlpRx128.sink     tlp_rx,
    IfAXIS128.source_lite   tlps_out
);
    
    bit             rxd_ready;
    wire [127:0]    rxf_data    = tlp_rx.data;
    wire [21:0]     rxf_user    = tlp_rx.user;
    wire            rxf_valid   = tlp_rx.valid && rxd_ready;
    wire            rxf_ready;
    assign          tlp_rx.ready = rxf_ready;
    
    bit             rxd_sof;
    bit             rxd_eof;
    bit             rxd_eof_dw;
    bit [6:0]       rxd_bar_hit;
    bit [63:0]      rxd_data_qw;
    bit             rxd_valid;
    
    wire [63:0]     rxf_data_qw0    = rxf_data[63:0];
    wire [63:0]     rxf_data_qw1    = rxf_data[127:64];
    wire            rxf_sof         = rxf_user[14];
    wire            rxf_sof_qw      = rxf_user[13];
    wire            rxf_eof         = rxf_user[21];
    wire [1:0]      rxf_eof_dw      = rxf_user[20:19];
    wire [6:0]      rxf_bar_hit     = rxf_user[8:2];
    
    wire [3:0]      rx_keep_dw; 
    
    assign rxf_ready = !(rxd_valid && rxf_eof && (rxf_eof_dw >= 2)) || !rxf_valid;
    
    assign tlps_out.tdata       = rxd_valid ? {rxf_data_qw0, rxd_data_qw} : {rxf_data_qw1, rxf_data_qw0};
    assign tlps_out.tuser[0]    = rxd_valid ? rxd_sof : (rxf_sof && !rxf_sof_qw);                       // tfirst
    assign tlps_out.tuser[1]    = rxd_valid ? (rxd_eof || (rxf_eof && (rxf_eof_dw <= 1))) : rxf_eof;    // tlast
    assign tlps_out.tuser[8:2]  = rxd_valid ? rxd_bar_hit : rxf_bar_hit;
    assign tlps_out.tlast       = tlps_out.tuser[1];
    assign tlps_out.tvalid      = rxd_valid || (rxf_valid && rxf_eof) || (rxf_valid && !(rxf_sof && rxf_sof_qw)); 
    
    assign tlps_out.tkeepdw[0]  = rxd_valid || rxf_valid;
    assign tlps_out.tkeepdw[1]  = rxd_valid ? (!rxd_eof || rxd_eof_dw) :
                                              (!rxf_eof || (rxf_eof_dw >= 1));
    assign tlps_out.tkeepdw[2]  = rxd_valid ? (!rxd_eof && rxf_valid) :
                                              (!rxf_eof || (rxf_eof_dw >= 2));
    assign tlps_out.tkeepdw[3]  = rxd_valid ? (!rxd_eof && rxf_valid && (!rxf_eof || (rxf_eof_dw >= 1))) :
                                              (!rxf_eof || (rxf_eof_dw >= 3));
                                              
    wire rxf_rxd_valid_next = !rst && rxf_valid && (rxd_valid ? ((!rxf_sof && !rxf_eof) || (rxf_sof && rxf_sof_qw) || (rxf_eof && (rxf_eof_dw >= 2))) :
                                                                (rxf_sof && rxf_sof_qw));
    
    always @ ( posedge clk_pcie ) begin
        rxd_ready   <= rxf_ready;
        rxd_bar_hit <= rxf_bar_hit;
        rxd_data_qw <= rxf_data_qw1;
        rxd_sof     <= rxf_sof && rxf_sof_qw;
        rxd_eof     <= rxf_eof && (rxf_eof_dw >= 2);
        rxd_eof_dw  <= (rxf_eof_dw == 3);
        rxd_valid   <= rxf_rxd_valid_next;
    end
    
endmodule
