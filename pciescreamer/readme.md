PCIeScreamer PCIe to USB3:
=================
This project contains software and HDL code for the [PCIeScreamer FPGA PCIe board](https://shop.lambdaconcept.com).
Once flashed it may be used together with the [PCILeech Direct Memory Access (DMA) Attack Toolkit](https://github.com/ufrisk/pcileech/) or [MemProcFS - The Memory Process File System](https://github.com/ufrisk/MemProcFS/) to perform DMA attacks, dump memory or perform research.

> :warning: **The PCIeScreamer R01/R02** firmware is not actively maintained and may not be up-to-date. The current firmware will still work with PCILeech.

Capabilities:
=================
* Retrieve memory from the target system over USB3 up to 100MB/s.
* Access all memory of target system without the need for kernel module (KMD) unless protected with VT-d/IOMMU.
* Enumerate/Probe accessible memory at >1GB/s.
* Raw PCIe Transaction Layer Packet (TLP) access.

For information about more capabilities check out the general [PCILeech](https://github.com/ufrisk/pcileech/) or [MemProcFS](https://github.com/ufrisk/MemProcFS/) abilities and capabilities.

For information about other supported FPGA based devices please check out [PCILeech FPGA](https://github.com/ufrisk/pcileech-fpga/).

The Hardware:
=================
* LambdaConcept PCIeScreamer R02 PCIe board. ([LambdaConcept](http://shop.lambdaconcept.com/home/32-pciescreamerR02.html))

For more information about the hardware, and alternative software, please check out the [PCIeScreamer wiki](http://blog.lambdaconcept.com/doku.php?id=products:pcie_screamer).

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/e4e9ae4bf5fe0f723d6afe30703ac97df7e2c905/__gh_pciescreamer2.jpg" height="400"/>

Please also note that the DIP-switch SW2 should be configured as: 1: ON, 2: OFF, 3: OFF (R01 model only).

Flashing (Xilinx/Diligent programming cable):
=================
Please note that this instruction applies to Xilinx Vivado compatible programming cables, such as Diligent HS2. This instruction will <i>not</i> work with the LambdaConcept programming cable.
1) Install Vivado WebPACK or Lab Edition (only for flashing).
2) Build PCILeech PCIeScreamer (see below) alternatively download and unzip pre-built binary (see below in releases section).
3) Open Vivado Tcl Shell command prompt.
4) cd into the directory of your unpacked files, or this directory (forward slash instead of backslash in path).
5) Make sure the JTAG USB cable is connected.
6) Run `source vivado_flash_hs2.tcl -notrace` to flash the PCILeech bitstream onto the PCIeScreamer board.
7) Finished !!!

Flashing (LambdaConcept programming cable):
=================
Please note that this instruction applies to the LambdaConcept programming cable. OpenOCD is recommended when using the LambdaConcept programming cable. The LambdaConcept programming cable is not supported by Xilinx Vivado.
1) Build PCILeech PCIeScreamer (see below) alternatively download and unzip pre-built binary (link in version history at the bottom of this readme).
2) Follow the instruction about how to flash with OpenOCD (Linux preferred) on the [LambdaConcept PCIeScreamer Wiki](http://blog.lambdaconcept.com/doku.php?id=products:pcie_screamer).

Building:
=================
1) Install Xilinx Vivado WebPACK 2020.2 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the directory of your pcileech_ac701.bin (forward slash instead of backslash in path).
4) Run `source vivado_generate_project.tcl -notrace` to generate required project files.
5) Run `source vivado_build.tcl -notrace` to generate Xilinx proprietary IP cores and build bitstream.
6) Finished !!!

Building the project may take a very long time (~1 hour).

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties check out the [build readme](build.md) for information.

Stability Issues:
=================
The PCIeScreamer R01 is known to have stability issues. The PCILeech/LeechCore have some mitigations built into the v3.2 version of the bitstream to mitigate as much as possible. If using the R01 version of the PCIeScreamer use the v3.2 version of the bitstream. The PCIe link to the target system may experience instability, degradation or total loss of connectivity in some cases. In some cases the link intermittently becomes unavailable resulting in lost DMA/TLP packets.

The PCIeScreamer R02 is more stable and should be usable in most situations. Use the latest version of the bitstream if using the R02 version. The latest version have stability mitigations removed which increases performance.

No stability issues or bug fixes will take place for the R01 version of the PCIeScreamer.

Furthermore, if connected to source which does not provide sufficient power, such as ExpressCard slot with PE3A adapter, it is recommended to use external power to the PCeScreamer to increase stability. 5V-15V is recommended. This is not needed if connected directly to PCIe slot in target computer.

If stability is paramount the ScreamerM2 or the more expensive SP605 or AC701 hardware is currently recommended. The PCIeScreamer R02 should be fine for most situations but the most demanding ones (e.g. offensive PCIe DMA attacking locked computers) in which the Xilinx dev boards are still prefered.

