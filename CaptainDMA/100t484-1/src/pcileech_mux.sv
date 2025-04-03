//
// PCILeech FPGA.
//
// Merge multiple 32-bit words into a 256-bit word consisting of one (1) 32-bit
// status word and seven (7) data words. This is done to enable relatively
// efficient transmission over the FT601 together with some additional info.
//
// (c) Ulf Frisk, 2017-2024
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps

module pcileech_mux(
    input                clk,
    input                rst,
    // output
    output [255:0]       dout,
    output               valid,
    input                rd_en,
    // port0: input highest priority
    input  [31:0]        p0_din,
    input  [1:0]         p0_tag,
    input  [1:0]         p0_ctx,
    input                p0_wr_en,
    output               p0_req_data,
    // port1:
    input  [31:0]        p1_din,
    input  [1:0]         p1_tag,
    input  [1:0]         p1_ctx,
    input                p1_wr_en,
    output               p1_req_data,
    // port2:
    input  [31:0]        p2_din,
    input  [1:0]         p2_tag,
    input  [1:0]         p2_ctx,
    input                p2_wr_en,
    output               p2_req_data,
    // port3:
    input  [31:0]        p3_din,
    input  [1:0]         p3_tag,
    input  [1:0]         p3_ctx,
    input                p3_wr_en,
    output               p3_req_data,
    // port4:
    input  [31:0]        p4_din,
    input  [1:0]         p4_tag,
    input  [1:0]         p4_ctx,
    input                p4_wr_en,
    output               p4_req_data,
    // port5:
    input  [31:0]        p5_din,
    input  [1:0]         p5_tag,
    input  [1:0]         p5_ctx,
    input                p5_wr_en,
    output               p5_req_data,
    // port6:
    input  [31:0]        p6_din,
    input  [1:0]         p6_tag,
    input  [1:0]         p6_ctx,
    input                p6_wr_en,
    output               p6_req_data,
    // port7:
    input  [31:0]        p7_din,
    input  [1:0]         p7_tag,
    input  [1:0]         p7_ctx,
    input                p7_wr_en,
    output               p7_req_data
    );

    // 'en' is delayed 1CLK so it's in synch with inputs.
    //      output integrity is handled by extra register.
    reg en;
    always @ ( posedge clk )
        en <= rd_en && !rst;

    assign p0_req_data = rd_en;
    assign p1_req_data = rd_en;
    assign p2_req_data = rd_en;
    assign p3_req_data = rd_en;
    assign p4_req_data = rd_en;
    assign p5_req_data = rd_en;
    assign p6_req_data = rd_en;
    assign p7_req_data = rd_en;

    reg [31:0]  data_reg[14];
    reg [3:0]   ctx_reg[14];

    wire        p8_wr_en;
    reg [3:0]   idx_base;
    wire [3:0]  p0_idx = idx_base;
    wire [3:0]  p1_idx = p0_idx + p0_wr_en;
    wire [3:0]  p2_idx = p1_idx + p1_wr_en;
    wire [3:0]  p3_idx = p2_idx + p2_wr_en;
    wire [3:0]  p4_idx = p3_idx + p3_wr_en;
    wire [3:0]  p5_idx = p4_idx + p4_wr_en;
    wire [3:0]  p6_idx = p5_idx + p5_wr_en;
    wire [3:0]  p7_idx = p6_idx + p6_wr_en;
    wire [3:0]  p8_idx = p7_idx + p7_wr_en;     // idle port
    wire [3:0] idx_max = p8_idx + p8_wr_en;     // max index

    // P8: INTERNAL "IDLE PORT"
    reg [3:0]   idle_count;
    wire [31:0] p8_din = 32'hffffffff;
    wire [1:0]  p8_tag = 2'b11;
    wire [1:0]  p8_ctx = 2'b11;
    assign      p8_wr_en = en && (idx_base > 0) && (idle_count > 7) && (idx_base == p8_idx);
    
    
    
    // output buffer logic, when rd_en is deasserted the output data must be
    // buffered not to cause data loss.
    reg             dout_valid;
    wire [255:0]    dout_data = { ctx_reg[1], ctx_reg[0], ctx_reg[3], ctx_reg[2], ctx_reg[5], ctx_reg[4], 4'hE, ctx_reg[6], data_reg[0], data_reg[1], data_reg[2], data_reg[3], data_reg[4], data_reg[5], data_reg[6] };
    reg             dout_buf_valid;
    reg [255:0]     dout_buf_data;
    assign valid = rd_en && (dout_buf_valid || dout_valid);
    assign dout = dout_buf_valid ? dout_buf_data : dout_data;
    
    
    
    always @ ( posedge clk ) begin
        if( rst )
            begin
                idx_base <= 0;
                idle_count <= 0;
                dout_valid <= 0;
                dout_buf_valid <= 0;
            end
        else
            begin
                // OUTPUT BUFFER LOGIC:
                
                if( en ) begin
                    dout_buf_valid <= 0;
                end else if( dout_valid ) begin
                    dout_buf_data <= dout_data;
                    dout_buf_valid <= 1;
                end
            
                // OUTPUT VALID:
                dout_valid <= en && (idx_max >= 7);
                
                if( en ) begin
                    // NEXT INDEX BASE:
                    idx_base <= idx_max - ((idx_max >= 7) ? 7 : 0);
                    // IDLE COUNT:
                    idle_count <= ((idx_base > 0) && (idx_base == p8_idx)) ? (idle_count + 1) : 0;
                    // DATA/CTX writes into index [0-8]:
                    if( p0_wr_en ) begin  data_reg[p0_idx] <= p0_din;  ctx_reg[p0_idx] <= {p0_ctx, p0_tag};  end
                    if( p1_wr_en ) begin  data_reg[p1_idx] <= p1_din;  ctx_reg[p1_idx] <= {p1_ctx, p1_tag};  end
                    if( p2_wr_en ) begin  data_reg[p2_idx] <= p2_din;  ctx_reg[p2_idx] <= {p2_ctx, p2_tag};  end
                    if( p3_wr_en ) begin  data_reg[p3_idx] <= p3_din;  ctx_reg[p3_idx] <= {p3_ctx, p3_tag};  end
                    if( p4_wr_en ) begin  data_reg[p4_idx] <= p4_din;  ctx_reg[p4_idx] <= {p4_ctx, p4_tag};  end
                    if( p5_wr_en ) begin  data_reg[p5_idx] <= p5_din;  ctx_reg[p5_idx] <= {p5_ctx, p5_tag};  end
                    if( p6_wr_en ) begin  data_reg[p6_idx] <= p6_din;  ctx_reg[p6_idx] <= {p6_ctx, p6_tag};  end
                    if( p7_wr_en ) begin  data_reg[p7_idx] <= p7_din;  ctx_reg[p7_idx] <= {p7_ctx, p7_tag};  end
                    if( p8_wr_en ) begin  data_reg[p8_idx] <= p8_din;  ctx_reg[p8_idx] <= {p8_ctx, p8_tag};  end
                end
                
                if( dout_valid ) begin
                    // DATA/CTX previous move:
                    if( idx_base > 0) begin  data_reg[0] <= data_reg[7+0];  ctx_reg[0] <= ctx_reg[7+0];  end
                    if( idx_base > 1) begin  data_reg[1] <= data_reg[7+1];  ctx_reg[1] <= ctx_reg[7+1];  end
                    if( idx_base > 2) begin  data_reg[2] <= data_reg[7+2];  ctx_reg[2] <= ctx_reg[7+2];  end
                    if( idx_base > 3) begin  data_reg[3] <= data_reg[7+3];  ctx_reg[3] <= ctx_reg[7+3];  end
                    if( idx_base > 4) begin  data_reg[4] <= data_reg[7+4];  ctx_reg[4] <= ctx_reg[7+4];  end
                    if( idx_base > 5) begin  data_reg[5] <= data_reg[7+5];  ctx_reg[5] <= ctx_reg[7+5];  end
                    if( idx_base > 6) begin  data_reg[6] <= data_reg[7+6];  ctx_reg[6] <= ctx_reg[7+6];  end
                end
                

            end
    end
endmodule
