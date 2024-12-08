PCIeScreamerR04 and ScreamerM2:
=================
This project contains software and HDL code for the [PCIeScreamerR04 PCIe board](https://shop.lambdaconcept.com) and the [ScreamerM2 FPGA M.2. board](https://shop.lambdaconcept.com).

Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.

:warning: The ScreamerM2 and PCIeScreamerR04 is no longer on sale at LambdaConcept. This project is kept as a reference project for users of the original hardware.


Capabilities:
=================
* Retrieve memory from the target system over USB3/USB-C in excess of 190MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at >1GB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) or [MemProcFS](https://github.com/ufrisk/MemProcFS/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).


The Hardware: ScreamerM2
========================
LambdaConcept ScreamerM2 M.2 Key M board. ([LambdaConcept](http://shop.lambdaconcept.com))

For more information about the hardware, and alternative software, [LambdaConcept ScreamerM2 Wiki](http://docs.lambdaconcept.com/screamer/index.html).

NB! The picture below depicts a ScreamerM2 R03 with a micro-usb3 connector. ScreamerM2 R04 have an USB-C connector instead. Both versions use identical software.

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/f806a68890c94561e53caa7758a5903bb01f5670/gh_m2_2.png"/>


Flashing ScreamerM2: (Xilinx/Diligent programming cable):
=================
Please note that this instruction applies to Xilinx Vivado compatible programming cables, such as Diligent HS2. This instruction will <i>not</i> work with the LambdaConcept programming cable.
1) Install Vivado WebPACK or Lab Edition (only for flashing).
2) Build PCILeech ScreamerM2 (see below) alternatively download and unzip pre-built binary (see below in releases section).
3) Open Vivado Tcl Shell command prompt.
4) cd into the directory of your unpacked files, or this directory (forward slash instead of backslash in path).
5) Make sure the JTAG USB cable is connected.
6) Run `source vivado_flash_hs2.tcl -notrace` to flash the PCILeech bitstream onto the ScreamerM2 board.
7) Finished !!!


Flashing ScreamerM2: (LambdaConcept programming cable):
=================
Please note that this instruction applies to the LambdaConcept programming cable. OpenOCD is recommended when using the LambdaConcept programming cable. The LambdaConcept programming cable is not supported by Xilinx Vivado.
1) Build PCILeech PCIeScreamer (see below) alternatively download and unzip pre-built binary (link in version history at the bottom of this readme).
2) Follow the instruction about how to flash with OpenOCD (Linux preferred) on the [LambdaConcept ScreamerM2 Wiki](http://docs.lambdaconcept.com/screamer/index.html).


Building:
=================
1) Install Xilinx Vivado WebPACK 2023.2 or later.
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


