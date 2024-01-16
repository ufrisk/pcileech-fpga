NeTV2 PCIe to UDP/IP:
=====================
This project contains software and HDL code for the [NeTV2 FPGA PCIe board](https://www.crowdsupply.com/alphamax/netv2).
Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.

> :warning: **NeTV2** firmware is not actively maintained and may not be up-to-date. The current firmware will still work with PCILeech.


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

1. Download the pre-built bitstream for your NeTV2 model as found below in releases section at bottom of this readme - alternatively copy the built bitstream from _PCILeech_NeTV2/PCILeech_NeTV2.runs/impl_1/pcileech_netv2_top.bin_ if building from source.
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


Support PCILeech/MemProcFS development:
=======================================
PCILeech and MemProcFS are hobby projects of mine. I put a lot of time and energy into my projects. The time being most of my spare time. If you think PCILeech and/or MemProcFS are awesome tools and/or if you had a use for them it's now possible to contribute.

 - Github Sponsors: [`https://github.com/sponsors/ufrisk`](https://github.com/sponsors/ufrisk)
 
To all my sponsors, Thank You :sparkling_heart:


Releases / Version History:
=================
<details><summary>Previous releases (click to expand):</summary>

v4.0
* Initial Release.
* Download pre-built binaries for XC7A35T and XC7A100T versions below:
  * [XC7A35T](https://mega.nz/#!da500IyB!bW1A-DgZ8sYdQxZ0Ibzk8gSMRAtSjQpZ25j49rUHoB0) SHA256: `4669105da3ec299a507d988ec56ebf14c7c9a0d57ab6bd74f2dd72c8db319954`
  * [XC7A100T](https://mega.nz/#!0agC2SbK!DaPNeS499POmIYr1Q_5eGn2xbjxW8d3Jy8RnFXFyQrQ) SHA256: `af5d43c942853871abf87def4e7d6feb5d7689ede6f60e28ce1a9b2ab87d09c9`

v4.1
* Minor bug-fixes and internal re-design.
* Download pre-built binaries for XC7A35T and XC7A100T versions below:
  * [XC7A35T](https://mega.nz/#!dHpAhY6K!G-NIsQR5j9baQnIELLT_mNFrzSj9pYZ-QJ8NiGAl_JU) SHA256: `d64ac026b345d60fe00d33f5f11321c7343cb0f4613e43f314a96c5e4105313f`
  * [XC7A100T](https://mega.nz/#!cbpwzCxB!WGaqYKTylkQmMa4Qk7vGkIqztU_nlTFm0VsIaJceVKM) SHA256: `0ed1933143bb2adfadf1eb6e05b21dea4b147083a3965cd5cf86da00467241ce`
  
v4.2
* Optional custom PCIe configuration space.
* Optional on-board static PCIe TLP transmit.
* Download pre-built binaries for XC7A35T and XC7A100T versions below:
  * [XC7A35T](https://mega.nz/#!ED5i3A4L!uaVsx9oR3S9-NlEQ4hlNnPZpUFwYjrm_0Otp7jmCcCk) SHA256: `86e1f6d4a109ca9e3dd063e6eab85efeea172701dac197fb691f538c7c7232fc`
  * [XC7A100T](https://mega.nz/#!1e4CUA4A!remhPrf7qRdqfNCgVgqRtbTAX-_9HDgqTMBwqdkKU-g) SHA256: `ed07835728641de5f5f7bb5df2c56a3b104a4c3e1fd0f23a014a10102636c5aa`

v4.4
* Disable PCIe WAKE#.
* Increased stability and reboot support.
* Support for Ryzen CPUs (NB! this is FPGA support only - PCILeech itself may still have issues).
* Download pre-built binaries for XC7A35T and XC7A100T versions below:
  * [XC7A35T](https://mega.nz/file/dD5AzaTR#o2oZSnlkxcT0543aHINSFOXvXFuQU6TaGbyNz3fUTt8) SHA256: `27a534192d597f42e8bc98bf561086c0ec5eeef1827d4590ec0ac7ac534de69f`
  * [XC7A100T](https://mega.nz/file/BK400CLS#oopXORZGvA1VW1v8S8t-JGF9FKcY3k63E732rLIU-i8) SHA256: `97b90c2efe0211aeb499ec82e2882cf9151546f4229c0577d5da6220f1dfec5f`

v4.5
* Fix for receiving initial data from PCILeech host.
* Download pre-built binaries for XC7A35T and XC7A100T versions below:
  * [XC7A35T](https://mega.nz/file/oLIzyA4b#FA9d8bokRxIN_SlIY8qbD0rJeMZKDM56Flq4Fbwu4o4) SHA256: `b280e184d71b76f6c1f21ae5a373ebd913e28ed3477326f3997f59c55f1cbf9a`
  * [XC7A100T](https://mega.nz/file/UCRziabR#RaO0d3aivOy4pv4QXQ_vG6-f9eIASBqB05yCEkGSr5k) SHA256: `e4e4eee85012c2312878413c8ba6c49d07a51eb07967b46dea3c919e8ba8900e`

v4.7
* New USB core.
* Support for auto-clear of PCIe status register / master abort flag.
* Download pre-built binaries for XC7A35T and XC7A100T versions below:
  * [XC7A35T](https://mega.nz/file/oKpAyQBC#OxNyFagjpLb56MIA_iqUCAZ1Vm6hAaEBzEhXrgQmrxg) SHA256: `222d023060373840140932113eb98aff41225a6658026fe585725081a48b5388`
  * [XC7A100T](https://mega.nz/file/sDo0BYDI#kUbXIaWqUX0LCHnK56hLBpzzS_YLy_9T9ArFomgUgkc) SHA256: `01b18df54e63d086d4b0a593e5e24a56f05925b01692711d2e16f9952856a8ab`

v4.8
* Bug fixes.
* Download pre-built binaries for XC7A35T version below:
  * [XC7A35T](https://mega.nz/file/kP5BwCJI#MGitoKdvQEnE6c8-yCZv31fa7LR8ab2VFJ8wWfpqO54) SHA256: `e4d27efc10e00bf592b8bc7bc8de34b528357c0dc062bc81aa5a08fc0ca2d46b`

v4.9
* Bug fixes.
* Download pre-built binaries for XC7A35T version below:
  * [XC7A35T](https://mega.nz/file/YGxQCCpD#ZZ5Yu_SvyERCl6Atx0OSdqX36yyBnKHByqIWQvOQmaI) SHA256: `3ed45eeb66408090cee6aa5a4b0706e1b857af6199c5e515da37a27a019defbe`
</details>

v4.12
* Bug fixes.
* Download pre-built binaries for XC7A35T version below:
  * [XC7A35T](https://mega.nz/file/JH5nFTbQ#-vn3nrpubC9V4KF0E-GZgNnx6UrQk9p0CHUQvDUE0pM) SHA256: `6a70cc7d969f25c85ed1195ce1f7f98c7f54b3a44944bc09e1009c4b2a9ae1fa`
