# FMC_LA10_N
set_property PACKAGE_PIN A18 [get_ports ft601_rst_n]
# FMC_LA00_CC_P
set_property PACKAGE_PIN D18 [get_ports ft601_oe_n]
# FMC_LA00_CC_N
set_property PACKAGE_PIN C18 [get_ports ft601_rd_n]
# FMC_LA08_P
set_property PACKAGE_PIN C17 [get_ports ft601_wr_n]
# FMC_LA07_P
set_property PACKAGE_PIN H16 [get_ports ft601_rxf_n]
# FMC_LA07_N
set_property PACKAGE_PIN G16 [get_ports ft601_txe_n]
# FMC_LA08_N
set_property PACKAGE_PIN B17 [get_ports ft601_siwu_n]
# FMC_LA15_N
set_property PACKAGE_PIN A22 [get_ports {ft601_be[0]}]
# FMC_LA15_P
set_property PACKAGE_PIN B22 [get_ports {ft601_be[1]}]
# FMC_LA09_N
set_property PACKAGE_PIN D16 [get_ports {ft601_be[2]}]
# FMC_LA09_P
set_property PACKAGE_PIN E16 [get_ports {ft601_be[3]}]
# FMC_LA32_N
set_property PACKAGE_PIN G26 [get_ports {ft601_data[0]}]
# FMC_LA33_N
set_property PACKAGE_PIN F25 [get_ports {ft601_data[1]}]
# FMC_LA32_P
set_property PACKAGE_PIN H26 [get_ports {ft601_data[2]}]
# FMC_LA33_P
set_property PACKAGE_PIN G25 [get_ports {ft601_data[3]}]
# FMC_LA30_N
set_property PACKAGE_PIN D25 [get_ports {ft601_data[4]}]
# FMC_LA31_N
set_property PACKAGE_PIN D26 [get_ports {ft601_data[5]}]
# FMC_LA30_P
set_property PACKAGE_PIN E25 [get_ports {ft601_data[6]}]
# FMC_LA31_P
set_property PACKAGE_PIN E26 [get_ports {ft601_data[7]}]
# FMC_LA28_N
set_property PACKAGE_PIN K23 [get_ports {ft601_data[8]}]
# FMC_LA29_N
set_property PACKAGE_PIN F24 [get_ports {ft601_data[9]}]
# FMC_LA28_P
set_property PACKAGE_PIN K22 [get_ports {ft601_data[10]}]
# FMC_LA29_P
set_property PACKAGE_PIN G24 [get_ports {ft601_data[11]}]
# FMC_LA24_N
set_property PACKAGE_PIN H18 [get_ports {ft601_data[12]}]
# FMC_LA25_N
set_property PACKAGE_PIN F22 [get_ports {ft601_data[13]}]
# FMC_LA24_P
set_property PACKAGE_PIN J18 [get_ports {ft601_data[14]}]
# FMC_LA25_P
set_property PACKAGE_PIN G22 [get_ports {ft601_data[15]}]
# FMC_LA27_N
set_property PACKAGE_PIN E23 [get_ports {ft601_data[16]}]
# FMC_LA26_N
set_property PACKAGE_PIN H24 [get_ports {ft601_data[17]}]
# FMC_LA27_P
set_property PACKAGE_PIN F23 [get_ports {ft601_data[18]}]
# FMC_LA26_P
set_property PACKAGE_PIN J24 [get_ports {ft601_data[19]}]
# FMC_LA21_N
set_property PACKAGE_PIN H19 [get_ports {ft601_data[20]}]
# FMC_LA22_N
set_property PACKAGE_PIN L18 [get_ports {ft601_data[21]}]
# FMC_LA21_P
set_property PACKAGE_PIN J19 [get_ports {ft601_data[22]}]
# FMC_LA22_P
set_property PACKAGE_PIN L17 [get_ports {ft601_data[23]}]
# FMC_LA23_N
set_property PACKAGE_PIN J20 [get_ports {ft601_data[24]}]
# FMC_LA23_P
set_property PACKAGE_PIN K20 [get_ports {ft601_data[25]}]
# FMC_LA19_N
set_property PACKAGE_PIN L14 [get_ports {ft601_data[26]}]
# FMC_LA19_P
set_property PACKAGE_PIN M14 [get_ports {ft601_data[27]}]
# FMC_LA20_N
set_property PACKAGE_PIN M17 [get_ports {ft601_data[28]}]
# FMC_LA20_P
set_property PACKAGE_PIN M16 [get_ports {ft601_data[29]}]
# FMC_LA17_CC_N
set_property PACKAGE_PIN J21 [get_ports {ft601_data[30]}]
# FMC_LA17_CC_P
set_property PACKAGE_PIN K21 [get_ports {ft601_data[31]}]
set_property IOSTANDARD LVCMOS25 [get_ports {ft601_txe_n ft601_rxf_n}]
set_property IOSTANDARD LVCMOS25 [get_ports {{ft601_be[*]} {ft601_data[*]}}]
set_property IOSTANDARD LVCMOS25 [get_ports {ft601_wr_n ft601_rd_n ft601_oe_n ft601_siwu_n ft601_rst_n}]
set_property SLEW FAST [get_ports {{ft601_be[*]} {ft601_data[*]}}]
set_property SLEW FAST [get_ports {ft601_wr_n ft601_rd_n ft601_oe_n ft601_siwu_n ft601_rst_n}]

