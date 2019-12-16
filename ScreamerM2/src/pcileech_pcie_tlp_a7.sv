//
// PCILeech FPGA.
//
// PCIe controller module - TLP handling for Artix-7.
//
// (c) Ulf Frisk, 2018-2019
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_pcie_tlp_a7(
    input                   rst,
    input                   clk_100,            // 100MHz
    input                   clk_pcie,           // 62.5MHz
    IfPCIeFifoTlp.mp_pcie   dfifo,
    
    // PCIe core transmit data (s_axis)
    IfPCIeTlpRxTx.source    tlp_tx,
    IfPCIeTlpRxTx.sink      tlp_rx,
    
    IfCfg_TlpCfg.tlp        cfg_tlpcfg,
    IfTlp32.sink            tlp_static
    );
    
    // ------------------------------------------------------------------------
    // Convert received TLPs from PCIe core and transmit onwards to FT601
    // FIFO depth: 512 / 64-bits.
    // ------------------------------------------------------------------------
    // pcie_tlp_rx_din[31:0]  = 2st DWORD
    // pcie_tlp_rx_din[32]    = 2st DWORD is LAST in TLP
    // pcie_tlp_rx_din[33]    = 2st DWORD VALID
    // pcie_tlp_tx_din[65:34] = 1nd DWORD
    // pcie_tlp_tx_din[66]    = 1nd DWORD is LAST in TLP
    // pcie_tlp_tx_din[67]    = 1nd DWORD VALID
    wire [67:0]     pcie_tlp_rx_din;
    wire            pcie_tlp_rx_almost_full;
    wire [33:0]     pcie_tlp_rx_dout;
    wire            pcie_tlp_rx_dout_i;
    
    assign pcie_tlp_rx_din[31:0] = tlp_rx.data[63:32];
    assign pcie_tlp_rx_din[32] = tlp_rx.last;
    assign pcie_tlp_rx_din[33] = tlp_rx.keep[7];
    assign pcie_tlp_rx_din[65:34] = tlp_rx.data[31:0];
    assign pcie_tlp_rx_din[66] = tlp_rx.last & ~tlp_rx.keep[7];
    assign pcie_tlp_rx_din[67] = 1'b1;
    assign tlp_rx.ready = ~pcie_tlp_rx_almost_full;
   
    fifo_68_34 i_fifo_pcie_tlp_rx(
        .rst            ( rst                       ),
        .wr_clk         ( clk_pcie                  ),
        .rd_clk         ( clk_100                   ),
        .din            ( pcie_tlp_rx_din           ),
        .wr_en          ( tlp_rx.valid              ),
        .rd_en          ( dfifo.rx_rd_en            ),
        .dout           ( pcie_tlp_rx_dout          ),
        .almost_full    ( pcie_tlp_rx_almost_full   ),
        .full           (                           ),
        .empty          ( dfifo.rx_empty            ),
        .valid          ( pcie_tlp_rx_dout_i        )
    );
    
    assign dfifo.rx_data     = pcie_tlp_rx_dout[31:0];
    assign dfifo.rx_last     = pcie_tlp_rx_dout[32];
    assign dfifo.rx_valid    = pcie_tlp_rx_dout_i & pcie_tlp_rx_dout[33];
    
    // ----------------------------------------------------------------------------
    // TX data received from FIFO
    // ----------------------------------------------------------------------------
    IfTlp128 fifo_tlp();
    
    tlp128_source_fifo i_tlp128_source_fifo(
        .clk_fifo       ( clk_100                   ),
        .clk            ( clk_pcie                  ),
        .rst            ( rst                       ),
        .dfifo          ( dfifo                     ),
        .tlp_out        ( fifo_tlp                  )
    );
    
    tlp128_sink_mux1 i_tlp128_sink_mux1(
        .clk            ( clk_pcie                  ),
        .rst            ( rst                       ),
        .tlp_tx         ( tlp_tx                    ),
        .p0             ( fifo_tlp                  ),
        .p1             ( tlp_static                ),
        .pX_en          ( cfg_tlpcfg.tlp_tx_en      )
    );

endmodule

