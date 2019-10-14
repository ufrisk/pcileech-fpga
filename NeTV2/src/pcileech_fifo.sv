//
// PCILeech FPGA.
//
// FIFO network / control.
//
// (c) Ulf Frisk, 2017-2019
// Author: Ulf Frisk, pcileech@frizk.net
// Special thanks to: Dmytro Oleksiuk @d_olex
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_fifo #(
    parameter               PARAM_DEVICE_ID = 0,
    parameter               PARAM_VERSION_NUMBER_MAJOR = 0,
    parameter               PARAM_VERSION_NUMBER_MINOR = 0
) (
    input                   clk,
    input                   rst,
    
    input   [31:0]          ft601_rx_data,
    input                   ft601_rx_wren,
    
    output  [255:0]         ft601_tx_data,
    output                  ft601_tx_valid,
    input                   ft601_tx_rd_en,
    
    IfPCIeCfgFifo.mp_fifo   dcfg,
    IfPCIeTlpFifo.mp_fifo   dtlp
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
   //                        /--> PCIe TLP (32-bit)
   //                        |
   // FT601 -->(32->64) -->--+--> PCIe CFG (64-bit)
   //                        |
   //                        +--> LOOPBACK (32-bit)
   //                        |
   //                        \--> COMMAND  (64-bit)
   //

   // ----------------------------------------------------------
   // Convert 32-bit incoming FT601 data to 64-bit below:
   // ----------------------------------------------------------
    reg [63:0]  ft601_rx_data64;
    reg [1:0]   ft601_rx_valid64_dw;
    wire        ft601_rx_valid64 = ft601_rx_valid64_dw[0] & ft601_rx_valid64_dw[1];
   
    always @ ( posedge clk )
        if ( rst | (~ft601_rx_wren & ft601_rx_valid64_dw[0] & ft601_rx_valid64_dw[1]) )
            ft601_rx_valid64_dw <= 2'b00;
        else if ( ft601_rx_wren )
            begin
                ft601_rx_data64 <= (ft601_rx_data64 << 32) | ft601_rx_data;
                ft601_rx_valid64_dw <= (ft601_rx_valid64_dw == 2'b01) ? 2'b11 : 2'b01;
            end
            
    // ----------------------------------------------------------
    // Route 64-bit incoming FT601 data to correct receiver below:
    // ----------------------------------------------------------
    `define CHECK_MAGIC     (ft601_rx_data64[7:0] == 8'h77)
    `define CHECK_TYPE_TLP  (ft601_rx_data64[9:8] == 2'b00)
    `define CHECK_TYPE_CFG  (ft601_rx_data64[9:8] == 2'b01)
    `define CHECK_TYPE_LOOP (ft601_rx_data64[9:8] == 2'b10)
    `define CHECK_TYPE_CMD  (ft601_rx_data64[9:8] == 2'b11)
    
    wire     _loop_rx_wren;
    wire     _cmd_rx_wren;
    assign   dtlp.tx_valid = ft601_rx_valid64 & `CHECK_MAGIC & `CHECK_TYPE_TLP;
    assign   dcfg.tx_valid = ft601_rx_valid64 & `CHECK_MAGIC & `CHECK_TYPE_CFG;
    assign   _loop_rx_wren = ft601_rx_valid64 & `CHECK_MAGIC & `CHECK_TYPE_LOOP;
    assign   _cmd_rx_wren  = ft601_rx_valid64 & `CHECK_MAGIC & `CHECK_TYPE_CMD;
    
    // Incoming TLPs are forwarded to PCIe core logic.
    assign dtlp.tx_data = ft601_rx_data64[63:32];
    assign dtlp.tx_last = ft601_rx_data64[10];
    // Incoming CFGs are forwarded to PCIe core logic.
    assign dcfg.tx_data = ft601_rx_data64;

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
        .din            ( {ft601_rx_data64[11:10], ft601_rx_data64[63:32]} ),
        .wr_en          ( _loop_rx_wren             ),
        .full           (                           ),
        .almost_full    (                           ),
        .empty          ( _loop_empty               ),
        .valid          ( _loop_valid               )
    );
   
    // ----------------------------------------------------------
    // COMMAND FIFO:
    // ----------------------------------------------------------
    wire [33:0]       _cmd_dout;
    wire              _cmd_valid;
    wire              _cmd_empty;
    wire              _cmd_rd_en;
    wire              _cmd_almost_full;
    reg               _cmd_wr_en;
    reg [33:0]        _cmd_din;
    fifo_34_34 i_fifo_cmd_tx(
        .clk            ( clk                       ),
        .srst           ( rst                       ),
        .rd_en          ( _cmd_rd_en                ),
        .dout           ( _cmd_dout                 ),
        .din            ( _cmd_din                  ),
        .wr_en          ( _cmd_wr_en                ),
        .full           (                           ),
        .almost_full    ( _cmd_almost_full          ),
        .empty          ( _cmd_empty                ),
        .valid          ( _cmd_valid                )
    );

    // ----------------------------------------------------------
    // MULTIPLEXER
    // ----------------------------------------------------------
    pcileech_mux i_pcileech_mux(
        .clk            ( clk                       ),
        .rst            ( rst                       ),
        // output
        .dout           ( ft601_tx_data             ),
        .valid          ( ft601_tx_valid            ),
        .rd_en          ( ft601_tx_rd_en            ),
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
        .p3_din         ( _cmd_dout[31:0]           ),
        .p3_ctx         ( _cmd_dout[33:32]          ),
        .p3_wr_en       ( _cmd_valid                ),
        .p3_has_data    ( ~_cmd_empty               ),
        .p3_req_data    ( _cmd_rd_en                )
    );
   
    // ------------------------------------------------------------------------
    // COMMAND / CONTROL FIFO: REGISTER FILE: COMMON
    // ------------------------------------------------------------------------
    
    wire    [255:0]     ro;
    reg     [127:0]     rw;
    
    // special non-user accessible registers 
    time                _cmd_timer_inactivity_base;
    
    // ------------------------------------------------------------------------
    // COMMAND / CONTROL FIFO: REGISTER FILE: READ-ONLY LAYOUT/SPECIFICATION
    // ------------------------------------------------------------------------
    
    // MAGIC
    assign ro[15:0]     = 16'hab89;                     // +000: MAGIC
    // SPECIAL
    assign ro[31:16]    = 0;                            // +002: SPECIAL
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
    // 0020 - 
    
    // ------------------------------------------------------------------------
    // INITIALIZATION/RESET BLOCK _AND_
    // COMMAND / CONTROL FIFO: REGISTER FILE: READ-WRITE LAYOUT/SPECIFICATION
    // ------------------------------------------------------------------------
    
    task pcileech_fifo_ctl_initialvalues;               // task is non automatic
        begin
            _cmd_wr_en  <= 1'b0;
               
            // MAGIC
            rw[15:0]    <= 16'hefcd;                    // +000: MAGIC
            // SPECIAL
            rw[16]      <= 0;                           // +002: enable inactivity timer
            rw[17]      <= 0;                           //       enable send count
            rw[31:18]   <= 0;                           //       RESERVED FUTURE
            // SIZEOF / BYTECOUNT [little-endian]
            rw[63:32]   <= $bits(rw) >> 3;              // +004: bytecount [little endian]
            // CMD INACTIVITY TIMER TRIGGER VALUE
            rw[95:64]   <= 0;                           // +008: cmd_inactivity_timer (ticks) [little-endian]
            // CMD SEND COUNT
            rw[127:96]   <= 0;                          // +00C: cmd_send_count [little-endian]
            // 0010 - 
        end
    endtask
    
    wire                _cmd_timer_inactivity_enable    = rw[16];
    wire    [31:0]      _cmd_timer_inactivity_ticks     = rw[95:64];
    wire    [15:0]      _cmd_send_count_dword           = rw[63:32];
    wire                _cmd_send_count_enable          = rw[17] & (_cmd_send_count_dword != 16'h0000);
    
    // ------------------------------------------------------------------------
    // COMMAND / CONTROL FIFO: STATE MACHINE / LOGIC FOR READ/WRITE AND OTHER HOUSEKEEPING TASKS
    // ------------------------------------------------------------------------
    
    integer i_write;
    wire [15:0] in_cmd_address_byte = ft601_rx_data64[31:16];
    wire [17:0] in_cmd_address_bit  = {in_cmd_address_byte[14:0], 3'b000};
    wire [15:0] in_cmd_value        = {ft601_rx_data64[48+:8], ft601_rx_data64[56+:8]};
    wire [15:0] in_cmd_mask         = {ft601_rx_data64[32+:8], ft601_rx_data64[40+:8]};
    wire        f_rw                = in_cmd_address_byte[15]; 
    wire [15:0] in_cmd_data_in      = (in_cmd_address_bit < (f_rw ? $bits(rw) : $bits(ro))) ? (f_rw ? rw[in_cmd_address_bit+:16] : ro[in_cmd_address_bit+:16]) : 16'h0000;
    wire        in_cmd_read         = ft601_rx_data64[12] & _cmd_rx_wren;
    wire        in_cmd_write        = ft601_rx_data64[13] & in_cmd_address_byte[15] & _cmd_rx_wren;
    
    initial pcileech_fifo_ctl_initialvalues();
    
    always @ ( posedge clk )
        if ( rst )
            pcileech_fifo_ctl_initialvalues();
        else
            begin
                // READ config
                if ( in_cmd_read )
                    begin
                        _cmd_wr_en      <= 1'b1;
                        _cmd_din[31:16] <= in_cmd_address_byte;
                        _cmd_din[15:0]  <= {in_cmd_data_in[7:0], in_cmd_data_in[15:8]};
                    end
                // SEND COUNT ACTION
                else if ( ~_cmd_almost_full & ~in_cmd_write & _cmd_send_count_enable )
                    begin
                        _cmd_wr_en      <= 1'b1;
                        _cmd_din[31:16] <= 16'hfffe;
                        _cmd_din[15:0]  <= _cmd_send_count_dword;
                        rw[63:32]       <= _cmd_send_count_dword - 1;
                    end
                // INACTIVITY TIMER ACTION
                else if ( ~_cmd_almost_full & ~in_cmd_write & _cmd_timer_inactivity_enable & (_cmd_timer_inactivity_ticks + _cmd_timer_inactivity_base < tickcount64) )
                    begin
                        _cmd_wr_en      <= 1'b1;
                        _cmd_din[31:16] <= 16'hffff;
                        _cmd_din[15:0]  <= 16'hcede;
                        rw[16]          <= 1'b0;
                    end
                else
                    _cmd_wr_en <= 1'b0;

                // WRITE config
                if ( tickcount64 < 10 )
                    pcileech_fifo_ctl_initialvalues();
                else if ( in_cmd_write )
                    for ( i_write = 0; i_write < 16; i_write = i_write + 1 )
                        begin
                            if ( in_cmd_mask[i_write] )
                                rw[in_cmd_address_bit+i_write] <= in_cmd_value[i_write];
                        end

                // UPDATE INACTIVITY TIMER BASE
                if ( ft601_tx_valid | ~ft601_tx_rd_en )
                    _cmd_timer_inactivity_base <= tickcount64;        
            
            end

endmodule
