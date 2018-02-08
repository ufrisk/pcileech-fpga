//
// PCILeech FPGA.
//
// PCIe configuration module - CFG handling for Artix-7.
//
// (c) Ulf Frisk, 2018
// Author: Ulf Frisk, pcileech@frizk.net
//

module pcileech_pcie_cfg_a7(
    input               rst,
    input               clk,                 // 100MHz
    input               clk_pcie,            // 62.5(x1)-250(x4)MHz
    
    // incoming from "FIFO" (must always be able to receive data, otherwise dropped)
    input       [63:0]  pcie_cfg_tx_data,
    input               pcie_cfg_tx_valid,
    
    // outgoing to "FIFO"
    output      [31:0]  pcie_cfg_rx_data,
    output              pcie_cfg_rx_valid,
    output              pcie_cfg_rx_empty,
    input               pcie_cfg_rx_rd_en,
    
    // PCIe core functionality
    input       [7:0]   cfg_bus_number,
    input       [4:0]   cfg_device_number,
    input       [2:0]   cfg_function_number,
    input       [15:0]  cfg_command,
    
    input       [31:0]  cfg_do,
    input               cfg_rd_wr_done,
    output      [9:0]   cfg_dwaddr,
    output              cfg_rd_en,
    output      [31:0]  cfg_di,
    output              cfg_wr_en,
    output      [3:0]   cfg_byte_en,
    
    // PCIe core PHY
    input       [2:0]   pl_initial_link_width,
    input               pl_phy_lnk_up,
    input       [1:0]   pl_lane_reversal_mode,
    input               pl_link_gen2_cap,
    input               pl_link_partner_gen2_supported,
    input               pl_link_upcfg_cap,
    input               pl_sel_lnk_rate,
    input       [1:0]   pl_sel_lnk_width,
    input       [5:0]   pl_ltssm_state,
    input       [1:0]   pl_rx_pm_state,
    input       [2:0]   pl_tx_pm_state,
    input               pl_directed_change_done,
    input               pl_received_hot_rst,
    output reg          pl_directed_link_auton = 1'b0,
    output reg  [1:0]   pl_directed_link_change = 2'b00,
    output reg          pl_directed_link_speed = 1'b1,
    output reg  [1:0]   pl_directed_link_width = 2'b00,
    output reg          pl_upstream_prefer_deemph = 1'b1,
    output reg          pl_transmit_hot_rst = 1'b0,
    output reg          pl_downstream_deemph_source = 1'b0
    );
    
    reg             cfg_rd_en_r = 1'b0;
    assign          cfg_rd_en = cfg_rd_en_r & ~cfg_rd_wr_done;
        
    reg     [9:0]   cfg_dwaddr_r = 10'h000;
    assign          cfg_dwaddr = cfg_dwaddr_r;
    
    reg     [31:0]  cfg_di_r = 32'h00000000;
    assign          cfg_di = cfg_di_r;
    
    reg             cfg_wr_en_r = 1'b0;
    assign          cfg_wr_en = cfg_wr_en_r & ~cfg_rd_wr_done;
    
    reg     [3:0]   cfg_byte_en_r = 4'b0000;
    assign          cfg_byte_en = cfg_byte_en_r;
    
    // ----------------------------------------------------------------------------
    // Convert received CFG data from FT601 to PCIe clock domain
    // FIFO depth: 512 / 64-bits
    // ----------------------------------------------------------------------------
    reg             in_rden;
    wire [63:0]     in_dout;
    wire            in_empty;
    wire            in_valid;
    
    reg [63:0]      in_data64;
    wire [31:0]     in_data32   = in_data64[63:32];
    wire [15:0]     in_data16   = in_data64[31:16];
    wire [3:0]      in_type     = in_data64[15:12];
	
    fifo_64_64 i_fifo_pcie_cfg_tx(
        .rst            ( rst                       ),
        .wr_clk         ( clk                       ),
        .rd_clk         ( clk_pcie                  ),
        .din            ( pcie_cfg_tx_data          ),
        .wr_en          ( pcie_cfg_tx_valid         ),
        .rd_en          ( in_rden                   ),
        .dout           ( in_dout                   ),
        .full           (                           ),
        .empty          ( in_empty                  ),
        .valid          ( in_valid                  )
    );
    
    // ------------------------------------------------------------------------
    // Convert received CFG from PCIe core and transmit onwards to FT601
    // FIFO depth: 512 / 64-bits.
    // ------------------------------------------------------------------------
    reg             out_wren = 1'b0;
    reg [63:0]      out_data = 64'hffeeddccbbaa9988;
    
    fifo_64_32 i_fifo_pcie_cfg_rx(
        .rst            ( rst                       ),
        .wr_clk         ( clk_pcie                  ),
        .rd_clk         ( clk                       ),
        .din            ( out_data                  ),
        .wr_en          ( out_wren                  ),
        .rd_en          ( pcie_cfg_rx_rd_en         ),
        .dout           ( pcie_cfg_rx_data          ),
        .full           (                           ),
        .empty          ( pcie_cfg_rx_empty         ),
        .valid          ( pcie_cfg_rx_valid         )
    );
    
    // ------------------------------------------------------------------------
    // STATE MACHINE FOR HANDLING PCIe CORE ACCESS BELOW:
    // ------------------------------------------------------------------------ 
    `define CFG_TYPE_STATUS               4'h0
    `define CFG_TYPE_CFG_READ             4'h1
    `define CFG_TYPE_CFG_WRITE            4'h2
    `define CFG_TYPE_PHY_READ             4'h3
    `define CFG_TYPE_PHY_WRITE            4'h4
 
    // STATE MACHINE:
    `define S_IDLE0         4'h0
    `define S_IDLE1         4'h1
    `define S_IDLE2         4'h2
    `define S_IDLE3         4'h3
    `define S_CFG_STATUS    4'h4
    `define S_CFG_READ      4'h5
    `define S_CFG_WRITE     4'h6
    `define S_PHY_READ      4'h7
    `define S_PHY_WRITE     4'h8
    reg [3:0]      state = `S_IDLE0;
    always @ ( posedge clk_pcie )
        begin
            if ( pl_received_hot_rst & (state != `S_CFG_WRITE) )
                pl_transmit_hot_rst <= 1'b0;
            if ( pl_directed_change_done & (state != `S_CFG_WRITE) )
                pl_directed_link_change <= 2'b00;
            case ( state )
                `S_IDLE0:
                    begin
                        in_rden <= 1'b1;
                        out_wren <= 1'b0;
                        state <= `S_IDLE1;
                    end
                `S_IDLE1:
                    begin
                        in_rden <= 1'b0;
                        state <= `S_IDLE2;
                    end
                `S_IDLE2:
                    begin
                        in_data64 <= in_dout;
                        state <= in_valid ? `S_IDLE3 : `S_IDLE0;
                    end
                `S_IDLE3:
                    begin
                        case ( in_type )
                            `CFG_TYPE_STATUS:
                                state <= `S_CFG_STATUS;
                            `CFG_TYPE_CFG_READ:
                                state <= `S_CFG_READ;
                            `CFG_TYPE_CFG_WRITE:
                                state <= `S_CFG_WRITE;
                            `CFG_TYPE_PHY_READ:
                                state <= `S_PHY_READ;
                            `CFG_TYPE_PHY_WRITE:
                                state <= `S_PHY_WRITE;
                            default:
                                state <= `S_IDLE0;
                        endcase
                    end
                `S_CFG_STATUS:
                    begin
                        out_wren <= 1'b1;
                        out_data[15:00] <= 16'h0177; // TYPE_STATUS+CFG+MAGIC
                        out_data[23:16] <= cfg_bus_number;
                        out_data[28:24] <= cfg_device_number;
                        out_data[31:29] <= cfg_function_number; 
                        out_data[47:32] <= cfg_command;
                        out_data[63:48] <= 16'h0000;
                        state <= `S_IDLE0;
                    end
                `S_CFG_READ:
                    begin
                        if ( cfg_rd_wr_done )
                            begin
                                out_wren <= 1'b1;
                                out_data[15:00] <= 16'h1177; // TYPE_READ+CFG+MAGIC
                                out_data[31:16] <= in_data16;
                                out_data[63:32] <= cfg_do;
                                cfg_rd_en_r <= 1'b0;
                                state <= `S_IDLE0;
                            end
                        else
                            begin
                                cfg_rd_en_r <= 1'b1;
                                cfg_dwaddr_r <= in_data16[9:0];
                            end
                    end
                `S_CFG_WRITE:
                    begin
                        if ( cfg_rd_wr_done )
                            begin
                                cfg_wr_en_r <= 1'b0;
                                state <= `S_IDLE0;
                            end
                        else
                            begin
                                cfg_wr_en_r <= 1'b1;
                                cfg_di_r <= in_data32;
                                cfg_dwaddr_r <= in_data16[9:0];
                                cfg_byte_en_r <= in_data16[15:12];
                            end
                    end
                `S_PHY_READ:
                    begin
                        state <= `S_IDLE0;
                        out_wren <= 1'b1;
                        out_data[15:00] <= 16'h3177; // TYPE_READ+CFG+MAGIC
                        // user set values
                        out_data[16:16] <= pl_directed_link_auton;
                        out_data[18:17] <= pl_directed_link_change;
                        out_data[19:19] <= pl_directed_link_speed;
                        out_data[21:20] <= pl_directed_link_width;
                        out_data[22:22] <= pl_upstream_prefer_deemph;
                        out_data[23:23] <= pl_transmit_hot_rst;
                        out_data[24:24] <= pl_downstream_deemph_source;
                        out_data[31:25] <= 7'h7f;
                        // pcie core values
                        out_data[37:32] <= pl_ltssm_state;
                        out_data[39:38] <= pl_rx_pm_state;
                        out_data[42:40] <= pl_tx_pm_state;
                        out_data[45:43] <= pl_initial_link_width;
                        out_data[47:46] <= pl_lane_reversal_mode;
                        out_data[49:48] <= pl_sel_lnk_width;
                        out_data[50:50] <= pl_phy_lnk_up;
                        out_data[51:51] <= pl_link_gen2_cap;
                        out_data[52:52] <= pl_link_partner_gen2_supported;
                        out_data[53:53] <= pl_link_upcfg_cap;
                        out_data[54:54] <= pl_sel_lnk_rate;
                        out_data[55:55] <= pl_directed_change_done;
                        out_data[56:56] <= pl_received_hot_rst;
                        out_data[63:57] <= 7'h7f;
                    end
                `S_PHY_WRITE:
                    begin
                        state <= `S_IDLE0;
                        pl_directed_link_auton      <= in_data64[16:16];
                        pl_directed_link_change     <= in_data64[18:17];
                        pl_directed_link_speed      <= in_data64[19:19];
                        pl_directed_link_width      <= in_data64[21:20];
                        pl_upstream_prefer_deemph   <= in_data64[22:22];
                        pl_transmit_hot_rst         <= in_data64[23:23];
                        pl_downstream_deemph_source <= in_data64[24:24];
                    end
            endcase
        end
	
endmodule
