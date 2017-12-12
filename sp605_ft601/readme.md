PCILeech SP605 / FT601 PCIe to USB3:
=================
This project contains software and HDL code for the Xilinx SP605 development board used together with the FTDI FT601 add-on board.
Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) to perform DMA attacks, dump memory or perform research.

Capabilities:
=================
* Retrieve memory from the target system over USB3 at 50-75MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at >1GB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) abilities and capabilities.

The Hardware:
=================
* Xilinx SP605 development board. ([Xilinx](https://www.xilinx.com/products/boards-and-kits/ek-s6-sp605-g.html)) ([Digikey](https://www.digikey.com/product-detail/en/xilinx-inc/EK-S6-SP605-G/122-1605-ND/2175980))
* FTDI FT601 USB3 UMFT601X-B add-on board. ([FTDI](http://www.ftdichip.com/Products/Modules/SuperSpeedModules.htm)) ([Digikey](https://www.digikey.com/product-detail/en/ftdi-future-technology-devices-international-ltd/UMFT601X-B/768-1303-ND/6556764))
* Also recommended: PCIe extension cable (very low cost ones exists on eBay).

Please see below for correct jumper and microswitch settings:

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/d01be0e485fde5ba09d84be35ca2970038e18577/_gh_fpga_ft601.jpg" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/d01be0e485fde5ba09d84be35ca2970038e18577/_gh_fpga_sp605.jpg" height="300"/>

Flashing:
=================
1) Ensure the both the SP605 and FT601 is configured correctly with correct jumpers and switches. Please see images above.
2) Install Xilinx ISE Development Environment.
3) Build PCILeech SP605/FT601 (see below) alternatively download and unzip pre-built binary: [`pcileech.mcs`](https://mega.nz/#!BCRUED6R!4qhJ57cF0iMK0Ux26XOtyqdN_GLTOc2bwu6cKxj4468).
4) Open ISE Design Suite 64-Bit Command Prompt.
5) Make sure the JTAG USB cable is connected.
6) Run `flash.bat` to flash the bitstream onto the SP605.
7) Finished !!!

If this fails please check out the [Xilinx documentation](https://www.xilinx.com/support/documentation/boards_and_kits/sp605_PCIe_Gen1_x1_pdf_xtp065_13.4.pdf) about how to flash manually with Impact.

Building:
=================
1) Install Xilinx ISE Development Environment.
2) Open ISE Design Suite 64-Bit Command Prompt.
3) Run `build.bat` to generate Xilinx proprietary IP cores and build bitstream.
4) Finished !!!

Even if just opening the project for viewing it's recommended to first run build - since Xilinx proprietary IP isn't included in soruce form in github project due to licensing issues. The user will have first to rebuild IP by running `build.bat` or the Xilinx `coregen` utility before opening the project in ISE.

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties check out the [advanced build readme](build.md) for information.

Future Work:
=================
* Increase memory dump speed. This is not likely to happen in the near future, but hopefully the current 50-75MB/s is still useful.

Other Notes:
=================
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. This project as-is published on Github contains no Xilinx proprietary IP. Published source code are licensed under the MIT License. The end user that have puschased a SP605 development board will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores with the `build.bat` script.

Version History:
=================
v1.0
* Initial Release.
* Compatible with PCILeech v2.3-2.4
* Download pre-built binary [here](https://mega.nz/#!oLZ0lbZT!6LUpE9kXdteg7fQaJlTEViJpPOsVsrzdYnFfsuXceGA).

v2.0
* Bug fixes and re-design.
* Compatible with PCILeech v2.5+
* Download pre-built binary [here](https://mega.nz/#!BCRUED6R!4qhJ57cF0iMK0Ux26XOtyqdN_GLTOc2bwu6cKxj4468).
