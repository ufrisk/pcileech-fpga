PCILeech Acorn CLE-215+ / LiteFury + FT2232H to USB2:
=================

**This project is a hardware modification project - please see the blog entry at: https://blog.frizk.net/2021/10/acorn.html for information.**

This PCILeech-FPGA project is the FPGA HDL code part of the project. It supports the Acorn CLE-215+ as well as the LiteFury FPGA boards used together with a FT2232H mini module.

Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.

> :warning: **The Acorn CLE-215+ / LiteFury + FT2232H** firmware is not actively maintained and may not be up-to-date. The current firmware will still work with PCILeech.


Capabilities:
=================
* Retrieve memory from the target system over USB2 at 25MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at >1GB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) or [MemProcFS](https://github.com/ufrisk/MemProcFS/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).

The Hardware:
=================
The hardware below is the Acorn CLE-215+ (very powerful Xilinx Artix7 200T speed grade 3 FPGA) and the LiteFury (a powerful Xilinx Artix7 100T speed grade 2 FPGA).

<img src="https://gist.github.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/25a6e45c31b617d6a5adc6240040ae0a05a80933/acorn_litefury.jpg"/>

The hardware below shows the Acorn CLE-215+ with hardware modifications connected via custom signal cable to FT2232H mini module. Please see the [blog entry](https://blog.frizk.net/2021/10/acorn.html) about this project for more information before getting started!

<img src="https://gist.github.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/25a6e45c31b617d6a5adc6240040ae0a05a80933/acorn_final.jpg"/>


Flashing:
=================
1) Install Vivado WebPACK (required for flashing).
2) Build PCILeech ACORN (see below) alternatively download and unzip pre-built binary (see below in releases section).
3) Open Vivado.
4) Flash according to instructions in the [blog entry](https://blog.frizk.net/2021/10/acorn.html) about this project.
5) Finished!


Building:
=================
For building instructions please check out the [build readme](build.md) for information. The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties please also check out the [build readme](build.md) for information.


Other Notes:
=================
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. This project as-is published on Github contains no Xilinx proprietary IP. Published source code are licensed under the MIT License. The end user that have purchased a AC701 development board will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores by running the build detailed above.


Support PCILeech/MemProcFS development:
=======================================
PCILeech and MemProcFS are hobby projects of mine. I put a lot of time and energy into my projects. The time being most of my spare time. If you think PCILeech and/or MemProcFS are awesome tools and/or if you had a use for them it's now possible to contribute.

 - Github Sponsors: [`https://github.com/sponsors/ufrisk`](https://github.com/sponsors/ufrisk)
 
To all my sponsors, Thank You :sparkling_heart:


Releases / Version History:
=================
v4.9
* Initial release.
* Download pre-built binaries for CLE-215+ and LiteFury versions below:
  * [CLE-215+](https://mega.nz/file/1SJVXK4A#ufAL7UjMizydzDOdlsdRbs5hHVjcy-PoItd7ZN0VmLQ) SHA256: `cb0d2d6d629c9003e79d2f3b805e776ec08aa355d654c1a91dc581e861ef0c84`
  * [LiteFury](https://mega.nz/file/weZxFayA#LPTh-4N_YOgfJBHlsFd0pNUY1VCheMvaDmLaphlC4qI) SHA256: `e3eb86e9515a1f95fe044f3c05221400bcb141888632fd1a1554131acb53ea09`
