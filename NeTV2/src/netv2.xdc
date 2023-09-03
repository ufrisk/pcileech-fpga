#
# CLK 50MHz BELOW 
#
set_property PACKAGE_PIN J19 [get_ports clk50]
set_property IOSTANDARD LVCMOS33 [get_ports clk50]
# create_clock -period 20.000 -waveform {0.000 10.000} [get_ports clk50]

#
# LED BELOW
#
set_property PACKAGE_PIN M21  [get_ports led00]
set_property PACKAGE_PIN N20  [get_ports led01]
set_property PACKAGE_PIN L21  [get_ports led10]
set_property PACKAGE_PIN AA21 [get_ports led11]
set_property PACKAGE_PIN R19  [get_ports led20]
set_property PACKAGE_PIN M16  [get_ports led21]
set_property IOSTANDARD LVCMOS33 [get_ports led00]
set_property IOSTANDARD LVCMOS33 [get_ports led01]
set_property IOSTANDARD LVCMOS33 [get_ports led10]
set_property IOSTANDARD LVCMOS33 [get_ports led11]
set_property IOSTANDARD LVCMOS33 [get_ports led20]
set_property IOSTANDARD LVCMOS33 [get_ports led21]

#
# RMII ETH BELOW
#
set_property PACKAGE_PIN D17  [get_ports eth_clk50]
set_property PACKAGE_PIN F16  [get_ports eth_rst_n]
set_property PACKAGE_PIN A20  [get_ports {eth_rx_data[0]}]
set_property PACKAGE_PIN B18  [get_ports {eth_rx_data[1]}]
set_property PACKAGE_PIN C20  [get_ports eth_crs_dv]
set_property PACKAGE_PIN A19  [get_ports eth_tx_en]
set_property PACKAGE_PIN C18  [get_ports {eth_tx_data[0]}]
set_property PACKAGE_PIN C19  [get_ports {eth_tx_data[1]}]
set_property PACKAGE_PIN F14  [get_ports eth_mdc]
set_property PACKAGE_PIN F13  [get_ports eth_mdio]
set_property PACKAGE_PIN B20  [get_ports eth_rx_err]
set_property IOSTANDARD LVCMOS33 [get_ports eth_clk50]
set_property IOSTANDARD LVCMOS33 [get_ports eth_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports {eth_rx_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {eth_rx_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports eth_crs_dv]
set_property IOSTANDARD LVCMOS33 [get_ports eth_tx_en]
set_property IOSTANDARD LVCMOS33 [get_ports {eth_tx_data[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {eth_tx_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports eth_mdc]
set_property IOSTANDARD LVCMOS33 [get_ports eth_mdio]
set_property IOSTANDARD LVCMOS33 [get_ports eth_rx_err]

set_false_path -from [get_pins {tickcount64_reg[*]/C}]
set_false_path -from [get_pins {i_pcileech_fifo/_pcie_core_config_reg[*]/C}]
set_false_path -from [get_pins i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/user_lnk_up_int_reg/C] -to [get_pins {i_pcileech_fifo/_cmd_tx_din_reg[16]/D}]
set_false_path -from [get_pins i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/user_reset_out_reg/C]

#PCIe signals
set_property PACKAGE_PIN E18 [get_ports pcie_perst_n]
set_property PACKAGE_PIN D20 [get_ports pcie_wake_n]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_perst_n]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_wake_n]

# NB! one of the LOC GTPE2 lines will generate a crical warning and be ignored.
# 35T = LOC GTPE2_CHANNEL_X0Y2
# 100T = LOC GTPE2_CHANNEL_X0Y6
set_property LOC GTPE2_CHANNEL_X0Y2 [get_cells {i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property LOC GTPE2_CHANNEL_X0Y6 [get_cells {i_pcileech_pcie_a7/i_pcie_7x_0/inst/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property PACKAGE_PIN C11 [get_ports {pcie_rx_n[0]}]
set_property PACKAGE_PIN D11 [get_ports {pcie_rx_p[0]}]
set_property PACKAGE_PIN C5 [get_ports {pcie_tx_n[0]}]
set_property PACKAGE_PIN D5 [get_ports {pcie_tx_p[0]}]
set_property PACKAGE_PIN E10 [get_ports pcie_clk_n]
set_property PACKAGE_PIN F10 [get_ports pcie_clk_p]

create_clock -name pcie_refclk_p -period 10.0 [get_nets pcie_clk_p]

#
# BITSTREAM CONFIG BELOW
#
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
