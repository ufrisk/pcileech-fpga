PCILeech FPGA Summary:
=================
PCILeech FPGA contains software and HDL code for FPGA based devices that may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/).
Using FPGA based devices have many advantages over using the USB3380 hardware that have traditionally been supported by PCILeech. 
FPGA based hardware provides full access to 64-bit memory space without having to rely on a kernel module running on the target system. 
FPGA based devices are also more stable compared to the USB3380. FPGA based devices may also send raw PCIe Transaction Layer Packets TLPs - allowing for more specialized research.

For information about PCILeech itself please check out the [PCILeech](https://github.com/ufrisk/pcileech/) project.

Supported Devices:
=================
PCILeech currently supports multiple FPGA based devices - please see the table below:

| Device          | Connection | Transfer Speed | PCIe Version | OS support (on attacker) | Creator         |
| --------------- | ---------- | -------------- | ------------ | ------------------------ | --------------- |
| [SP605/FT601](sp605_ft601)     | USB3       | 50-75 MB/s     | PCIe gen1 x1 | Windows                  | Ulf Frisk       |
| [SP605/TCP](https://github.com/Cr4sh/s6_pcie_microblaze)     | TCP/IP     | 100kB/s        | PCIe gen1 x1 | Windows, Linux, Android  | Dmytro Oleksiuk |

Please select the FPGA setup that best suits your needs from the above list. If performance is key the SP605 / FT601 combo is currently recommended.

Please check out [PCILeech SP605 FT601](sp605_ft601) for more information about the usage, building and flashing of the SP605/FT601 combo. The images below depicts the SP605 / FT601 combo used for PCILeech PCIe access over USB3.

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/d01be0e485fde5ba09d84be35ca2970038e18577/_gh_fpga_ft601.jpg" height="300"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/d01be0e485fde5ba09d84be35ca2970038e18577/_gh_fpga_sp605.jpg" height="300"/>

Future Work (SP605/FT601 design):
=================
* Add Linux and Android support to PCILeech.
* Increase memory dump speed.