Other Notes:
=================
The completed solution contains Xilinx proprietary IP cores licensed under the Xilinx CORE LICENSE AGREEMENT. This project as-is published on Github contains no Xilinx proprietary IP. Published source code are licensed under the MIT License. The end user that have downloaded the no-charge Vivado WebPACK from Xilinx will have the proper licenses and will be able to re-generate Xilinx proprietary IP cores by running the build detailed above.

Releases / Version History:
=================
<details><summary>Previous releases (click to expand):</summary>

v4.0
* Major internal re-design for increased future flexibility and ease of use.
* Download pre-built binaries for R01 and R02 versions of the PCIeScreamer below:
  * [R01](https://mega.nz/#!wTg2EAJL!w6ceKt1Yd7M64dwz2V0dOsACh0DzTcTq8k1fZi5Vtyg) SHA256: `c4af173d40b0023229dccd4fc21cd515a67e5565f78c00c17797c7b1e5079591`
  * [R02](https://mega.nz/#!8WpUQKqB!zNacAGjFyyUXrYYWq4ZLGBjmmg9tA3XoJhsQOhkDk0c) SHA256: `43bc08fb3708afaa32ee091025ed358ad46b6e1a88c3eecd10ef9a02d7bdc39f`

v4.1
* Minor bug-fixes and internal re-design.
* Download pre-built binaries for R01 and R02 versions of the PCIeScreamer below:
  * [R01](https://mega.nz/#!tbhwUaKQ!gixprx3CwhMnP9cxbJiT3U9K4MSupGyWbLwEEIEcxMQ) SHA256: `7b45c8ac6b6f4fa0a3824ecc2a69b01ab5096fb0cdc6a6c00c4cf224288dee78`
  * [R02](https://mega.nz/#!Na4CDIRC!lkWRQgj6M_zi81OPJQYA2KZpfRlQlWVAN29WU4jIElE) SHA256: `8cb8c30cfaa514462fde6db0dc416bf06ddc94576798f0875ccd359c30e55b4c`

v4.2
* Optional custom PCIe configuration space.
* Optional on-board static PCIe TLP transmit.
* Download pre-built binaries for R01 and R02 versions of the PCIeScreamer below:
  * [R01](https://mega.nz/#!pCgG2ajB!P64I04yKWgd_uX2br4Jd5nQ2FTaE0EbKKMgM7kbamxU) SHA256: `858d8faf11fb9d5e861f5cd7bbc94234b62dd6d8ec8464b7f5cd9585e226a025`
  * [R02](https://mega.nz/#!oOhg1SYR!445FVx40YlpeO14fO8DNn_43VqpX5ZUCE69lRA9rLTc) SHA256: `6200360b2b8caa16f9683bc660a4b9000ba3ff9dad300a2c6bf2e02c331b2c27`

v4.6
* Support for Ryzen CPUs.
* Support connecting USB cable after device power-on.
* NB! stability issues remain!
  * [R01](https://mega.nz/file/geQBgKYL#n7Orl6SDmXxbBW8WfXjPqpTSmuot4B2-dA4smVC0Qzo) SHA256: `d0579e5b691de8f37a7f835898a1c6562498cd42a7808b73b8eb569db2bd4548`
  * [R02](https://mega.nz/file/RSJx2aRT#MCqIKd8Pteq6LOodVmsg_LDRyoYgehzolUEQKGj3s4s) SHA256: `f4402e56ab1dd98f846e7dcb232e8068ac1bb9594959f1b7440afec55d80bc73`

v4.7
* New USB core.
* Support for auto-clear of PCIe status register / master abort flag.
* NB! stability issues remain!
  * [R01](https://mega.nz/file/tKoinKgC#RB9i0y0vSwo2J2nf21_XfHZhM_I-JCPuhxXlNpWMFMI) SHA256: `2f564b979f77202ec6153797657e169648ca52180553a77ae73a55005b759094`
  * [R02](https://mega.nz/file/VPxAjQqC#TpYO1Odakv6QD3dOwDWmWeXqUXcmzu0-8UnGsDdjlIc) SHA256: `29a6b06fc13034dfde65db87b6953b8d8531c00584ec8a3067cef89ba8d2b747`

v4.8
* Bug fixes.
* NB! stability issues remain!
  * [R02](https://mega.nz/file/9Xg3FAKT#fJSGvm4vNIB6nkFHaI1QhwrTatR-0ipKliAf0zmWIsU) SHA256: `8be43dbf89f30eb25db4582291de8a07e11cd4b36824c4f50125aa7488e9c6de`

</details>

v4.9
* Bug fixes.
* NB! stability issues remain!
  * [R02](https://mega.nz/file/MepgCYiY#zSQYu5SdgHtlui3eoU36vR-PlpXnIp3Q4Q3wml3KaoQ) SHA256: `f46c816b70d18a135f0587db4e5daeeba266c17bff94cc2cccb9e90703d1d884`

**PCILeech-FPGA versions above v4.2 are only partially supported due to lack of hardware support.**
