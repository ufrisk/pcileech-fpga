//
// PCILeech FPGA.
//
// Virtual FIFO controller. Controls the output FIFO which is backed by RAM.
//
// (c) Ulf Frisk, 2018
// Author: Ulf Frisk, pcileech@frizk.net
//

module pcileech_vfifo_ctl(
    // DDR
    output [13:0]   DDR3_addr,
    output [2:0]    DDR3_ba,
    output          DDR3_cas_n,
    output [0:0]    DDR3_ck_n,
    output [0:0]    DDR3_ck_p,
    output [0:0]    DDR3_cke,
    output [0:0]    DDR3_cs_n,
    output [7:0]    DDR3_dm,
    inout [63:0]    DDR3_dq,
    inout [7:0]     DDR3_dqs_n,
    inout [7:0]     DDR3_dqs_p,
    output [0:0]    DDR3_odt,
    output          DDR3_ras_n,
    output          DDR3_reset_n,
    output          DDR3_we_n,
    
    // CLK SYS
    input           SYS_CLK_n,
    input           SYS_CLK_p,

    // CLK (100MHz)
    input           clk,
    input           rst,
    
    // INCOMING DATA
    input [255:0]   vfifo_0_in_data,
    input           vfifo_0_in_valid,
    output          vfifo_0_in_ready,
    
    // OUTGOING DATA
    input           ft601_txe_n,
    output [31:0]   ft601_tx_dout,
    input           ft601_tx_rden,
    output          ft601_tx_valid,
    output          ft601_tx_empty
    );
    
    // -------------------------------------------------------------------------
    // Virtual FIFO below:
    // -------------------------------------------------------------------------
    wire            vfifo_clk;
    
    wire [127:0]    vfifo_out_data;
    wire            vfifo_out_valid;
    wire            vfifo_out_ready;
    wire [0:0]      vfifo_out_dest;
    
    wire [127:0]    vfifo_in_data;
    wire            vfifo_in_valid;
    wire            vfifo_in_ready;
    
    wire [1:0]      vfifo_mm2s_full;
    wire [1:0]      vfifo_s2mm_full;
    
    pcileech_vfifo i_pcileech_vfifo (
        .DDR3_0_addr        ( DDR3_addr             ),
        .DDR3_0_ba          ( DDR3_ba               ),
        .DDR3_0_cas_n       ( DDR3_cas_n            ),
        .DDR3_0_ck_n        ( DDR3_ck_n             ),
        .DDR3_0_ck_p        ( DDR3_ck_p             ),
        .DDR3_0_cke         ( DDR3_cke              ),
        .DDR3_0_dm          ( DDR3_dm               ),
        .DDR3_0_dq          ( DDR3_dq               ),
        .DDR3_0_dqs_n       ( DDR3_dqs_n            ),
        .DDR3_0_dqs_p       ( DDR3_dqs_p            ),
        .DDR3_0_odt         ( DDR3_odt              ),
        .DDR3_0_ras_n       ( DDR3_ras_n            ),
        .DDR3_0_reset_n     ( DDR3_reset_n          ),
        .DDR3_0_we_n        ( DDR3_we_n             ),
        .DDR3_0_cs_n        ( DDR3_cs_n             ),
        .SYS_CLK_0_clk_n    ( SYS_CLK_n             ),
        .SYS_CLK_0_clk_p    ( SYS_CLK_p             ),
        
        .sys_rst_0          ( rst                   ),  // <-
        .aresetn_0          ( ~rst                  ),  // <-
        .ui_clk_0           ( vfifo_clk             ),  // ->
        .vfifo_mm2s_channel_full_0( vfifo_mm2s_full ),  // <-
        .vfifo_s2mm_channel_full_0( vfifo_s2mm_full ),  // ->
        
        .M_AXIS_0_tdata     ( vfifo_out_data        ),  // ->
        .M_AXIS_0_tdest     ( vfifo_out_dest        ),  // ->
        .M_AXIS_0_tid       (                       ),  // ->
        .M_AXIS_0_tkeep     (                       ),  // ->
        .M_AXIS_0_tlast     (                       ),  // ->
        .M_AXIS_0_tready    ( vfifo_out_ready       ),  // <-
        .M_AXIS_0_tstrb     (                       ),  // ->
        .M_AXIS_0_tvalid    ( vfifo_out_valid       ),  // ->
                
        .S_AXIS_0_tdata     ( vfifo_in_data         ),  // <-
        .S_AXIS_0_tdest     ( 1'b0                  ),  // <-
        .S_AXIS_0_tid       ( 1'b0                  ),  // <-
        .S_AXIS_0_tkeep     ( 16'h0000              ),  // <-
        .S_AXIS_0_tlast     ( 1'b0                  ),  // <-
        .S_AXIS_0_tready    ( vfifo_in_ready        ),  // ->
        .S_AXIS_0_tstrb     ( 16'h0000              ),  // <-
        .S_AXIS_0_tvalid    ( vfifo_in_valid        )   // <-
    );
        
    // -------------------------------------------------------------------------
    // Outgoing regular FIFOs below:
    // -------------------------------------------------------------------------
    
    wire [31:0] vfifo_0_out_data;
    wire        vfifo_0_out_valid;
    wire        vfifo_0_out_ready;
    wire        vfifo_0_out_almost_full;
    wire        vfifo_0_out_prog_full;
    
    wire        fram_almost_full;
    wire        fram_prog_empty;
    reg         __d_ft601_txe_n;
    always @ ( posedge clk )
        __d_ft601_txe_n <= ft601_txe_n;
    // FTDI have a bug ( in chip or driver ) which doesn't terminate transfer if
    // even multiple of 1024 bytes are transmitted. Always insert five (5) MAGIC
    // DWORD (0x66665555) in beginning of stream to mitigate this.  Since normal
    // data size is always a multiple of 32-bytes/256-bits this will resolve the
    // issue. 
    wire ftdi_bug_workaround = fram_prog_empty & __d_ft601_txe_n & ~vfifo_0_out_valid;
    fifo_32x16_32 i_pcileech_out_ft601(
        .clk                ( clk                   ),
        .srst               ( rst                   ),
        
        .din                ( ftdi_bug_workaround ? 32'h66665555 : vfifo_0_out_data ),
        .wr_en              ( vfifo_0_out_valid | ftdi_bug_workaround ),
        .full               (                       ),
        .almost_full        ( fram_almost_full      ),
        
        .dout               ( ft601_tx_dout         ),
        .rd_en              ( ft601_tx_rden         ),
        .valid              ( ft601_tx_valid        ),

        .empty              ( ft601_tx_empty        ),        
        .prog_empty         ( fram_prog_empty       )
    );
    assign vfifo_0_out_ready = ~fram_almost_full;
   
    fifo_128x1024_32 i_pcileech_vfifo_0_out(
        .rd_clk             ( clk                   ),
        .wr_clk             ( vfifo_clk             ),
        .rst                ( rst                   ),
        
        .dout               ( vfifo_0_out_data      ),
        .valid              ( vfifo_0_out_valid     ),
        .empty              (                       ),
        .rd_en              ( vfifo_0_out_ready     ),
        
        .din                ( vfifo_out_data        ),
        .wr_en              ( vfifo_out_valid & (vfifo_out_dest == 1'b0) ),
        .almost_full        ( vfifo_0_out_almost_full ),
        .full               (                       ),
        .prog_full          ( vfifo_0_out_prog_full )
    );
    
    assign vfifo_out_ready = ~vfifo_0_out_almost_full;
    assign vfifo_mm2s_full[0] = vfifo_0_out_prog_full;
    assign vfifo_mm2s_full[1] = 1'b1;
    
    // -------------------------------------------------------------------------
    // Incoming regular FIFO below:
    // -------------------------------------------------------------------------
    
    // convert 256-bit data to 128-bit data in order to "save" 2BRAMs in total.
    // the 256-bit data must be guaranteed not to be sent two times in a row
    // i.e. vfifo_0_in_valid must not be asserted two cycles in a row!
    reg [127:0]     __d_vfifo_0_in_data;
    reg             __d_vfifo_0_in_valid;
    wire            vfifo_0_in256_valid = vfifo_0_in_valid | __d_vfifo_0_in_valid;
    wire [127:0]    vfifo_0_in256_data128 = vfifo_0_in_valid ? vfifo_0_in_data[255:128] : __d_vfifo_0_in_data;
    
    always @ ( posedge clk )
        begin
            __d_vfifo_0_in_data <= vfifo_0_in_data[127:0];
            __d_vfifo_0_in_valid <= vfifo_0_in_valid;
        end

    wire vfifo_0_in_prog_full;
  
    fifo_128x512_128 i_pcileech_vfifo_0_in(
        .rd_clk             ( vfifo_clk             ),
        .wr_clk             ( clk                   ),
        .rst                ( rst                   ),
        
        .dout               ( vfifo_in_data         ),
        .valid              ( vfifo_in_valid        ),
        .empty              (                       ),
        .rd_en              ( vfifo_in_ready & ~vfifo_s2mm_full[0] ),
        
        .din                ( vfifo_0_in256_data128 ),
        .wr_en              ( vfifo_0_in256_valid   ),
        .full               (                       ),
        .prog_full          ( vfifo_0_in_prog_full  )
    );
            
    assign vfifo_0_in_ready = ~vfifo_0_in_prog_full;
   
endmodule
