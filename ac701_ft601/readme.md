PCILeech AC701 / FT601 PCIe to USB3:
=================
This project contains software and HDL code for the Xilinx AC701 development board used together with the FTDI FT601 add-on board.
Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.


Capabilities:
=================
* Retrieve memory from the target system over USB3/USB-C in excess of 190MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at >1GB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) or [MemProcFS](https://github.com/ufrisk/MemProcFS/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).


The Hardware:
=================
* Xilinx AC701 development board. ([Xilinx](https://www.xilinx.com/products/boards-and-kits/ek-a7-ac701-g.html)) ([Digikey](https://www.digikey.com/product-detail/en/xilinx-inc/EK-A7-AC701-G/122-1838-ND/3903850))
* FTDI FT601 USB3 UMFT601X-B add-on board. ([FTDI](http://www.ftdichip.com/Products/Modules/SuperSpeedModules.htm)) ([Digikey](https://www.digikey.com/product-detail/en/ftdi-future-technology-devices-international-ltd/UMFT601X-B/768-1303-ND/6556764))
* Also recommended: PCIe extension cable (very low cost ones exists on eBay).

Please see below for correct jumper and microswitch settings:

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/d01be0e485fde5ba09d84be35ca2970038e18577/_gh_fpga_ft601.jpg" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/adc36641ce9f74f1bb210334b8f6996dc65253fb/gh_ac701_desc.jpg" height="300"/>

###### GPIO_LED0 = blink on ft601 clk; GPIO_LED1 = lit; GPIO_LED2 = PCIe state; SW3 = RESET; SW5 = blink GPIO_LED1.

Flashing:
=================
1) Ensure the both the AC701 and FT601 is configured correctly with correct jumpers and switches. Please see images above.
2) Install Vivado WebPACK or Lab Edition (only for flashing).
3) Build PCILeech AC701/FT601 (see below) alternatively download and unzip pre-built binary (see below in releases section).
4) Open Vivado Tcl Shell command prompt.
5) cd into the directory of your pcileech_ac701.bin (forward slash instead of backslash in path).
6) Make sure the JTAG USB cable is connected.
7) Run `source vivado_flash.tcl -notrace` to flash the bitstream onto the AC701.
8) Finished !!!

