//
// PCILeech FPGA.
//
// Merge multiple 32-bit words into a 256-bit word consisting of one (1) 32-bit
// status word and seven (7) data words. This is done to enable relatively
// efficient transmission over the FT601 together with some additional info.
//
// The port with the lowest number will always be prioritized if it has data.
//
// (c) Ulf Frisk, 2017-2020
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps

module pcileech_mux(
   input                clk,
   input                rst,
   // output
   output reg [255:0]   dout,
   output reg           valid = 0,
   input                rd_en,          // inverse of almost_full in receiver FIFO
   // port0: input highest priority
   input  [31:0]        p0_din,
   input  [1:0]         p0_ctx,
   input                p0_wr_en,
   input                p0_has_data,
   output reg           p0_req_data = 0,
   // port1:
   input  [31:0]        p1_din,
   input  [1:0]         p1_ctx,
   input                p1_wr_en,
   input                p1_has_data,
   output reg           p1_req_data = 0,
   // port2:
   input  [31:0]        p2_din,
   input  [1:0]         p2_ctx,
   input                p2_wr_en,
   input                p2_has_data,
   output reg           p2_req_data = 0,
   // port3:
   input  [31:0]        p3_din,
   input  [1:0]         p3_ctx,
   input                p3_wr_en,
   input                p3_has_data,
   output reg           p3_req_data = 0
   );
   
   reg                  mux_valid = 0;
   reg [2:0]            mux_count = 0;
   reg [223:0]          mux_data = 0;
   reg [27:0]           mux_status = 32'hffffffff;
   reg [3:0]            mux_skip_counter = 0;
   `define              MUX_WR   (p0_wr_en || p1_wr_en || p2_wr_en || p3_wr_en || (mux_skip_counter > 7))
   
   always @ ( posedge clk )
      if( rst )
         begin
            valid <= 0;
            mux_count <= 0;
            mux_valid <= 0;
            p0_req_data <= 0;
            p1_req_data <= 0;
            p2_req_data <= 0;
            p3_req_data <= 0;
            mux_skip_counter <= 0;
         end
      else
         begin
            // request data
            p0_req_data <= rd_en & p0_has_data;
            p1_req_data <= rd_en & p1_has_data & ~p0_has_data;
            p2_req_data <= rd_en & p2_has_data & ~p1_has_data & ~p0_has_data;
            p3_req_data <= rd_en & p3_has_data & ~p2_has_data & ~p1_has_data & ~p0_has_data;
            // count
            if( `MUX_WR && (mux_count < 6) )
               begin
                  mux_valid <= 0;
                  mux_count <= mux_count + 1;
               end
            else if( `MUX_WR && (mux_count == 6) )
               begin
                  mux_valid <= 1;
                  mux_count <= 0;
                  mux_skip_counter <= 0;
               end
            else if ( mux_count > 0 )
               begin
                  mux_valid <= 0;
                  mux_skip_counter <= mux_skip_counter + 1;
               end
            else
               begin
                  mux_valid <= 0;
               end               
            // valid & transmit to output
            dout[223:0] <= mux_data;
            dout[227:224] <= mux_status[3:0];
            dout[231:228] <= 4'hE;
            dout[235:232] <= mux_status[11:8];
            dout[239:236] <= mux_status[7:4];
            dout[243:240] <= mux_status[19:16];
            dout[247:244] <= mux_status[15:12];
            dout[251:248] <= mux_status[27:24];
            dout[255:252] <= mux_status[23:20];
            valid <= mux_valid;
            // data & status
            if( p0_wr_en )
               begin
                  mux_status <= (mux_status << 4) | (p0_ctx << 2) | 2'b00;
                  mux_data <= (mux_data << 32) | p0_din;
               end
            if( p1_wr_en & ~p0_wr_en )
               begin
                  mux_status <= (mux_status << 4) | (p1_ctx << 2) | 2'b01;
                  mux_data <= (mux_data << 32) | p1_din;
               end
            if( p2_wr_en & ~p1_wr_en & ~p0_wr_en )
               begin
                  mux_status <= (mux_status << 4) | (p2_ctx << 2) | 2'b10;
                  mux_data <= (mux_data << 32) | p2_din;
               end
            if( p3_wr_en & ~p2_wr_en & ~p1_wr_en & ~p0_wr_en )
               begin
                  mux_status <= (mux_status << 4) | (p3_ctx << 2) | 2'b11;
                  mux_data <= (mux_data << 32) | p3_din;
               end
            if( ~p3_wr_en & ~p2_wr_en & ~p1_wr_en & ~p0_wr_en & (mux_skip_counter > 7) )
               begin
                  mux_status <= (mux_status << 4) | 4'b1111;
                  mux_data <= (mux_data << 32) | 32'hffffffff;
               end
         end
endmodule
