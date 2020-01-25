ScreamerM2 M.2 Key E (PCIe) to USB3:
=================
This project contains software and HDL code for the [ScreamerM2 FPGA PCIe board](https://shop.lambdaconcept.com).
Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.

Capabilities:
=================
* Retrieve memory from the target system over USB3 up to 150MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at >1GB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) or [MemProcFS](https://github.com/ufrisk/MemProcFS/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).

The Hardware:
=================
* LambdaConcept ScreamerM2 M.2 Key E board. ([LambdaConcept](http://shop.lambdaconcept.com))

For more information about the hardware, and alternative software, please check out the [PCIeScreamer wiki](http://blog.lambdaconcept.com/doku.php?id=products:pcie_screamer).

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/f806a68890c94561e53caa7758a5903bb01f5670/gh_m2_2.png"/>

Flashing (Xilinx/Diligent programming cable):
=================
Please note that this instruction applies to Xilinx Vivado compatible programming cables, such as Diligent HS2. This instruction will <i>not</i> work with the LambdaConcept programming cable.
1) Install Vivado WebPACK or Lab Edition (only for flashing).
2) Build PCILeech ScreamerM2 (see below) alternatively download and unzip pre-built binary (see below in releases section).
3) Open Vivado Tcl Shell command prompt.
4) cd into the directory of your unpacked files, or this directory (forward slash instead of backslash in path).
5) Make sure the JTAG USB cable is connected.
6) Run `source vivado_flash_hs2.tcl -notrace` to flash the PCILeech bitstream onto the ScreamerM2 board.
7) Finished !!!

Flashing (LambdaConcept programming cable):
=================
Please note that this instruction applies to the LambdaConcept programming cable. OpenOCD is recommended when using the LambdaConcept programming cable. The LambdaConcept programming cable is not supported by Xilinx Vivado.
1) Build PCILeech PCIeScreamer (see below) alternatively download and unzip pre-built binary (link in version history at the bottom of this readme).
2) Follow the instruction about how to flash with OpenOCD (Linux preferred) on the [LambdaConcept PCIeScreamer Wiki](http://blog.lambdaconcept.com/doku.php?id=products:pcie_screamer).

Building:
=================
1) Install Xilinx Vivado WebPACK 2019.2 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the directory of ScreamerM2 (forward slash instead of backslash in path).
4) Run `source vivado_generate_project.tcl -notrace` to generate required project files.
5) Run `source vivado_build.tcl -notrace` to generate Xilinx proprietary IP cores and build bitstream.
6) Finished !!!

Building the project may take a very long time (~1 hour).

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties check out the [build readme](build.md) for information.


Other Notes:
=================
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. This project as-is published on Github contains no Xilinx proprietary IP. Published source code are licensed under the MIT License. The end user that have downloaded the no-charge Vivado WebPACK from Xilinx will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores by running the build detailed above.


Releases / Version History:
=================
v4.1
* Initial Release.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/#!pC4CzKxK!GwnhexGDB4kppY6naI99M2edV66_MXiY2DQ7HSAdcPM) SHA256: `589eb60b26745a0b5c4dbc8831a71b1f3edbcaf693384366a1d2d374a8400169`

v4.2
* Optional custom PCIe configuration space.
* Optional on-board static PCIe TLP transmit.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/#!sGwyQKTZ!zA9OjhL1_En-H_OzJA4rlqZLptcCP5in5XhK1E1kRno) SHA256: `ec9a1df74c969f970dbd5bddcc47ecdb0c38ca80a9b2d2a503dbc247553163bc`

v4.3
* Blink LD2 on startup.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/#!ofogyYBS!lR3K6nMqS5PTqREXVC6uea_MQrjskwMs_alIxlGfXv8) SHA256: `961d3526a0c89b0965cafabffcd1f3ceacb2e5788d0e3716767ddf04b2fb9385`
