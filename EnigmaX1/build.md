PCILeech Enigma x1 Build
=================
This readme details some customizations that are possible to perform prior to building/flashing the FPGA. For general information please check out the general [readme](readme.md).

Building:
=================
1) Install Xilinx Vivado WebPACK 2023.2 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the EnigmaX1 directory of the cloned or unpacked code (forward slash instead of backslash in path).
4) Run `source vivado_generate_project.tcl -notrace` to generate required project files.
5) Run `source vivado_build.tcl -notrace` to generate Xilinx proprietary IP cores and build bitstream.
6) Finished !!!

Building the project may take a very long time (~1 hour). Sometimes the build will fail if the directory path is too long. If build fails try re-run it while pcileech-fpga is placed in C:\Temp or any other place with short directory path.

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties check out the section below for information.

Customizing PCIe device type, vendor ID and product ID:
=================
Please note that many combinations of device types, vendor IDs and product IDs will make computers not boot, hang and otherwise perform badly when the PCIe device is connected. If that happens please try another combination of values.

Please also note that changing the device and vendor ID is not in itself sufficient to make the device "undetectable" by software looking for malicious DMA devices. There are, more settings that are or aren't, directly modifiable in the PCIe configuration wizard that will alter the device PCIe configuration space.

* Please first generate the initial project as outlined in points 1-4 above.
* Open the project in Vivado by double clicking on `pcileech_enigma_x1.xpr` in the generated pcileech_enigma_x1 sub-folder.
* In the PROJECT MANAGER - EnigmaX1 window expand: Design Sources > pcileech_enigma_x1_top > i_pcileech_pcie_a7.
* Double click on i_pcie_7x_0 shown in the expanded hierarchy from above to open the PCIe core designer GUI.
* Navigate to the IDs tab. Alter ID Initial Values and Class Code to custom values.
* (Optionally navigate to the BARs tab and alter the Bar0 Enabled memory values currently set to 4kB. It is not recommended to disable or go lower than 4kB).
* Click OK to save the changes to the PCIe core. Click Generate in the following dialogue.
* After the PCIe core is rebuilt - exit Vivado and resume building of the project from point 5 in the Building section above. (Optionally one may keep Vivado open and build the project by clicking on Generate Bitstream in the lower left instead).


#### Device Serial Number (DSN):

It may also be a good idea to modify the device serial number (DSN) by editing the line below in the file: `src/pcileech_pcie_cfg_a7.sv`
```verilog
rw[127:64]  <= 64'h0000000101000A35;    // cfg_dsn
```


#### Configuration Space:

It's possible to partly change the PCIe configuration space of the device. This is achieved by altering the value below from `1'b1` to `1'b0` in the file `src/pcileech_fifo.sv` (please see below). The PCIe configuration space is configured by editing the file `ip/pcileech_cfgspace.coe`. Please note that the Xilinx PCIe core will in-part override user-configured values.

in `src/pcileech_fifo.sv` change:
```verilog
rw[203]     <= 1'b1;                        //       CFGTLP ZERO DATA
```
into:
```verilog
rw[203]     <= 1'b0;                        //       CFGTLP ZERO DATA (0 = CUSTOM CONFIGURATION SPACE ENABLED)
```

It's not currently possible to read the custom configuration space from within PCILeech, but on a Linux system it's possible to view it using the `lspci` command. The command line, if the vendor/device id is the default 10ee:0666, is:

Linux lspci command line: `lspci -d 10ee:0666 -xxxx`.



#### BAR PIO Memory Regions:

It's possible to implement a custom BAR PIO memory region, commonly used by devices. Properly implemented BAR PIO memory regions may allow for more complete device emulation.

First, edit the Xilinx PCIe core in Vivado. By default there is one BAR, BAR0 which have 4kB of all-zero read/write memory assigned. This is possible to change.

Secondly, edit the file: `pcileech_tlps128_bar_controller.sv` and follow the instructions in the file to implement custom BAR PIO memory regions.
