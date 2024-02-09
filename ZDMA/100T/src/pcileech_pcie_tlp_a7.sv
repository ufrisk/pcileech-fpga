//
// PCILeech FPGA.
//
// PCIe controller module - TLP handling for Artix-7.
//
// (c) Ulf Frisk, 2018-2024
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps
`include "pcileech_header.svh"

module pcileech_pcie_tlp_a7(
    input                   rst,
    input                   clk_pcie,
    input                   clk_sys,
    IfPCIeFifoTlp.mp_pcie   dfifo,
    
    // PCIe core receive/transmit data
    IfAXIS128.source        tlps_tx,
    IfAXIS128.sink_lite     tlps_rx,
    IfAXIS128.sink          tlps_static,
    IfShadow2Fifo.shadow    dshadow2fifo,
    input [15:0]            pcie_id
    );
    
    IfAXIS128 tlps_bar_rsp();
    IfAXIS128 tlps_cfg_rsp();
    
    // ------------------------------------------------------------------------
    // Convert received TLPs from PCIe core and transmit onwards:
    // ------------------------------------------------------------------------
    IfAXIS128 tlps_filtered();
    
    pcileech_tlps128_bar_controller i_pcileech_tlps128_bar_controller(
        .rst            ( rst                           ),
        .clk            ( clk_pcie                      ),
        .bar_en         ( dshadow2fifo.bar_en           ),
        .pcie_id        ( pcie_id                       ),
        .tlps_in        ( tlps_rx                       ),
        .tlps_out       ( tlps_bar_rsp.source           )
    );
    
    pcileech_tlps128_cfgspace_shadow i_pcileech_tlps128_cfgspace_shadow(
        .rst            ( rst                           ),
        .clk_pcie       ( clk_pcie                      ),
        .clk_sys        ( clk_sys                       ),
        .tlps_in        ( tlps_rx                       ),
        .pcie_id        ( pcie_id                       ),
        .dshadow2fifo   ( dshadow2fifo                  ),
        .tlps_cfg_rsp   ( tlps_cfg_rsp.source           )
    );
    
    pcileech_tlps128_filter i_pcileech_tlps128_filter(
        .rst            ( rst                           ),
        .clk_pcie       ( clk_pcie                      ),
        .alltlp_filter  ( dshadow2fifo.alltlp_filter    ),
        .cfgtlp_filter  ( dshadow2fifo.cfgtlp_filter    ),
        .tlps_in        ( tlps_rx                       ),
        .tlps_out       ( tlps_filtered.source_lite     )
    );
    
    pcileech_tlps128_dst_fifo i_pcileech_tlps128_dst_fifo(
        .rst            ( rst                           ),
        .clk_pcie       ( clk_pcie                      ),
        .clk_sys        ( clk_sys                       ),
        .tlps_in        ( tlps_filtered.sink_lite       ),
        .dfifo          ( dfifo                         )
    );
    
    // ------------------------------------------------------------------------
    // TX data received from FIFO
    // ------------------------------------------------------------------------
    IfAXIS128 tlps_rx_fifo();
    
    pcileech_tlps128_src_fifo i_pcileech_tlps128_src_fifo(
        .rst            ( rst                           ),
        .clk_pcie       ( clk_pcie                      ),
        .clk_sys        ( clk_sys                       ),
        .dfifo_tx_data  ( dfifo.tx_data                 ),
        .dfifo_tx_last  ( dfifo.tx_last                 ),
        .dfifo_tx_valid ( dfifo.tx_valid                ),
        .tlps_out       ( tlps_rx_fifo.source           )
    );
    
    pcileech_tlps128_sink_mux1 i_pcileech_tlps128_sink_mux1(
        .rst            ( rst                           ),
        .clk_pcie       ( clk_pcie                      ),
        .tlps_out       ( tlps_tx                       ),
        .tlps_in1       ( tlps_cfg_rsp.sink             ),
        .tlps_in2       ( tlps_bar_rsp.sink             ),
        .tlps_in3       ( tlps_rx_fifo.sink             ),
        .tlps_in4       ( tlps_static                   )
    );

endmodule



// ------------------------------------------------------------------------
// TLP-AXI-STREAM destination:
// Forward the data to output device (FT601, etc.). 
// ------------------------------------------------------------------------
module pcileech_tlps128_dst_fifo(
    input                   rst,
    input                   clk_pcie,
    input                   clk_sys,
    IfAXIS128.sink_lite     tlps_in,
    IfPCIeFifoTlp.mp_pcie   dfifo
);
    
    wire         tvalid;
    wire [127:0] tdata;
    wire [3:0]   tkeepdw;
    wire         tlast;
    wire         first;
       
    fifo_134_134_clk2 i_fifo_134_134_clk2 (
        .rst        ( rst               ),
        .wr_clk     ( clk_pcie          ),
        .rd_clk     ( clk_sys           ),
        .din        ( { tlps_in.tuser[0], tlps_in.tlast, tlps_in.tkeepdw, tlps_in.tdata } ),
        .wr_en      ( tlps_in.tvalid    ),
        .rd_en      ( dfifo.rx_rd_en    ),
        .dout       ( { first, tlast, tkeepdw, tdata } ),
        .full       (                   ),
        .empty      (                   ),
        .valid      ( tvalid            )
    );

    assign dfifo.rx_data[0]  = tdata[31:0];
    assign dfifo.rx_data[1]  = tdata[63:32];
    assign dfifo.rx_data[2]  = tdata[95:64];
    assign dfifo.rx_data[3]  = tdata[127:96];
    assign dfifo.rx_first[0] = first;
    assign dfifo.rx_first[1] = 0;
    assign dfifo.rx_first[2] = 0;
    assign dfifo.rx_first[3] = 0;
    assign dfifo.rx_last[0]  = tlast && (tkeepdw == 4'b0001);
    assign dfifo.rx_last[1]  = tlast && (tkeepdw == 4'b0011);
    assign dfifo.rx_last[2]  = tlast && (tkeepdw == 4'b0111);
    assign dfifo.rx_last[3]  = tlast && (tkeepdw == 4'b1111);
    assign dfifo.rx_valid[0] = tvalid && tkeepdw[0];
    assign dfifo.rx_valid[1] = tvalid && tkeepdw[1];
    assign dfifo.rx_valid[2] = tvalid && tkeepdw[2];
    assign dfifo.rx_valid[3] = tvalid && tkeepdw[3];

endmodule



// ------------------------------------------------------------------------
// TLP-AXI-STREAM FILTER:
// Filter away certain packet types such as CfgRd/CfgWr or non-Cpl/CplD
// ------------------------------------------------------------------------
module pcileech_tlps128_filter(
    input                   rst,
    input                   clk_pcie,
    input                   alltlp_filter,
    input                   cfgtlp_filter,
    IfAXIS128.sink_lite     tlps_in,
    IfAXIS128.source_lite   tlps_out
);

    bit [127:0]     tdata;
    bit [3:0]       tkeepdw;
    bit             tvalid  = 0;
    bit [8:0]       tuser;
    bit             tlast;
    
    assign tlps_out.tdata   = tdata;
    assign tlps_out.tkeepdw = tkeepdw;
    assign tlps_out.tvalid  = tvalid;
    assign tlps_out.tuser   = tuser;
    assign tlps_out.tlast   = tlast;
    
    bit  filter = 0;
    wire first = tlps_in.tuser[0];
    wire is_tlphdr_cpl = first && (
                        (tlps_in.tdata[31:25] == 7'b0000101) ||      // Cpl:  Fmt[2:0]=000b (3 DW header, no data), Cpl=0101xb
                        (tlps_in.tdata[31:25] == 7'b0100101)         // CplD: Fmt[2:0]=010b (3 DW header, data),    CplD=0101xb
                      );
    wire is_tlphdr_cfg = first && (
                        (tlps_in.tdata[31:25] == 7'b0000010) ||      // CfgRd: Fmt[2:0]=000b (3 DW header, no data), CfgRd0/CfgRd1=0010xb
                        (tlps_in.tdata[31:25] == 7'b0100010)         // CfgWr: Fmt[2:0]=010b (3 DW header, data),    CfgWr0/CfgWr1=0010xb
                      );
    wire filter_next = (filter && !first) || (cfgtlp_filter && first && is_tlphdr_cfg) || (alltlp_filter && first && !is_tlphdr_cpl && !is_tlphdr_cfg);
                      
    always @ ( posedge clk_pcie ) begin
        tdata   <= tlps_in.tdata;
        tkeepdw <= tlps_in.tkeepdw;
        tvalid  <= tlps_in.tvalid && !filter_next && !rst;
        tuser   <= tlps_in.tuser;
        tlast   <= tlps_in.tlast;
        filter  <= filter_next && !rst;
    end
    
endmodule



// ------------------------------------------------------------------------
// RX FROM FIFO - TLP-AXI-STREAM:
// Convert 32-bit incoming data to 128-bit TLP-AXI-STREAM to be sent onwards to mux/pcie core. 
// ------------------------------------------------------------------------
module pcileech_tlps128_src_fifo (
    input                   rst,
    input                   clk_pcie,
    input                   clk_sys,
    input [31:0]            dfifo_tx_data,
    input                   dfifo_tx_last,
    input                   dfifo_tx_valid,
    IfAXIS128.source        tlps_out
);

    // 1: 32-bit -> 128-bit state machine:
    bit [127:0] tdata;
    bit [3:0]   tkeepdw = 0;
    bit         tlast;
    bit         first   = 1;
    wire        tvalid  = tlast || tkeepdw[3];
    
    always @ ( posedge clk_sys )
        if ( rst ) begin
            tkeepdw <= 0;
            tlast   <= 0;
            first   <= 1;
        end
        else begin
            tlast   <= dfifo_tx_valid && dfifo_tx_last;
            tkeepdw <= tvalid ? (dfifo_tx_valid ? 4'b0001 : 4'b0000) : (dfifo_tx_valid ? ((tkeepdw << 1) | 1'b1) : tkeepdw);
            first   <= tvalid ? tlast : first;
            if ( dfifo_tx_valid ) begin
                if ( tvalid || !tkeepdw[0] )
                    tdata[31:0]   <= dfifo_tx_data;
                if ( !tkeepdw[1] )
                    tdata[63:32]  <= dfifo_tx_data;
                if ( !tkeepdw[2] )
                    tdata[95:64]  <= dfifo_tx_data;
                if ( !tkeepdw[3] )
                    tdata[127:96] <= dfifo_tx_data;   
            end
        end
		
    // 2.1 - packet count (w/ safe fifo clock-crossing).
    bit [10:0]  pkt_count       = 0;
    wire        pkt_count_dec   = tlps_out.tvalid && tlps_out.tlast;
    wire        pkt_count_inc;
    wire [10:0] pkt_count_next  = pkt_count + pkt_count_inc - pkt_count_dec;
    assign tlps_out.has_data    = (pkt_count_next > 0);
    
    fifo_1_1_clk2 i_fifo_1_1_clk2(
        .rst            ( rst                       ),
        .wr_clk         ( clk_sys                   ),
        .rd_clk         ( clk_pcie                  ),
        .din            ( 1'b1                      ),
        .wr_en          ( tvalid && tlast           ),
        .rd_en          ( 1'b1                      ),
        .dout           (                           ),
        .full           (                           ),
        .empty          (                           ),
        .valid          ( pkt_count_inc             )
    );
	
    always @ ( posedge clk_pcie ) begin
        pkt_count <= rst ? 0 : pkt_count_next;
    end
        
    // 2.2 - submit to output fifo - will feed into mux/pcie core.
    //       together with 2.1 this will form a low-latency "packet fifo".
    fifo_134_134_clk2_rxfifo i_fifo_134_134_clk2_rxfifo(
        .rst            ( rst                       ),
        .wr_clk         ( clk_sys                   ),
        .rd_clk         ( clk_pcie                  ),
        .din            ( { first, tlast, tkeepdw, tdata } ),
        .wr_en          ( tvalid                    ),
        .rd_en          ( tlps_out.tready && (pkt_count_next > 0) ),
        .dout           ( { tlps_out.tuser[0], tlps_out.tlast, tlps_out.tkeepdw, tlps_out.tdata } ),
        .full           (                           ),
        .empty          (                           ),
        .valid          ( tlps_out.tvalid           )
    );

endmodule



// ------------------------------------------------------------------------
// RX MUX - TLP-AXI-STREAM:
// Select the TLP-AXI-STREAM with the highest priority (lowest number) and
// let it transmit its full packet.
// Each incoming stream must have latency of 1CLK. 
// ------------------------------------------------------------------------
module pcileech_tlps128_sink_mux1 (
    input                       clk_pcie,
    input                       rst,
    IfAXIS128.source            tlps_out,
    IfAXIS128.sink              tlps_in1,
    IfAXIS128.sink              tlps_in2,
    IfAXIS128.sink              tlps_in3,
    IfAXIS128.sink              tlps_in4
);
    bit [2:0] id = 0;
    
    assign tlps_out.has_data    = tlps_in1.has_data || tlps_in2.has_data || tlps_in3.has_data || tlps_in4.has_data;
    
    assign tlps_out.tdata       = (id==1) ? tlps_in1.tdata :
                                  (id==2) ? tlps_in2.tdata :
                                  (id==3) ? tlps_in3.tdata :
                                  (id==4) ? tlps_in4.tdata : 0;
    
    assign tlps_out.tkeepdw     = (id==1) ? tlps_in1.tkeepdw :
                                  (id==2) ? tlps_in2.tkeepdw :
                                  (id==3) ? tlps_in3.tkeepdw :
                                  (id==4) ? tlps_in4.tkeepdw : 0;
    
    assign tlps_out.tlast       = (id==1) ? tlps_in1.tlast :
                                  (id==2) ? tlps_in2.tlast :
                                  (id==3) ? tlps_in3.tlast :
                                  (id==4) ? tlps_in4.tlast : 0;
    
    assign tlps_out.tuser       = (id==1) ? tlps_in1.tuser :
                                  (id==2) ? tlps_in2.tuser :
                                  (id==3) ? tlps_in3.tuser :
                                  (id==4) ? tlps_in4.tuser : 0;
    
    assign tlps_out.tvalid      = (id==1) ? tlps_in1.tvalid :
                                  (id==2) ? tlps_in2.tvalid :
                                  (id==3) ? tlps_in3.tvalid :
                                  (id==4) ? tlps_in4.tvalid : 0;
    
    wire [2:0] id_next_newsel   = tlps_in1.has_data ? 1 :
                                  tlps_in2.has_data ? 2 :
                                  tlps_in3.has_data ? 3 :
                                  tlps_in4.has_data ? 4 : 0;
    
    wire [2:0] id_next          = ((id==0) || (tlps_out.tvalid && tlps_out.tlast)) ? id_next_newsel : id;
    
    assign tlps_in1.tready      = tlps_out.tready && (id_next==1);
    assign tlps_in2.tready      = tlps_out.tready && (id_next==2);
    assign tlps_in3.tready      = tlps_out.tready && (id_next==3);
    assign tlps_in4.tready      = tlps_out.tready && (id_next==4);
    
    always @ ( posedge clk_pcie ) begin
        id <= rst ? 0 : id_next;
    end
    
endmodule
