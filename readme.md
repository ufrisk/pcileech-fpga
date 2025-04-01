PCILeech FPGA Summary:
=================
PCILeech FPGA contains software and HDL code for FPGA based devices that may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) and [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/).
Using FPGA based devices have many advantages over using the USB3380 hardware that have traditionally been supported by PCILeech. 
FPGA based hardware provides full access to 64-bit memory space without having to rely on a kernel module running on the target system. 
FPGA based devices are also more stable compared to the USB3380. FPGA based devices may also send raw PCIe Transaction Layer Packets TLPs - allowing for more specialized research.



Supported Devices:
=================
PCILeech currently supports multiple FPGA based devices with most recent firmware versions - please see the table below:

| Device                                     | Connection   | Transfer Speed | Version | FPGA         | PCIe Version    | Project<br>Sponsor                   |
| ------------------------------------------ | ------------ | -------------- | --------| ------------ | --------------- | ------------------------------------ |
| [Screamer PCIe Squirrel](PCIeSquirrel)     | USB-C        | 190 MB/s       | 4.14    | XC7A35T-484  | PCIe gen2 x1    | [💖](https://shop.lambdaconcept.com) |
| [ZDMA](ZDMA)                               | Thunderbolt3 | 1000 MB/s      | 4.17    | XC7A100T-484 | PCIe gen2 x4    | [💖](https://lightningz.net/)       |
| [GBOX](GBOX)                               | Thunderbolt3 | 220+ MB/s      | 4.15    | XC7A35T-484  | PCIe gen2 x1-x4 | [💖](https://lightningz.net/)       |
| [LeetDMA](https://enigma-x1.com/)          | USB-C        | 190 MB/s       | 4.14    | XC7A35T-484  | PCIe gen2 x1    | [💖](https://enigma-x1.com/)         |
| [CaptainDMA M2](CaptainDMA)                | USB-C        | 190 MB/s       | 4.15    | XC7A35T-325  | PCIe gen2 x1-x4 | [💖](https://www.captaindma.com/)    |
| [CaptainDMA 4.1th](CaptainDMA)             | USB-C        | 190 MB/s       | 4.14    | XC7A35T-484  | PCIe gen2 x1    | [💖](https://www.captaindma.com/)    |
| [CaptainDMA 75T](CaptainDMA)               | USB-C        | 200 MB/s       | 4.14    | XC7A75T-484  | PCIe gen2 x1    | [💖](https://www.captaindma.com/)    |
| [Enigma X1](EnigmaX1)                      | USB-C        | 200 MB/s       | 4.14    | XC7A75T-484  | PCIe gen2 x1    | [💖](https://enigma-x1.com/)         |
| [ScreamerM2](ScreamerM2)                   | USB3/USB-C   | 190 MB/s       | 4.14    | XC7A35T-325  | PCIe gen2 x4*   | [💖](https://shop.lambdaconcept.com) |
| [AC701/FT601](ac701_ft601)                 | USB3         | 190 MB/s       | 4.15    | XC7A200T-676 | PCIe gen2 x4    |                                      |

###### *) PCILeech FPGA uses PCIe x1 even if more PCIe lanes are available hardware-wise. This is sufficient to deliver neccessary performance.

Select the FPGA setup that best suits your needs from the above list. If performance and value for money is key the Screamer PCIe Squirrel is currently recommended. If performance is key alone ZDMA is a good pick.

Check out the individual FPGA projects in the table above for more information about the purchase, usage, building and flashing of the devices. Each device have different advantages and disadvantages.

**A special Thank You 💖 to the project hardware sponsors!**
* [LambdaConcept](https://shop.lambdaconcept.com) - The original maker of custom PCILeech hardware and the maker of the [Screamer PCIe Squirrel](PCIeSquirrel).
* [Enigma-X1](https://enigma-x1.com/) - Long time supporter and the maker of [Enigma X1](EnigmaX1) and [LeetDMA](https://enigma-x1.com/).
* [LightingZ](https://lightningz.net/) - Maker of the fastest PCILeech hardwares, the [ZDMA](ZDMA) and [GBOX](GBOX).
* [CaptainDMA](https://captaindma.com/) - Our most recent sponsor, maker of many PCILeech compatible hardwares including [M2 devices](https://captaindma.com/product/captain-dma-m-2/).

Thank You [LambdaConcept](https://shop.lambdaconcept.com),  [Enigma-X1](https://enigma-x1.com/), [LightingZ](https://lightningz.net/) and [CaptainDMA](https://captaindma.com/) for supporting the PCILeech and MemProcFS projects 💖

**The images below depicts:**
* Top row: LambdaConcept Screamer PCIe Squirrel and ZDMA.
* Middle row: CaptainDMA M2, CaptainDMA 75T and LeetDMA.
* Bottom row: NeTV2, SP605 and AC701.


<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/19ae5834c61f267bfe440cb2a3b2894633078d0a/sqr-1.jpg" height="280"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/65984ae014a8caa659c2e297dbb77c6c67c0889a/zdma-250.jpg" height="280"/>

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/91288318c4824ba73a25bb1320b7b970dab9a243/captaindma_m2_2.png" height="200"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/91288318c4824ba73a25bb1320b7b970dab9a243/captaindma_75t.png" height="200"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/5d214db54bcba428690007d8705ed6b4012b15d5/leet-1.jpg" height="200"/>

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/2032adf8761dfdfc8bad86b08c2385b2497070be/_gh_netv2_1.jpg" height="200"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/66612319445e565edd215d6a1d9f4d84f1e845e7/_gh_sp605_front_x200.jpg" height="200"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/66612319445e565edd215d6a1d9f4d84f1e845e7/_gh_ac701_front_x200.jpg" height="200"/>



Older Devices:
==============

PCILeech also supports multiple FPGA based devices that may not have the most recent firmware available for download, but will still work with some limitations:

| Legacy Device                          | Connection  | Transfer Speed | Version | PCIe Version  |
| -------------------------------------- | ----------- | -------------- | ------- | ------------- |
| [PCIeScreamer](pciescreamer)           | USB3        | 100 MB/s       | 4.9     | PCIe gen2 x1  |
| [SP605/FT601](sp605_ft601)             | USB3        | 75 MB/s        | 2.2     | PCIe gen1 x1  |
| [Acorn/FT2232H](acorn_ft2232h)         | USB2        | 25 MB/s        | 4.9     | PCIe gen2 x4* |
| [NeTV2](NeTV2)                         | UDP/IP      | 7 MB/s         | 4.12    | PCIe gen2 x4* |



Support PCILeech/MemProcFS development:
=======================================
PCILeech and MemProcFS are hobby projects of mine. I put a lot of time and energy into my projects. The time being most of my spare time. If you think PCILeech and/or MemProcFS are awesome tools and/or if you had a use for them it's now possible to contribute.

 - Github Sponsors: [`https://github.com/sponsors/ufrisk`](https://github.com/sponsors/ufrisk)
 
To all my sponsors, Thank You :sparkling_heart:
