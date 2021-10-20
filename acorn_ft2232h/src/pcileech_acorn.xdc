set_property PACKAGE_PIN G3 [get_ports led_1]
set_property IOSTANDARD LVCMOS33 [get_ports led_1]

set_property PACKAGE_PIN AB8 [get_ports ft245_data[0]]
set_property PACKAGE_PIN AA8 [get_ports ft245_data[1]]
set_property PACKAGE_PIN Y9  [get_ports ft245_data[2]]
set_property PACKAGE_PIN W9  [get_ports ft245_data[3]]
set_property PACKAGE_PIN Y8  [get_ports ft245_data[4]]
set_property PACKAGE_PIN Y7  [get_ports ft245_data[5]]
set_property PACKAGE_PIN V9  [get_ports ft245_data[6]]
set_property PACKAGE_PIN V8  [get_ports ft245_data[7]]

# FT2232H/ACBUS-0
set_property PACKAGE_PIN K2  [get_ports ft245_rxf_n]
# FT2232H/ACBUS-1
set_property PACKAGE_PIN J2  [get_ports ft245_txe_n]
# FT2232H/ACBUS-2
set_property PACKAGE_PIN J5  [get_ports ft245_rd_n]
# FT2232H/ACBUS-3
set_property PACKAGE_PIN H5  [get_ports ft245_wr_n]
# FT2232H/ACBUS-4, (LED3) COLOR: BROWN
set_property PACKAGE_PIN G4  [get_ports ft245_siwu_n]
# FT2232H/ACBUS-6, (LED2) COLOR: BLACK
set_property PACKAGE_PIN H3  [get_ports ft245_oe_n]

set_property IOSTANDARD LVTTL [get_ports {ft245_data[*] ft245_rd_n ft245_wr_n ft245_oe_n ft245_siwu_n ft245_rxf_n ft245_txe_n}]
set_property PULLTYPE PULLUP  [get_ports {ft245_data[*] ft245_rd_n ft245_wr_n ft245_oe_n ft245_siwu_n ft245_rxf_n ft245_txe_n}]

# CLK: SYS: 200MHz
set_property PACKAGE_PIN J19 [get_ports clk_sys_p]
set_property PACKAGE_PIN H19 [get_ports clk_sys_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {clk_sys_p clk_sys_n}]

# CLK: FT245: 66MHz  (LED4)
set_property PACKAGE_PIN H4 [get_ports ft245_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ft245_clk]
set_property PULLTYPE PULLDOWN [get_ports ft245_clk]
create_clock -period 16.666 -name net_ft245_clk -waveform {0.000 8.333} [get_ports ft245_clk]

set_input_delay  -clock [get_clocks net_ft245_clk] -min 9.0 [get_ports {ft245_data[*] ft245_rxf_n ft245_rxf_n ft245_txe_n ft245_txe_n}]
set_input_delay  -clock [get_clocks net_ft245_clk] -max 0.0 [get_ports {ft245_data[*] ft245_rxf_n ft245_rxf_n ft245_txe_n ft245_txe_n}]
set_output_delay -clock [get_clocks net_ft245_clk] -max 7.5 [get_ports {ft245_data[*] ft245_wr_n ft245_rd_n ft245_oe_n}]
set_output_delay -clock [get_clocks net_ft245_clk] -min 0.0 [get_ports {ft245_data[*] ft245_wr_n ft245_rd_n ft245_oe_n}]

set_property IOB TRUE [get_cells i_pcileech_com/i_pcileech_ft245/FT245_OE_N_reg]
set_property IOB TRUE [get_cells i_pcileech_com/i_pcileech_ft245/FT245_RD_N_reg]
set_property IOB TRUE [get_cells i_pcileech_com/i_pcileech_ft245/FT245_WR_N_reg]
set_property IOB TRUE [get_cells i_pcileech_com/i_pcileech_ft245/txo_dout_reg[*]]

set_false_path -from [get_pins i_pcileech_com/i_pcileech_ft245/oe_reg/C] -to [get_ports {ft245_data[*]}]
set_false_path -from [get_pins {tickcount64_reg[*]/C}]
set_false_path -from [get_pins {i_pcileech_fifo/_pcie_core_config_reg[*]/C}]
set_false_path -from [get_pins i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/user_lnk_up_int_reg/C] -to [get_pins {i_pcileech_fifo/_cmd_tx_din_reg[16]/D}]
set_false_path -from [get_pins i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/user_reset_out_reg/C]

#PCIe signals
set_property PACKAGE_PIN J1  [get_ports pcie_perst_n]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_perst_n]

set_property LOC GTPE2_CHANNEL_X0Y7 [get_cells {i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property PACKAGE_PIN B10 [get_ports pcie_rx_p[0]]
set_property PACKAGE_PIN A10 [get_ports pcie_rx_n[0]]
set_property PACKAGE_PIN B6  [get_ports pcie_tx_p[0]]
set_property PACKAGE_PIN A6  [get_ports pcie_tx_n[0]]
#set_property LOC GTPE2_CHANNEL_X0Y6 [get_cells {i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
#set_property PACKAGE_PIN B8  [get_ports pcie_rx_p[1]]
#set_property PACKAGE_PIN A8  [get_ports pcie_rx_n[1]]
#set_property PACKAGE_PIN B4  [get_ports pcie_tx_p[1]]
#set_property PACKAGE_PIN A4  [get_ports pcie_tx_n[1]]
#set_property LOC GTPE2_CHANNEL_X0Y5 [get_cells {i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
#set_property PACKAGE_PIN D11 [get_ports pcie_rx_p[2]]
#set_property PACKAGE_PIN C11 [get_ports pcie_rx_n[2]]
#set_property PACKAGE_PIN D5  [get_ports pcie_tx_p[2]]
#set_property PACKAGE_PIN C5  [get_ports pcie_tx_n[2]]
#set_property LOC GTPE2_CHANNEL_X0Y4 [get_cells {i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
#set_property PACKAGE_PIN D9  [get_ports pcie_rx_p[3]]
#set_property PACKAGE_PIN C9  [get_ports pcie_rx_n[3]]
#set_property PACKAGE_PIN D7  [get_ports pcie_tx_p[3]]
#set_property PACKAGE_PIN C7  [get_ports pcie_tx_n[3]]
set_property PACKAGE_PIN F6 [get_ports pcie_clk_p]
set_property PACKAGE_PIN E6 [get_ports pcie_clk_n]

create_clock -name pcie_refclk_p -period 10.0 [get_nets pcie_clk_p]

# bitstream config
set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]

set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN Div-1 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