set_property PACKAGE_PIN M26 [get_ports gpio_led[0]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio_led[0]]
set_property PACKAGE_PIN T24 [get_ports gpio_led[1]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio_led[1]]
set_property PACKAGE_PIN T25 [get_ports gpio_led[2]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio_led[2]]
set_property PACKAGE_PIN P6 [get_ports gpio_sw_north]
set_property IOSTANDARD LVCMOS15 [get_ports gpio_sw_north]
set_property PACKAGE_PIN T5 [get_ports gpio_sw_south]
set_property IOSTANDARD SSTL15 [get_ports gpio_sw_south]

# SYSCLK
set_property PACKAGE_PIN R3 [get_ports sysclk_p]
set_property PACKAGE_PIN P3 [get_ports sysclk_n]
set_property IOSTANDARD LVDS_25 [get_ports sysclk_p]
set_property IOSTANDARD LVDS_25 [get_ports sysclk_n]

# FT601 CLK
set_property PACKAGE_PIN G20 [get_ports ft601_clk]
set_property IOSTANDARD LVCMOS25 [get_ports ft601_clk]
create_clock -period 10.000 -name net_ft601_clk -waveform {0.000 5.000} [get_ports ft601_clk]

set_input_delay -clock [get_clocks net_ft601_clk] -min 6.5 [get_ports {ft601_data[*]}]
set_input_delay -clock [get_clocks net_ft601_clk] -max 7.0 [get_ports {ft601_data[*]}]
set_input_delay -clock [get_clocks net_ft601_clk] -min 6.5 [get_ports ft601_rxf_n]
set_input_delay -clock [get_clocks net_ft601_clk] -max 7.0 [get_ports ft601_rxf_n]
set_input_delay -clock [get_clocks net_ft601_clk] -min 6.5 [get_ports ft601_txe_n]
set_input_delay -clock [get_clocks net_ft601_clk] -max 7.0 [get_ports ft601_txe_n]

set_output_delay -clock [get_clocks net_ft601_clk] -max 1.0 [get_ports {ft601_wr_n ft601_rd_n ft601_oe_n}]
set_output_delay -clock [get_clocks net_ft601_clk] -min 4.8 [get_ports {ft601_wr_n ft601_rd_n ft601_oe_n}]
set_output_delay -clock [get_clocks net_ft601_clk] -max 1.0 [get_ports {{ft601_be[*]} {ft601_data[*]}}]
set_output_delay -clock [get_clocks net_ft601_clk] -min 4.8 [get_ports {{ft601_be[*]} {ft601_data[*]}}]

set_property IOB TRUE [get_cells i_pcileech_com/i_pcileech_ft601/FT601_OE_N_reg]
set_property IOB TRUE [get_cells i_pcileech_com/i_pcileech_ft601/FT601_RD_N_reg]
set_property IOB TRUE [get_cells i_pcileech_com/i_pcileech_ft601/FT601_WR_N_reg]
set_property IOB TRUE [get_cells i_pcileech_com/i_pcileech_ft601/FT601_DATA_OUT_reg[0][*]]

set_multicycle_path 2 -from [get_pins i_pcileech_com/i_pcileech_ft601/OE_reg/C] -to [get_ports {{ft601_be[*]} {ft601_data[*]}}]
set_false_path -from [get_pins {tickcount64_reg[*]/C}]
set_false_path -from [get_pins {i_pcileech_fifo/_pcie_core_config_reg[*]/C}]
set_false_path -from [get_pins i_pcileech_pcie_a7x4/i_pcie_7x_0/inst/inst/user_lnk_up_int_reg/C] -to [get_pins {i_pcileech_fifo/_cmd_tx_din_reg[16]/D}]
set_false_path -from [get_pins i_pcileech_pcie_a7x4/i_pcie_7x_0/inst/inst/user_reset_out_reg/C]

#PCIe signals
set_property PACKAGE_PIN M20 [get_ports pcie_perst_n]
set_property PACKAGE_PIN K26 [get_ports pcie_wake_n]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_perst_n]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_wake_n]

#set_property LOC GTPE2_CHANNEL_X0Y7 [get_cells {i_pcileech_pcie_a7x4/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
#set_property PACKAGE_PIN C12 [get_ports {pcie_rx_n[0]}]
#set_property LOC GTPE2_CHANNEL_X0Y6 [get_cells {i_pcileech_pcie_a7x4/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
#set_property PACKAGE_PIN A13 [get_ports {pcie_rx_n[1]}]
#set_property LOC GTPE2_CHANNEL_X0Y5 [get_cells {i_pcileech_pcie_a7x4/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
#set_property PACKAGE_PIN C14 [get_ports {pcie_rx_n[2]}]
#set_property LOC GTPE2_CHANNEL_X0Y4 [get_cells {i_pcileech_pcie_a7x4/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
#set_property PACKAGE_PIN A11 [get_ports {pcie_rx_n[3]}]
set_property PACKAGE_PIN E11 [get_ports pcie_clk_n]
set_property PACKAGE_PIN F11 [get_ports pcie_clk_p]

create_clock -name pcie_refclk_p -period 10.0 [get_nets pcie_clk_p]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
