//
// PCILeech FPGA.
//
// PCIe controller module - TLP handling for Artix-7.
//
// (c) Ulf Frisk, 2018-2020
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
    IfTlp64.sink            tlp_static,
    IfFifo2CfgSpace.sink    dcfgspacewr
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
    // pcie_tlp_rx_suppress   = CfgRdWr packets may optionally kept by logic (not forwarded to rx fifo)
    wire [67:0]     pcie_tlp_rx_din;
    wire            pcie_tlp_rx_almost_full;
    wire [33:0]     pcie_tlp_rx_dout;
    wire            pcie_tlp_rx_dout_i;
    wire            pcie_tlp_rx_filter;
    
    assign pcie_tlp_rx_din[31:0] = tlp_rx.data[63:32];
    assign pcie_tlp_rx_din[32] = tlp_rx.last;
    assign pcie_tlp_rx_din[33] = tlp_rx.keep[7];
    assign pcie_tlp_rx_din[65:34] = tlp_rx.data[31:0];
    assign pcie_tlp_rx_din[66] = tlp_rx.last & ~tlp_rx.keep[7];
    assign pcie_tlp_rx_din[67] = 1'b1;
    assign tlp_rx.ready = ~pcie_tlp_rx_almost_full;
   
    fifo_68_34 i_fifo_pcie_tlp_rx (
        .rst            ( rst                       ),
        .wr_clk         ( clk_pcie                  ),
        .rd_clk         ( clk_100                   ),
        .din            ( pcie_tlp_rx_din           ),
        .wr_en          ( tlp_rx.valid & ~pcie_tlp_rx_filter  ),
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
    
    // ------------------------------------------------------------------------
    // PCIe configuration space implementation - snoop received TLPs from PCIe
    // fore for configuration space read requests and forward them onto module
    // for configuration space.
    // ------------------------------------------------------------------------
    IfTlp16 tlp_cpl_cfgspace();
    
    pcileech_pcie_cfgspace i_pcileech_pcie_cfgspace (
        .rst            ( rst                       ),
        .clk            ( clk_pcie                  ),
        .tlp_rx         ( tlp_rx                    ),
        .tlp_tx         ( tlp_cpl_cfgspace          ),
        .tlp_pcie_id    ( cfg_tlpcfg.tlp_pcie_id    ),
        .tlp_pcie_filter ( pcie_tlp_rx_filter       ),
        .dcfgspacewr    ( dcfgspacewr               )
    );
        
    // ------------------------------------------------------------------------
    // TX data received from FIFO
    // ------------------------------------------------------------------------
    IfTlp128 fifo_tlp();
    
    tlp128_source_fifo i_tlp128_source_fifo(
        .clk_fifo       ( clk_100                   ),
        .clk            ( clk_pcie                  ),
        .rst            ( rst                       ),
        .dfifo_tx_data  ( dfifo.tx_data             ),
        .dfifo_tx_last  ( dfifo.tx_last             ),
        .dfifo_tx_valid ( dfifo.tx_valid            ),
        .tlp_out        ( fifo_tlp                  )
    );
    
    tlp128_sink_mux1 i_tlp128_sink_mux1(
        .clk            ( clk_pcie                  ),
        .rst            ( rst                       ),
        .tlp_tx         ( tlp_tx                    ),
        .p0             ( fifo_tlp                  ),
        .p1             ( tlp_cpl_cfgspace          ),
        .p2             ( tlp_static                ),
        .pX_en          ( cfg_tlpcfg.tlp_tx_en      )
    );

endmodule



module pcileech_pcie_cfgspace(
    input                   rst,
    input                   clk,                // 62.5MHz (PCIe CLK)
    
    IfPCIeTlpRxTx.sink      tlp_rx,
    IfTlp16.source          tlp_tx,
    IfFifo2CfgSpace.sink    dcfgspacewr,
    
    input   [15:0]          tlp_pcie_id,        // PCIe id of this core
    output                  tlp_pcie_filter     // do not forward TLP QWORD to user application
    );
    
    // ------------------------------------------------------------------------
    // INCOMING data to pcie config space - snooped from main TLP AXI stream
    // only act on valid configuration space requests. Read requests should be
    // turned into BRAM read requests.
    // ------------------------------------------------------------------------
    bit  [63:0]     snoop_data_first;   
    wire            snoop_next_first_n = ~rst & tlp_rx.valid & ~tlp_rx.last;      // Next QWORD may be 1st in CfgRdWr TLP. 
    bit             snoop_first_n   = 1'b0;
    bit             snoop_error     = 1'b0;
    wire [127:0]    snoop_data      = { tlp_rx.data, snoop_data_first };
    wire [9:0]      snoop_addr_dw   = snoop_data[75:66];
    wire [7:0]      snoop_tag       = snoop_data[47:40];
    wire [15:0]     snoop_requester_id = snoop_data[63:48];
    wire            snoop_valid_rdwr = dcfgspacewr.cfgtlp_en & 
                                    ~rst & tlp_rx.valid & tlp_rx.last & ~snoop_error & ~tlp_rx.keep[7] &
                                    (snoop_data[39:36] == 4'b0000) &            // Last DW BE[3:0] == 0000b
                                    (snoop_data[22:20] == 3'b000) &             // TC[2:0] == 000b
                                    (snoop_data[13:00] == 14'b00000000000001);  // LENGTH = 0000000001b, AT=00b, Attr = 00b
    wire            snoop_valid_rd = snoop_valid_rdwr & 
                                    (snoop_data[31:25] == 7'b0000010);          // Fmt[2:0]=000b (3 DW header, no data), CfgRd0/CfgRd1=0010xb
    wire            snoop_valid_wr = snoop_valid_rdwr & 
                                    (snoop_data[31:25] == 7'b0100010);          // Fmt[2:0]=010b (3 DW header, data), CfgWr0/CfgWr1=0010xb
    // Filter / suppress forwarding of received CfgRdWr TLP packets to user application.
    // This is done to avoid too many config TLPs to be received w/o reading them -
    // since that will clog up the buffers and may cause target OS to freeze.
    bit             cfgtlp_filter         = 1'b0;
    wire            cfgtlp_filter_snoop   = ~snoop_first_n & (tlp_rx.data[29:25] == 5'b00010);  // fast detect cfg packet - Fmt[2:0]=xx0b, CfgRdWr0/CfgRdWr1=0010xb
    assign          tlp_pcie_filter       = dcfgspacewr.filter_en & (cfgtlp_filter | cfgtlp_filter_snoop);

    always @ ( posedge clk )
        begin
            snoop_data_first    <= tlp_rx.data;
            snoop_first_n       <= snoop_next_first_n;
            snoop_error         <= snoop_next_first_n & snoop_first_n;
            cfgtlp_filter       <= snoop_next_first_n & tlp_pcie_filter;
        end

    // ------------------------------------------------------------------------
    // READ/WRITE configuration space to/from BRAM memory. 
    // READ takes two CLK on port B.
    // ------------------------------------------------------------------------
    bit             bram_valid;             // bram valid
    bit             bram_supress_onwr;      // bram supress (= Cpl packet on Wr)
    bit [7:0]       bram_tag;
    bit [15:0]      bram_requester_id;
    wire [31:0]     bram_data1;
    wire [31:0]     bram_data2 = dcfgspacewr.cfgtlp_zero ? 32'h00000000 : bram_data1;
                                    
    bram_pcie_cfgspace i_bram_pcie_cfgspace(
        .clka           ( dcfgspacewr.clk           ),
        .addra          ( dcfgspacewr.addr          ),
        .dina           ( dcfgspacewr.data          ),
        .ena            ( dcfgspacewr.wren          ),
        .wea            ( 1'b1                      ),
        .clkb           ( clk                       ),
        .addrb          ( snoop_addr_dw             ),
        .doutb          ( bram_data1                )
    );
 
    always @ ( posedge clk )
        begin
            bram_valid          <= snoop_valid_rd;
            bram_supress_onwr   <= snoop_valid_wr;
            bram_tag            <= snoop_tag;
            bram_requester_id   <= snoop_requester_id;
        end
 
    // ------------------------------------------------------------------------
    // COMPLETION TLP generation and buffering below: 
    // ------------------------------------------------------------------------
    wire [63:0]     cplrd_tlp_data_qw1  = { tlp_pcie_id, 16'h0004, 32'b01001010000000000000000000000001 };
    wire [63:0]     cplrd_tlp_data_qw2  = { bram_data2, bram_requester_id, bram_tag, 8'h00 };
    wire [127:0]    cplrd_tlp_data      = { cplrd_tlp_data_qw2, cplrd_tlp_data_qw1 };
    wire [63:0]     cplwr_tlp_data_qw1  = { tlp_pcie_id, 16'h00, 32'b00001010000000000000000000000000 };
    wire [63:0]     cplwr_tlp_data_qw2  = { 32'h00000000, bram_requester_id, bram_tag, 8'h00 };
    wire [127:0]    cplwr_tlp_data      = { cplwr_tlp_data_qw2, cplwr_tlp_data_qw1 };
    wire [128:0]    cpl_tlp_data        = { bram_valid, (bram_valid ? cplrd_tlp_data : cplwr_tlp_data)};
    
    wire [128:0]    txcpl_tlp_data;
    wire            txcpl_tlp_empty;
    
    fifo_128_128_clk1_cfgspace i_fifo_128_128_clk1_cfgspace (
        .srst           ( rst                       ),
        .clk            ( clk                       ),
        .din            ( cpl_tlp_data              ),
        .wr_en          ( bram_valid | bram_supress_onwr ),
        .rd_en          ( tlp_tx.req_data           ),
        .dout           ( txcpl_tlp_data            ),
        .full           (                           ),
        .empty          ( txcpl_tlp_empty           ),
        .valid          ( tlp_tx.valid              )
    );
    
    assign tlp_tx.has_data = ~txcpl_tlp_empty;
    assign tlp_tx.data = {txcpl_tlp_data[128], 1'b1, txcpl_tlp_data[127:64], 2'b10, txcpl_tlp_data[63:0]};

endmodule



module tlp128_sink_mux1 (
    input                   clk,
    input                   rst,
    IfPCIeTlpRxTx.source    tlp_tx,
    IfTlp128.sink           p0,
    IfTlp16.sink            p1,
    IfTlp64.sink            p2,
    input   [2:0]           pX_en
);
    reg [66 * 18 - 1 : 0]   tlp     = 0;
    
    wire req_data = ~tlp[64] & ~tlp[65] & ~p0.valid & ~p1.valid & ~p2.valid; 
    assign p0.req_data = req_data & pX_en[0] & p0.has_data;
    assign p1.req_data = req_data & pX_en[1] & p1.has_data & ~p0.req_data;
    assign p2.req_data = req_data & pX_en[2] & p2.has_data & ~p0.req_data & ~p1.req_data;
    
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
        else if ( p2.valid )
            tlp <= p2.data;
        else if ( tlp_tx.ready )
            tlp <= (tlp >> 66);
            
endmodule



module tlp128_source_fifo (
    input                   clk_fifo,
    input                   clk,
    input                   rst,
    input [31:0]            dfifo_tx_data,
    input                   dfifo_tx_last,
    input                   dfifo_tx_valid,
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
    
    assign pcie_tlp_tx_din[31:0] = d_pcie_tlp_tx_valid ? d_pcie_tlp_tx_data : dfifo_tx_data;
    assign pcie_tlp_tx_din[63:32] = dfifo_tx_data;
    assign pcie_tlp_tx_din[64] = dfifo_tx_last;
    assign pcie_tlp_tx_din[65] = d_pcie_tlp_tx_valid;
    assign pcie_tlp_tx_wren = dfifo_tx_valid & ( dfifo_tx_last | d_pcie_tlp_tx_valid );
    
    always @ ( posedge clk_fifo )
        if( rst )
            d_pcie_tlp_tx_valid <= 1'b0;
        else if ( dfifo_tx_valid )
            begin
                d_pcie_tlp_tx_data <= dfifo_tx_data;
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
