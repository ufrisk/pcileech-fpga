//
// PCILeech FPGA.
//
// SystemVerilog Header File for PCILeech FPGA projects.
//
// (c) Ulf Frisk, 2019-2020
// Author: Ulf Frisk, pcileech@frizk.net
//

`ifndef _pcileech_header_svh_
`define _pcileech_header_svh_

`define _bs16(v)   {{v}[7:0], {v}[15:8]}
`define _bs32(v)   {{v}[7:0], {v}[15:8], {v}[23:16], {v}[31:24]}

// ------------------------------------------------------------------------
// Interface connecting COM to FIFO module.
// ------------------------------------------------------------------------
interface IfComToFifo;
    wire [63:0]     com_dout;
    wire            com_dout_valid;
    wire [255:0]    com_din;
    wire            com_din_wr_en;
    wire            com_din_ready;

    modport mp_com (
        output com_dout, com_dout_valid, com_din_ready,
        input com_din, com_din_wr_en
    );

    modport mp_fifo (
        input com_dout, com_dout_valid, com_din_ready,
        output com_din, com_din_wr_en
    );
endinterface

// ------------------------------------------------------------------------
// Interface connecting PCIe to PCIe CFG module.
// ------------------------------------------------------------------------
interface IfPCIeSignals;
    // ------------------------------------------------------------------------
    // VALUES FROM PCIe TO module.
    // ------------------------------------------------------------------------
    wire    [7:0]       cfg_bus_number;
    wire    [4:0]       cfg_device_number;
    wire    [2:0]       cfg_function_number;
    
    wire    [15:0]      cfg_command;
    wire    [31:0]      cfg_mgmt_do;
    wire                cfg_mgmt_rd_wr_done;
    
    wire    [2:0]       pl_initial_link_width;
    wire                pl_phy_lnk_up;
    wire    [1:0]       pl_lane_reversal_mode;
    wire                pl_link_gen2_cap;
    wire                pl_link_partner_gen2_supported;
    wire                pl_link_upcfg_cap;
    wire                pl_sel_lnk_rate;
    wire    [1:0]       pl_sel_lnk_width;
    wire    [5:0]       pl_ltssm_state;
    wire    [1:0]       pl_rx_pm_state;
    wire    [2:0]       pl_tx_pm_state;
    wire                pl_directed_change_done;
    wire                pl_received_hot_rst;
    
    wire                cfg_aer_rooterr_corr_err_received;
    wire                cfg_aer_rooterr_corr_err_reporting_en;
    wire                cfg_aer_rooterr_fatal_err_received;
    wire                cfg_aer_rooterr_fatal_err_reporting_en;
    wire                cfg_aer_rooterr_non_fatal_err_received;
    wire                cfg_aer_rooterr_non_fatal_err_reporting_en;
    wire                cfg_bridge_serr_en;
    wire    [15:0]      cfg_dcommand;
    wire    [15:0]      cfg_dcommand2;
    wire    [15:0]      cfg_dstatus;
    wire    [15:0]      cfg_lcommand;
    wire    [15:0]      cfg_lstatus;
    wire    [2:0]       cfg_pcie_link_state;
    wire                cfg_pmcsr_pme_en;
    wire                cfg_pmcsr_pme_status;
    wire    [1:0]       cfg_pmcsr_powerstate;
    wire                cfg_received_func_lvl_rst;
    wire                cfg_root_control_pme_int_en;
    wire                cfg_root_control_syserr_corr_err_en;
    wire                cfg_root_control_syserr_fatal_err_en;
    wire                cfg_root_control_syserr_non_fatal_err_en;
    wire                cfg_slot_control_electromech_il_ctl_pulse;
    wire    [15:0]      cfg_status;
    wire                cfg_to_turnoff;
    wire    [5:0]       tx_buf_av;
    wire                tx_cfg_req;
    wire                tx_err_drop;
    wire    [6:0]       cfg_vc_tcvc_map;
    
    wire    [2:0]       cfg_interrupt_mmenable;
    wire                cfg_interrupt_msienable;
    wire                cfg_interrupt_msixenable;
    wire                cfg_interrupt_msixfm;
    wire                cfg_interrupt_rdy;
    wire    [7:0]       cfg_interrupt_do;
    
    // ------------------------------------------------------------------------
    // VALUES FROM module TO PCIe.
    // ------------------------------------------------------------------------
    
    wire                cfg_mgmt_rd_en;
    wire                cfg_mgmt_wr_en;
    
    wire    [63:0]      cfg_dsn;
    wire    [31:0]      cfg_mgmt_di;
    wire    [9:0]       cfg_mgmt_dwaddr;
    wire    [3:0]       cfg_mgmt_byte_en;
    wire                cfg_mgmt_wr_readonly;
    wire                cfg_mgmt_wr_rw1c_as_rw;
    
    wire    [1:0]       pl_directed_link_change;
    wire    [1:0]       pl_directed_link_width;
    wire                pl_directed_link_auton;
    wire                pl_directed_link_speed;
    wire                pl_upstream_prefer_deemph;
    wire                pl_transmit_hot_rst;
    wire                pl_downstream_deemph_source;
    
    wire    [7:0]       cfg_interrupt_di;
    wire    [4:0]       cfg_pciecap_interrupt_msgnum;
    wire                cfg_interrupt_assert;
    wire                cfg_interrupt;
    wire                cfg_interrupt_stat;
    
    wire    [1:0]       cfg_pm_force_state;
    wire                cfg_pm_force_state_en;
    wire                cfg_pm_halt_aspm_l0s;
    wire                cfg_pm_halt_aspm_l1;
    wire                cfg_pm_send_pme_to;
    wire                cfg_pm_wake;
    wire                cfg_trn_pending;
    wire                cfg_turnoff_ok;
    wire                rx_np_ok;
    wire                rx_np_req;
    wire                tx_cfg_gnt;
    
    modport mpm (
        input cfg_bus_number, cfg_device_number, cfg_function_number, cfg_command, cfg_mgmt_do, cfg_mgmt_rd_wr_done,
            pl_initial_link_width, pl_phy_lnk_up, pl_lane_reversal_mode, pl_link_gen2_cap, pl_link_partner_gen2_supported,
            pl_link_upcfg_cap, pl_sel_lnk_rate, pl_sel_lnk_width, pl_ltssm_state, pl_rx_pm_state,
            pl_tx_pm_state, pl_directed_change_done, pl_received_hot_rst,
            cfg_aer_rooterr_corr_err_received, cfg_aer_rooterr_corr_err_reporting_en, cfg_aer_rooterr_fatal_err_received, cfg_aer_rooterr_fatal_err_reporting_en,
            cfg_aer_rooterr_non_fatal_err_received, cfg_aer_rooterr_non_fatal_err_reporting_en, cfg_bridge_serr_en, cfg_dcommand, cfg_dcommand2, cfg_dstatus,
            cfg_lcommand, cfg_lstatus, cfg_pcie_link_state, cfg_pmcsr_pme_en, cfg_pmcsr_pme_status, cfg_pmcsr_powerstate, cfg_received_func_lvl_rst, cfg_root_control_pme_int_en,
            cfg_root_control_syserr_corr_err_en, cfg_root_control_syserr_fatal_err_en, cfg_root_control_syserr_non_fatal_err_en, cfg_slot_control_electromech_il_ctl_pulse,
            cfg_status, cfg_to_turnoff, tx_buf_av, tx_cfg_req, tx_err_drop, cfg_vc_tcvc_map,
            cfg_interrupt_mmenable, cfg_interrupt_msienable, cfg_interrupt_msixenable, cfg_interrupt_msixfm, cfg_interrupt_rdy, cfg_interrupt_do,
            
        output cfg_mgmt_rd_en, cfg_mgmt_wr_en, cfg_dsn, cfg_mgmt_di, cfg_mgmt_dwaddr, cfg_mgmt_wr_readonly, cfg_mgmt_wr_rw1c_as_rw, cfg_mgmt_byte_en, pl_directed_link_change, pl_directed_link_width, pl_directed_link_auton,
            pl_directed_link_speed, pl_upstream_prefer_deemph, pl_transmit_hot_rst, pl_downstream_deemph_source,
            cfg_interrupt_di, cfg_pciecap_interrupt_msgnum, cfg_interrupt_assert, cfg_interrupt, cfg_interrupt_stat, cfg_pm_force_state, cfg_pm_force_state_en, cfg_pm_halt_aspm_l0s,
            cfg_pm_halt_aspm_l1, cfg_pm_send_pme_to, cfg_pm_wake, cfg_trn_pending, cfg_turnoff_ok, rx_np_ok, rx_np_req, tx_cfg_gnt
    );
