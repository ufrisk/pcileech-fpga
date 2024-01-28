Screamer PCIe Squirrel:
=================
This project contains software and HDL code for the [Screamer PCIe Squirrel PCIe board](https://shop.lambdaconcept.com).

Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.

> :warning: **3rd party boards** not listed on this Github may not always be compatible with the firmware. It would depend on the 3rd party hardware vendor. No support can be given on 3rd party boards not mentioned on this Github. **If you purchase a 3rd party board please consider [sponsoring](https://github.com/sponsors/ufrisk)** this project with a small sum since the 3rd party vendor does not.


Capabilities:
=================
* Retrieve memory from the target system over USB3 in excess of 190MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at >1GB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) or [MemProcFS](https://github.com/ufrisk/MemProcFS/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).


The Hardware: Screamer PCIe Squirrel
========================
LambdaConcept PCIe Screamer Squirrel. ([LambdaConcept](http://shop.lambdaconcept.com))

For more information about the hardware, and alternative software, [LambdaConcept PCIe Screamer Squirrel Wiki](http://docs.lambdaconcept.com/screamer/index.html).

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/19ae5834c61f267bfe440cb2a3b2894633078d0a/sqr-1.jpg"/>

Flashing Screamer PCIe Squirrel: (built-in update port):
=================
**Please note that this instruction applies to the built-in update port.** OpenOCD is recommended when using the built-in update port. The built-in update port is not directly supported by Xilinx Vivado. Please also note that the on-board JTAG PINs is disabled by default.
1) Build PCILeech (see below) alternatively download and unzip pre-built binary (link in version history at the bottom of this readme).
2) Follow the instruction about how to flash with OpenOCD (Linux preferred) on the [LambdaConcept Screamer PCIe Squirrel Wiki](http://docs.lambdaconcept.com/screamer/index.html).


Building:
=================
1) Install Xilinx Vivado WebPACK 2023.2 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the directory of PCIeSquirrel (forward slash instead of backslash in path).
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
**Thank You [LambdaConcept](https://lambdaconcept.com/) for sponsoring the PCILeech project :sparkling_heart:**

Some other hardware sellers have chosen not to support the project! If you think PCILeech and/or MemProcFS is awesome or if you had a use for it it's now also possible to support the project via Github Sponsors: [`https://github.com/sponsors/ufrisk`](https://github.com/sponsors/ufrisk).
 
To all my sponsors, Thank You :sparkling_heart:


Releases / Version History:
=================
<details><summary>Previous releases (click to expand):</summary>

v4.10
* Initial Release.
* Download pre-built binaries below:
  * [Screamer PCIe Squirrel](https://mega.nz/file/UXQ2xZTK#fENkArWDadoWlWCUCI8l2k7k03mIfreHs2kBEFcVwx8) SHA256: `0a519ef2312feb4984bb0dacbea85b479b3a51789a7915ae9a28e0b61b4fd60f`

v4.11
* Bug fixes and new USB core.
* Download pre-built binaries below:
  * [Screamer PCIe Squirrel](https://mega.nz/file/ZGx30ZxB#9S7vDbQGnepPnV8XEUIWr93KkcM9O_Dzl1-ivcC-G94) SHA256: `4d0038ce607723dbc84c85393c391733a74fccd5627d2653c06fdf20890cafb7`

v4.12
* Bug fixes.
* Download pre-built binaries below:
  * [Screamer PCIe Squirrel](https://mega.nz/file/YGgjHJCR#KawMhx_r1jZVkm2hyi_mSFKtqwBh0q7eddIf10G-Jj8) SHA256: `68c8cd753b1feabf5319b6bab5d28e5b23378913f5326f39d5ac96224c5fcef9`

</details>

v4.13
* Bug fixes.
* New internal design with on-board PIO BAR support.
* Download pre-built binaries below:
  * [Screamer PCIe Squirrel](https://mega.nz/file/dexBFIKa#cdjTryyluiFDNCbbz0xhrk75UziyBKPZLokfEt5xEGo) SHA256: `ee5e2886a923b0ac19e0bb9207e879fd211ef835097bc8c224a060c3f55c417f`

v4.14
* Bug fixes.
* Download pre-built binaries below:
  * [Screamer PCIe Squirrel](https://mega.nz/file/EX5C0SRa#20cjCl2SXuwPJC9lIOKAcF5kcMt1i7NO8yYvRaxQM3Q) SHA256: `c5f05117785c5d7b7b8a57054fa7648354e23b62e353ea94ad585aba9d0b8fb6`
