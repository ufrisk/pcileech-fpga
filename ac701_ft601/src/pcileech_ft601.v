//
// PCILeech FPGA.
//
// FT601 / FT245 controller module.
//
// (c) Ulf Frisk, 2017-2018
// Author: Ulf Frisk, pcileech@frizk.net
// Special thanks to: Dmytro Oleksiuk @d_olex
//

module pcileech_ft601(
   input                clk,
   input                rst,
   // TO/FROM PADS
   inout [31:0]         FT601_DATA,
   inout [3:0]          FT601_BE,
   input                FT601_RXF_N,
   input                FT601_TXE_N,
   output               FT601_WR_N,
   output               FT601_SIWU_N,
   output               FT601_RD_N,
   output               FT601_OE_N,
   // TO/FROM FIFO
   output reg [31:0]    fifo_rx_data,
   output reg           fifo_rx_wr,
   input [31:0]         fifo_tx_data,
   input                fifo_tx_empty,
   input                fifo_tx_valid,
   output reg           fifo_tx_rd,
   // Activity LED
   output reg           led_activity,
   // Transfer Strategy - prioritize: 0 = transmit, 1 = receive
   input                xfer_prio_rx
   );
   assign FT601_SIWU_N = 1'b1;
   
   // OE (output enable) to data/byte-enable line
   reg oe = 1'b0;
      
   // FT601 WR, RD, OE
   reg ft601_wr = 1'b0;
   reg ft601_rd = 1'b0;
   reg ft601_oe = 1'b0;
   reg __d_ft601_wr_n;
   reg __d_ft601_rd_n;
   reg __d_ft601_oe_n;
   assign FT601_WR_N = __d_ft601_wr_n;
   assign FT601_RD_N = __d_ft601_rd_n;
   assign FT601_OE_N = __d_ft601_oe_n;
   // DATA
   wire [31:0] ft601_data_rx;
   reg [31:0] ft601_data_tx;
   reg [31:0] __d_ft601_data;
   assign FT601_DATA = oe ? __d_ft601_data : 32'hzzzzzzzz;
   assign FT601_BE = oe ? 4'b1111 : 4'bzzzz;
   // RX DATA (and TXE) : (incl. endianess conversion).
   reg         __d_ft601_txe_n;
   reg         __d_ft601_rxf_n = 1'b1;
   reg [31:0]  __d_ft601_data_rx;
   
   // CLK
   always @ ( posedge clk )
      begin
         led_activity <= ft601_wr | ft601_rd;
         __d_ft601_txe_n <= FT601_TXE_N;
         __d_ft601_rxf_n <= FT601_RXF_N;
         __d_ft601_wr_n <= ~ft601_wr;
         __d_ft601_rd_n <= ~ft601_rd;
         __d_ft601_oe_n <= ~ft601_oe;
         // data endianess conversions for rx data
         __d_ft601_data_rx[7:0] = FT601_DATA[31:24];
         __d_ft601_data_rx[15:8] = FT601_DATA[23:16];
         __d_ft601_data_rx[23:16] = FT601_DATA[15:8];
         __d_ft601_data_rx[31:24] = FT601_DATA[7:0];      
         // data endianess conversions for tx data
         __d_ft601_data[7:0] <= ft601_data_tx[31:24];
         __d_ft601_data[15:8] <= ft601_data_tx[23:16];
         __d_ft601_data[23:16] <= ft601_data_tx[15:8];
         __d_ft601_data[31:24] <= ft601_data_tx[7:0];
      end

   // STATE MACHINE FT245 BUS
   `define S_IDLE             4'h0
   `define S_RX_WAIT1         4'h1
   `define S_RX_WAIT2         4'h2
   `define S_RX_WAIT3         4'h3
   `define S_RX_ACTIVE        4'h4
   `define S_TX_WAIT          4'h5
   `define S_TX_RETX          4'h6
   `define S_TX_ACTIVE        4'h7
   `define S_TX_FINISH        4'h8
   `define S_TX_FINISH_EFIFO  4'h9
   `define RESET              oe <= 1; ft601_oe <= 0; ft601_rd <= 0; ft601_wr <= 0; fifo_rx_wr <= 0; fifo_tx_rd <= 0;
   reg [3:0]      state = `S_IDLE;
   reg [159:0]    tx_last;
   reg [4:0]      tx_last_f = 5'b00000;
   reg            tx_last_en = 1'b0;
   always @ ( posedge clk )
      if ( rst )
         begin
            `RESET
            tx_last_en <= 1'b0;
            tx_last_f <= 4'b0000;
            state <= `S_IDLE;
         end
      else case ( state )
         `S_IDLE:
            begin
               if ( ~__d_ft601_txe_n & tx_last_en )
                  state <= `S_TX_RETX;
               else if ( ~xfer_prio_rx & ~__d_ft601_txe_n & ~fifo_tx_empty )
                  begin
                     fifo_tx_rd <= 1'b1;
                     state <= `S_TX_WAIT;
                  end
               else if ( ~__d_ft601_rxf_n )
                  begin
                     oe <= 1'b0;
                     ft601_oe <= 1'b1;
                     state <= `S_RX_WAIT1;
                  end
               else if ( ~__d_ft601_txe_n & ~fifo_tx_empty )
                 begin
                    fifo_tx_rd <= 1'b1;
                    state <= `S_TX_WAIT;
                 end
            end
         `S_TX_WAIT:
            begin
               state <= `S_TX_ACTIVE;
            end
         `S_TX_RETX:
            // re-transmit the last words from the last tx that was lost after
            // the FT601 became full.
            begin
               tx_last_en <= 1'b0;
               tx_last_f <= tx_last_f << 1;
               tx_last <= tx_last << 32;
               ft601_wr <= tx_last_f[4];
               ft601_data_tx <= tx_last[159:128];
               if ( ~fifo_tx_empty & (tx_last_f[3:0] == 4'b1000) )
                  fifo_tx_rd <= 1'b1;
               if ( ~fifo_tx_empty & (tx_last_f == 5'b10000) )
                  state <= `S_TX_ACTIVE;
               if ( tx_last_f == 5'b00000 ) begin
                  `RESET
                  state <= `S_TX_FINISH;
               end
            end
         `S_TX_ACTIVE:
            begin
               ft601_data_tx <= fifo_tx_data;
               tx_last <= (tx_last << 32) | fifo_tx_data;
               tx_last_f <= (tx_last_f << 1) | fifo_tx_valid;
               // NORMAL TX
               if ( ~__d_ft601_txe_n ) begin
                  ft601_wr <= 1'b1;
               end
               // FIFO EMPTY -> TX LAST WORD & FINISH
               if ( ~__d_ft601_txe_n & fifo_tx_empty ) begin
                  ft601_wr <= 1'b1;
                  state <= `S_TX_FINISH_EFIFO;
               end
               // FT601 FULL -> FINISH
               if ( __d_ft601_txe_n ) begin
                  tx_last_en <= 1'b1;
                  `RESET
                  state <= `S_TX_FINISH;
               end
            end
         `S_TX_FINISH:
            begin
               tx_last <= (tx_last << 32) | fifo_tx_data;
               tx_last_f <= (tx_last_f << 1) | fifo_tx_valid;
               `RESET
               state <= `S_IDLE;               
            end
         `S_TX_FINISH_EFIFO:
            begin
               // SET tx_last_en (if required) SO THAT LAST WORDS WON'T BE LOST & FINISH
               `RESET
               if( tx_last_f[3:0] == 4'b0000 )
                  state <= `S_IDLE;
               else if ( __d_ft601_txe_n )
                  begin
                     tx_last <= (tx_last << 96);
                     tx_last_f <= (tx_last_f << 3);
                     tx_last_en <= 1'b1;
                     state <= `S_IDLE;
                  end
               else
                  begin
                     tx_last <= (tx_last << 32);
                     tx_last_f <= (tx_last_f << 1);
                  end
            end
         // RX data from the FT601. The receiver FIFO is assumed to always be
         // non-full. If receiver FIFO is full data will still be received but
         // lost.
         `S_RX_WAIT1:
            begin
               ft601_rd <= 1'b1;
               state <= `S_RX_WAIT2;
            end
         `S_RX_WAIT2:
            state <= `S_RX_WAIT3;
         `S_RX_WAIT3:
            state <= `S_RX_ACTIVE;
         `S_RX_ACTIVE:
            if ( ~__d_ft601_rxf_n )
               begin
                  fifo_rx_wr <= 1'b1;
                  fifo_rx_data <= __d_ft601_data_rx;
               end
            else
               begin
                  `RESET
                  state <= `S_IDLE;
               end
      endcase          
endmodule