endinterface

// ------------------------------------------------------------------------
// Interface PCIe CFG module to PCIe TLP module
// ------------------------------------------------------------------------

interface IfCfg_TlpCfg;
    wire    [2:0]   tlp_tx_en;
    wire    [15:0]  tlp_pcie_id;
    
    modport cfg(
        output tlp_pcie_id, tlp_tx_en
    );
    
    modport tlp(
        input tlp_pcie_id, tlp_tx_en
    );
endinterface

// ------------------------------------------------------------------------
// Interface connecting PCIe CFG to FIFO
// ------------------------------------------------------------------------
interface IfPCIeFifoCfg;
    wire    [63:0]      tx_data;
    wire                tx_valid;
    wire    [31:0]      rx_data;
    wire                rx_valid;
    wire                rx_empty;
    wire                rx_rd_en;

    modport mp_fifo (
        output tx_data, tx_valid, rx_rd_en,
        input rx_data, rx_valid, rx_empty
    );

    modport mp_pcie (
        input tx_data, tx_valid, rx_rd_en,
        output rx_data, rx_valid, rx_empty
    );
endinterface

// ------------------------------------------------------------------------
// Interface connecting PCIe TLP to FIFO
// ------------------------------------------------------------------------
interface IfPCIeFifoTlp;
    wire    [31:0]      tx_data;
    wire                tx_last;
    wire                tx_valid;   
    wire    [31:0]      rx_data;
    wire                rx_last;
    wire                rx_valid;
    wire                rx_empty;
    wire                rx_rd_en;

    modport mp_fifo (
        output tx_data, tx_last, tx_valid, rx_rd_en,
        input rx_data, rx_last, rx_valid, rx_empty    
    );

    modport mp_pcie (
        input tx_data, tx_last, tx_valid, rx_rd_en,
        output rx_data, rx_last, rx_valid, rx_empty
    );
