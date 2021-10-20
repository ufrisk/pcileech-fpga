//
// PCILeech FPGA.
//
// FT2232H / FT245 controller module (v4).
//
// (c) Ulf Frisk, 2017-2021
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps

module pcileech_ft245(
    input               clk,
    input               rst,
    // TO/FROM PADS
    inout  [7:0]        FT245_DATA,
    input               FT245_RXF_N,
    input               FT245_TXE_N,
    output reg          FT245_WR_N      = 1'b1,
    output reg          FT245_SIWU_N    = 1'b1,
    output reg          FT245_RD_N      = 1'b1,
    output reg          FT245_OE_N      = 1'b1,
    // TO/FROM FIFO
    output reg [7:0]    dout,
    output reg          dout_valid      = 1'b0,
    input [7:0]         din,
    input               din_empty,
    input               din_wr_en,
    output              din_req_data
    );

    // set ft245 output data
    reg [7:0] txo_dout;
    reg oe              = 1'b0;
    assign FT245_DATA   = oe ? txo_dout : 8'hzz;
   
    always @ ( posedge clk ) begin
        dout    <= FT245_DATA;
    end

    // -------------------------------------------------------------------------
    // Main FT245 control below:
    // -------------------------------------------------------------------------
    
    `define S_FT245_IDLE         4'h0
    `define S_FT245_RX_WAIT0     4'h1
    `define S_FT245_RX_WAIT1     4'h2
    `define S_FT245_RX_WAIT2     4'h3
    `define S_FT245_RX_WAIT3     4'h4
    `define S_FT245_RX_ACTIVE    4'h5
    `define S_FT245_RX_COOLDOWN1 4'h6
    `define S_FT245_RX_COOLDOWN2 4'h7
    `define S_FT245_TX_WAIT1     4'h8
    `define S_FT245_TX_WAIT2     4'h9
    `define S_FT245_TX_ACTIVE    4'ha
    `define S_FT245_TX_COOLDOWN1 4'hb
    `define S_FT245_TX_COOLDOWN2 4'hc
    
    reg [3:0]           state = `S_FT245_IDLE;
    
    reg [1:0]           retx_valid      = 2'b00;
    reg [15:0]          retx_data;
    reg [1:0]           retx_valid_pre  = 2'b00;
    reg [15:0]          retx_data_pre;
    (* KEEP = "TRUE" *) reg txo_wr_n    = 1'b1;
    reg                 d_txo_wr_n      = 1'b1;
    
    assign din_req_data = ~din_empty & ~FT245_TXE_N & ~retx_valid[1] & ((state == `S_FT245_TX_WAIT2) | (state == `S_FT245_TX_ACTIVE));
    
    always @ ( posedge clk )
        begin
            dout_valid   <= ~rst & ~FT245_RXF_N & ((state == `S_FT245_RX_ACTIVE));
            FT245_OE_N   <=  rst |  FT245_RXF_N | ((state != `S_FT245_RX_WAIT2) && (state != `S_FT245_RX_WAIT3) && (state != `S_FT245_RX_ACTIVE));
            FT245_RD_N   <=  rst |  FT245_RXF_N | ((state != `S_FT245_RX_WAIT3) && (state != `S_FT245_RX_ACTIVE));
            FT245_WR_N   <=  rst |  FT245_TXE_N | (state != `S_FT245_TX_ACTIVE) | ~(retx_valid[0] | din_wr_en);
            txo_wr_n     <=  rst |  FT245_TXE_N | (state != `S_FT245_TX_ACTIVE) | ~(retx_valid[0] | din_wr_en);
            d_txo_wr_n   <=  txo_wr_n;
            FT245_SIWU_N <= ~(~rst && din_empty && (retx_valid_pre == 2'b00) && ~d_txo_wr_n && txo_wr_n);
        end
    
    always @ ( posedge clk )
        if ( rst )
            begin
                oe <= 0;
                retx_valid <= 2'b00;
                retx_valid_pre <= 2'b00;
                state <= `S_FT245_IDLE;
            end
        else case ( state )
            // ----------------------------------------------------------------
            // IDLE STATE:
            // RX are prioritized above TX in case both options are available. 
            // ----------------------------------------------------------------
            `S_FT245_IDLE:
                if ( ~FT245_RXF_N )
                    state <= `S_FT245_RX_WAIT0;
                else if ( ~FT245_TXE_N & (retx_valid_pre[0] | ~din_empty) )
                    state <= `S_FT245_TX_WAIT1;
            // ----------------------------------------------------------------
            // RX DATA FROM THE FT245:
            // The receiver FIFO is assumed to always be non-full.
            // If receiver FIFO is full data will still be received but lost.
            // ----------------------------------------------------------------
            `S_FT245_RX_WAIT0:
                state <= FT245_RXF_N ? `S_FT245_RX_COOLDOWN1 : `S_FT245_RX_WAIT1;
            `S_FT245_RX_WAIT1:
                state <= FT245_RXF_N ? `S_FT245_RX_COOLDOWN1 : `S_FT245_RX_WAIT2;
            `S_FT245_RX_WAIT2:
                state <= FT245_RXF_N ? `S_FT245_RX_COOLDOWN1 : `S_FT245_RX_WAIT3;
            `S_FT245_RX_WAIT3:
                state <= FT245_RXF_N ? `S_FT245_RX_COOLDOWN1 : `S_FT245_RX_ACTIVE;
            `S_FT245_RX_ACTIVE:
                state <= FT245_RXF_N ? `S_FT245_RX_COOLDOWN1 : `S_FT245_RX_ACTIVE;
            `S_FT245_RX_COOLDOWN1:
                state <= `S_FT245_RX_COOLDOWN2;
            `S_FT245_RX_COOLDOWN2:
                state <= `S_FT245_IDLE;
            // ----------------------------------------------------------------
            // TX DATA TO THE FT245:
            // ----------------------------------------------------------------
            `S_FT245_TX_WAIT1:
                begin
                    retx_data       <= retx_data_pre;
                    retx_valid      <= retx_valid_pre;
                    retx_valid_pre  <= 2'b00;
                    state           <= `S_FT245_TX_WAIT2;
                end
            `S_FT245_TX_WAIT2:
                begin
                    oe              <= 1'b1;
                    state           <= `S_FT245_TX_ACTIVE;
                end
            `S_FT245_TX_ACTIVE:
                begin
                    retx_data       <= retx_data >> 8;
                    retx_valid      <= retx_valid >> 1;
                    txo_dout        <= retx_valid[0] ? retx_data[7:0] : din;
                    if ( ~FT245_TXE_N & (retx_valid[0] | din_wr_en) )
                        begin
                            state                <= `S_FT245_TX_ACTIVE;
                        end
                    else
                        begin
                            retx_valid_pre[0]    <= ~txo_wr_n & FT245_TXE_N;
                            retx_valid_pre[1]    <= retx_valid[0] | din_wr_en;
                            retx_data_pre[7:0]   <= txo_dout;
                            retx_data_pre[15:8]  <= retx_valid[0] ? retx_data[7:0] : din;
                            oe                   <= 0;
                            state                <= `S_FT245_TX_COOLDOWN1;
                        end
                end
            `S_FT245_TX_COOLDOWN1:
                begin
                    state   <= `S_FT245_TX_COOLDOWN2;
                    if(~retx_valid_pre[0])
                        begin
                            retx_valid_pre <= retx_valid_pre >> 1;
                            retx_data_pre  <= retx_data_pre >> 8;
                        end
                end
            `S_FT245_TX_COOLDOWN2:
                state   <= `S_FT245_IDLE;
        endcase
endmodule
