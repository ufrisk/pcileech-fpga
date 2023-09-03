//
// PCILeech FPGA.
//
// PCIe configuration module - CFG handling for Artix-7.
//
// (c) Ulf Frisk, 2018-2022
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_pcie_cfg_a7(
    input                   rst,
    input                   clk_100,    // 100MHz
    input                   clk_pcie,   // 62.5MHz
    IfPCIeFifoCfg.mp_pcie   dfifo,
    IfPCIeSignals.mpm       ctx,
    IfCfg_TlpCfg.cfg        cfg_tlpcfg,
    IfTlp64.source          tlp_static
    );

    // ----------------------------------------------------
    // TickCount64
    // ----------------------------------------------------
    
    time tickcount64 = 0;
    always @ ( posedge clk_pcie )
        tickcount64 <= tickcount64 + 1;
    
    // ----------------------------------------------------------------------------
    // Convert received CFG data from FT601 to PCIe clock domain
    // FIFO depth: 512 / 64-bits
    // ----------------------------------------------------------------------------
    reg             in_rden;
    wire [63:0]     in_dout;
    wire            in_empty;
    wire            in_valid;
    
    reg [63:0]      in_data64;
    wire [31:0]     in_data32   = in_data64[63:32];
    wire [15:0]     in_data16   = in_data64[31:16];
    wire [3:0]      in_type     = in_data64[15:12];
	
    fifo_64_64 i_fifo_pcie_cfg_tx(
        .rst            ( rst                   ),
        .wr_clk         ( clk_100               ),
        .rd_clk         ( clk_pcie              ),
        .din            ( dfifo.tx_data         ),
        .wr_en          ( dfifo.tx_valid        ),
        .rd_en          ( in_rden               ),
        .dout           ( in_dout               ),
        .full           (                       ),
        .empty          ( in_empty              ),
        .valid          ( in_valid              )
    );
    
    // ------------------------------------------------------------------------
    // Convert received CFG from PCIe core and transmit onwards to FT601
    // FIFO depth: 512 / 64-bits.
    // ------------------------------------------------------------------------
    reg             out_wren;
    reg [31:0]      out_data;
    wire            pcie_cfg_rx_almost_full;
    
    fifo_32_32_clk2 i_fifo_pcie_cfg_rx(
        .rst            ( rst                   ),
        .wr_clk         ( clk_pcie              ),
        .rd_clk         ( clk_100               ),
        .din            ( out_data              ),
        .wr_en          ( out_wren              ),
        .rd_en          ( dfifo.rx_rd_en        ),
        .dout           ( dfifo.rx_data         ),
        .full           (                       ),
        .almost_full    ( pcie_cfg_rx_almost_full ),
        .empty          ( dfifo.rx_empty        ),
        .valid          ( dfifo.rx_valid        )
    );
    
    // ------------------------------------------------------------------------
    // REGISTER FILE: COMMON
    // ------------------------------------------------------------------------
    
    wire    [383:0]     ro;
    reg     [703:0]     rw;
    
    // special non-user accessible registers 
    reg                 rwi_cfg_mgmt_rd_en;
    reg                 rwi_cfg_mgmt_wr_en;
    reg                 rwi_cfgrd_valid;
    reg     [9:0]       rwi_cfgrd_addr;
    reg     [3:0]       rwi_cfgrd_byte_en;
    reg     [31:0]      rwi_cfgrd_data;
    reg                 rwi_tlp_static_valid;
    reg                 rwi_tlp_static_has_data;
    reg     [31:0]      rwi_count_cfgspace_status_cl;
   
    // ------------------------------------------------------------------------
    // REGISTER FILE: READ-ONLY LAYOUT/SPECIFICATION
    // ------------------------------------------------------------------------
     
    // MAGIC
    assign ro[15:0]     = 16'h2301;                     // +000: MAGIC
    // SPECIAL
    assign ro[16]       = ctx.cfg_mgmt_rd_en;           // +002: SPECIAL
    assign ro[17]       = ctx.cfg_mgmt_wr_en;           //
    assign ro[31:18]    = 0;                            //
    // SIZEOF / BYTECOUNT [little-endian]
    assign ro[63:32]    = $bits(ro) >> 3;               // +004: BYTECOUNT
    // PCIe CFG STATUS
    assign ro[71:64]    = ctx.cfg_bus_number;           // +008:
    assign ro[76:72]    = ctx.cfg_device_number;        //
    assign ro[79:77]    = ctx.cfg_function_number;      //
    // PCIe PL PHY
    assign ro[85:80]    = ctx.pl_ltssm_state;           // +00A
    assign ro[87:86]    = ctx.pl_rx_pm_state;           //
    assign ro[90:88]    = ctx.pl_tx_pm_state;           // +00B
    assign ro[93:91]    = ctx.pl_initial_link_width;    //
    assign ro[95:94]    = ctx.pl_lane_reversal_mode;    //
    assign ro[97:96]    = ctx.pl_sel_lnk_width;         // +00C
    assign ro[98]       = ctx.pl_phy_lnk_up;            //
    assign ro[99]       = ctx.pl_link_gen2_cap;         //
    assign ro[100]      = ctx.pl_link_partner_gen2_supported; //
    assign ro[101]      = ctx.pl_link_upcfg_cap;        //
    assign ro[102]      = ctx.pl_sel_lnk_rate;          //
    assign ro[103]      = ctx.pl_directed_change_done;  // +00D:
    assign ro[104]      = ctx.pl_received_hot_rst;      //
    assign ro[126:105]  = 0;                            //       SLACK
    assign ro[127]      = ctx.cfg_mgmt_rd_wr_done;      //
    // PCIe CFG MGMT
    assign ro[159:128]  = ctx.cfg_mgmt_do;              // +010:
    // PCIe CFG STATUS
    assign ro[175:160]  = ctx.cfg_command;              // +014:
    assign ro[176]      = ctx.cfg_aer_rooterr_corr_err_received;            // +016:
    assign ro[177]      = ctx.cfg_aer_rooterr_corr_err_reporting_en;        //
    assign ro[178]      = ctx.cfg_aer_rooterr_fatal_err_received;           //
    assign ro[179]      = ctx.cfg_aer_rooterr_fatal_err_reporting_en;       //
    assign ro[180]      = ctx.cfg_aer_rooterr_non_fatal_err_received;       //
    assign ro[181]      = ctx.cfg_aer_rooterr_non_fatal_err_reporting_en;   //
    assign ro[182]      = ctx.cfg_bridge_serr_en;                           //
    assign ro[183]      = ctx.cfg_received_func_lvl_rst;                    //
    assign ro[186:184]  = ctx.cfg_pcie_link_state;      // +017:
    assign ro[187]      = ctx.cfg_pmcsr_pme_en;         //
    assign ro[189:188]  = ctx.cfg_pmcsr_powerstate;     //
    assign ro[190]      = ctx.cfg_pmcsr_pme_status;     //
    assign ro[191]      = 0;                            //       SLACK
    assign ro[207:192]  = ctx.cfg_dcommand;             // +018:
    assign ro[223:208]  = ctx.cfg_dcommand2;            // +01A:
    assign ro[239:224]  = ctx.cfg_dstatus;              // +01C:
    assign ro[255:240]  = ctx.cfg_lcommand;             // +01E:
    assign ro[271:256]  = ctx.cfg_lstatus;              // +020:
    assign ro[287:272]  = ctx.cfg_status;               // +022:
    assign ro[293:288]  = ctx.tx_buf_av;                // +024:
    assign ro[294]      = ctx.tx_cfg_req;               //
    assign ro[295]      = ctx.tx_err_drop;              //
    assign ro[302:296]  = ctx.cfg_vc_tcvc_map;          // +025:
    assign ro[303]      = 0;                            //       SLACK
    assign ro[304]      = ctx.cfg_root_control_pme_int_en;              // +026:
    assign ro[305]      = ctx.cfg_root_control_syserr_corr_err_en;      //
    assign ro[306]      = ctx.cfg_root_control_syserr_fatal_err_en;     //
    assign ro[307]      = ctx.cfg_root_control_syserr_non_fatal_err_en; //
    assign ro[308]      = ctx.cfg_slot_control_electromech_il_ctl_pulse;//
    assign ro[309]      = ctx.cfg_to_turnoff;                           //
    assign ro[319:310]  = 0;                                            //       SLACK
    // PCIe INTERRUPT
    assign ro[327:320]  = ctx.cfg_interrupt_do;         // +028:
    assign ro[330:328]  = ctx.cfg_interrupt_mmenable;   // +029:
    assign ro[331]      = ctx.cfg_interrupt_msienable;  //
    assign ro[332]      = ctx.cfg_interrupt_msixenable; //
    assign ro[333]      = ctx.cfg_interrupt_msixfm;     //
    assign ro[334]      = ctx.cfg_interrupt_rdy;        //
    assign ro[335]      = 0;                            //       SLACK
    // CFG SPACE READ RESULT
    assign ro[345:336]  = rwi_cfgrd_addr;               // +02A:
    assign ro[346]      = 0;                            //       SLACK
    assign ro[347]      = rwi_cfgrd_valid;              //
    assign ro[351:348]  = rwi_cfgrd_byte_en;            //
    assign ro[383:352]  = rwi_cfgrd_data;               // +02C:
    // 0030 - 
    
    
    // ------------------------------------------------------------------------
    // INITIALIZATION/RESET BLOCK _AND_
    // REGISTER FILE: READ-WRITE LAYOUT/SPECIFICATION
    // ------------------------------------------------------------------------
    
    localparam integer  RWPOS_CFG_RD_EN                 = 16;
    localparam integer  RWPOS_CFG_WR_EN                 = 17;
    localparam integer  RWPOS_CFG_WAIT_COMPLETE         = 18;
    localparam integer  RWPOS_CFG_STATIC_TLP_TX_EN      = 19;
    localparam integer  RWPOS_CFG_CFGSPACE_STATUS_CL_EN = 20;
    localparam integer  RWPOS_CFG_CFGSPACE_COMMAND_EN   = 21;
    
    task pcileech_pcie_cfg_a7_initialvalues;        // task is non automatic
        begin
            out_wren <= 1'b0;
            
            rwi_cfg_mgmt_rd_en <= 1'b0;
            rwi_cfg_mgmt_wr_en <= 1'b0;
    
            // MAGIC
            rw[15:0]    <= 16'h6745;                // +000:
            // SPECIAL START TASK BLOCK (write 1 to start action)
            rw[16]      <= 0;                       // +002: CFG RD EN
            rw[17]      <= 0;                       //       CFG WR EN
            rw[18]      <= 0;                       //       WAIT FOR PCIe CFG SPACE RD/WR COMPLETION BEFORE ACCEPT NEW FIFO READ/WRITES
            rw[19]      <= 0;                       //       TLP_STATIC TX ENABLE
            rw[20]      <= 0;                       //       CFGSPACE_STATUS_REGISTER_AUTO_CLEAR [master abort flag]
            rw[21]      <= 0;                       //       CFGSPACE_COMMAND_REGISTER_AUTO_SET [bus master and other flags (set in rw[143:128] <= 16'h....;)]
            rw[27:22]   <= 0;                       //       RESERVED FUTURE
            rw[31:28]   <= 4'hf;                    //       PCIe TLP TX ENABLE FOR MUX CHANNEL 0-3 [MUX[0] == RW[28] ..].
            // SIZEOF / BYTECOUNT [little-endian]
            rw[63:32]   <= $bits(rw) >> 3;          // +004: bytecount [little endian]
            // DSN
            rw[127:64]  <= 64'h0000000101000A35;    // +008: cfg_dsn
            // PCIe CFG MGMT
            rw[159:128] <= 0;                       // +010: cfg_mgmt_di
            rw[169:160] <= 0;                       // +014: cfg_mgmt_dwaddr
            rw[170]     <= 0;                       //       cfg_mgmt_wr_readonly
            rw[171]     <= 0;                       //       cfg_mgmt_wr_rw1c_as_rw
            rw[175:172] <= 4'hf;                    //       cfg_mgmt_byte_en
            // PCIe PL PHY
            rw[176]     <= 0;                       // +016: pl_directed_link_auton
            rw[178:177] <= 0;                       //       pl_directed_link_change
            rw[179]     <= 1;                       //       pl_directed_link_speed 
            rw[181:180] <= 0;                       //       pl_directed_link_width            
            rw[182]     <= 1;                       //       pl_upstream_prefer_deemph
            rw[183]     <= 0;                       //       pl_transmit_hot_rst
            rw[184]     <= 0;                       // +017: pl_downstream_deemph_source
            rw[191:185] <= 0;                       //       SLACK  
            // PCIe INTERRUPT
            rw[199:192] <= 0;                       // +018: cfg_interrupt_di
            rw[204:200] <= 0;                       // +019: cfg_pciecap_interrupt_msgnum
            rw[205]     <= 0;                       //       cfg_interrupt_assert
            rw[206]     <= 0;                       //       cfg_interrupt
            rw[207]     <= 0;                       //       cfg_interrupt_stat
            // PCIe CTRL
            rw[209:208] <= 0;                       // +01A: cfg_pm_force_state
            rw[210]     <= 0;                       //       cfg_pm_force_state_en
            rw[211]     <= 0;                       //       cfg_pm_halt_aspm_l0s
            rw[212]     <= 0;                       //       cfg_pm_halt_aspm_l1
            rw[213]     <= 0;                       //       cfg_pm_send_pme_to
            rw[214]     <= 0;                       //       cfg_pm_wake
            rw[215]     <= 0;                       //       cfg_trn_pending
            rw[216]     <= 0;                       // +01B: cfg_turnoff_ok
            rw[217]     <= 1;                       //       rx_np_ok
            rw[218]     <= 1;                       //       rx_np_req
            rw[219]     <= 1;                       //       tx_cfg_gnt
            rw[223:220] <= 0;                       //       SLACK 
            // PCIe STATIC TLP TRANSMIT
            rw[224+:12] <= 0;                       // +01C: TLP_STATIC TLP QWORD VALID [each-2bit: [0] = last, [1] = keep]
            rw[236+:4]  <= 0;                       // +01C: SLACK
            rw[240+:16] <= 0;                       // +01E: TLP_STATIC TLP TX SLEEP (ticks) [little-endian]
            rw[256+:384] <= 0;                      // +020: TLP_STATIC TLP [6*64-bit, 12*32-bit hdr+data]
            rw[640+:32] <= 0;                       // +050: TLP_STATIC TLP RETRANSMIT COUNT
            // PCIe STATUS register clear timer
            rw[672+:32] <= 62500;                   // +054: CFGSPACE_STATUS_CLEAR TIMER (ticks) [little-endian] [default = 1ms - 62.5k @ 62.5MHz]
            
        end
    endtask
    
    assign ctx.cfg_mgmt_rd_en               = rwi_cfg_mgmt_rd_en & ~ctx.cfg_mgmt_rd_wr_done;
    assign ctx.cfg_mgmt_wr_en               = rwi_cfg_mgmt_wr_en & ~ctx.cfg_mgmt_rd_wr_done;
    
    assign ctx.cfg_dsn                      = rw[127:64];
    assign ctx.cfg_mgmt_di                  = rw[159:128];
    assign ctx.cfg_mgmt_dwaddr              = rw[169:160];
    assign ctx.cfg_mgmt_wr_readonly         = rw[170];
    assign ctx.cfg_mgmt_wr_rw1c_as_rw       = rw[171];
    assign ctx.cfg_mgmt_byte_en             = rw[175:172];
    
    assign ctx.pl_directed_link_auton       = rw[176];
    assign ctx.pl_directed_link_change      = rw[178:177];
    assign ctx.pl_directed_link_speed       = rw[179];
    assign ctx.pl_directed_link_width       = rw[181:180];
    assign ctx.pl_upstream_prefer_deemph    = rw[182];
    assign ctx.pl_transmit_hot_rst          = rw[183];
    assign ctx.pl_downstream_deemph_source  = rw[184];
    
    assign ctx.cfg_interrupt_di             = rw[199:192];
    assign ctx.cfg_pciecap_interrupt_msgnum = rw[204:200];
    assign ctx.cfg_interrupt_assert         = rw[205];
    assign ctx.cfg_interrupt                = rw[206];
    assign ctx.cfg_interrupt_stat           = rw[207];

    assign ctx.cfg_pm_force_state           = rw[209:208];
    assign ctx.cfg_pm_force_state_en        = rw[210];
    assign ctx.cfg_pm_halt_aspm_l0s         = rw[211];
    assign ctx.cfg_pm_halt_aspm_l1          = rw[212];
    assign ctx.cfg_pm_send_pme_to           = rw[213];
    assign ctx.cfg_pm_wake                  = rw[214];
    assign ctx.cfg_trn_pending              = rw[215];
    assign ctx.cfg_turnoff_ok               = rw[216];
    assign ctx.rx_np_ok                     = rw[217];
    assign ctx.rx_np_req                    = rw[218];
    assign ctx.tx_cfg_gnt                   = rw[219];
    
    assign cfg_tlpcfg.tlp_tx_en             = rw[31:28];
    assign cfg_tlpcfg.tlp_pcie_id           = ro[79:64];
    
    assign tlp_static.data[395:0]           = {
        rw[(224+2*5)+:2], rw[(256+64*5+32)+:8], rw[(256+64*5+40)+:8], rw[(256+64*5+48)+:8], rw[(256+64*5+56)+:8], rw[(256+64*5+00)+:8], rw[(256+64*5+08)+:8], rw[(256+64*5+16)+:8], rw[(256+64*5+24)+:8],
        rw[(224+2*4)+:2], rw[(256+64*4+32)+:8], rw[(256+64*4+40)+:8], rw[(256+64*4+48)+:8], rw[(256+64*4+56)+:8], rw[(256+64*4+00)+:8], rw[(256+64*4+08)+:8], rw[(256+64*4+16)+:8], rw[(256+64*4+24)+:8],
        rw[(224+2*3)+:2], rw[(256+64*3+32)+:8], rw[(256+64*3+40)+:8], rw[(256+64*3+48)+:8], rw[(256+64*3+56)+:8], rw[(256+64*3+00)+:8], rw[(256+64*3+08)+:8], rw[(256+64*3+16)+:8], rw[(256+64*3+24)+:8],
        rw[(224+2*2)+:2], rw[(256+64*2+32)+:8], rw[(256+64*2+40)+:8], rw[(256+64*2+48)+:8], rw[(256+64*2+56)+:8], rw[(256+64*2+00)+:8], rw[(256+64*2+08)+:8], rw[(256+64*2+16)+:8], rw[(256+64*2+24)+:8],
        rw[(224+2*1)+:2], rw[(256+64*1+32)+:8], rw[(256+64*1+40)+:8], rw[(256+64*1+48)+:8], rw[(256+64*1+56)+:8], rw[(256+64*1+00)+:8], rw[(256+64*1+08)+:8], rw[(256+64*1+16)+:8], rw[(256+64*1+24)+:8],
        rw[(224+2*0)+:2], rw[(256+64*0+32)+:8], rw[(256+64*0+40)+:8], rw[(256+64*0+48)+:8], rw[(256+64*0+56)+:8], rw[(256+64*0+00)+:8], rw[(256+64*0+08)+:8], rw[(256+64*0+16)+:8], rw[(256+64*0+24)+:8]};
    assign tlp_static.valid                 = rwi_tlp_static_valid;
    assign tlp_static.has_data              = rwi_tlp_static_has_data;
    
    // ------------------------------------------------------------------------
    // STATE MACHINE / LOGIC FOR READ/WRITE AND OTHER HOUSEKEEPING TASKS
    // ------------------------------------------------------------------------
    
    integer i_write, i_tlpstatic;
    wire [15:0] in_cmd_address_byte = in_dout[31:16];
    wire [17:0] in_cmd_address_bit  = {in_cmd_address_byte[14:0], 3'b000};
    wire [15:0] in_cmd_value        = {in_dout[48+:8], in_dout[56+:8]};
    wire [15:0] in_cmd_mask         = {in_dout[32+:8], in_dout[40+:8]};
    wire        f_rw                = in_cmd_address_byte[15]; 
    wire [15:0] in_cmd_data_in      = (in_cmd_address_bit < (f_rw ? $bits(rw) : $bits(ro))) ? (f_rw ? rw[in_cmd_address_bit+:16] : ro[in_cmd_address_bit+:16]) : 16'h0000;
    wire        in_cmd_read         = in_dout[12] & in_valid;
    wire        in_cmd_write        = in_dout[13] & in_cmd_address_byte[15] & in_valid;
    wire        pcie_cfg_rw_en      = rwi_cfg_mgmt_rd_en | rwi_cfg_mgmt_wr_en | rw[RWPOS_CFG_RD_EN] | rw[RWPOS_CFG_WR_EN];
    // in_rden = request data from incoming fifo. Only do this if there is space
    // in the output fifo and every 2nd clock cycle (in case a resulting write
    // starts an action that will last longer than a single clock there must be
    // time to react and stop reading incoming read/writes until processed).
    assign in_rden = tickcount64[1] & ~pcie_cfg_rx_almost_full & ( ~rw[RWPOS_CFG_WAIT_COMPLETE] | ~pcie_cfg_rw_en);
    
    initial pcileech_pcie_cfg_a7_initialvalues();
    
    always @ ( posedge clk_pcie )
        if ( rst )
            pcileech_pcie_cfg_a7_initialvalues();
        else
            begin
                // READ config
                out_wren <= in_cmd_read;
                if ( in_cmd_read )
                    begin
                        out_data[31:16] <= in_cmd_address_byte;
                        out_data[15:0]  <= {in_cmd_data_in[7:0], in_cmd_data_in[15:8]};
                    end

                // WRITE config
                if ( in_cmd_write )
                    for ( i_write = 0; i_write < 16; i_write = i_write + 1 )
                        begin
                            if ( in_cmd_mask[i_write] )
                                rw[in_cmd_address_bit+i_write] <= in_cmd_value[i_write];
                        end

                // STATUS REGISTER CLEAR
                if ( (rw[RWPOS_CFG_CFGSPACE_STATUS_CL_EN] | rw[RWPOS_CFG_CFGSPACE_COMMAND_EN]) & ~in_cmd_read & ~in_cmd_write & ~rw[RWPOS_CFG_RD_EN] & ~rw[RWPOS_CFG_WR_EN] & ~rwi_cfg_mgmt_rd_en & ~rwi_cfg_mgmt_wr_en )
                    if ( rwi_count_cfgspace_status_cl < rw[672+:32] )
                        rwi_count_cfgspace_status_cl <= rwi_count_cfgspace_status_cl + 1;
                    else begin
                        rwi_count_cfgspace_status_cl <= 0;
                        rw[RWPOS_CFG_WR_EN] <= 1'b1;
                        rw[143:128] <= 16'h0007;                            // cfg_mgmt_di: command register [update to set individual command register bits]
                        rw[159:144] <= 16'hff00;                            // cfg_mgmt_di: status register [do not update]
                        rw[169:160] <= 1;                                   // cfg_mgmt_dwaddr
                        rw[170]     <= 0;                                   // cfg_mgmt_wr_readonly
                        rw[171]     <= 0;                                   // cfg_mgmt_wr_rw1c_as_rw
                        rw[172]     <= rw[RWPOS_CFG_CFGSPACE_COMMAND_EN];   // cfg_mgmt_byte_en: command register
                        rw[173]     <= rw[RWPOS_CFG_CFGSPACE_COMMAND_EN];   // cfg_mgmt_byte_en: command register
                        rw[174]     <= 0;                                   // cfg_mgmt_byte_en: status register
                        rw[175]     <= rw[RWPOS_CFG_CFGSPACE_STATUS_CL_EN]; // cfg_mgmt_byte_en: status register
                    end

                // CONFIG SPACE READ/WRITE                        
                if ( ctx.cfg_mgmt_rd_wr_done )
                    begin
                        rwi_cfg_mgmt_rd_en  <= 1'b0;
                        rwi_cfg_mgmt_wr_en  <= 1'b0;
                        rwi_cfgrd_valid     <= 1'b1;
                        rwi_cfgrd_addr      <= ctx.cfg_mgmt_dwaddr;
                        rwi_cfgrd_data      <= ctx.cfg_mgmt_do;
                        rwi_cfgrd_byte_en   <= ctx.cfg_mgmt_byte_en;
                    end
                else if ( rw[RWPOS_CFG_RD_EN] )
                    begin
                        rw[RWPOS_CFG_RD_EN] <= 1'b0;
                        rwi_cfg_mgmt_rd_en  <= 1'b1;
                        rwi_cfgrd_valid     <= 1'b0;
                    end
                else if ( rw[RWPOS_CFG_WR_EN] )
                    begin
                        rw[RWPOS_CFG_WR_EN] <= 1'b0;
                        rwi_cfg_mgmt_wr_en  <= 1'b1;
                        rwi_cfgrd_valid     <= 1'b0;
                    end
                    
                // STATIC_TLP TRANSMIT
                if ( rwi_tlp_static_valid | ~rw[RWPOS_CFG_STATIC_TLP_TX_EN] )
                    begin
                        rwi_tlp_static_valid <= 1'b0;
                        rwi_tlp_static_has_data <= 1'b0;
                    end
                else if ( rwi_tlp_static_has_data & tlp_static.req_data )
                     rwi_tlp_static_valid <= 1'b1;
                else if ( ((tickcount64[0+:16] & rw[240+:16]) == rw[240+:16]) & (rw[640+:32] > 0) & (tlp_static.data[64] | tlp_static.data[65]) )
                    begin
                        rwi_tlp_static_has_data <= 1'b1;
                        rw[640+:32] <= rw[640+:32] - 1;     // count - 1
                        if ( rw[640+:32] == 32'h00000001 )
                            rw[RWPOS_CFG_STATIC_TLP_TX_EN] <= 1'b0;
                    end
                
            end
    
endmodule
