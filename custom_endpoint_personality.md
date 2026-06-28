Custom Endpoint Personality Hooks
=================================

PCILeech FPGA boards include default PCIe endpoint personality hooks in
`src/pcileech_device_config.svh`. The defaults preserve the stock firmware
identity and BAR behavior. Build tooling may replace this file, or define the
same macros before `pcileech_header.svh` is included, to select a custom
endpoint personality without editing the FIFO, PCIe config, or BAR controller
sources.


Config Space Defaults
=====================

The following macros control the initial PCIe identity and selected config
space behavior:

* `PCILEECH_CFG_SUBSYS_VEND_ID`
* `PCILEECH_CFG_SUBSYS_ID`
* `PCILEECH_CFG_VEND_ID`
* `PCILEECH_CFG_DEV_ID`
* `PCILEECH_CFG_REV_ID`
* `PCILEECH_CFG_DSN`
* `PCILEECH_CFGTLP_ZERO_DATA`
* `PCILEECH_CFGTLP_PCIE_WRITE_ENABLE`
* `PCILEECH_CFGSPACE_STATUS_REGISTER_AUTO_CLEAR`
* `PCILEECH_CFGSPACE_COMMAND_REGISTER_AUTO_SET`
* `PCILEECH_CFG_PM_FORCE_STATE`
* `PCILEECH_CFG_PM_FORCE_STATE_EN`
* `PCILEECH_CFG_PM_HALT_ASPM_L0S`
* `PCILEECH_CFG_PM_HALT_ASPM_L1`


BAR Implementation Defaults
===========================

The BAR controller instantiates module names from these macros:

* `PCILEECH_BAR_IMPL_0`
* `PCILEECH_BAR_IMPL_1`
* `PCILEECH_BAR_IMPL_2`
* `PCILEECH_BAR_IMPL_3`
* `PCILEECH_BAR_IMPL_4`
* `PCILEECH_BAR_IMPL_5`
* `PCILEECH_BAR_IMPL_6`

All selected BAR modules must use the same interface as the stock
implementations:

```systemverilog
module pcileech_bar_impl_custom(
    input               rst,
    input               clk,
    input [31:0]        wr_addr,
    input [3:0]         wr_be,
    input [31:0]        wr_data,
    input               wr_valid,
    input [87:0]        rd_req_ctx,
    input [31:0]        rd_req_addr,
    input               rd_req_valid,
    output bit [87:0]   rd_rsp_ctx,
    output bit [31:0]   rd_rsp_data,
    output bit          rd_rsp_valid
);
```

The BAR controller requires all BAR implementations to return read data with
the same latency, matching the existing controller contract.
