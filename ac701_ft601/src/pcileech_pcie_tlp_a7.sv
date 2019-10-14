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
    IfPCIeTlpFifo.mp_pcie   dfifo,
    
    // PCIe core transmit data (s_axis)
    output  [63:0]          s_axis_tx_tdata,
    output  [7:0]           s_axis_tx_tkeep,
    output                  s_axis_tx_tlast,
    input                   s_axis_tx_tready,
    output                  s_axis_tx_tvalid,
    
    // PCIe core receive data (m_axis)
    input   [63:0]          m_axis_rx_tdata,
    input   [7:0]           m_axis_rx_tkeep,
    input                   m_axis_rx_tlast,
    output                  m_axis_rx_tready,
    input                   m_axis_rx_tvalid
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
    
    assign pcie_tlp_rx_din[31:0] = m_axis_rx_tdata[63:32];
    assign pcie_tlp_rx_din[32] = m_axis_rx_tlast;
    assign pcie_tlp_rx_din[33] = m_axis_rx_tkeep[7];
    assign pcie_tlp_rx_din[65:34] = m_axis_rx_tdata[31:0];
    assign pcie_tlp_rx_din[66] = m_axis_rx_tlast & ~m_axis_rx_tkeep[7];
    assign pcie_tlp_rx_din[67] = 1'b1;
    assign m_axis_rx_tready = ~pcie_tlp_rx_almost_full;
   
    fifo_68_34 i_fifo_pcie_tlp_rx(
        .rst            ( rst                       ),
        .wr_clk         ( clk_pcie                  ),
        .rd_clk         ( clk_100                   ),
        .din            ( pcie_tlp_rx_din           ),
        .wr_en          ( m_axis_rx_tvalid          ),
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
    // Convert received TLP data from FT601 to PCIe transmit data.
    // FIFO depth: 512 / 64-bits (for data).
    // ----------------------------------------------------------------------------

    // data ( pcie_tlp_tx_din / pcie_tlp_tx_dout ) as follows:
    // pcie_tlp_tx_din[31:0]  = 1st DWORD
    // pcie_tlp_tx_din[63:32] = 2nd DWORD
    // pcie_tlp_tx_din[64]    = Last DWORD in TLP
    // pcie_tlp_tx_din[65]    = 2nd DWORD is valid
    wire [65:0]     pcie_tlp_tx_din;
    wire [65:0]     pcie_tlp_tx_dout;
    wire            pcie_tlp_tx_wren;
    reg [31:0]      d_pcie_tlp_tx_data;
    reg             d_pcie_tlp_tx_valid = 1'b0;
    
    assign pcie_tlp_tx_din[31:0] = d_pcie_tlp_tx_valid ? d_pcie_tlp_tx_data : dfifo.tx_data;
    assign pcie_tlp_tx_din[63:32] = dfifo.tx_data;
    assign pcie_tlp_tx_din[64] = dfifo.tx_last;
    assign pcie_tlp_tx_din[65] = d_pcie_tlp_tx_valid;
    assign pcie_tlp_tx_wren = dfifo.tx_valid & ( dfifo.tx_last | d_pcie_tlp_tx_valid );
    
    always @ ( posedge clk_100 )
        if( rst )
            d_pcie_tlp_tx_valid <= 1'b0;
        else if ( dfifo.tx_valid )
            begin
                d_pcie_tlp_tx_data <= dfifo.tx_data;
                d_pcie_tlp_tx_valid <= ~pcie_tlp_tx_wren;
            end
    
    fifo_66_66 i_fifo_pcie_tlp_tx(
        .rst            ( rst                       ),
        .wr_clk         ( clk_100                   ),
        .rd_clk         ( clk_pcie                  ),
        .din            ( pcie_tlp_tx_din           ),
        .wr_en          ( pcie_tlp_tx_wren          ),
        .rd_en          ( s_axis_tx_tready          ),
        .dout           ( pcie_tlp_tx_dout          ),
        .full           (                           ),
        .empty          (                           ),
        .valid          ( s_axis_tx_tvalid          )
    );
    
    assign s_axis_tx_tdata = pcie_tlp_tx_dout[63:0];
    assign s_axis_tx_tkeep[3:0] = 4'hf;
    assign s_axis_tx_tkeep[7:4] = pcie_tlp_tx_dout[65] ? 4'hf : 4'h0;
    assign s_axis_tx_tlast = pcie_tlp_tx_dout[64];

endmodule
