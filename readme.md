PCILeech FPGA Summary:
=================
PCILeech FPGA contains software and HDL code for FPGA based devices that may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/).
Using FPGA based devices have many advantages over using the USB3380 hardware that have traditionally been supported by PCILeech. 
FPGA based hardware provides full access to 64-bit memory space without having to rely on a kernel module running on the target system. 
FPGA based devices are also more stable compared to the USB3380. FPGA based devices may also send raw PCIe Transaction Layer Packets TLPs - allowing for more specialized research.

Supported Devices:
=================
PCILeech currently supports multiple FPGA based devices - please see the table below:

| Device                       | Connection | Transfer Speed | PCIe Version | OS support<br>(on attacker) | Creator         |
| ---------------------------- | ---------- | -------------- | ------------ | ------------------------ | --------------- |
| [AC701/FT601](ac701_ft601)   | USB3       | 150 MB/s       | PCIe gen2 x4 | Windows                  | Ulf Frisk       |
| [PCIeScreamer](pciescreamer) | USB3       | 100 MB/s       | PCIe gen2 x1 | Windows                  | Ramtin Amin<br>Ulf Frisk |
| [SP605/FT601](sp605_ft601)   | USB3       | 75 MB/s        | PCIe gen1 x1 | Windows                  | Ulf Frisk       |
| [SP605/TCP](https://github.com/Cr4sh/s6_pcie_microblaze) | TCP/IP | 100kB/s | PCIe gen1 x1 | Windows, Linux, Android  | Dmytro Oleksiuk |

Please select the FPGA setup that best suits your needs from the above list. If performance is key the AC701 is currently recommended.

Please check out the individual FPGA projects in the table above for more information about the purchase, usage, building and flashing of the devices. Each device have different advantages and disadvantages.

The images below depicts the SP605, PCIeScreamer and AC701 devices used for PCILeech PCIe access over USB3.

<img src="https://gist.github.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/31a153ab0ee8769e5971bfc2ed955008f422be21/_gh_sp605_front.jpg" height="230"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/2dec37bf6f495b419fd78ff616beede45af6cec1/_gh_pciescreamer1.jpg" height="230"/><img src="https://gist.github.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/31a153ab0ee8769e5971bfc2ed955008f422be21/_gh_ac701_front.jpg" height="230"/>

Future Work:
=================
* Add Linux and Android support to PCILeech for FPGA devices.
* Add support for more FPGA devices.
