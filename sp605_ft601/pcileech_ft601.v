//
// PCILeech for Spartan6 SP605 with FTDI FT601.
//
// FT601 / FT245 controller module.
//
// (c) Ulf Frisk, 2017
// Author: Ulf Frisk, pcileech@frizk.net
// Special thanks to: Dmytro Oleksiuk @d_olex
//

module pcileech_ft601 (
   // TO/FROM PADS
   input                FT601_CLK,
   input                FT601_RESET_N,
   inout [31:0]         FT601_DATA,
   inout [3:0]          FT601_BE,
   input                FT601_RXF_N,
   input                FT601_TXE_N,
   output               FT601_WR_N,
   output reg           FT601_SIWU_N = 1'b1,
   output               FT601_RD_N,
   output               FT601_OE_N,

   // TO/FROM FIFO
   output reg [31:0]    fifo_rx_data,
   output reg           fifo_rx_wr,
   
   input [31:0]         fifo_tx_data,
   input                fifo_tx_empty,
   input                fifo_tx_almost_empty,
   input                fifo_tx_valid,
   output reg           fifo_tx_rd,
   
   // Activity  LED
   output reg           led_activity
   );
   
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
   // data endianess conversions for rx data
   assign ft601_data_rx[7:0] = FT601_DATA[31:24];
   assign ft601_data_rx[15:8] = FT601_DATA[23:16];
   assign ft601_data_rx[23:16] = FT601_DATA[15:8];
   assign ft601_data_rx[31:24] = FT601_DATA[7:0];
   
   

   // Clock results into ft245 output registers. It's not possible to assign
   // them directly due to timing constraints. This solution won't violate
   // timing (as much) but we'll delay the data 1 cycle.
   always @ ( posedge FT601_CLK )
      begin
         __d_ft601_wr_n <= ~ft601_wr;
         __d_ft601_rd_n <= ~ft601_rd;
         __d_ft601_oe_n <= ~ft601_oe;
         led_activity <= ft601_wr | ft601_rd;
         // data endianess conversions for tx data
         __d_ft601_data[7:0] <= ft601_data_tx[31:24];
         __d_ft601_data[15:8] <= ft601_data_tx[23:16];
         __d_ft601_data[23:16] <= ft601_data_tx[15:8];
         __d_ft601_data[31:24] <= ft601_data_tx[7:0];
      end

   // STATE MACHINE FT245 BUS
   `define S_IDLE             4'h0
   `define S_RX_WAIT          4'h1
   `define S_RX_WAIT2         4'h2
   `define S_RX_ACTIVE        4'h3
   `define S_TX_WAIT          4'h4
   `define S_TX_RETX          4'h5
   `define S_TX_ACTIVE        4'h6
   `define S_TX_FINISH        4'h7
   `define S_TX_FINISH_EFIFO  4'h8
   `define RESET           oe <= 1; ft601_oe <= 0; ft601_rd <= 0; ft601_wr <= 0; fifo_rx_wr <= 0; fifo_tx_rd <= 0;
   reg [4:0]      state = `S_IDLE;
   reg [127:0]    tx_last;
   reg [3:0]      tx_last_f = 4'b0000;
   reg            tx_last_en = 1'b0;
   always @ ( posedge FT601_CLK )
      if ( ~FT601_RESET_N )
         begin
            `RESET
            tx_last_en <= 1'b0;
            tx_last_f <= 4'b0000;
            state <= `S_IDLE;
         end
      else case ( state )
         `S_IDLE:
            begin
               if ( ~FT601_TXE_N & tx_last_en )
                  state <= `S_TX_RETX;
               else if ( ~FT601_TXE_N & ~fifo_tx_empty )
                  begin
                     fifo_tx_rd <= 1'b1;
                     state <= `S_TX_WAIT;
                  end
               else if ( ~FT601_RXF_N )
                  begin
                     oe <= 1'b0;
                     ft601_oe <= 1'b1;
                     state <= `S_RX_WAIT;
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
               ft601_wr <= tx_last_f[3];
               ft601_data_tx <= tx_last[127:96];
               if ( ~fifo_tx_empty & (tx_last_f[2:0] == 3'b100) )
                  fifo_tx_rd <= 1'b1;
               if ( ~fifo_tx_empty & (tx_last_f == 4'b1000) )
                  state <= `S_TX_ACTIVE;
               if ( tx_last_f == 4'b0000 ) begin
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
               if ( ~FT601_TXE_N & ~fifo_tx_almost_empty ) begin
                  ft601_wr <= 1'b1;
               end
               // FIFO EMPTY -> TX LAST WORD & FINISH
               if ( ~FT601_TXE_N & fifo_tx_empty ) begin
                  ft601_wr <= 1'b1;
                  state <= `S_TX_FINISH_EFIFO;
               end
               // FT601 FULL -> FINISH
               if ( FT601_TXE_N ) begin
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
               if( tx_last_f[2:0] == 3'b000 )
                  state <= `S_IDLE;
               else if ( FT601_TXE_N )
                  begin
                     tx_last <= (tx_last << 64);
                     tx_last_f <= (tx_last_f << 2);
                     tx_last_en <= 1'b1;
                     state <= `S_IDLE;
                  end
               else
                  begin
                     tx_last <= (tx_last << 32);
                     tx_last_f <= (tx_last_f << 1);
                  end
            end
         `S_RX_WAIT:
            begin
               ft601_rd <= 1'b1;
               state <= `S_RX_WAIT2;
            end
         `S_RX_WAIT2:
            begin
               state <= `S_RX_ACTIVE;
            end
         `S_RX_ACTIVE:
            begin
               if ( ~FT601_RXF_N ) begin
                  fifo_rx_wr <= 1'b1;
                  fifo_rx_data <= ft601_data_rx;
               end
               if ( FT601_RXF_N ) begin
                  `RESET
                  state <= `S_IDLE;
               end
            end
      endcase

endmodule
