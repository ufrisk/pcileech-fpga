//
// PCILeech FPGA.
//
// Default PCIe endpoint personality settings.
//

`ifndef _pcileech_device_config_svh_
`define _pcileech_device_config_svh_

`ifndef PCILEECH_CFG_SUBSYS_VEND_ID
`define PCILEECH_CFG_SUBSYS_VEND_ID 16'h10EE
`endif

`ifndef PCILEECH_CFG_SUBSYS_ID
`define PCILEECH_CFG_SUBSYS_ID 16'h0007
`endif

`ifndef PCILEECH_CFG_VEND_ID
`define PCILEECH_CFG_VEND_ID 16'h10EE
`endif

`ifndef PCILEECH_CFG_DEV_ID
`define PCILEECH_CFG_DEV_ID 16'h0666
`endif

`ifndef PCILEECH_CFG_REV_ID
`define PCILEECH_CFG_REV_ID 8'h02
`endif

`ifndef PCILEECH_CFG_DSN
`define PCILEECH_CFG_DSN 64'h0000000101000A35
`endif

`ifndef PCILEECH_CFGTLP_ZERO_DATA
`define PCILEECH_CFGTLP_ZERO_DATA 1'b1
`endif

`ifndef PCILEECH_CFGTLP_PCIE_WRITE_ENABLE
`define PCILEECH_CFGTLP_PCIE_WRITE_ENABLE 1'b0
`endif

`ifndef PCILEECH_CFGSPACE_STATUS_REGISTER_AUTO_CLEAR
`define PCILEECH_CFGSPACE_STATUS_REGISTER_AUTO_CLEAR 1'b0
`endif

`ifndef PCILEECH_CFGSPACE_COMMAND_REGISTER_AUTO_SET
`define PCILEECH_CFGSPACE_COMMAND_REGISTER_AUTO_SET 1'b0
`endif

`ifndef PCILEECH_CFG_PM_FORCE_STATE
`define PCILEECH_CFG_PM_FORCE_STATE 2'b00
`endif

`ifndef PCILEECH_CFG_PM_FORCE_STATE_EN
`define PCILEECH_CFG_PM_FORCE_STATE_EN 1'b0
`endif

`ifndef PCILEECH_CFG_PM_HALT_ASPM_L0S
`define PCILEECH_CFG_PM_HALT_ASPM_L0S 1'b0
`endif

`ifndef PCILEECH_CFG_PM_HALT_ASPM_L1
`define PCILEECH_CFG_PM_HALT_ASPM_L1 1'b0
`endif

`ifndef PCILEECH_BAR_IMPL_0
`define PCILEECH_BAR_IMPL_0 pcileech_bar_impl_zerowrite4k
`endif

`ifndef PCILEECH_BAR_IMPL_1
`define PCILEECH_BAR_IMPL_1 pcileech_bar_impl_loopaddr
`endif

`ifndef PCILEECH_BAR_IMPL_2
`define PCILEECH_BAR_IMPL_2 pcileech_bar_impl_none
`endif

`ifndef PCILEECH_BAR_IMPL_3
`define PCILEECH_BAR_IMPL_3 pcileech_bar_impl_none
`endif

`ifndef PCILEECH_BAR_IMPL_4
`define PCILEECH_BAR_IMPL_4 pcileech_bar_impl_none
`endif

`ifndef PCILEECH_BAR_IMPL_5
`define PCILEECH_BAR_IMPL_5 pcileech_bar_impl_none
`endif

`ifndef PCILEECH_BAR_IMPL_6
`define PCILEECH_BAR_IMPL_6 pcileech_bar_impl_none
`endif

`endif
