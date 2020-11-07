//
// PCILeech FPGA.
//
// FT601 / FT245 controller module (v3).
//
// (c) Ulf Frisk, 2017-2020
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps

module pcileech_ft601(
    input               clk,
    input               rst,
    // TO/FROM PADS
    inout [31:0]        FT601_DATA,
    output [3:0]        FT601_BE,
    input               FT601_RXF_N,
    input               FT601_TXE_N,
    output reg          FT601_WR_N      = 1'b1,
    output reg          FT601_SIWU_N    = 1'b1,
    output reg          FT601_RD_N      = 1'b1,
    output reg          FT601_OE_N      = 1'b1,
    // TO/FROM FIFO
    output reg [31:0]   dout,
    output reg          dout_valid      = 1'b0,
    input [31:0]        din,
    input               din_empty,
    input               din_wr_en,
    output              din_req_data
    );

    // set ft601 output data
    reg [31:0] txo_dout;
    reg oe              = 1'b0;
    assign FT601_DATA   = oe ? {txo_dout[7:0], txo_dout[15:8], txo_dout[23:16], txo_dout[31:24]} : 32'hzzzzzzzz; // including byte-swap (endianess)
    assign FT601_BE     = oe ? 4'b1111 : 4'bzzzz;
   
    always @ ( posedge clk )
        begin
            // endianess convert incoming/rx data
            dout[7:0]       <= FT601_DATA[31:24];
            dout[15:8]      <= FT601_DATA[23:16];
            dout[23:16]     <= FT601_DATA[15:8];
            dout[31:24]     <= FT601_DATA[7:0];
        end

    // -------------------------------------------------------------------------
    // Main FT245 control below:
    // -------------------------------------------------------------------------
    
    `define S_FT601_IDLE         4'h0
    `define S_FT601_RX_WAIT0     4'h1
    `define S_FT601_RX_WAIT1     4'h2
    `define S_FT601_RX_WAIT2     4'h3
    `define S_FT601_RX_WAIT3     4'h4
    `define S_FT601_RX_ACTIVE    4'h5
    `define S_FT601_RX_COOLDOWN1 4'h6
    `define S_FT601_RX_COOLDOWN2 4'h7
    `define S_FT601_TX_WAIT1     4'h8
    `define S_FT601_TX_WAIT2     4'h9
    `define S_FT601_TX_ACTIVE    4'ha
    `define S_FT601_TX_COOLDOWN1 4'hb
    `define S_FT601_TX_COOLDOWN2 4'hc
    
    reg [3:0]           state = `S_FT601_IDLE;
    
    reg [1:0]           retx_valid      = 2'b00;
    reg [63:0]          retx_data;
    reg [1:0]           retx_valid_pre  = 2'b00;
    reg [63:0]          retx_data_pre;
    (* KEEP = "TRUE" *) reg txo_wr_n    = 1'b1;
    
    assign din_req_data = ~din_empty & ~FT601_TXE_N & ~retx_valid[1] & ((state == `S_FT601_TX_WAIT2) | (state == `S_FT601_TX_ACTIVE));
    
    always @ ( posedge clk )
        begin
            dout_valid  <= ~rst & ~FT601_RXF_N & ((state == `S_FT601_RX_ACTIVE));
            FT601_OE_N  <=  rst |  FT601_RXF_N | ((state != `S_FT601_RX_WAIT2) && (state != `S_FT601_RX_WAIT3) && (state != `S_FT601_RX_ACTIVE));
            FT601_RD_N  <=  rst |  FT601_RXF_N | ((state != `S_FT601_RX_WAIT3) && (state != `S_FT601_RX_ACTIVE));
            FT601_WR_N  <=  rst |  FT601_TXE_N | (state != `S_FT601_TX_ACTIVE) | ~(retx_valid[0] | din_wr_en);
            txo_wr_n    <=  rst |  FT601_TXE_N | (state != `S_FT601_TX_ACTIVE) | ~(retx_valid[0] | din_wr_en);
        end
    
    always @ ( posedge clk )
        if ( rst )
            begin
                oe <= 0;
                retx_valid <= 2'b00;
                retx_valid_pre <= 2'b00;
                state <= `S_FT601_IDLE;
            end
        else case ( state )
            // ----------------------------------------------------------------
            // IDLE STATE:
            // RX are prioritized above TX in case both options are available. 
            // ----------------------------------------------------------------
            `S_FT601_IDLE:
                if ( ~FT601_RXF_N )
                    state <= `S_FT601_RX_WAIT0;
                else if ( ~FT601_TXE_N & (retx_valid_pre[0] | ~din_empty) )
                    state <= `S_FT601_TX_WAIT1;
            // ----------------------------------------------------------------
            // RX DATA FROM THE FT601:
            // The receiver FIFO is assumed to always be non-full.
            // If receiver FIFO is full data will still be received but lost.
            // ----------------------------------------------------------------
            `S_FT601_RX_WAIT0:
                state <= FT601_RXF_N ? `S_FT601_RX_COOLDOWN1 : `S_FT601_RX_WAIT1;
            `S_FT601_RX_WAIT1:
                state <= FT601_RXF_N ? `S_FT601_RX_COOLDOWN1 : `S_FT601_RX_WAIT2;
            `S_FT601_RX_WAIT2:
                state <= FT601_RXF_N ? `S_FT601_RX_COOLDOWN1 : `S_FT601_RX_WAIT3;
            `S_FT601_RX_WAIT3:
                state <= FT601_RXF_N ? `S_FT601_RX_COOLDOWN1 : `S_FT601_RX_ACTIVE;
            `S_FT601_RX_ACTIVE:
                state <= FT601_RXF_N ? `S_FT601_RX_COOLDOWN1 : `S_FT601_RX_ACTIVE;
            `S_FT601_RX_COOLDOWN1:
                state <= `S_FT601_RX_COOLDOWN2;
            `S_FT601_RX_COOLDOWN2:
                state <= `S_FT601_IDLE;
            // ----------------------------------------------------------------
            // TX DATA TO THE FT601:
            // ----------------------------------------------------------------
            `S_FT601_TX_WAIT1:
                begin
                    retx_data       <= retx_data_pre;
                    retx_valid      <= retx_valid_pre;
                    retx_valid_pre  <= 2'b00;
                    state           <= `S_FT601_TX_WAIT2;
                end
            `S_FT601_TX_WAIT2:
                begin
                    oe              <= 1'b1;
                    state           <= `S_FT601_TX_ACTIVE;
                end
            `S_FT601_TX_ACTIVE:
                begin
                    retx_data       <= retx_data >> 32;
                    retx_valid      <= retx_valid >> 1;
                    txo_dout        <= retx_valid[0] ? retx_data[31:0] : din;
                    if ( ~FT601_TXE_N & (retx_valid[0] | din_wr_en) )
                        begin
                            state                <= `S_FT601_TX_ACTIVE;
                        end
                    else
                        begin
                            retx_valid_pre[0]    <= ~txo_wr_n & FT601_TXE_N;
                            retx_valid_pre[1]    <= retx_valid[0] | din_wr_en;
                            retx_data_pre[31:0]  <= txo_dout;
                            retx_data_pre[63:32] <= retx_valid[0] ? retx_data[31:0] : din;
                            oe                   <= 0;
                            state                <= `S_FT601_TX_COOLDOWN1;
                        end
                end
            `S_FT601_TX_COOLDOWN1:
                begin
                    state   <= `S_FT601_TX_COOLDOWN2;
                    if(~retx_valid_pre[0])
                        begin
                            retx_valid_pre <= retx_valid_pre >> 1;
                            retx_data_pre  <= retx_data_pre >> 32;
                        end
                end
            `S_FT601_TX_COOLDOWN2:
                state   <= `S_FT601_IDLE;
        endcase
endmodule
