PCIeScreamer PCIe to USB3:
=================
This project contains software and HDL code for the [PCIeScreamer FPGA PCIe board](https://shop.lambdaconcept.com).
Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) to perform DMA attacks, dump memory or perform research.

Capabilities:
=================
* Retrieve memory from the target system over USB3 up to 100MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).

The Hardware:
=================
* LambdaConcept PCIeScreamer PCIe board. ([LambdaConcept](http://shop.lambdaconcept.com/home/11-pciescreamer.html))

For more information about the hardware, and alternative software, please check out the [PCIeScreamer wiki](http://blog.lambdaconcept.com/doku.php?id=products:pcie_screamer).

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/e4e9ae4bf5fe0f723d6afe30703ac97df7e2c905/__gh_pciescreamer2.jpg" height="400"/>

Please also note that the DIP-switch SW2 should be configured as: 1: ON, 2: OFF, 3: OFF.

Flashing (Xilinx/Diligent programming cable):
=================
Please note that this instruction applies to Xilinx Vivado compatible programming cables, such as Diligent HS2. This instruction will <i>not</i> work with the LambdaConcept programming cable.
1) Install Vivado WebPACK or Lab Edition (only for flashing).
2) Build PCILeech PCIeScreamer (see below) alternatively download and unzip pre-built binary (v3.2): [`pcileech_pciescreamer.bin`](https://mega.nz/#!1LgCzDTQ!5bo20E17oYc_zA1ofwAzXFgGtiHuEoa4PyaXrPk4spY). Alternatively try the v3.3-beta version.
3) Open Vivado Tcl Shell command prompt.
4) cd into the directory of your unpacked files, or this directory (forward slash instead of backslash in path).
5) Make sure the JTAG USB cable is connected.
6) Run `source vivado_flash_hs2.tcl -notrace` to flash the PCILeech bitstream onto the PCIeScreamer board.
7) Finished !!!

Flashing (LambdaConcept programming cable):
=================
Please note that this instruction applies to the LambdaConcept programming cable. OpenOCD is recommended when using the LambdaConcept programming cable. The LambdaConcept programming cable is not supported by Xilinx Vivado.
1) Build PCILeech PCIeScreamer (see below) alternatively download and unzip pre-built binary: [`pcileech_pciescreamer.bin`](https://mega.nz/#!VKI3HSiB!PqfghoIJNn6k8ScxIACtZyMRVg6sr1wC3zQ1zca95oM).
2) Follow the instruction about how to flash with OpenOCD (Linux preferred) on the [LambdaConcept PCIeScreamer Wiki](http://blog.lambdaconcept.com/doku.php?id=products:pcie_screamer).

Building:
=================
1) Install Xilinx Vivado WebPACK 2018.2 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the directory of your pcileech_ac701.bin (forward slash instead of backslash in path).
4) Run `source vivado_generate_project.tcl -notrace` to generate required project files.
5) Run `source vivado_build.tcl -notrace` to generate Xilinx proprietary IP cores and build bitstream.
6) Finished !!!

Building the project may take a very long time (~1 hour).

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default.

Stability Issues:
=================
The current software/hardware combo is not completely stable. The PCIe link to the target system may experience instability, degradation or total loss of connectivity in some cases. In some cases the link intermittently becomes unavailable resulting in lost DMA/TLP packets. PCILeech mitigates this to some degree in software.

The PCIeScreamer is:
* Most likely OK if connected directly to PCIe slot of target system (connectivity loss or degradation of link happens occasionally).
* Likely OK if connected directly to ExpressCard adapter such as BPlus PE3A. (connectivity loss or degradation of link likely).
* Most likely NOT OK if connected to PCIe extension cable. (total loss of connectivity).

Furthermore, if connected to source which does not provide sufficient power, such as ExpressCard slot with PE3A adapter, it is recommended to use external power to the PCeScreamer to increase stability. 5V-15V is recommended. This is not needed if connected directly to PCIe slot in target computer.

If stability is paramount the SP605 or AC701 hardware is currently recommended.

Other Notes:
=================
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. This project as-is published on Github contains no Xilinx proprietary IP. Published source code are licensed under the MIT License. The end user that have downloaded the no-charge Vivado WebPACK from Xilinx will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores by running the build detailed above.

Version History:
=================
v3.0
* Initial Release.
* Compatible with PCILeech v2.6.
* Download pre-built binary [here](https://mega.nz/#!VCBgzZZA!kTgM-J5OM9sv0r4TraetLpOrKxisFQ9RsTIOaoKnGN8). <br>SHA256: `4e8c0e536f543a9a1266ff65530dcefd2a7909a7fe98f7e1696a3aed1d5da136`

v3.2
* Bug fixes - USB and Timing.
* Download pre-built binary [here](https://mega.nz/#!1LgCzDTQ!5bo20E17oYc_zA1ofwAzXFgGtiHuEoa4PyaXrPk4spY). <br>SHA256: `bbd506082532cae75a006ee310967dd695ea5068548d851c958a597d504641bf`

v3.3-beta
* Internal changes - data buffering in RAM.
* Download pre-built binary [here](https://mega.nz/#!8Wp2gYzb!dUj9WpstO9KZdA11p_VzR7PPbTDOEB1JXLoih4v9QmY). <br>SHA256: `8273595938a046969b54ca5606b833a354b664077bbbfa623905037684e2a67d`