If this fails please check out the Xilinx documentation about how to manually flash with Vivado.


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
<details><summary>Previous releases (click to expand):</summary>
v4.0
* Major internal re-design for increased future flexibility and ease of use.
* Download pre-built binary [here](https://mega.nz/#!4DxE1AoR!0o8BiuwaU1YOACDXE1mXhzoopNKcc86Eexd5GMCBG44). <br>SHA256: `f9873de8f63a2844585c2450fa1aff5a8edd7e8d297655a65fe9883277957d55`

v4.1
* Minor bug-fixes and internal re-design.
* Download pre-built binary [here](https://mega.nz/#!Ja4wGaTA!07cDnJupQQUYU2WtpjhNOhzZJ8ULNwX78l8nB_WD59E). <br>SHA256: `a57468028fffb673064cef7f9b41e268794d4b631ea4747817f79e5cafd3c1ea`

v4.2
* Optional custom PCIe configuration space.
* Optional on-board static PCIe TLP transmit.
* Download pre-built binary [here](https://mega.nz/#!lHw0GY5L!jJaSToLPmGLo3r6uTQ7UPn-OXC69soWf4sZUZ4JdkJo). <br>SHA256: `fedf159d9c21b79ad5ca2a57b03b3319c97e7632ac7294d84bbfabadf1a781db`

v4.4
* Disable PCIe WAKE#.
* Increased stability and reboot support.
* Support for Ryzen CPUs (NB! this is FPGA support only - PCILeech itself may still have issues).
* Download pre-built binary [here](https://mega.nz/file/UPgWyShJ#4G8TCtdGEU17NFZs0kU8_mX_04m27GTUxOsb7eNfpFY). <br>SHA256: `fa6f90e101273766608fab8cbb13361489d5a2bc0ed8e91e64fbe45ff67d7ddf`

v4.5
* Fix for receiving initial data from PCILeech host.
* Download pre-built binary [here](https://mega.nz/file/8DIhlAgI#T-GBLdhtYj5pNSG0vIc2zhWr_3KmUZbFijS-cap23Hs). <br>SHA256: `fd1982b1e8e2da48b0fa75ffb196eb41ac45c13dbb25f7547bb084c4c152f4f7`

v4.6
* Support connecting USB cable after device power-on.
* Download pre-built binary [here](https://mega.nz/file/oP4T1SqJ#ng6h0DYTiE8kxEtdCWEh5To8xD8Ehgn19ZvBzgiPsvg). <br>SHA256: `8ea10e48711f67bd38bf9fb0003ca1bf67ea8bd91243ae7fefa250a8257d6774`

v4.7
* New USB core.
* Support for auto-clear of PCIe status register / master abort flag.
* Download pre-built binary [here](https://mega.nz/file/5LhgyIAD#J0WxajgP4B8aTBsYFJo0zAkTJhdwDaF-rHjdOCHzmfs). <br>SHA256: `5d8ab88d1499ea002a2d22901f2ffba2a6319463401e532d58368f70224c2b2e`

v4.8
* Bug fixes.
* Download pre-built binary [here](https://mega.nz/file/0WgT1CoR#0UGvgxH6mpQvuwg7QOjiEjbr52OBw6FCQ3HVJuISvg4). <br>SHA256: `9131243d1d50b97b4dcfaff1436d770cda69999cf699b2e6862feca8a7a66166`

v4.9
* Bug fixes.
* Download pre-built binary [here](https://mega.nz/file/dbhSSaDb#Dkyd9vnQugZpSjumBFvVTIAkomPEsfv8ojg6HMAXBMs). <br>SHA256: `1e031f660a2734f38eb8e42003521af66475a9cee3d13069fa93f1a92b1174e9`

v4.11
* Bug fixes and new USB core.
* Download pre-built binary [here](https://mega.nz/file/1CQ0lb4Y#TmcP3GTrTum5EhEBOyti5q7aQ_uqg7WEFltkSj-Hk8A). <br>SHA256: `281b8f068fa3b74e5ee3653497ea94d03f0bd95c42f4f995cf3047b4bcc5a710`

v4.12
* Bug fixes.
* Download pre-built binary [here](https://mega.nz/file/haxAFYZR#6oEOklJH4hmyWYW7Ffhj88wdiUoaxVgyIpbEFhS95aY). <br>SHA256: `4581fda04fb681c7d0fe909c156c7c8dcb2c789bb3c0422ade0a973d8962365b`

v4.13
* Bug fixes.
* New internal design with on-board PIO BAR support.
* Download pre-built binary [here](https://mega.nz/file/1W4QgILB#t5pBSs2eznL8crm3GgSNRzbk1CSzb3_YSTI5Ok65-Ww) SHA256: `1607eed95b24b470be20b4ea710c0a4d0f446786a7acae939df4b827201cddea`
</details>

v4.14
* Bug fixes.
* Download pre-built binary [here](https://mega.nz/file/AOhiSKDZ#OiQr9rgyWiOMMLE7S_qG3NDKLdRmpHs3tNENtKMw5v0) SHA256: `7d13e2626df82a352df16011ce94d0ca8f3958190fba08facda702f5e0a1916a`

v4.15
* Bug fixes for PCIe x4 interface.
* Download pre-built binary [here](https://mega.nz/file/EbpwHTKB#TIYE4UorBDvBEFG_Year-jC8UYz27sRNqJGfJxbKiOY) SHA256: `ea27d5588fdb2a8250bb30e35fda727d20441ec94b825cb6d473a608f25736e8`
