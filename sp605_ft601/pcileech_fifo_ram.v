//
// RAM FIFO
// 
// RAM FIFO acts as a native FIFO but is backed by the on-board DDR3 DRAM on
// the SP605 board. Data is inputted at a width of 256-bit and is outputted at
// a 32-bit width. The internal width used when transmitting to/from the DDR3
// DRAM is 128-bits.
//
// Author: Ulf Frisk, pcileech@frizk.net
//

// MIT License
//
// Copyright (c) 2017 Ulf Frisk
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/*
   REQUIRED CHANGES FOR THE SP605
   IN MIG.v:
      localparam C3_CLKOUT0_DIVIDE       = 1;  // MCB 667 MHz clock 0 phase shift     
      localparam C3_CLKOUT1_DIVIDE       = 1;  // MCB 667 MHz clock 180 phase shift     
      localparam C3_CLKOUT2_DIVIDE       = 8;  // Traffic generator
      localparam C3_CLKOUT3_DIVIDE       = 8;  // Soft calibration clock
      localparam C3_CLKFBOUT_MULT        = 10; // MMCM VCO operating at 667MHz = (200*10)/3
      localparam C3_DIVCLK_DIVIDE        = 3;  // SP605 MMCM VCO at 667 MHz
*/

module pcileech_fifo_ram(
   // TO/FROM SYSTEM MEMORY CONTROLLER
   inout  [15:0]     mcb3_dram_dq,
   output [12:0]     mcb3_dram_a,
   output [2:0]      mcb3_dram_ba,
   output            mcb3_dram_ras_n,
   output            mcb3_dram_cas_n,
   output            mcb3_dram_we_n,
   output            mcb3_dram_odt,
   output            mcb3_dram_reset_n,
   output            mcb3_dram_cke,
   output            mcb3_dram_dm,
   inout             mcb3_dram_udqs,
   inout             mcb3_dram_udqs_n,
   inout             mcb3_rzq,
   inout             mcb3_zio,
   output            mcb3_dram_udm,
   input             c3_sys_clk_p,
   input             c3_sys_clk_n,
   input             c3_sys_rst_i,
   output            c3_calib_done,
   output            c3_clk0,
   output            c3_rst0,
   inout             mcb3_dram_dqs,
   inout             mcb3_dram_dqs_n,
   output            mcb3_dram_ck,
   output            mcb3_dram_ck_n,
   // FIFO public interface
   input             clk,
   input             rst,
   input  [255:0]    din,
   input             wr_en,
   input             rd_en,
   output [31:0]     dout,
   output            full,
   output            almost_full,
   output            empty,
   output            valid
);

   // FIFO for incoming data. Transforms incoming 256-bit data to 128-bit data
   // width used when transmitting data to/from the on-board DDR3 DRAM
   wire [127:0]      fifo_in_dout;
   wire              fifo_in_rd_en;
   wire              fifo_in_empty;
   wire              fifo_in_valid;
   fifo_256_128_mig i_fifo_in(
      .rd_clk     (  clk                     ),
      .wr_clk     (  clk                     ),
      .rst        (  rst                     ),
      .din        (  din                     ),
      .wr_en      (  wr_en                   ),
      .rd_en      (  fifo_in_rd_en           ),
      .dout       (  fifo_in_dout            ),
      .full       (  full                    ),
      .almost_full(  almost_full             ),
      .empty      (  fifo_in_empty           ),
      .valid      (  fifo_in_valid           )
   );

   // FIFO for outgoing data. Receives 128-bit data from the on-board DDR3 DRAM
   // and transforms it to 32-bit data - which is outputted to the FT601.
   wire [127:0]      fifo_out_din;
   wire              fifo_out_wr_en;
   wire              fifo_out_prog_full;
   fifo_128_32_mig i_fifo_out(
      .rd_clk     (  clk                     ),
      .wr_clk     (  clk                     ),
      .rst        (  rst                     ),
      .din        (  fifo_out_din            ),
      .wr_en      (  fifo_out_wr_en          ),
      .rd_en      (  rd_en                   ),
      .dout       (  dout                    ),
      .full       (                          ),
      .prog_full  (  fifo_out_prog_full      ),
      .empty      (  empty                   ),
      .valid      (  valid                   )
   );
   
   // RAM CMD
   `define CMD_READ     3'b001;
   `define CMD_WRITE    3'b000;
   reg            ram_cmd_en = 0;         // <-
   reg [2:0]      ram_cmd_instr;          // <-
   reg [5:0]      ram_cmd_bl;             // <-
   reg [29:0]     ram_cmd_byte_addr;      // <-
   wire           ram_cmd_empty;          // ->
   // RAM RD
   wire           ram_rd_en;              // <-
   wire           ram_rd_empty;           // ->
   wire [127:0]   ram_rd_data;            // ->
   // RAM WR
   wire [6:0]     ram_wr_count;           // ->
   reg            ram_wr_en;              // <-
   reg  [127:0]   ram_wr_data;            // <-

   // RAM RD --> FIFO OUT
   assign fifo_out_wr_en   = ram_rd_en;
   assign fifo_out_din     = ram_rd_data;
   assign ram_rd_en        = ~fifo_out_prog_full & ~ram_rd_empty;
  
   // FIFO IN --> RAM WR
   reg  [63:0]    wc_ram_wr_rd = 0; // word count - ram write fifo (output)
   reg  [63:0]    wc_ram_wr_wr = 0; // word count - ram write fifo (input)
   wire [63:0]    wc_ram_wr_diff = wc_ram_wr_wr - wc_ram_wr_rd;
   assign fifo_in_rd_en = (ram_wr_count < 7'h30) & ~fifo_in_empty;
   always @ ( posedge clk )
      begin
         wc_ram_wr_wr <= wc_ram_wr_wr + (ram_wr_en ? 1 : 0);
         ram_wr_data <= fifo_in_dout;
         ram_wr_en <= fifo_in_valid;
      end

   //
   // STATE MACHINE MEMORY ACCESSES
   //
   `define min(a,b) ((a < b) ? a : b)
   reg [25:0]  ram_write_addr = 0;
   reg [25:0]  ram_read_addr = 0;
   time        cooldown_rd = 0;
   time        cooldown_wr = 0;
   time        master_counter = 0;
   always @ ( posedge clk )
      begin
         master_counter <= master_counter + 1;
         if ( rst )
            begin
               cooldown_rd <= 0;
               cooldown_wr <= 0;
               ram_write_addr <= 0;
               ram_read_addr <= 0;
               master_counter <= 0;
            end
         else if ( ram_cmd_empty && (cooldown_rd < master_counter) && ram_rd_empty && ~fifo_out_prog_full && (ram_read_addr < ram_write_addr) )   // READ (RAM --> RD_FIFO)
            begin
               cooldown_rd <= master_counter + 64;
               ram_cmd_en <= 1'b1;
               ram_cmd_instr <= `CMD_READ;
               ram_cmd_byte_addr <= (ram_read_addr << 4); // 128-bit/16-byte words -> lower 4 addr bits = 0
               ram_cmd_bl <= `min(26'h40, ram_write_addr - ram_read_addr) - 26'h01;
               ram_read_addr <= ram_read_addr + `min(26'h40, ram_write_addr - ram_read_addr);
            end
         else if ( ram_cmd_empty && (cooldown_wr < master_counter) && (wc_ram_wr_diff > 0) )  // WRITE (WR_FIFO --> RAM)
            begin
               cooldown_wr <= master_counter + 32;
               ram_cmd_en <= 1'b1;
               ram_cmd_instr <= `CMD_WRITE;
               ram_cmd_byte_addr <= (ram_write_addr << 4); // 128-bit/16-byte words -> lower 4 addr bits = 0
               ram_cmd_bl <= `min(64'h40, wc_ram_wr_diff) - 7'h01;
               ram_write_addr <= ram_write_addr + `min(64'h40, wc_ram_wr_diff);
               wc_ram_wr_rd <= wc_ram_wr_rd + wc_ram_wr_diff;
            end         
         else  // IDLE    
            begin
               ram_cmd_en <= 1'b0;
               if( ram_write_addr == ram_read_addr )
                  begin
                     ram_read_addr <= 0;
                     ram_write_addr <= 0;
                  end
            end
      end
   //
   // The actual MIG - DDR3 DRAM backed FIFO.
   //
   mig i_mig(
      // TO/FROM SYSTEM MEMORY CONTROLLER
      .mcb3_dram_dq           ( mcb3_dram_dq       ),
      .mcb3_dram_a            ( mcb3_dram_a        ),
      .mcb3_dram_ba           ( mcb3_dram_ba       ),
      .mcb3_dram_ras_n        ( mcb3_dram_ras_n    ),
      .mcb3_dram_cas_n        ( mcb3_dram_cas_n    ),
      .mcb3_dram_we_n         ( mcb3_dram_we_n     ),
      .mcb3_dram_odt          ( mcb3_dram_odt      ),
      .mcb3_dram_reset_n      ( mcb3_dram_reset_n  ),
      .mcb3_dram_cke          ( mcb3_dram_cke      ),
      .mcb3_dram_dm           ( mcb3_dram_dm       ),
      .mcb3_dram_udqs         ( mcb3_dram_udqs     ),
      .mcb3_dram_udqs_n       ( mcb3_dram_udqs_n   ),
      .mcb3_rzq               ( mcb3_rzq           ),
      .mcb3_zio               ( mcb3_zio           ),
      .mcb3_dram_udm          ( mcb3_dram_udm      ),
      .c3_sys_clk_p           ( c3_sys_clk_p       ),
      .c3_sys_clk_n           ( c3_sys_clk_n       ),
      .c3_sys_rst_i           ( c3_sys_rst_i       ),
      .c3_calib_done          ( c3_calib_done      ),
      .c3_clk0                ( c3_clk0            ),
      .c3_rst0                ( c3_rst0            ),
      .mcb3_dram_dqs          ( mcb3_dram_dqs      ),
      .mcb3_dram_dqs_n        ( mcb3_dram_dqs_n    ),
      .mcb3_dram_ck           ( mcb3_dram_ck       ),
      .mcb3_dram_ck_n         ( mcb3_dram_ck_n     ),
      // RAM CONTROL
      .c3_p0_cmd_clk          ( clk                ), // <-
      .c3_p0_cmd_en           ( ram_cmd_en         ), // <-
      .c3_p0_cmd_instr        ( ram_cmd_instr      ), // <- [2:0]
      .c3_p0_cmd_bl           ( ram_cmd_bl         ), // <- [5:0]
      .c3_p0_cmd_byte_addr    ( ram_cmd_byte_addr  ), // <- [29:0]
      .c3_p0_cmd_empty        ( ram_cmd_empty      ), // ->
      .c3_p0_cmd_full         (                    ), // ->
      // RAM FIFO IN
      .c3_p0_wr_clk           ( clk                ), // <-
      .c3_p0_wr_en            ( ram_wr_en          ), // <-
      .c3_p0_wr_mask          ( 16'h0000           ), // <- [15:0]
      .c3_p0_wr_data          ( ram_wr_data        ), // <- [127:0]
      .c3_p0_wr_full          (                    ), // ->
      .c3_p0_wr_empty         (                    ), // ->
      .c3_p0_wr_count         ( ram_wr_count       ), // -> [6:0]
      .c3_p0_wr_underrun      (                    ), // ->
      .c3_p0_wr_error         (                    ), // ->
      // FIFO OUT
      .c3_p0_rd_clk           ( clk                ), // <-
      .c3_p0_rd_en            ( ram_rd_en          ), // <-
      .c3_p0_rd_data          ( ram_rd_data        ), // -> [127:0]
      .c3_p0_rd_full          (                    ), // ->
      .c3_p0_rd_empty         ( ram_rd_empty       ), // ->
      .c3_p0_rd_count         (                    ), // -> [6:0]
      .c3_p0_rd_overflow      (                    ), // ->
      .c3_p0_rd_error         (                    )  // ->
   );

endmodule
