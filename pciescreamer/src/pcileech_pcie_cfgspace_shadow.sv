//
// PCILeech FPGA.
//
// PCIe custom shadow configuration space.
// Xilinx PCIe core will take configuration space priority; if Xilinx PCIe core
// is configured to forward configuration requests to user application such TLP
// will end up being processed by this module.
//
// (c) Ulf Frisk, 2020
// Author: Ulf Frisk, pcileech@frizk.net
//

`timescale 1ns / 1ps

module pcileech_pcie_cfgspace_shadow(
    input                   rst,
    input                   clk,
    IfShadow2Fifo.src       dshadow2fifo,
    IfShadow2Tlp.shadow     dshadow2tlp
    );
    
    wire            int_rden;
    wire            int_wren;
    wire [9:0]      int_wr_addr;
    wire [31:0]     int_wr_data;
    wire [9:0]      int_rd_addr;
    
    // ----------------------------------------------------------------------------
    // WRITE multiplexor: simple naive multiplexor which will prioritize in order:
    // (1) PCIe (if enabled), (2) USB, (3) INTERNAL.
    // Collisions will be discarded (it's assumed that they'll be very rare)
    // ----------------------------------------------------------------------------
    wire            bram_wr_1_tlp = dshadow2tlp.rx_wren;
    wire            bram_wr_2_usb = ~bram_wr_1_tlp & dshadow2fifo.rx_wren;
    wire            bram_wr_3_int = ~bram_wr_1_tlp & ~bram_wr_2_usb & int_wren;
    wire [3:0]      bram_wr_be = bram_wr_1_tlp ? (dshadow2fifo.cfgtlp_wren ? dshadow2tlp.rx_be : 4'b0000) : (bram_wr_2_usb ? dshadow2fifo.rx_be : (bram_wr_3_int ? 4'b1111 : 4'b0000));
    wire [9:0]      bram_wr_addr = bram_wr_1_tlp ? dshadow2tlp.rx_addr : (bram_wr_2_usb ? dshadow2fifo.rx_addr : int_wr_addr);
    wire [31:0]     bram_wr_data = bram_wr_1_tlp ? dshadow2tlp.rx_data : (bram_wr_2_usb ? dshadow2fifo.rx_data : int_wr_data);
    
    // ----------------------------------------------------------------------------
    // WRITE multiplexor and state machine: simple naive multiplexor which will prioritize in order:
    // (1) PCIe (if enabled), (2) USB, (3) INTERNAL.
    // Collisions will be discarded (it's assumed that they'll be very rare)
    // ----------------------------------------------------------------------------
    `define S_SHADOW_CFGSPACE_IDLE  2'b00
    `define S_SHADOW_CFGSPACE_TLP   2'b01
    `define S_SHADOW_CFGSPACE_USB   2'b10
    `define S_SHADOW_CFGSPACE_INT   2'b11
    
    wire [31:0]     bram_rd_data;
    wire            bram_rd_1_tlp = dshadow2tlp.rx_rden;
    wire            bram_rd_2_usb = ~bram_rd_1_tlp & dshadow2fifo.rx_rden;
    wire            bram_rd_3_int = ~bram_rd_1_tlp & ~bram_rd_2_usb & int_rden;
    wire [1:0]      bram_rd_tp_3 =   bram_rd_1_tlp ? `S_SHADOW_CFGSPACE_TLP : (
                                     bram_rd_2_usb ? `S_SHADOW_CFGSPACE_USB : (
                                     bram_rd_3_int ? `S_SHADOW_CFGSPACE_INT : `S_SHADOW_CFGSPACE_IDLE));
    wire [9:0]      bram_rd_addr_3 = bram_rd_1_tlp ? dshadow2tlp.rx_addr : (
                                     bram_rd_2_usb ? dshadow2fifo.rx_addr : int_rd_addr);
    wire [7:0]      bram_rd_tag_3 =  bram_rd_1_tlp ? dshadow2tlp.rx_tag : {7'h00, dshadow2fifo.rx_addr_lo};
    bit [9:0]       bram_rd_addr, bram_rd_addr_2;
    bit [7:0]       bram_rd_tag,  bram_rd_tag_2;
    bit [1:0]       bram_rd_tp,   bram_rd_tp_2;    
    
    always @ ( posedge clk )
        begin
            bram_rd_addr    <= bram_rd_addr_2;
            bram_rd_tag     <= bram_rd_tag_2;
            bram_rd_tp      <= bram_rd_tp_2;
            bram_rd_addr_2  <= bram_rd_addr_3;
            bram_rd_tag_2   <= bram_rd_tag_3;
            bram_rd_tp_2    <= bram_rd_tp_3;
        end
    
    // BRAM MEMORY ACCESS for the 4kB / 0x1000 byte shadow configuration space.
    bram_pcie_cfgspace i_bram_pcie_cfgspace(
        .clka           ( clk                       ),
        .clkb           ( clk                       ),
        .wea            ( bram_wr_be                ),
        .addra          ( bram_wr_addr              ),
        .dina           ( bram_wr_data              ),
        .addrb          ( bram_rd_addr_3            ),
        .doutb          ( bram_rd_data              )
    );
    
    assign dshadow2tlp.tx_valid     = bram_wr_1_tlp | (bram_rd_tp == `S_SHADOW_CFGSPACE_TLP);
    assign dshadow2tlp.tx_tlprd     = ~bram_wr_1_tlp;
    assign dshadow2tlp.tx_tag       = bram_wr_1_tlp ? dshadow2tlp.rx_tag : bram_rd_tag;
    assign dshadow2tlp.tx_data      = dshadow2fifo.cfgtlp_zero ? 32'h00000000 : bram_rd_data;
    
    assign dshadow2fifo.tx_valid    = (bram_rd_tp == `S_SHADOW_CFGSPACE_USB);
    assign dshadow2fifo.tx_addr     = bram_rd_addr;
    assign dshadow2fifo.tx_addr_lo  = bram_rd_tag[0];
    assign dshadow2fifo.tx_data     = dshadow2fifo.cfgtlp_zero ? 32'h00000000 : bram_rd_data;
    
    // ----------------------------------------------------------------------------
    // INTERNAL LOGIC BELOW:
    // ----------------------------------------------------------------------------
    
    assign int_rden     = 0;
    assign int_wren     = 0;
    assign int_wr_addr  = 0;
    assign int_wr_data  = 0;
    assign int_rd_addr  = 0;
    
endmodule
