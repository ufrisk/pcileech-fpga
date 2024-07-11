#
# RUN FROM WITHIN "Vivado Tcl Shell" WITH COMMAND:
# source vivado_flash_hs2.tcl -notrace
#
puts "-------------------------------------------------------"
puts " SEARCHING FOR PROGRAMMING CABLE AND OPENING DEVICE ..."
puts "-------------------------------------------------------"
set programming_files {./pcileech_screamer_m2.bin}
open_hw
connect_hw_server
current_hw_target [get_hw_targets]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets]
open_hw_target
set my_mem_device [lindex [get_cfgmem_parts {is25lp256d-spi-x1_x2_x4}] 0]
set my_hw_cfgmem [create_hw_cfgmem -hw_device \
[lindex [get_hw_devices] 0] -mem_dev $my_mem_device]
set_property PROGRAM.ADDRESS_RANGE {use_file} $my_hw_cfgmem
set_property PROGRAM.FILES $programming_files $my_hw_cfgmem
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} $my_hw_cfgmem
program_hw_devices [lindex [get_hw_devices] 0]
puts "-------------------------------------------------------"
puts " STARTING TO PROGRAM DEVICE ...                        "
puts " THIS MAY TAKE SOME TIME.                              "
puts "-------------------------------------------------------"
set_property PROGRAM.BLANK_CHECK 0 $my_hw_cfgmem
set_property PROGRAM.ERASE 1 $my_hw_cfgmem
set_property PROGRAM.CFG_PROGRAM 1 $my_hw_cfgmem
set_property PROGRAM.VERIFY 1 $my_hw_cfgmem
program_hw_cfgmem -hw_cfgmem $my_hw_cfgmem
close_hw_target
disconnect_hw_server
puts "-------------------------------------------------------"
puts " PROGRAM DEVICE HOPEFULLY COMPLETED.                   "
puts " POWER CYCLE DEVICE FOR CHANGES TO TAKE EFFECT.        "
puts "-------------------------------------------------------"