module tlp128_sink_mux1 (
    input                   clk,
    input                   rst,

    IfPCIeTlpRxTx.source    tlp_tx,
    IfTlp128.sink           p0,
    IfTlp32.sink            p1,
    input   [3:0]           pX_en
);
    reg [66 * 18 - 1 : 0]   tlp     = 0;
    
    wire req_data = ~tlp[64] & ~tlp[65] & ~p0.valid & ~p1.valid; 
    assign p0.req_data = req_data & pX_en[0] & p0.has_data;
    assign p1.req_data = req_data & pX_en[1] & p1.has_data & ~p0.req_data;
    
    assign tlp_tx.data = tlp[63:0];
    assign tlp_tx.keep = (tlp[64] & ~tlp[65]) ? 8'h0f : 8'hff;
    assign tlp_tx.last = tlp[64];
    assign tlp_tx.valid = tlp_tx.ready & (tlp[64] | tlp[65]);
    
    always @ ( posedge clk )
        if ( rst )
            tlp <= 0;
        else if ( p0.valid )
            tlp <= p0.data;
        else if ( p1.valid )
            tlp <= p1.data;
        else if ( tlp_tx.ready )
            tlp <= (tlp >> 66);
            
endmodule

module tlp128_source_fifo (
    input                   clk_fifo,
    input                   clk,
    input                   rst,

    IfPCIeFifoTlp.mp_pcie   dfifo,
    IfTlp128.source         tlp_out
);
    // data ( pcie_tlp_tx_din / tlp_din ) as follows:
    // pcie_tlp_tx_din[31:0]  = 1st DWORD
    // pcie_tlp_tx_din[63:32] = 2nd DWORD
    // pcie_tlp_tx_din[64]    = Last DWORD in TLP
    // pcie_tlp_tx_din[65]    = 2nd DWORD is valid
    wire [65:0]     pcie_tlp_tx_din;
    wire            pcie_tlp_tx_wren;
    reg [31:0]      d_pcie_tlp_tx_data;
    reg             d_pcie_tlp_tx_valid = 1'b0;
    
    assign pcie_tlp_tx_din[31:0] = d_pcie_tlp_tx_valid ? d_pcie_tlp_tx_data : dfifo.tx_data;
    assign pcie_tlp_tx_din[63:32] = dfifo.tx_data;
    assign pcie_tlp_tx_din[64] = dfifo.tx_last;
    assign pcie_tlp_tx_din[65] = d_pcie_tlp_tx_valid;
    assign pcie_tlp_tx_wren = dfifo.tx_valid & ( dfifo.tx_last | d_pcie_tlp_tx_valid );
    
    always @ ( posedge clk_fifo )
        if( rst )
            d_pcie_tlp_tx_valid <= 1'b0;
        else if ( dfifo.tx_valid )
            begin
                d_pcie_tlp_tx_data <= dfifo.tx_data;
                d_pcie_tlp_tx_valid <= ~pcie_tlp_tx_wren;
            end
            
    wire [65:0]     tlp_din;
    wire            tlp_din_valid;
    wire            tlp_din_rd_en;
    
    fifo_66_66 i_fifo_66_66_clk2(
        .rst            ( rst                       ),
        .wr_clk         ( clk_fifo                  ),
        .rd_clk         ( clk                       ),
        .din            ( pcie_tlp_tx_din           ),
        .wr_en          ( pcie_tlp_tx_wren          ),
        .rd_en          ( tlp_din_rd_en             ),
        .dout           ( tlp_din                   ),
        .almost_full    (                           ),
        .full           (                           ),
        .empty          (                           ),
        .valid          ( tlp_din_valid             )
    );
 
    reg [66 * 18 - 1 : 0]   tlp             = 0;
    reg [10:0]              tlp_base        = 0;
    reg                     tlp_complete    = 0;
    reg                     tlp_error       = 0;
    reg                     tlp_valid       = 0;
    
    assign tlp_din_rd_en = ~tlp_complete & ~(tlp_din_valid & tlp_din[64]);
    
    assign tlp_out.data = tlp;
    assign tlp_out.valid = tlp_valid;
    assign tlp_out.has_data = tlp_complete;
    
    always @ ( posedge clk )
        if ( rst | tlp_valid | (tlp_error & tlp_din[64]) )
            begin
                tlp <= 0;
                tlp_base <= 0;
                tlp_complete <= 0;
                tlp_error <= 0;
                tlp_valid <= 0;
            end
        else
            begin
                if ( tlp_complete & tlp_out.req_data )
                    tlp_valid <= 1'b1;
                if ( tlp_din_valid & ~tlp_error )
                    begin
                        tlp[tlp_base+:66] <= tlp_din;
                        if ( tlp_din[64] )
                            tlp_complete <= 1'b1;
                        else if ( tlp_base == 66 * 17 )
                            tlp_error <= 1'b1;
                        else
                            tlp_base <= tlp_base + 66;
                    end
            end

endmodule