endinterface

// ------------------------------------------------------------------------
// Interface connecting PCIe CORE config to FIFO
// ------------------------------------------------------------------------
interface IfPCIeFifoCore;
    wire                clk100_en;
    // PCIe optional config
    wire                pcie_rst_core;
    wire                pcie_rst_subsys;
    wire    [15:0]      pcie_cfg_vend_id;
    wire    [15:0]      pcie_cfg_dev_id;
    wire    [7:0]       pcie_cfg_rev_id;
    wire    [15:0]      pcie_cfg_subsys_vend_id;
    wire    [15:0]      pcie_cfg_subsys_id;
    // DRP config
    wire                drp_rdy;
    wire    [15:0]      drp_do;
    wire                drp_en;
    wire                drp_we;
    wire    [8:0]       drp_addr;
    wire    [15:0]      drp_di;
    
    modport mp_fifo (
        input drp_rdy, drp_do,
        output clk100_en, pcie_rst_core, pcie_rst_subsys, pcie_cfg_vend_id, pcie_cfg_dev_id, pcie_cfg_rev_id, pcie_cfg_subsys_vend_id, pcie_cfg_subsys_id, drp_en, drp_we, drp_addr, drp_di
    );

    modport mp_pcie (
        input clk100_en, pcie_rst_core, pcie_rst_subsys, pcie_cfg_vend_id, pcie_cfg_dev_id, pcie_cfg_rev_id, pcie_cfg_subsys_vend_id, pcie_cfg_subsys_id, drp_en, drp_we, drp_addr, drp_di,
        output drp_rdy, drp_do
    );
endinterface

