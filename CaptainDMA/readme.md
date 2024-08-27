# CaptainDMA Hardware

[CaptainDMA](https://www.captaindma.com/) is a supporter of the PCILeech and MemProcFS projects. CaptainDMA makes several different hardwares that may be used together with the PCILeech project.

Pre-built default versions of the PCILeech default bitstream exists for CaptainDMA M2 (in PCIe x1 and x4 versions), CaptainDMA 75T and CaptainDMA 35T 4.1.

For additional support if the below instructions aren't sufficient, to flash etc., contact [CaptainDMA](https://www.captaindma.com/).



## CaptainDMA M2

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/91288318c4824ba73a25bb1320b7b970dab9a243/captaindma_m2_2.png" height="215"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/7632ff874708db8ce94ab3f262e09e04ff90992c/captaindma_m2_tb.png" height="215"/><img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/7632ff874708db8ce94ab3f262e09e04ff90992c/captaindma_m2_h.png" height="215"/>

CaptainDMA M2 is a M2 key M device based on Artix7 35T. It's ideal for security research when M2 slots usually found on laptops are targeted. It's also ideal when Thunderbolt is targeted together with the CaptainDMA Thunderbolt enclosure.

To flash the CaptainDMA M2 you may flash it with either a PCIe x1 firmware or a PCIe x4 firmware, both available for download below in the firmware section. The speeds are similar between the x1 and x4 versions since they are bottlenecked by the USB connection which is slower than the PCIe connection.

To flash the CaptainDMA M2 you'd require a separate M2-FW flash module which can be purchased separately from CaptainDMA. Note that even the CaptainDMA M2 contains a JTAG header the spacing between the PINs are non-standard. It's therefore recommended to get the M2-FW flash module.

To flash: Download the [CH347 FPGA Tool](https://github.com/WCHSoftGroup/ch347/releases/tag/CH347_OpenOCD_Release) and the firmware below. Start the WCH347 fpga flash tool as elevated admin and flash. Drivers for WCH347 may also have to be installed.



## CaptainDMA 75T

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/7632ff874708db8ce94ab3f262e09e04ff90992c/captaindma_75t.png" height="300"/>

CaptainDMA 75T is a standard PCIe board which is ideal when targeting desktop PCs with PCILeech. The Artix7 75T FPGA chip allows for more advanced firmware projects than the 35T due to the more powerful FPGA. The CaptainDMA 75T also offers an integrated update port for easy re-flashing and an on/off switch which allows the device to be powered off without removing it from the computer.

To flash: Download the [CH347 FPGA Tool](https://github.com/WCHSoftGroup/ch347/releases/tag/CH347_OpenOCD_Release) and the firmware below. Start the WCH347 fpga flash tool as elevated admin and flash. Drivers for WCH347 may also have to be installed.



## CaptainDMA 4.1th

<img src="https://gist.githubusercontent.com/ufrisk/c5ba7b360335a13bbac2515e5e7bb9d7/raw/7632ff874708db8ce94ab3f262e09e04ff90992c/captaindma_4_1.png" height="300"/>

CaptainDMA 4.1th is a standard PCIe board which is ideal when targeting desktop PCs with PCILeech. The Artix7 35T FPGA chip is perfect for DMA and allows for all but the most advanced features. The CaptainDMA 4.1th also offers an integrated update port for easy re-flashing and an on/off switch which allows the device to be powered off without removing it from the computer.

To flash: Follow the flash instructions of the PCIeSquirrel [here](https://github.com/ufrisk/pcileech-fpga/blob/master/PCIeSquirrel/readme.md), but use the firmware downloaded below.



## Firmware

Find firmware for the different CaptainDMA devices below. Make sure you download the firmware for the correct device, otherwise it will not work. Note that the CaptainDMA M2 x4 device have version 4.15 since it contains a bug fix applicable to x4 devices only. The other devices have version 4.14.

Note that the below firmware is the default PCILeech firmware. It's meant for security research and will be perfectly visible to the target computer operating system and any software running on that system. The PCILeech project does not in itself provide any custom firmware or emulated firmware.

| Device                                                                                        | Firmware version | SHA256                                                           | FPGA Project  |
| --------------------------------------------------------------------------------------------- | ---------------- | ---------------------------------------------------------------- | ------------- |
| [CaptainDMA M2 x1](https://mega.nz/file/xfRVSYRa#wMtat6ofhrje9Sj92Mzkj0SoPGAxOkh-npO11OZeI5A) | 4.14             | a10b5171878e598069c01733cc5b48cdee7d77b0d48c072f7e88e21372e60d95 | [35t325_x1](https://github.com/ufrisk/pcileech-fpga-dev/tree/master/CaptainDMA/35t325_x1) |
| [CaptainDMA M2 x4](https://mega.nz/file/wSQlgZ7I#WqqZ4jskXqePwFTByXRYMoecB7LviRfPivZJ2926-9s) | 4.15             | f53a409b754b4443e5156c2d9b7cbe62f5bbdcf9ca3d5ba243174f9d4b073073 | [35t325_x4](https://github.com/ufrisk/pcileech-fpga-dev/tree/master/CaptainDMA/35t325_x4) |
| [CaptainDMA 75T](https://mega.nz/file/YLgU3ZbB#ZQbaMbv-Evus2jF6NDJ8I0-tVrNudiwmq5QFuAsC9Ps)   | 4.14             | ef6e737fbabd08948dae52e9dfe4811f6792739e5827a308275648adabef85ab | [75t484_x1](https://github.com/ufrisk/pcileech-fpga-dev/tree/master/CaptainDMA/75t484_x1) |
| [CaptainDMA 4.1th](https://mega.nz/file/9PpSmBqR#Mphh6YcmGqz8tiKySOAOvJeLaLlMN7L_7enoMxWbENw) | 4.14             | 0c4e997c1212187dc74954cb2ff2b24ce2397831e6662b942ffba62f9077c503 | [35t484_x1](https://github.com/ufrisk/pcileech-fpga-dev/tree/master/CaptainDMA/35t484_x1) |
