//
// PCILeech FPGA.
//
// FT601 / FT245 controller module (v2).
//
// (c) Ulf Frisk, 2017-2018
// Author: Ulf Frisk, pcileech@frizk.net
//

module pcileech_ft601(
    input               clk,
    input               rst,
    // TO/FROM PADS
    inout [31:0]        FT601_DATA,
    output [3:0]        FT601_BE,
    input               FT601_RXF_N,
    input               FT601_TXE_N,
    output              FT601_WR_N,
    output reg          FT601_SIWU_N = 1'b1,
    output              FT601_RD_N,
    output              FT601_OE_N,
    // TO/FROM FIFO
    output reg [31:0]   dout,
    output reg          dout_valid,
    input [31:0]        din,
    input               din_empty,
    input               din_wr_en,
    output              din_req_data, 
    // Activity LED
    output              led_activity
    );
   
    // OE (output enable) to data/byte-enable line
    reg oe = 1'b0;
      
    // FT601 WR, RD, OE
    reg ft601_rd = 1'b0;
    reg ft601_oe = 1'b0;
    reg __d_ft601_rd_n;
    reg __d_ft601_oe_n;

    // RX DATA (and TXE) : (incl. endianess conversion).
    reg         __d_ft601_txe_n = 1'b1;
    reg         __d_ft601_rxf_n = 1'b1;
    reg [31:0]  __d_ft601_data_rx;

    // registers & wires related to transmit "module"
    reg         txo_rd_en;
    reg         txo_has_data;
    reg [31:0]  txo_dout;
    reg         txo_valid_n;
    wire        txe_d1 = ~__d_ft601_txe_n;

    // set ft601 output data
    assign FT601_RD_N = __d_ft601_rd_n;
    assign FT601_OE_N = __d_ft601_oe_n;
    assign FT601_WR_N   = txo_valid_n;
    assign FT601_DATA   = oe ? {txo_dout[7:0], txo_dout[15:8], txo_dout[23:16], txo_dout[31:24]} : 32'hzzzzzzzz; // including byte-swap (endianess)
    assign FT601_BE     = oe ? 4'b1111 : 4'bzzzz;
   
    always @ ( posedge clk )
        begin
            __d_ft601_txe_n    <= FT601_TXE_N;
            __d_ft601_rxf_n    <= FT601_RXF_N;
            __d_ft601_rd_n     <= ~ft601_rd;
            __d_ft601_oe_n     <= ~ft601_oe;
            // endianess convert incoming/rx data
            __d_ft601_data_rx[7:0]     <= FT601_DATA[31:24];
            __d_ft601_data_rx[15:8]    <= FT601_DATA[23:16];
            __d_ft601_data_rx[23:16]   <= FT601_DATA[15:8];
            __d_ft601_data_rx[31:24]   <= FT601_DATA[7:0];
        end

    // -------------------------------------------------------------------------
    // Main FT245 control below:
    // -------------------------------------------------------------------------

    `define S_FT601_IDLE       3'h0
    `define S_FT601_RX_WAIT1   3'h1
    `define S_FT601_RX_WAIT2   3'h2
    `define S_FT601_RX_WAIT3   3'h3
    `define S_FT601_RX_ACTIVE  3'h4
    `define S_FT601_TX_ACTIVE  3'h5
    `define RESET              oe <= 1; ft601_oe <= 0; ft601_rd <= 0; dout_valid <= 0; txo_rd_en <= 0;
    reg [2:0]      state = `S_FT601_IDLE;
    always @ ( posedge clk )
        if ( rst )
            begin
                `RESET
                state <= `S_FT601_IDLE;
            end
        else case ( state )
            `S_FT601_IDLE:
                begin
                    if ( ~__d_ft601_rxf_n )
                        begin
                            state       <= `S_FT601_RX_WAIT1;
                            ft601_oe    <= 1'b1;
                            oe          <= 1'b0;
                        end
                    else if ( ~__d_ft601_txe_n & txo_has_data )
                        begin
                            state       <= `S_FT601_TX_ACTIVE;
                            txo_rd_en   <= 1'b1;
                            ft601_oe    <= 1'b0;
                            oe          <= 1'b1;
                        end
                end
            `S_FT601_TX_ACTIVE:
                begin
                    if( ~txo_has_data )
                        begin
                            state       <= `S_FT601_IDLE;
                            txo_rd_en   <= 1'b0;
                        end
                end
            // RX data from the FT601. The receiver FIFO is assumed to always be
            // non-full. If receiver FIFO is full data will still be received but
            // lost.
            `S_FT601_RX_WAIT1:
                begin
                    ft601_rd <= 1'b1;
                    state <= `S_FT601_RX_WAIT2;
                end
            `S_FT601_RX_WAIT2:
                state <= `S_FT601_RX_WAIT3;
            `S_FT601_RX_WAIT3:
                state <= `S_FT601_RX_ACTIVE;
            `S_FT601_RX_ACTIVE:
                if ( ~__d_ft601_rxf_n )
                    begin
                        dout_valid   <= 1'b1;
                        dout <= __d_ft601_data_rx;
                    end
                else
                    begin
                        `RESET
                        state <= `S_FT601_IDLE;
                    end
        endcase
    assign led_activity = ~rst & (state != `S_FT601_IDLE);

    // -------------------------------------------------------------------------
    // Transmission and re-transmission "module" below: 
    // -------------------------------------------------------------------------
    
    reg [2:0]           i_valid     = 4'b0000;
    reg [95:0]          i_data;
    reg [2:0]           i_pre_valid = 3'b000;
    reg [95:0]          i_pre_data;
    
    // STATE MACHINE
    `define S_FT601TX_IDLE          3'h0
    `define S_FT601TX_ACTIVE        3'h1
    `define S_FT601TX_COOLDOWN1     3'h2
    `define S_FT601TX_COOLDOWN2     3'h3
    `define S_FT601TX_CLEANUP       3'h4
    reg [2:0]         txo_state     = `S_FT601TX_IDLE;
    
    assign din_req_data = ~din_empty & txo_rd_en & txe_d1 & ~i_pre_valid[1] & ((txo_state == `S_FT601TX_IDLE) | (txo_state == `S_FT601TX_ACTIVE));

    always @ ( posedge clk )
    if ( rst )
        begin
            txo_state       <= `S_FT601TX_IDLE;
            txo_valid_n     <= 1'b1;
            txo_has_data    <= 1'b0;
            i_valid         <= 3'b000;
            i_pre_valid     <= 3'b000;
        end
    else case ( txo_state )
        `S_FT601TX_IDLE:
            begin
                if( txo_rd_en & txe_d1 & (i_pre_valid[0] | ~din_empty) )
                begin
                    txo_state       <= `S_FT601TX_ACTIVE;
                    // transmit re-tx data (if there is any ...)
                    i_data[95:64]   <= i_pre_data[31:0];
                    txo_dout        <= i_pre_data[31:0];
                    i_valid[2]      <= i_pre_valid[0];
                    txo_valid_n     <= ~i_pre_valid[0];
                    // move retransmit list data
                    i_pre_valid     <= i_pre_valid >> 1;
                    i_pre_data      <= i_pre_data >> 32;
                end
                // has data next cycle if: retransmit or fifo data exists.
                txo_has_data        <= i_pre_valid[0] | ~din_empty;
            end
        `S_FT601TX_ACTIVE:
            begin
                // has data next cycle if no error condition exists that will switch to cooldown
                if( ~txo_rd_en | ~txe_d1 | (~i_pre_valid[1] & din_empty) )
                    begin
                        txo_state       <= `S_FT601TX_COOLDOWN1;
                        txo_has_data    <= 1'b0;
                    end
                // set output data and fill up ongoing history list
                i_data[95:64]   <= i_pre_valid[0] ? i_pre_data[31:0] : din;
                txo_dout        <= i_pre_valid[0] ? i_pre_data[31:0] : din;
                i_valid[2]      <= i_pre_valid[0] | din_wr_en;
                txo_valid_n     <= ~(i_pre_valid[0] | din_wr_en);
                // move ongoing history list data (and invalidate if successfully transmitted)
                i_valid[0]      <= i_valid[1] & ~txe_d1;
                i_valid[1]      <= i_valid[2];
                i_data[63:0]    <= i_data >> 32;
                // move retransmit list data
                i_pre_valid     <= i_pre_valid >> 1;
                i_pre_data      <= i_pre_data >> 32;
            end
        `S_FT601TX_COOLDOWN1:
            begin
                txo_state       <= `S_FT601TX_COOLDOWN2;
                txo_valid_n     <= 1'b1;
                i_valid[1]      <= i_valid[1] & ~txe_d1;
            end
        `S_FT601TX_COOLDOWN2:
            begin
                txo_state       <= `S_FT601TX_CLEANUP;
                i_valid[2]      <= i_valid[2] & ~txe_d1;
            end
        `S_FT601TX_CLEANUP:
            begin
                i_valid <= i_valid << 1;
                i_data  <= i_data << 32;
                if ( i_valid[1:0] == 2'b00 ) // topmost bit not necessary to check
                    txo_state   <= `S_FT601TX_IDLE;
                if ( i_valid[2] )
                    begin
                        i_pre_valid <= (i_pre_valid << 1) | i_valid[2];
                        i_pre_data  <= (i_pre_data << 32) | i_data[95:64];
                    end
            end
    endcase
endmodule