Support PCILeech/MemProcFS development:
=======================================
**Thank You [LambdaConcept](https://shop.lambdaconcept.com/) for sponsoring the PCILeech project :sparkling_heart:**

Some other hardware sellers have chosen not to support the project! If you think PCILeech and/or MemProcFS is awesome or if you had a use for it it's now also possible to support the project via Github Sponsors: [`https://github.com/sponsors/ufrisk`](https://github.com/sponsors/ufrisk).
 
To all my sponsors, Thank You :sparkling_heart:


Releases / Version History:
=================
<details><summary>Previous releases (click to expand):</summary>
v4.1
* Initial Release.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/file/hPZwiQwa#GwnhexGDB4kppY6naI99M2edV66_MXiY2DQ7HSAdcPM) SHA256: `589eb60b26745a0b5c4dbc8831a71b1f3edbcaf693384366a1d2d374a8400169`

v4.2
* Optional custom PCIe configuration space.
* Optional on-board static PCIe TLP transmit.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/file/keJh3KCQ#zA9OjhL1_En-H_OzJA4rlqZLptcCP5in5XhK1E1kRno) SHA256: `ec9a1df74c969f970dbd5bddcc47ecdb0c38ca80a9b2d2a503dbc247553163bc`

v4.3
* Blink LD2 on startup.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/file/9SBnQJLC#lR3K6nMqS5PTqREXVC6uea_MQrjskwMs_alIxlGfXv8) SHA256: `961d3526a0c89b0965cafabffcd1f3ceacb2e5788d0e3716767ddf04b2fb9385`

v4.4
* Disable PCIe WAKE#.
* Increased stability and reboot support.
* Support for Ryzen CPUs (NB! this is FPGA support only - PCILeech itself may still have issues).
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/file/JXIFnBYR#RZ_r90yVYB9UeCTdIaJZ1avTKVq4s25BBfWefgVOT0k) SHA256: `54ed5706357459d9595906b833155783801da9c1ef852c79e0533d4b613796df`

v4.5
* Fix for receiving initial data from PCILeech host.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/file/UbBBQQ5K#2kD04ffpducrxojd4p2Iv9mr7ShHuScL5G8EU6xqn9w) SHA256: `04ca8e631981020dc12a4116c585e686def1b63d58660edb5970b00b3ce4592c`
  
v4.6
* Support connecting USB cable after device power-on.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/file/ACoVHCwL#vEpzHxNOSRsaEJXI4ce6OnPtjZECZVhIV4HEnRxV1T0) SHA256: `875c32a36934875f194af7d68648a5454c63aaa6ec4a730532632d9424148cd3`
  
v4.7
* New USB core.
* Support for auto-clear of PCIe status register / master abort flag.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/file/0exghSoS#bqdbZFT3eGH9k1BHGuhtB16QHte_uJjsnfUt-VpYQB8) SHA256: `431959337c3321ddaa18d2eed85b7af5abf03f59db99880a1c9b1f5f9b204746`

v4.8
* Bug fixes.
* Download pre-built binaries below:
  * [ScreamerM2](https://mega.nz/file/cagCkZwT#XcrGhKWvI4d23wUuyctWa6NGBi3xGJIf_815iaROmOg) SHA256: `926413ae821ef6b0e6cd5b0833691c04d67629d78c60b09a63dee5d0eb51e95d`

v4.9
* Bug fixes.
* Download pre-built binaries below:
  * [PCIeScreamerR04/ScreamerM2](https://mega.nz/file/5GQ31YRB#6Sf6sU0y7RBpwgBAFrYNAOL6XHSzcevRkuEfmvyv0Hw) SHA256: `f4095b649117182c5a3130c5ea48b049ad02a2dd9d095fe11a5715f582ff495a`

v4.11
* Bug fixes.
* Download pre-built binaries below:
  * [PCIeScreamerR04/ScreamerM2](https://mega.nz/file/tHZm2SxR#ksoa5QyW3l4FmlQuSkX1UsL_n2zvhmWGnV1zSxFMcYQ) SHA256: `64be806e262e859126b93ebb3283c91be18c942bc2a690c95e6b966538572385`
 
v4.12
* Bug fixes.
* Download pre-built binaries below:
  * [PCIeScreamerR04/ScreamerM2](https://mega.nz/file/ZPJVnL4Y#J6oZtYc9FwW459VqKVcuXEpvKmD9esZiDs9yOCv2WDk) SHA256: `d2e063f26367fbf2d00df52f0f5fb7ec18732d91aaa47cca8733399e55d697a0`
</details>
 
v4.13
* Bug fixes.
* New internal design with on-board PIO BAR support.
* Download pre-built binaries below:
  * [PCIeScreamerR04/ScreamerM2](https://mega.nz/file/tSp1xZZI#e1OJqMkQrq3fTG2rXQe695fYnsp1neOr_8FH3kWymoA) SHA256: `25d5b47a7ba6d485bc8cf35c6f45c8a9f99ab906657ce706a012353437c37b39`

v4.14
* Bug fixes.
* New internal design with on-board PIO BAR support.
* Download pre-built binaries below:
  * [PCIeScreamerR04/ScreamerM2](https://mega.nz/file/sSIHTDyB#MgXLLu9ZHapz3sl3pDjHHndly3ph_fAbEqbfT3aD158) SHA256: `e0a93e9c0bfcba3f9ebe219d5d302a93599c13526fb0e6d9537847cd14a27565`
