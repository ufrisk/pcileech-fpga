//
// PCILeech FPGA.
//
// FT601 / FT245 controller module (v4).
//
// (c) Ulf Frisk, 2017-2024
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps

module pcileech_ft601(
    input               clk,
    input               rst,
    // TO/FROM PADS
    output [3:0]        FT601_BE,
    inout [31:0]        FT601_DATA,
    input               FT601_RXF_N,
    input               FT601_TXE_N,
    output bit          FT601_OE_N,
    output bit          FT601_RD_N,
    output bit          FT601_WR_N,
    output bit          FT601_SIWU_N,
    // TO/FROM FIFO
    output bit [31:0]   dout,
    output bit          dout_valid,
    input [31:0]        din,
    input               din_wr_en,
    output              din_req_data
    );
    
    initial begin
        FT601_OE_N   <= 1'b1;
        FT601_RD_N   <= 1'b1;
        FT601_WR_N   <= 1'b1;
        FT601_SIWU_N <= 1'b1;
        dout_valid   <= 1'b0;
        dout         <= 32'h00000000;
    end

    `define S_FT601_IDLE         4'h0
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

                        bit [31:0]      FT601_DATA_OUT[5];
    (* KEEP = "TRUE" *) wire            FWD;
    (* KEEP = "TRUE" *) bit             OE                  = 1'b1;
    (* KEEP = "TRUE" *) bit [3:0]       data_cooldown_count = 0;
    (* KEEP = "TRUE" *) bit [2:0]       data_queue_count    = 0;     
    (* KEEP = "TRUE" *) bit [3:0]       state               = `S_FT601_IDLE;



    // -------------------------------------------------------------------------
    // FT245 RX / DATA INPUT BELOW:
    // -------------------------------------------------------------------------

    always @ ( posedge clk )
        begin
            dout_valid      <= !rst && !FT601_RXF_N && (state == `S_FT601_RX_ACTIVE);
            dout[7:0]       <= FT601_DATA[31:24];
            dout[15:8]      <= FT601_DATA[23:16];
            dout[23:16]     <= FT601_DATA[15:8];
            dout[31:24]     <= FT601_DATA[7:0];
        end



    // -------------------------------------------------------------------------
    // FT245 TX / DATA OUTPUT BELOW:
    // -------------------------------------------------------------------------        

    assign FT601_BE     = OE ? 4'b1111 : 4'bzzzz;
    assign FT601_DATA   = OE ? {FT601_DATA_OUT[0][7:0], FT601_DATA_OUT[0][15:8], FT601_DATA_OUT[0][23:16], FT601_DATA_OUT[0][31:24]} : 32'hzzzzzzzz;
    assign din_req_data = !rst && (data_queue_count == 2) || (data_queue_count == 3);
    assign FWD          = !rst && !FT601_TXE_N && (data_queue_count != 0) && (state == `S_FT601_TX_ACTIVE);

    always @ ( posedge clk ) begin
        if ( rst || (data_cooldown_count == 4'hf) ) begin
            data_cooldown_count <= 0;
            data_queue_count    <= 5;
            FT601_DATA_OUT[0]   <= 32'h66665555;
            FT601_DATA_OUT[1]   <= 32'h66665555;
            FT601_DATA_OUT[2]   <= 32'h66665555;
            FT601_DATA_OUT[3]   <= 32'h66665555;
            FT601_DATA_OUT[4]   <= 32'h66665555;
        end
        else begin
            data_cooldown_count <= (data_queue_count == 0) ? (data_cooldown_count + 1) : 0;
            data_queue_count    <= data_queue_count + (din_wr_en ? 3'b001 : 3'b000) - (FWD ? 3'b001 : 3'b000);
            if ( FWD ) begin
                if ( data_queue_count > 1 ) begin
                    FT601_DATA_OUT[0] <= FT601_DATA_OUT[1];
                end
                if ( data_queue_count > 2 ) begin
                    FT601_DATA_OUT[1] <= FT601_DATA_OUT[2];
                end
                if ( data_queue_count > 3 ) begin
                    FT601_DATA_OUT[2] <= FT601_DATA_OUT[3];
                end
                if ( data_queue_count > 4 ) begin
                    FT601_DATA_OUT[3] <= FT601_DATA_OUT[4];
                end
            end
            if ( din_wr_en ) begin
                FT601_DATA_OUT[data_queue_count - (FWD ? 3'b001 : 3'b000)] <= din;
            end
        end
    end



    // -------------------------------------------------------------------------
    // FT245 main control below:
    // -------------------------------------------------------------------------

    always @ ( posedge clk )
        begin
            OE          <=  (rst || FT601_RXF_N || ((state != `S_FT601_RX_ACTIVE) && (state != `S_FT601_RX_WAIT3) && (state != `S_FT601_RX_WAIT2) && (state != `S_FT601_RX_COOLDOWN1) && (state != `S_FT601_RX_COOLDOWN2)));
            FT601_OE_N  <=  (rst || FT601_RXF_N || ((state != `S_FT601_RX_ACTIVE) && (state != `S_FT601_RX_WAIT3) && (state != `S_FT601_RX_WAIT2)));
            FT601_RD_N  <=  (rst || FT601_RXF_N || ((state != `S_FT601_RX_ACTIVE) && (state != `S_FT601_RX_WAIT3)));
            FT601_WR_N  <=  !(!rst && !FT601_TXE_N && ((state == `S_FT601_TX_WAIT2) || ((state == `S_FT601_TX_ACTIVE) && (din_wr_en || (data_queue_count > 1)))));
        end

    always @ ( posedge clk )
        if ( rst )
            begin
                state <= `S_FT601_IDLE;
            end
        else case ( state )
            // ----------------------------------------------------------------
            // IDLE STATE:
            // RX are prioritized above TX in case both options are available. 
            // ----------------------------------------------------------------
            `S_FT601_IDLE:
                if ( !FT601_RXF_N )
                    state <= `S_FT601_RX_WAIT1;
                else if ( !FT601_TXE_N && (data_queue_count > 0) )
                    state <= `S_FT601_TX_WAIT1;
            // ----------------------------------------------------------------
            // RX DATA FROM THE FT601:
            // The receiver FIFO is assumed to always be non-full.
            // If receiver FIFO is full data will still be received but lost.
            // ----------------------------------------------------------------
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
                state <= FT601_TXE_N ? `S_FT601_TX_COOLDOWN1 : `S_FT601_TX_WAIT2;
            `S_FT601_TX_WAIT2:
                state <= FT601_TXE_N ? `S_FT601_TX_COOLDOWN1 : `S_FT601_TX_ACTIVE;
            `S_FT601_TX_ACTIVE:
                state <= (FT601_TXE_N || (!din_wr_en && (data_queue_count <= 1))) ? `S_FT601_TX_COOLDOWN1 : `S_FT601_TX_ACTIVE;
            `S_FT601_TX_COOLDOWN1:
                state <= `S_FT601_TX_COOLDOWN2;
            `S_FT601_TX_COOLDOWN2:
                state   <= `S_FT601_IDLE;
        endcase

endmodule
