PCILeech FPGA Summary:
=================
PCILeech FPGA contains software and HDL code for FPGA based devices that may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) and [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/).
Using FPGA based devices have many advantages over using the USB3380 hardware that have traditionally been supported by PCILeech. 
FPGA based hardware provides full access to 64-bit memory space without having to rely on a kernel module running on the target system. 
FPGA based devices are also more stable compared to the USB3380. FPGA based devices may also send raw PCIe Transaction Layer Packets TLPs - allowing for more specialized research.

Supported Devices:
=================
PCILeech currently supports multiple FPGA based devices - please see the table below:

| Device                       | Connection | Transfer Speed | PCIe Version  | OS support<br>(on attacker) | Creator         |
| ---------------------------- | ---------- | -------------- | ------------- | ------------------------ | --------------- |
| [AC701/FT601](ac701_ft601)   | USB3       | 150 MB/s       | PCIe gen2 x4* | Windows                  | Ulf Frisk       |
| [ScreamerM2](ScreamerM2)     | USB3/USB-C | 150 MB/s       | PCIe gen2 x4* | Windows                  | Ramtin Amin<br>Ulf Frisk |
| [PCIeScreamer](pciescreamer) | USB3       | 100 MB/s       | PCIe gen2 x1  | Windows                  | Ramtin Amin<br>Ulf Frisk |
| [SP605/FT601](sp605_ft601)   | USB3       | 75 MB/s        | PCIe gen1 x1  | Windows                  | Ulf Frisk       |
| [NeTV2](NeTV2)               | UDP/IP     | 7 MB/s         | PCIe gen2 x4* | Windows                  | Ulf Frisk       |
| [SP605/TCP](https://github.com/Cr4sh/s6_pcie_microblaze) | TCP/IP | 100kB/s | PCIe gen1 x1 | Windows, Linux | Dmytro Oleksiuk |

###### *) PCILeech FPGA uses PCIe x1 even if more PCIe lanes are available hardware-wise. This is sufficient to deliver neccessary performance.

Please select the FPGA setup that best suits your needs from the above list. If performance is key the ScreamerM2 or the AC701 is currently recommended.

Please check out the individual FPGA projects in the table above for more information about the purchase, usage, building and flashing of the devices. Each device have different advantages and disadvantages.

The images below depicts the SP605, ScreamerM2, PCIeScreamer, ScreamerM2 and AC701 devices used for PCILeech PCIe access over USB3 and the NeTV2 for access over 100Mbit UDP/IP.

<img src="https://gist.github.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/31a153ab0ee8769e5971bfc2ed955008f422be21/_gh_sp605_front.jpg" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/f806a68890c94561e53caa7758a5903bb01f5670/gh_m2_1.png" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/2dec37bf6f495b419fd78ff616beede45af6cec1/_gh_pciescreamer1.jpg" height="300"/>
<img src="https://gist.github.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/31a153ab0ee8769e5971bfc2ed955008f422be21/_gh_ac701_front.jpg" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/2032adf8761dfdfc8bad86b08c2385b2497070be/_gh_netv2_1.jpg" height="300"/>

Future Work:
=================
* Add support for more FPGA devices.

Support PCILeech/MemProcFS development:
=======================================
**I'm not officially affiliated with any hardware sold! I do _NOT_ receive any revenue from hardware sold! If you purchase hardware to use PCILeech/MemProcFS please consider supporting the project as well!**

PCILeech and MemProcFS are hobby projects of mine. I put a lot of time and energy into my projects. The time being most of my spare time - since I'm not able to work with this. Unfortunately since some aspects also relate to hardware I also put quite some of money into my projects. If you think PCILeech and/or MemProcFS are awesome tools and/or if you had a use for them it's now possible to contribute.

Please do note that PCILeech and MemProcFS are free and open source - as such I'm not expecting sponsorships; even though a sponsorship would be very much appreciated. I'm also not able to promise product features, consultancy or other things in return for a sponsorship. A sponsorship will have to stay a sponsorship and no more.

 - Github Sponsors: [`https://github.com/sponsors/ufrisk`](https://github.com/sponsors/ufrisk)
 
