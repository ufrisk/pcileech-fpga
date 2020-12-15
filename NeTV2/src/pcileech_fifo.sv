//
// PCILeech FPGA.
//
// FIFO network / control.
//
// (c) Ulf Frisk, 2017-2020
// Author: Ulf Frisk, pcileech@frizk.net
// Special thanks to: Dmytro Oleksiuk @d_olex
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

//`define ENABLE_STARTUPE2

module pcileech_fifo #(
    parameter               PARAM_DEVICE_ID = 0,
    parameter               PARAM_VERSION_NUMBER_MAJOR = 0,
    parameter               PARAM_VERSION_NUMBER_MINOR = 0,
    parameter               PARAM_CUSTOM_VALUE = 0
) (
    input                   clk,
    input                   rst,
    
    input                   pcie_present,
    input                   pcie_perst_n,
    
    IfComToFifo.mp_fifo     dcom,
    
    IfPCIeFifoCfg.mp_fifo   dcfg,
    IfPCIeFifoTlp.mp_fifo   dtlp,
    IfPCIeFifoCore.mp_fifo  dpcie,
    IfShadow2Fifo.fifo      dshadow2fifo
    );
      
    // ----------------------------------------------------
    // TickCount64
    // ----------------------------------------------------
    
    time tickcount64 = 0;
    always @ ( posedge clk )
        tickcount64 <= tickcount64 + 1;
   
    // ----------------------------------------------------------------------------
    // RX FROM USB/FT601/FT245 BELOW:
    // ----------------------------------------------------------------------------
    // Incoming data received from FT601 is converted from 32-bit to 64-bit.
    // This always happen regardless whether receiving FIFOs are full or not.
    // The actual data contains a MAGIC which tells which receiving FIFO should
    // accept the data. Receiving TYPEs are: PCIe TLP, PCIe CFG, Loopback, Command.
    //
    //         /--> PCIe TLP (32-bit)
    //         |
    // FT601 --+--> PCIe CFG (64-bit)
    //         |
    //         +--> LOOPBACK (32-bit)
    //         |
    //         \--> COMMAND  (64-bit)
    //
            
    // ----------------------------------------------------------
    // Route 64-bit incoming FT601 data to correct receiver below:
    // ----------------------------------------------------------
    `define CHECK_MAGIC     (dcom.com_dout[7:0] == 8'h77)
    `define CHECK_TYPE_TLP  (dcom.com_dout[9:8] == 2'b00)
    `define CHECK_TYPE_CFG  (dcom.com_dout[9:8] == 2'b01)
    `define CHECK_TYPE_LOOP (dcom.com_dout[9:8] == 2'b10)
    `define CHECK_TYPE_CMD  (dcom.com_dout[9:8] == 2'b11)
    
    assign   dtlp.tx_valid = dcom.com_dout_valid & `CHECK_MAGIC & `CHECK_TYPE_TLP;
    assign   dcfg.tx_valid = dcom.com_dout_valid & `CHECK_MAGIC & `CHECK_TYPE_CFG;
    wire     _loop_rx_wren = dcom.com_dout_valid & `CHECK_MAGIC & `CHECK_TYPE_LOOP;
    wire     _cmd_rx_wren  = dcom.com_dout_valid & `CHECK_MAGIC & `CHECK_TYPE_CMD;
    
    // Incoming TLPs are forwarded to PCIe core logic.
    assign dtlp.tx_data = dcom.com_dout[63:32];
    assign dtlp.tx_last = dcom.com_dout[10];
    // Incoming CFGs are forwarded to PCIe core logic.
    assign dcfg.tx_data = dcom.com_dout;

    // ----------------------------------------------------------------------------
    // TX TO USB/FT601/FT245 BELOW:
    // ----------------------------------------------------------------------------
    //
    //                                         MULTIPLEXER
    //                                         ===========
    //                                         1st priority
    // PCIe TLP ->(32-bit) --------------------->--\
    //                                         2nd |    /-----------------------------------------\
    // PCIe CFG ->(32-bit)---------------------->--+--> | 256-> BUFFER FIFO (NATIVE OR DRAM) ->32 | -> FT601
    //                                             |    \-----------------------------------------/
    //            /--------------------------\ 3rd |
    // FT601   -> | 34->  Loopback FIFO ->34 | ->--/
    //            \--------------------------/     | 
    //                                             |
    //            /--------------------------\ 4th |
    // COMMAND -> | 34->  Command FIFO  ->34 | ->--/
    //            \--------------------------/
    //
   
    // ----------------------------------------------------------
    // LOOPBACK FIFO:
    // ----------------------------------------------------------
    wire [33:0]       _loop_dout;
    wire              _loop_valid;
    wire              _loop_empty;
    wire              _loop_rd_en;
    fifo_34_34 i_fifo_loop_tx(
        .clk            ( clk                       ),
        .srst           ( rst                       ),
        .rd_en          ( _loop_rd_en               ),
        .dout           ( _loop_dout                ),
        .din            ( {dcom.com_dout[11:10], dcom.com_dout[63:32]} ),
        .wr_en          ( _loop_rx_wren             ),
        .full           (                           ),
        .almost_full    (                           ),
        .empty          ( _loop_empty               ),
        .valid          ( _loop_valid               )
    );
   
    // ----------------------------------------------------------
    // COMMAND FIFO:
    // ----------------------------------------------------------
    wire [33:0]       _cmd_tx_dout;
    wire              _cmd_tx_valid;
    wire              _cmd_tx_empty;
    wire              _cmd_tx_rd_en;
    wire              _cmd_tx_almost_full;
    reg               _cmd_tx_wr_en;
    reg [33:0]        _cmd_tx_din;
    fifo_34_34 i_fifo_cmd_tx(
        .clk            ( clk                       ),
        .srst           ( rst                       ),
        .rd_en          ( _cmd_tx_rd_en             ),
        .dout           ( _cmd_tx_dout              ),
        .din            ( _cmd_tx_din               ),
        .wr_en          ( _cmd_tx_wr_en             ),
        .full           (                           ),
        .almost_full    ( _cmd_tx_almost_full       ),
        .empty          ( _cmd_tx_empty             ),
        .valid          ( _cmd_tx_valid             )
    );

    // ----------------------------------------------------------
    // MULTIPLEXER
    // ----------------------------------------------------------
    pcileech_mux i_pcileech_mux(
        .clk            ( clk                       ),
        .rst            ( rst                       ),
        // output
        .dout           ( dcom.com_din              ),
        .valid          ( dcom.com_din_wr_en        ),
        .rd_en          ( dcom.com_din_ready        ),
        // port0: PCIe TLP (highest priority)
        .p0_din         ( dtlp.rx_data              ),
        .p0_ctx         ( {1'b0, dtlp.rx_last}      ),
        .p0_wr_en       ( dtlp.rx_valid             ),
        .p0_has_data    ( ~dtlp.rx_empty            ),
        .p0_req_data    ( dtlp.rx_rd_en             ),
        // port1: PCIe CFG
        .p1_din         ( dcfg.rx_data              ),
        .p1_ctx         ( 2'b00                     ),
        .p1_wr_en       ( dcfg.rx_valid             ),
        .p1_has_data    ( ~dcfg.rx_empty            ),
        .p1_req_data    ( dcfg.rx_rd_en             ),
        // port2: LOOPBACK
        .p2_din         ( _loop_dout[31:0]          ),
        .p2_ctx         ( _loop_dout[33:32]         ),
        .p2_wr_en       ( _loop_valid               ),
        .p2_has_data    ( ~_loop_empty              ),
        .p2_req_data    ( _loop_rd_en               ),
        // port3: COMMAND (lowest priority)
        .p3_din         ( _cmd_tx_dout[31:0]        ),
        .p3_ctx         ( _cmd_tx_dout[33:32]       ),
        .p3_wr_en       ( _cmd_tx_valid             ),
        .p3_has_data    ( ~_cmd_tx_empty            ),
        .p3_req_data    ( _cmd_tx_rd_en             )
    );
   
    // ------------------------------------------------------------------------
    // COMMAND / CONTROL FIFO: REGISTER FILE: COMMON
    // ------------------------------------------------------------------------
    
    localparam          RWPOS_WAIT_COMPLETE         = 18;   // WAIT FOR DRP COMPLETION
    localparam          RWPOS_DRP_RD_EN             = 20;
    localparam          RWPOS_DRP_WR_EN             = 21;
    localparam          RWPOS_GLOBAL_SYSTEM_RESET   = 31;
    
    wire    [319:0]     ro;
    reg     [239:0]     rw;
    
    // special non-user accessible registers 
    reg     [77:0]      _pcie_core_config = { 1'b0, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 8'h02, 16'h0666, 16'h10EE, 16'h0007, 16'h10EE };
    time                _cmd_timer_inactivity_base;
    reg                 rwi_drp_rd_en;
    reg                 rwi_drp_wr_en;
    reg     [15:0]      rwi_drp_data;
    
    // ------------------------------------------------------------------------
    // COMMAND / CONTROL FIFO: REGISTER FILE: READ-ONLY LAYOUT/SPECIFICATION
    // ------------------------------------------------------------------------
    
    // MAGIC
    assign ro[15:0]     = 16'hab89;                     // +000: MAGIC
    // SPECIAL
    assign ro[19:16]    = 0;                            // +002: SPECIAL
    assign ro[20]       = rwi_drp_rd_en;                //
    assign ro[21]       = rwi_drp_wr_en;                //
    assign ro[31:22]    = 0;                            //
    // SIZEOF / BYTECOUNT [little-endian]
    assign ro[63:32]    = $bits(ro) >> 3;               // +004: SIZEOF / BYTECOUNT [little-endian]
    // ID: VERSION & DEVICE
    assign ro[71:64]    = PARAM_VERSION_NUMBER_MAJOR;   // +008: VERSION MAJOR
    assign ro[79:72]    = PARAM_VERSION_NUMBER_MINOR;   // +009: VERSION MINOR
    assign ro[87:80]    = PARAM_DEVICE_ID;              // +00A: DEVICE ID
    assign ro[127:88]   = 0;                            // +00B: SLACK
    // UPTIME (tickcount64*100MHz)
    assign ro[191:128]   = tickcount64;                 // +010: UPTIME (tickcount64*100MHz)
    // INACTIVITY TIMER
    assign ro[255:192]  = _cmd_timer_inactivity_base;   // +018: INACTIVITY TIMER
    // PCIe DRP 
    assign ro[271:256]  = rwi_drp_data;                 // +020: DRP: pcie_drp_do
    // PCIe
    assign ro[272]      = pcie_present;                 // +022: PCIe PRSNT#
    assign ro[273]      = pcie_perst_n;                 //       PCIe PERST#
    assign ro[287:274]  = 0;                            //       SLACK
    // CUSTOM_VALUE
    assign ro[319:288]  = PARAM_CUSTOM_VALUE;           // +024: CUSTOM VALUE
    // +028
    
    // ------------------------------------------------------------------------
    // INITIALIZATION/RESET BLOCK _AND_
    // COMMAND / CONTROL FIFO: REGISTER FILE: READ-WRITE LAYOUT/SPECIFICATION
    // ------------------------------------------------------------------------
    
    task pcileech_fifo_ctl_initialvalues;               // task is non automatic
        begin
            _cmd_tx_wr_en  <= 1'b0;
               
            // MAGIC
            rw[15:0]    <= 16'hefcd;                    // +000: MAGIC
            // SPECIAL
            rw[16]      <= 0;                           // +002: enable inactivity timer
            rw[17]      <= 0;                           //       enable send count
            rw[18]      <= 1;                           //       WAIT FOR PCIe DRP RD/WR COMPLETION BEFORE ACCEPT NEW FIFO READ/WRITES
            rw[19]      <= 0;                           //       SLACK
            rw[20]      <= 0;                           //       DRP RD EN
            rw[21]      <= 0;                           //       DRP WR EN
            rw[30:22]   <= 0;                           //       RESERVED FUTURE
            rw[31]      <= 0;                           //       global system reset (GSR) via STARTUPE2 primitive
            // SIZEOF / BYTECOUNT [little-endian]
            rw[63:32]   <= $bits(rw) >> 3;              // +004: bytecount [little endian]
            // CMD INACTIVITY TIMER TRIGGER VALUE
            rw[95:64]   <= 0;                           // +008: cmd_inactivity_timer (ticks) [little-endian]
            // CMD SEND COUNT
            rw[127:96]  <= 0;                           // +00C: cmd_send_count [little-endian]
            // PCIE INITIAL CONFIG (SPECIAL BITSTREAM)
            // NB! "initial" CLK0 values may also be changed in: '_pcie_core_config = {...};' [important on PCIeScreamer].
            rw[143:128] <= 16'h10EE;                    // +010: CFG_SUBSYS_VEND_ID (NOT IMPLEMENTED)
            rw[159:144] <= 16'h0007;                    // +012: CFG_SUBSYS_ID (NOT IMPLEMENTED)
            rw[175:160] <= 16'h10EE;                    // +014: CFG_VEND_ID (NOT IMPLEMENTED)
            rw[191:176] <= 16'h0666;                    // +016: CFG_DEV_ID (NOT IMPLEMENTED)
            rw[199:192] <= 8'h02;                       // +018: CFG_REV_ID (NOT IMPLEMENTED)
            rw[200]     <= 1'b1;                        // +019: PCIE CORE RESET
            rw[201]     <= 1'b0;                        //       PCIE SUBSYSTEM RESET
            rw[202]     <= 1'b1;                        //       CFGTLP PROCESSING ENABLE
            rw[203]     <= 1'b1;                        //       CFGTLP ZERO DATA
            rw[204]     <= 1'b1;                        //       CFGTLP FILTER TLP FROM USER
            rw[205]     <= 1'b1;                        //       CLK_IS_ENABLED [if clk not started _pcie_core_config[77] will remain zero].
            rw[206]     <= 1'b0;                        //       CFGTLP PCIE WRITE ENABLE
            rw[207:207] <= 0;                           //       SLACK
            // PCIe DRP, PRSNT#, PERST#
            rw[208+:16] <= 0;                           // +01A: DRP: pcie_drp_di
            rw[224+:9]  <= 0;                           // +01C: DRP: pcie_drp_addr
            rw[233+:7]  <= 0;                           //       SLACK
            // 01E -  
             
        end
    endtask
    
    wire                _cmd_timer_inactivity_enable    = rw[16];
    wire    [31:0]      _cmd_timer_inactivity_ticks     = rw[95:64];
    wire    [15:0]      _cmd_send_count_dword           = rw[63:32];
    wire                _cmd_send_count_enable          = rw[17] & (_cmd_send_count_dword != 16'h0000);
    
    always @ ( posedge clk )
         _pcie_core_config <= rw[205:128];
    assign dpcie.pcie_cfg_subsys_vend_id                = _pcie_core_config[0+:16];
    assign dpcie.pcie_cfg_subsys_id                     = _pcie_core_config[16+:16];
    assign dpcie.pcie_cfg_vend_id                       = _pcie_core_config[32+:16];
    assign dpcie.pcie_cfg_dev_id                        = _pcie_core_config[48+:16];
    assign dpcie.pcie_cfg_rev_id                        = _pcie_core_config[64+:8];
    assign dpcie.pcie_rst_core                          = _pcie_core_config[72];
    assign dpcie.pcie_rst_subsys                        = _pcie_core_config[73];
    assign dpcie.clk100_en                              = _pcie_core_config[77];
    
    assign dshadow2fifo.cfgtlp_en                       = _pcie_core_config[74];
    assign dshadow2fifo.cfgtlp_zero                     = rw[203];
    assign dshadow2fifo.cfgtlp_filter                   = _pcie_core_config[76];
    assign dshadow2fifo.cfgtlp_wren                     = rw[206];
    assign dpcie.drp_en                                 = rw[RWPOS_DRP_WR_EN] | rw[RWPOS_DRP_RD_EN];
    assign dpcie.drp_we                                 = rw[RWPOS_DRP_WR_EN];
    assign dpcie.drp_addr                               = rw[224+:9];
    assign dpcie.drp_di                                 = rw[208+:16];
    
    // ------------------------------------------------------------------------
    // COMMAND / CONTROL FIFO: STATE MACHINE / LOGIC FOR READ/WRITE AND OTHER HOUSEKEEPING TASKS
    // ------------------------------------------------------------------------
 
    wire [63:0] cmd_rx_dout;
    wire        cmd_rx_valid;
    wire        cmd_rx_rd_en_drp = rwi_drp_rd_en | rwi_drp_wr_en | rw[RWPOS_DRP_RD_EN] | rw[RWPOS_DRP_WR_EN];
    wire        cmd_rx_rd_en = tickcount64[1] & ( ~rw[RWPOS_WAIT_COMPLETE] | ~cmd_rx_rd_en_drp);
    
    fifo_64_64_clk1_fifocmd i_fifo_cmd_rx(
        .clk            ( clk                       ),
        .srst           ( rst                       ),
        .rd_en          ( cmd_rx_rd_en              ),
        .dout           ( cmd_rx_dout               ),
        .din            ( dcom.com_dout             ),
        .wr_en          ( _cmd_rx_wren              ),
        .full           (                           ),
        .empty          (                           ),
        .valid          ( cmd_rx_valid              )
    );
    
    integer i_write;
    wire [15:0] in_cmd_address_byte = cmd_rx_dout[31:16];
    wire [17:0] in_cmd_address_bit  = {in_cmd_address_byte[14:0], 3'b000};
    wire [15:0] in_cmd_value        = {cmd_rx_dout[48+:8], cmd_rx_dout[56+:8]};
    wire [15:0] in_cmd_mask         = {cmd_rx_dout[32+:8], cmd_rx_dout[40+:8]};
    wire        f_rw                = in_cmd_address_byte[15];
    wire        f_shadowcfgspace    = in_cmd_address_byte[14];
    wire [15:0] in_cmd_data_in      = (in_cmd_address_bit < (f_rw ? $bits(rw) : $bits(ro))) ? (f_rw ? rw[in_cmd_address_bit+:16] : ro[in_cmd_address_bit+:16]) : 16'h0000;
    wire        in_cmd_read         = cmd_rx_valid & cmd_rx_dout[12] & ~f_shadowcfgspace;
    wire        in_cmd_write        = cmd_rx_valid & cmd_rx_dout[13] & ~f_shadowcfgspace & f_rw;
    assign dshadow2fifo.rx_rden     = cmd_rx_valid & cmd_rx_dout[12] &  f_shadowcfgspace;
    assign dshadow2fifo.rx_wren     = cmd_rx_valid & cmd_rx_dout[13] &  f_shadowcfgspace & f_rw;
    assign dshadow2fifo.rx_be       = {(in_cmd_mask[7:0] > 0 ? ~in_cmd_address_byte[1] : 1'b0), (in_cmd_mask[15:8] > 0 ? ~in_cmd_address_byte[1] : 1'b0), (in_cmd_mask[7:0] > 0 ? in_cmd_address_byte[1] : 1'b0), (in_cmd_mask[15:8] > 0 ? in_cmd_address_byte[1] : 1'b0)};
    assign dshadow2fifo.rx_addr     = in_cmd_address_byte[11:2];
    assign dshadow2fifo.rx_addr_lo  = in_cmd_address_byte[1];
    assign dshadow2fifo.rx_data     = {in_cmd_value[7:0], in_cmd_value[15:8], in_cmd_value[7:0], in_cmd_value[15:8]};
    
    initial pcileech_fifo_ctl_initialvalues();
    
    always @ ( posedge clk )
        if ( rst )
            pcileech_fifo_ctl_initialvalues();
        else
            begin
                // SHADOW CONFIG SPACE RESPONSE
                if ( dshadow2fifo.tx_valid )
                    begin
                        _cmd_tx_wr_en       <= 1'b1;
                        _cmd_tx_din[31:16]  <= {4'b1100, dshadow2fifo.tx_addr, dshadow2fifo.tx_addr_lo, 1'b0};
                        _cmd_tx_din[15:0]   <= dshadow2fifo.tx_addr_lo ? dshadow2fifo.tx_data[15:0] : dshadow2fifo.tx_data[31:16];                        
                    end
                // READ config
                else if ( in_cmd_read )
                    begin
                        _cmd_tx_wr_en       <= 1'b1;
                        _cmd_tx_din[31:16]  <= in_cmd_address_byte;
                        _cmd_tx_din[15:0]   <= {in_cmd_data_in[7:0], in_cmd_data_in[15:8]};
                    end
                // SEND COUNT ACTION
                else if ( ~_cmd_tx_almost_full & ~in_cmd_write & _cmd_send_count_enable )
                    begin
                        _cmd_tx_wr_en       <= 1'b1;
                        _cmd_tx_din[31:16]  <= 16'hfffe;
                        _cmd_tx_din[15:0]   <= _cmd_send_count_dword;
                        rw[63:32]           <= _cmd_send_count_dword - 1;
                    end
                // INACTIVITY TIMER ACTION
                else if ( ~_cmd_tx_almost_full & ~in_cmd_write & _cmd_timer_inactivity_enable & (_cmd_timer_inactivity_ticks + _cmd_timer_inactivity_base < tickcount64) )
                    begin
                        _cmd_tx_wr_en       <= 1'b1;
                        _cmd_tx_din[31:16]  <= 16'hffff;
                        _cmd_tx_din[15:0]   <= 16'hcede;
                        rw[16]              <= 1'b0;
                    end
                else
                    _cmd_tx_wr_en <= 1'b0;

                // WRITE config
                if ( tickcount64 < 8 )
                    pcileech_fifo_ctl_initialvalues();
                else if ( in_cmd_write )
                    for ( i_write = 0; i_write < 16; i_write = i_write + 1 )
                        begin
                            if ( in_cmd_mask[i_write] )
                                rw[in_cmd_address_bit+i_write] <= in_cmd_value[i_write];
                        end

                // UPDATE INACTIVITY TIMER BASE
                if ( dcom.com_din_wr_en | ~dcom.com_din_ready )
                    _cmd_timer_inactivity_base <= tickcount64;  
                    
                // DRP READ/WRITE                        
                if ( dpcie.drp_rdy )
                    begin
                        rwi_drp_rd_en   <= 1'b0;
                        rwi_drp_wr_en   <= 1'b0;
                        rwi_drp_data    <= dpcie.drp_do;
                    end
                else if ( rw[RWPOS_DRP_RD_EN] | rw[RWPOS_DRP_WR_EN] )
                    begin
                        rw[RWPOS_DRP_RD_EN] <= 1'b0;
                        rw[RWPOS_DRP_WR_EN] <= 1'b0;
                        rwi_drp_rd_en <= rwi_drp_rd_en | rw[RWPOS_DRP_RD_EN];
                        rwi_drp_wr_en <= rwi_drp_wr_en | rw[RWPOS_DRP_WR_EN];
                    end      
            
            end

    // ----------------------------------------------------
    // GLOBAL SYSTEM RESET:  ( provided via STARTUPE2 primitive )
    // ----------------------------------------------------
`ifdef ENABLE_STARTUPE2

    STARTUPE2 #(
      .PROG_USR         ( "FALSE"           ),
      .SIM_CCLK_FREQ    ( 0.0               )
    ) i_STARTUPE2 (
      .CFGCLK           (                   ), // ->
      .CFGMCLK          (                   ), // ->
      .EOS              (                   ), // ->
      .PREQ             (                   ), // ->
      .CLK              ( clk               ), // <-
      .GSR              ( rw[RWPOS_GLOBAL_SYSTEM_RESET] ), // <- GLOBAL SYSTEM RESET
      .GTS              ( 1'b0              ), // <-
      .KEYCLEARB        ( 1'b0              ), // <-
      .PACK             ( 1'b0              ), // <-
      .USRCCLKO         ( 1'b0              ), // <-
      .USRCCLKTS        ( 1'b0              ), // <-
      .USRDONEO         ( 1'b1              ), // <-
      .USRDONETS        ( 1'b1              )  // <-
    );
`endif /* ENABLE_STARTUPE2 */

endmodule
