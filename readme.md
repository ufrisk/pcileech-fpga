PCILeech FPGA Summary:
=================
PCILeech FPGA contains software and HDL code for FPGA based devices that may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/).
Using FPGA based devices have many advantages over using the USB3380 hardware that have traditionally been supported by PCILeech. 
FPGA based hardware provides full access to 64-bit memory space without having to rely on a kernel module running on the target system. 
FPGA based devices are also more stable compared to the USB3380. FPGA based devices may also send raw PCIe Transaction Layer Packets TLPs - allowing for more specialized research.

For information about PCILeech itself please check out the [PCILeech](https://github.com/ufrisk/pcileech/) project.

Supported Devices:
=================
PCILeech currently supports the Xilinx SP605 development board together with a FTDI601 add-on card for a USB3 connection. The combo is currently capable of dumping memory at 85MB/s over PCIe gen1 x1.

Please check out [PCILeech SP605 FT601](sp605_ft601) for more information about the usage, building and flashing of the device.

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/d01be0e485fde5ba09d84be35ca2970038e18577/_gh_fpga_sp605.jpg" height="300"/>

Future Work:
=================
* Increase top speed from 85MB/s.
* Fix known bugs and inefficiencies in the SP506/FT601 design.
* Add support for more devices to PCILeech including a [Network connected SP605](https://github.com/Cr4sh/s6_pcie_microblaze) by Cr4sh/Dmytro Oleksiuk.

Other Notes:
=================
Current design have known inefficiencies and bugs. This should not hurt users in any other ways than low transfer speeds (85MB/s @i7 7700K attacker, 56MB/s @i5 surface3 attacker). Attack speed should reach well over 100MB/s if redesigned. A re-design is planned for later.
