NeTV2 PCIe to UDP/IP:
=====================
This project contains software and HDL code for the [NeTV2 FPGA PCIe board](https://www.crowdsupply.com/alphamax/netv2).
Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.

Capabilities:
=================
* Retrieve memory from the target system over 100Mbit UDP/IP up to 7MB/s.<br><sub><sup>(7MB/s is the effective memory dump speed after protocol overhead)</sup></sub>
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at 500-1000MB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) or [MemProcFS](https://github.com/ufrisk/MemProcFS/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).

The Hardware:
=================
* NeTV2 PCIe FPGA board. ([CrowdSupply](https://www.crowdsupply.com/alphamax/netv2))

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/2032adf8761dfdfc8bad86b08c2385b2497070be/_gh_netv2_2.jpg" height="350"/> <img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/2032adf8761dfdfc8bad86b08c2385b2497070be/_gh_netv2_3.jpg" height="350"/>

### Please note:
1) The NeTV2 have a PCIe x4 connector and will **NOT** fit in PCIe x1 slots! It will fit in x4 - x16 slots.<br>
2) The NeTV2 unfortunately have the JTAG flash connector (connecting to bundled RPi) soldered on to it. This connector will take up space to render the adjacent PCIe slot (marked as 1) unusable.
3) The Ethernet connector is on the internal facing card edge. The external facing card edge is populated with HDMI connectors not used by PCILeech.

Please also note that the NeTV2 currently have a too high latency for some PCILeech kernel injection techniques - such as injecting into recent Win10 kernels.

Flashing (by using RPi via NeTV2 Quickstart Package):
=====================================================
Easiest way to flash the NeTV2 is by flashing it with the co-bundled Rasberry Pi in the Quickstart package. Please note that you need a rather long Torx screwdriver to open the case and unscrew the NeTV2 board from the case (which won't let you access PCIe and the NeTV2 ethernet).

1. Download the pre-built bitstream for your NeTV2 model as found below - alternatively copy the built bitstream from _PCILeech_NeTV2/PCILeech_NeTV2.runs/impl_1/pcileech_netv2_top.bin_ if building from source.
<br>[XC7A35T](https://mega.nz/#!da500IyB!bW1A-DgZ8sYdQxZ0Ibzk8gSMRAtSjQpZ25j49rUHoB0) SHA256: `4669105da3ec299a507d988ec56ebf14c7c9a0d57ab6bd74f2dd72c8db319954`
<br>[XC7A100T](https://mega.nz/#!0agC2SbK!DaPNeS499POmIYr1Q_5eGn2xbjxW8d3Jy8RnFXFyQrQ) SHA256: `af5d43c942853871abf87def4e7d6feb5d7689ede6f60e28ce1a9b2ab87d09c9`
2. **scp** bitstream to RPi: `scp pcileech_netv2_top.bin pi@<IPv4_addr_of_RPi>:~/pcileech_netv2_top.bin`. The default password is: **netv2mvp**
3. **ssh** into RPi: `ssh pi@<IPv4_addr_of_RPi>`
4. **Flash!** depending on model either:
<br>**35T**: `sudo openocd -c "set BSCAN_FILE /home/pi/code/netv2mvp-scripts/bscan_spi_xc7a35t.bit" -c "set FPGAIMAGE /home/pi/pcileech_netv2_top.bin" -f /home/pi/code/netv2mvp-scripts/cl-spifpga.cfg`
<br>or
<br>**100T**: `sudo openocd -c "set BSCAN_FILE /home/pi/code/netv2mvp-scripts/bscan_spi_xc7a100t.bit" -c "set FPGAIMAGE /home/pi/pcileech_netv2_top.bin" -f /home/pi/code/netv2mvp-scripts/cl-spifpga.cfg`

It should probably be possible to flash by other methods as well, such as with OpenOCD and LambdaConcept programming cable (this is untested though). Or if having own RPi it's possible to download the sd-card image for booting the prepared NeTV2 RPi and flash it by the above method.

Building:
=================
For building instructions please check out the [build readme](build.md) for information. The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties please also check out the [build readme](build.md) for information.

Connecting to the NeTV2:
=======================
Once powered on the NeTV2 will try to fetch an IPv4 address by using DHCP regardless whether the ethernet cable is connected or not. This is indicated by a green blinking at the single HDMI port on the side. If no DHCP address is received in the first 10s the device will by default fall back to the default static IPv4 address of **192.168.0.222**. This is indicated by a red blinking at the single HDMI port on the side.

Connect to the device by using the `-device rawudp://192.168.0.222` parameter in PCILeech or MemProcFS. The transport will take place over UDP - which may be lossy. Note that any lost UDP packages are not handled and may cause issues (this is normally not a problem).

Other Notes:
=================
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. The completed solution contains an ethernet UDP core from [fpga-cores.com](https://www.fpga-cores.com). The ethernet core is OK to use for non-commercial purposes, but for commercial use a license should be acquired from fpga-cores.com.

This project as-is published on Github contains no Xilinx or fpga-cores.com proprietary IP.

Published source code are licensed under the MIT License. The end user that have downloaded the no-charge Vivado WebPACK from Xilinx will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores by running the build detailed above.

Version History:
=================
v4.0
* Initial Release.
* Download pre-built binaries for XC7A35T and XC7A100T versions below:
  * [XC7A35T](https://mega.nz/#!da500IyB!bW1A-DgZ8sYdQxZ0Ibzk8gSMRAtSjQpZ25j49rUHoB0) SHA256: `4669105da3ec299a507d988ec56ebf14c7c9a0d57ab6bd74f2dd72c8db319954`
  * [XC7A100T](https://mega.nz/#!0agC2SbK!DaPNeS499POmIYr1Q_5eGn2xbjxW8d3Jy8RnFXFyQrQ) SHA256: `af5d43c942853871abf87def4e7d6feb5d7689ede6f60e28ce1a9b2ab87d09c9`
