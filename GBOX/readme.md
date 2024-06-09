GBOX - PCIe to PCIe over OCuLink:
=================================
This project contains software and HDL code for the [GBOX device](https://lightingz.store/).

Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.

> :warning: **GBOX have additional requirements**. Make sure the [requirements](#Requirements) are met before purchase.

Capabilities:
=============
* Retrieve memory from the target system over Thunderbolt in excess of 220MB/s.
* Access physical memory of target system unless protected with VT-d/IOMMU.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general readme and info wiki pages at: [PCILeech](https://github.com/ufrisk/pcileech/), [MemProcFS](https://github.com/ufrisk/MemProcFS/) and [LeechCore](https://github.com/ufrisk/LeechCore/) for information about features and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).


The Hardware: GBOX
==================
The GBOX PCIe gen2 x1-x4 hardware contains an Artix7 35T FPGA which allows for good performance and also interesting applications besides PCILeech/MemProcFS. The GBOX may be purchased from: [lightingz.store](https://lightingz.store/). For more information about the hardware please check out [lightingz.store](https://lightingz.store/). Please note that the GBOX is sold by a 3rd party and not by the PCILeech project itself!

The GBOX contains a two OCuLink PCIe ports for data transfer and an update port for easy updating without the need for additional hardware.

Performance is roughly as follows:

| Config Target Computer (PC1) | Config Controller Computer (PC2) | Performance |
| ---------------------------- | -------------------------------- | ----------- |
| OCuLink to PCIe x1           | OCuLink to PCIe x1               | 220MB/s     |
| OCuLink to PCIe x4           | OCuLink to PCIe x1               | 220MB/s     |
| OCuLink to PCIe x1           | OCuLink to PCIe x4               | 280MB/s     |
| OCuLink to PCIe x4           | OCuLink to PCIe x4               | 400MB/s     |

Requirements:
=============
* A PCIe x4 or PCIe x16 slot on the target computer (PC1) (if x4 adapter is used), otherwise a PCIe x1 slot is sufficient.
* A PCIe x4 or PCIe x16 slot on the controlling computer (PC2) (if x4 adapter is used), otherwise a PCIe x1 slot is sufficient.
* 64-bit Windows or on the controlling computer (PC2). 64-bit (x64) Ubuntu will also work.

Windows Driver:
===============
GBOX requires a signed Windows kernel driver. [Download it here](https://mega.nz/file/Eb5nwZ5K#4lAN0NddlSjET-5yPgtoBp4VMmatT63cjoRkMTa5Bu0). Right click on the .inf file and select "install" in the popup menu that appears to install the driver. Additionally GBOX requires the file leechcore_driver.dll. This file should be included in the latest downloads of PCILeech and MemProcFS.

Linux Driver:
=============
GBOX requires Linux driver to be compiled from source to a kernel module (.ko). [Download it here](https://mega.nz/file/xOZkgQJb#6BbC8mbE2_AHoRRoh58PuPQij0pZ_l6eJxvfPFME4MQ). Additionally GBOX requires the file leechcore_driver.so. This file should be included in the latest downloads of PCILeech and MemProcFS.

:warning: The Linux driver currently does not fully support IOMMU (enabled by default). This will result in failed tx. It's possible to disable it in BIOS settings or via kernel boot parameter.

Flashing:
=========
Please note that this instruction applies to the built-in JTAG update port.
1) Install Vivado WebPACK or Lab Edition (only for flashing).
2) Build PCILeech GBOX (see below) alternatively download and unzip pre-built binary (see below in releases section).
3) Open Vivado.
4) Open Hardware Manager found on the Vivado start screen.
5) Open target. Make sure the USB cable is connected to the JTAG port of the GBOX device.
6) Flash using Xilinx Vivado Hardware Manager (shown below). Make sure you flash `xc7a35t_0` (the other fpga must not be flashed)! Please select memory part: `is25lp128f`.
7) Finished !!!


Building:
=================
1) Install Xilinx Vivado WebPACK 2023.2 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the directory of GBOX (forward slash instead of backslash in path).
4) Run `source vivado_generate_project.tcl -notrace` to generate required project files.
5) Run `source vivado_build.tcl -notrace` to generate Xilinx proprietary IP cores and build bitstream.
6) Finished !!!

Building the project may take a very long time (~1 hour).

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties check out the [build readme](build.md) for information.


Other Notes:
============
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. This project as-is published on Github contains no Xilinx proprietary IP. Published source code are licensed under the MIT License. The end user that have downloaded the no-charge Vivado WebPACK from Xilinx will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores by running the build detailed above.


Support PCILeech/MemProcFS development:
=======================================
**Thank You LightingZDMA for supporting the PCILeech project :sparkling_heart:**

Some other hardware sellers have chosen not to support the project! If you think PCILeech and/or MemProcFS is awesome or if you had a use for it it's now possible to support the project via Github Sponsors: [`https://github.com/sponsors/ufrisk`](https://github.com/sponsors/ufrisk).

To all my sponsors, Thank You :sparkling_heart:


Releases / Version History:
===========================

v4.15
* Initial Release.
* Download pre-built binaries below:
  * [GBOX](https://mega.nz/file/lOIC3BRa#21-NVCgM1x1VdIe7jZlbGhOcAV7kNRSRQKrEJMbxh9g) SHA256: `4f699ce126461846714f9e969bdae73e73f5ac0f630d335414d3b88133275bef`
