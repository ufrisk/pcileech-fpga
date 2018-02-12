PCILeech AC701 / FT601 PCIe to USB3:
=================
This project contains software and HDL code for the Xilinx AC701 development board used together with the FTDI FT601 add-on board.
Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) to perform DMA attacks, dump memory or perform research.

Capabilities:
=================
* Retrieve memory from the target system over USB3 at 150MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at >1GB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).

The Hardware:
=================
* Xilinx AC701 development board. ([Xilinx](https://www.xilinx.com/products/boards-and-kits/ek-a7-ac701-g.html)) ([Digikey](https://www.digikey.com/product-detail/en/xilinx-inc/EK-A7-AC701-G/122-1838-ND/3903850))
* FTDI FT601 USB3 UMFT601X-B add-on board. ([FTDI](http://www.ftdichip.com/Products/Modules/SuperSpeedModules.htm)) ([Digikey](https://www.digikey.com/product-detail/en/ftdi-future-technology-devices-international-ltd/UMFT601X-B/768-1303-ND/6556764))
* Also recommended: PCIe extension cable (very low cost ones exists on eBay).

Please see below for correct jumper and microswitch settings:

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/d01be0e485fde5ba09d84be35ca2970038e18577/_gh_fpga_ft601.jpg" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/adc36641ce9f74f1bb210334b8f6996dc65253fb/gh_ac701_desc.jpg" height="300"/>

Flashing:
=================
1) Ensure the both the AC701 and FT601 is configured correctly with correct jumpers and switches. Please see images above.
2) Install Vivado WebPACK or Lab Edition (only for flashing).
3) Build PCILeech AC701/FT601 (see below) alternatively download and unzip pre-built binary: [`pcileech_ac701_ft601.bin`](https://mega.nz/#!kbA3BTRJ!8nXUVN7sJDTOHgtuCGlkmdKR5q_Wgzpsd-y-F6eQ5Jk).
4) Open Vivado Tcl Shell command prompt.
5) cd into the directory of your pcileech_ac701.bin (forward slash instead of backslash in path).
6) Make sure the JTAG USB cable is connected.
7) Run `source vivado_flash.tcl -notrace` to flash the bitstream onto the AC701.
8) Finished !!!

If this fails please check out the Xilinx documentation about how to manually flash with Vivado.

Building:
=================
1) Install Xilinx Vivado WebPACK 2017.4 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the ac701_ft601 directory of the cloned or unpacked code (forward slash instead of backslash in path).
4) Run `source vivado_generate_project.tcl -notrace` to generate required project files.
5) Run `source vivado_build.tcl -notrace` to generate Xilinx proprietary IP cores and build bitstream.
6) Finished !!!

Building the project may take a very long time (~1 hour).

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default.

Other Notes:
=================
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. This project as-is published on Github contains no Xilinx proprietary IP. Published source code are licensed under the MIT License. The end user that have purchased a AC701 development board will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores by running the build detailed above.

Version History:
=================
v3.0
* Initial Release.
* Compatible with PCILeech v2.6
* Download pre-built binary [here](https://mega.nz/#!VCgGSJQR!z3UuWJtKcUCLcUuRMSZ1ViRf3fWU3LBL-bB-a08G7Bc).

v3.1
* Bug fixes.
* More optimization in build step to resolve timing issues.
* Download pre-built binary [here](https://mega.nz/#!kbA3BTRJ!8nXUVN7sJDTOHgtuCGlkmdKR5q_Wgzpsd-y-F6eQ5Jk).
