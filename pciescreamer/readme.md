PCIeScreamer PCIe to USB3:
=================
This project contains software and HDL code for the [PCIeScreamer FPGA PCIe board](https://shop.lambdaconcept.com).
Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.

Capabilities:
=================
* Retrieve memory from the target system over USB3 up to 100MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at >1GB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) or [MemProcFS](https://github.com/ufrisk/MemProcFS/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).

The Hardware:
=================
* LambdaConcept PCIeScreamer R02 PCIe board. ([LambdaConcept](http://shop.lambdaconcept.com/home/32-pciescreamerR02.html))

For more information about the hardware, and alternative software, please check out the [PCIeScreamer wiki](http://blog.lambdaconcept.com/doku.php?id=products:pcie_screamer).

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/e4e9ae4bf5fe0f723d6afe30703ac97df7e2c905/__gh_pciescreamer2.jpg" height="400"/>

Please also note that the DIP-switch SW2 should be configured as: 1: ON, 2: OFF, 3: OFF (R01 model only).

Flashing (Xilinx/Diligent programming cable):
=================
Please note that this instruction applies to Xilinx Vivado compatible programming cables, such as Diligent HS2. This instruction will <i>not</i> work with the LambdaConcept programming cable.
1) Install Vivado WebPACK or Lab Edition (only for flashing).
2) Build PCILeech PCIeScreamer (see below) alternatively download and unzip pre-built binary for R02 (v3.4): [`pcileech_pciescreamer.bin`](https://mega.nz/#!8LxGWQab!nOJ5IM4yhDDnjoyBmX13l2frsvPwDEZqP7-YWz8dV0s). NB! for earlier R01 release download the v3.2 version of the bitstream.
3) Open Vivado Tcl Shell command prompt.
4) cd into the directory of your unpacked files, or this directory (forward slash instead of backslash in path).
5) Make sure the JTAG USB cable is connected.
6) Run `source vivado_flash_hs2.tcl -notrace` to flash the PCILeech bitstream onto the PCIeScreamer board.
7) Finished !!!

Flashing (LambdaConcept programming cable):
=================
Please note that this instruction applies to the LambdaConcept programming cable. OpenOCD is recommended when using the LambdaConcept programming cable. The LambdaConcept programming cable is not supported by Xilinx Vivado.
1) Build PCILeech PCIeScreamer (see below) alternatively download and unzip pre-built binary (link in version history at the bottom of this readme).
2) Follow the instruction about how to flash with OpenOCD (Linux preferred) on the [LambdaConcept PCIeScreamer Wiki](http://blog.lambdaconcept.com/doku.php?id=products:pcie_screamer).

Building:
=================
1) Install Xilinx Vivado WebPACK 2018.3 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the directory of your pcileech_ac701.bin (forward slash instead of backslash in path).
4) Run `source vivado_generate_project.tcl -notrace` to generate required project files.
5) Run `source vivado_build.tcl -notrace` to generate Xilinx proprietary IP cores and build bitstream.
6) Finished !!!

Building the project may take a very long time (~1 hour).

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties check out the [build readme](build.md) for information.

Stability Issues:
=================
The PCIeScreamer R01 is known to have stability issues. The PCILeech/LeechCore have some mitigations built into the v3.2 version of the bitstream to mitigate as much as possible. If using the R01 version of the PCIeScreamer use the v3.2 version of the bitstream. The PCIe link to the target system may experience instability, degradation or total loss of connectivity in some cases. In some cases the link intermittently becomes unavailable resulting in lost DMA/TLP packets.

The PCIeScreamer R02 is more stable and should be usable in most situations. Use the latest version of the bitstream if using the R02 version. The latest version have stability mitigations removed which increases performance.

No stability issues or bug fixes will take place for the R01 version of the PCIeScreamer.

Furthermore, if connected to source which does not provide sufficient power, such as ExpressCard slot with PE3A adapter, it is recommended to use external power to the PCeScreamer to increase stability. 5V-15V is recommended. This is not needed if connected directly to PCIe slot in target computer.

If stability is paramount the more expensive SP605 or AC701 hardware is currently recommended. The PCIeScreamer R02 should be fine for most situations but the most demanding ones (e.g. offensive PCIe DMA attacking locked computers) in which the Xilinx dev boards are still prefered.

Other Notes:
=================
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. This project as-is published on Github contains no Xilinx proprietary IP. Published source code are licensed under the MIT License. The end user that have downloaded the no-charge Vivado WebPACK from Xilinx will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores by running the build detailed above.


Version History:
=================
v3.0
* Initial Release.
* Compatible with PCILeech v2.6.
* Download pre-built binary [here](https://mega.nz/#!VCBgzZZA!kTgM-J5OM9sv0r4TraetLpOrKxisFQ9RsTIOaoKnGN8). <br>SHA256: `4e8c0e536f543a9a1266ff65530dcefd2a7909a7fe98f7e1696a3aed1d5da136`

v3.2 - use if using PCIeScreamer R01 board
* Bug fixes - USB and Timing.
* Download pre-built binary [here](https://mega.nz/#!1LgCzDTQ!5bo20E17oYc_zA1ofwAzXFgGtiHuEoa4PyaXrPk4spY). <br>SHA256: `bbd506082532cae75a006ee310967dd695ea5068548d851c958a597d504641bf`

~~v3.3-beta~~
* ~~Internal changes - data buffering in RAM.~~
* ~~Download pre-built binary [here](https://mega.nz/#!8Wp2gYzb!dUj9WpstO9KZdA11p_VzR7PPbTDOEB1JXLoih4v9QmY). <br>SHA256: `8273595938a046969b54ca5606b833a354b664077bbbfa623905037684e2a67d`~~

v3.4 - use if using PCIeScreamer R02 board
* Minor design changes and bug fixes.
* Download pre-built binary [here](https://mega.nz/#!8LxGWQab!nOJ5IM4yhDDnjoyBmX13l2frsvPwDEZqP7-YWz8dV0s). <br>SHA256: `ae02af2b14b098c91cf56f24f564a8b08dc395f1d473833ff893fa58836633e8`

v4.0
* Major internal re-design for increased future flexibility and ease of use.
* Download pre-built binaries for R01 and R02 versions of the PCIeScreamer below:
  * [R01](https://mega.nz/#!wTg2EAJL!w6ceKt1Yd7M64dwz2V0dOsACh0DzTcTq8k1fZi5Vtyg) SHA256: `c4af173d40b0023229dccd4fc21cd515a67e5565f78c00c17797c7b1e5079591`
  * [R02](https://mega.nz/#!8WpUQKqB!zNacAGjFyyUXrYYWq4ZLGBjmmg9tA3XoJhsQOhkDk0c) SHA256: `43bc08fb3708afaa32ee091025ed358ad46b6e1a88c3eecd10ef9a02d7bdc39f`
