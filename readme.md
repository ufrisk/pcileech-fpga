PCILeech FPGA Summary:
=================
PCILeech FPGA contains software and HDL code for FPGA based devices that may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) and [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/).
Using FPGA based devices have many advantages over using the USB3380 hardware that have traditionally been supported by PCILeech. 
FPGA based hardware provides full access to 64-bit memory space without having to rely on a kernel module running on the target system. 
FPGA based devices are also more stable compared to the USB3380. FPGA based devices may also send raw PCIe Transaction Layer Packets TLPs - allowing for more specialized research.

Supported Devices:
=================
PCILeech currently supports multiple FPGA based devices - please see the table below:

| Device                       | Connection | Transfer Speed | PCIe Version  |
| ---------------------------- | ---------- | -------------- | ------------- |
| [AC701/FT601](ac701_ft601)   | USB3       | 150 MB/s       | PCIe gen2 x4* |
| [ScreamerM2](ScreamerM2)**   | USB3/USB-C | 150 MB/s       | PCIe gen2 x4* |
| [PCIeScreamer](pciescreamer) | USB3       | 100 MB/s       | PCIe gen2 x1  |
| [SP605/FT601](sp605_ft601)   | USB3       | 75 MB/s        | PCIe gen1 x1  |
| [NeTV2](NeTV2)               | UDP/IP     | 7 MB/s         | PCIe gen2 x4* |
| [SP605/TCP](https://github.com/Cr4sh/s6_pcie_microblaze) | TCP/IP | 100kB/s | PCIe gen1 x1 |

###### *) PCILeech FPGA uses PCIe x1 even if more PCIe lanes are available hardware-wise. This is sufficient to deliver neccessary performance.
###### **) The ScreamerM2 bitstream also work with RaptorDMA hardware.

Please select the FPGA setup that best suits your needs from the above list. If performance is key the ScreamerM2 or the AC701 is currently recommended.

Please check out the individual FPGA projects in the table above for more information about the purchase, usage, building and flashing of the devices. Each device have different advantages and disadvantages.

The images below depicts the SP605, ScreamerM2, PCIeScreamer, ScreamerM2, AC701 devices used for PCILeech PCIe access over USB3 and the NeTV2 for access over 100Mbit UDP/IP.

<img src="https://gist.github.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/31a153ab0ee8769e5971bfc2ed955008f422be21/_gh_sp605_front.jpg" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/2dec37bf6f495b419fd78ff616beede45af6cec1/_gh_pciescreamer1.jpg" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/f806a68890c94561e53caa7758a5903bb01f5670/gh_m2_1.png" height="300"/>
<img src="https://gist.github.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/31a153ab0ee8769e5971bfc2ed955008f422be21/_gh_ac701_front.jpg" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/2032adf8761dfdfc8bad86b08c2385b2497070be/_gh_netv2_1.jpg" height="300"/>

Future Work:
=================
* Add support for more FPGA devices.

Support PCILeech/MemProcFS development:
=======================================
PCILeech and MemProcFS are hobby projects of mine. I put a lot of time and energy into my projects. The time being most of my spare time. If you think PCILeech and/or MemProcFS are awesome tools and/or if you had a use for them it's now possible to contribute.

 - Github Sponsors: [`https://github.com/sponsors/ufrisk`](https://github.com/sponsors/ufrisk)
 
To all my sponsors, Thank You :sparkling_heart:
