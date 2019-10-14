//
// PCILeech FPGA.
//
//
// (c) Ulf Frisk, 2019
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps

module pcileech_ft601_buf (
    // SYS
    input               clk,                // 100MHz CLK
    input               rst,
    
    // TO/FROM PADS
    inout [31:0]        FT601_DATA,
    output [3:0]        FT601_BE,
    input               FT601_RXF_N,
    input               FT601_TXE_N,
    output              FT601_WR_N,
    output              FT601_SIWU_N,
    output              FT601_RD_N,
    output              FT601_OE_N,
    
    // State and Activity LEDs
    input               led_state_invert,
    output              led_state_txdata,
    
    // TO/FROM FIFO
    output [31:0]       dout,
    output              dout_valid,
    input [255:0]       din,
    input               din_wr_en,
    output              din_ready
    
    );
    
    // FT601/FT245 <--> BUFFER FIFOs
    wire [31:0]     ft601_tx_data;
    wire            ft601_tx_empty;
    wire            ft601_tx_valid;
    wire            ft601_tx_rden;
    
    pcileech_ft601 i_pcileech_ft601(
        .clk                ( clk                   ),
        .rst                ( rst                   ),
        // TO/FROM FT601 PADS
        .FT601_DATA         ( FT601_DATA            ),
        .FT601_BE           ( FT601_BE              ),
        .FT601_TXE_N        ( FT601_TXE_N           ),
        .FT601_RXF_N        ( FT601_RXF_N           ),
        .FT601_SIWU_N       ( FT601_SIWU_N          ),
        .FT601_WR_N         ( FT601_WR_N            ),
        .FT601_RD_N         ( FT601_RD_N            ),
        .FT601_OE_N         ( FT601_OE_N            ),
        // FT601 CTL <--> FIFO CTL
        .dout               ( dout                  ),
        .dout_valid         ( dout_valid            ),
        // FT601 CTL <--> MAIN OUTPUT FIFO  
        .din                ( ft601_tx_data         ),
        .din_empty          ( ft601_tx_empty        ),
        .din_wr_en          ( ft601_tx_valid        ),
        .din_req_data       ( ft601_tx_rden         )
    );
    
    wire [31:0] fram_din;
    wire fram_almost_full;
    wire fram_wr_en;
    wire fram_prog_empty;
    wire out_buffer1_almost_full;
    reg  __d_ft601_txe_n;
    always @ ( posedge clk )
        __d_ft601_txe_n <= FT601_TXE_N;
    // FTDI have a bug ( in chip or driver ) which doesn't terminate transfer if
    // even multiple of 1024 bytes are transmitted. Always insert five (5) MAGIC
    // DWORD (0x66665555) in beginning of stream to mitigate this.  Since normal
    // data size is always a multiple of 32-bytes/256-bits this will resolve the
    // issue. 
    wire ftdi_bug_workaround = fram_prog_empty & __d_ft601_txe_n & ~fram_wr_en;
    fifo_32_32_deep i_pcileech_out_buffer2(
        .clk                ( clk                   ),
        .srst               ( rst                   ),
        .din                ( ftdi_bug_workaround ? 32'h66665555 : fram_din ),
        .wr_en              ( fram_wr_en | ftdi_bug_workaround ),
        .rd_en              ( ft601_tx_rden         ),
        .dout               ( ft601_tx_data         ),
        .full               (                       ),
        .almost_full        ( fram_almost_full      ),
        .empty              ( ft601_tx_empty        ),
        .prog_empty         ( fram_prog_empty       ),
        .valid              ( ft601_tx_valid        )
    );
    fifo_256_32 i_pcileech_out_buffer1(
        .clk                ( clk                   ),
        .srst               ( rst                   ),
        .din                ( din                   ),
        .wr_en              ( din_wr_en             ),
        .rd_en              ( ~fram_almost_full     ),
        .dout               ( fram_din              ),
        .full               (                       ),
        .almost_full        ( out_buffer1_almost_full ),
        .empty              (                       ),
        .valid              ( fram_wr_en            )
    );
    assign din_ready = ~out_buffer1_almost_full;
    OBUF led_ld3_obuf(.O( led_state_txdata ), .I( led_state_invert ^ ~ft601_tx_empty ));

endmodule