interface IfShadow2Fifo;
    // SHADOW CONFIGURATION SPACE TO FIFO
    wire                rx_rden;
    wire                rx_wren;
    wire    [3:0]       rx_be;
    wire    [31:0]      rx_data;
    wire    [9:0]       rx_addr;
    wire                rx_addr_lo;
    wire                tx_valid;
    wire    [31:0]      tx_data;
    wire    [9:0]       tx_addr;
    wire                tx_addr_lo;
    wire                cfgtlp_wren;
    wire                cfgtlp_zero;
    wire                cfgtlp_en;
    wire                cfgtlp_filter;
    
    modport fifo (
        output cfgtlp_wren, cfgtlp_zero, rx_rden, rx_wren, rx_be, rx_addr, rx_addr_lo, rx_data, cfgtlp_en, cfgtlp_filter,
        input tx_valid, tx_addr, tx_addr_lo, tx_data
    );

    modport src (
        input cfgtlp_wren, cfgtlp_zero, rx_rden, rx_wren, rx_be, rx_addr, rx_addr_lo, rx_data,
        output tx_valid, tx_addr, tx_addr_lo, tx_data
    );
    
    modport tlp (
        input cfgtlp_en, cfgtlp_filter
    );
endinterface

interface IfShadow2Tlp;
    // TLP -> SHADOW CONFIGURATION SPACE
    wire                rx_rden;
    wire                rx_wren;
    wire    [3:0]       rx_be;
    wire    [7:0]       rx_tag;
    wire    [9:0]       rx_addr;
    wire    [31:0]      rx_data;
    
    // SHADOW CONFIGURATION SPACE -> TLP
    wire    [7:0]       tx_tag;
    wire    [31:0]      tx_data;
    wire                tx_valid;
    wire                tx_tlprd;
    
    modport shadow (
        input rx_be, rx_tag, rx_addr, rx_data, rx_rden, rx_wren,
        output tx_tag, tx_data, tx_valid, tx_tlprd
    );
    
    modport tlp (
        output rx_be, rx_tag, rx_addr, rx_data, rx_rden, rx_wren,
        input tx_tag, tx_data, tx_valid, tx_tlprd
    );
    
endinterface

// ------------------------------------------------------------------------
// Interface PCIe AXI RX / TX
// ------------------------------------------------------------------------
interface IfPCIeTlpRxTx;
    wire    [63:0]      data;
    wire    [7:0]       keep;
    wire                last;
    wire                valid;
    wire                ready;
    
    modport source (
        output data, keep, last, valid,
        input ready
    );
    
    modport sink (
        input data, keep, last, valid,
        output ready
    );
endinterface


// ------------------------------------------------------------------------
// Interface TLP 128-byte connector
// ------------------------------------------------------------------------
interface IfTlp128;
    // [31:0]  = DWORD 1 - always valid 
    // [63:32] = DWORD 2 - depending on KEEP DWORD 2 if LAST DWORD
    // [64]    = LAST DWORD
    // [65]    = KEEP DWORD 2
    // in total 18 dual-dword = 4 dw hdr + 32 dw data
    wire    [66 * 18 - 1 : 0]   data;
    wire                        valid;
    wire                        has_data;
    wire                        req_data;
    
    modport source (
        output data, valid, has_data,
        input req_data
    );
    
    modport sink (
        input data, valid, has_data,
        output req_data
    );
endinterface

interface IfTlp64;
    // [31:0]  = DWORD 1 - always valid 
    // [63:32] = DWORD 2 - depending on KEEP DWORD 2 if LAST DWORD
    // [64]    = LAST DWORD
    // [65]    = KEEP DWORD 2
    // in total 6 dual-dword = 4 dw hdr + 8 dw data
    wire    [66 * 6 - 1 : 0]        data;
    wire                        valid;
    wire                        has_data;
    wire                        req_data;
    
    modport source (
        output data, valid, has_data,
        input req_data
    );
    
    modport sink (
        input data, valid, has_data,
        output req_data
    );
endinterface

interface IfTlp16;
    // [31:0]  = DWORD 1 - always valid 
    // [63:32] = DWORD 2 - depending on KEEP DWORD 2 if LAST DWORD
    // [64]    = LAST DWORD
    // [65]    = KEEP DWORD 2
    // in total 2 dual-dword = 3 dw hdr + 1 dw data
    wire    [66 * 2 - 1: 0]        data;
    wire                        valid;
    wire                        has_data;
    wire                        req_data;
    
    modport source (
        output data, valid, has_data,
        input req_data
    );
    
    modport sink (
        input data, valid, has_data,
        output req_data
    );
endinterface

`endif
