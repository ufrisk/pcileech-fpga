PCILeech PCIeScreamer Advanced Build
=================
This readme details some customizations that are possible to perform prior to building/flashing the FPGA. For general information please check out the general [readme](readme.md).

Building:
=================
1) Install Xilinx Vivado WebPACK 2018.3 or later.
2) Open Vivado Tcl Shell command prompt.
3) cd into the pciescreamer directory of the cloned or unpacked code (forward slash instead of backslash in path).
4) Run `source vivado_generate_project.tcl -notrace` to generate required project files.
5) Run `source vivado_build.tcl -notrace` to generate Xilinx proprietary IP cores and build bitstream.
6) Finished !!!

Building the project may take a very long time (~1 hour). Sometimes the build will fail if the directory path is too long. If build fails try re-run it while pcileech-fpga is placed in C:\Temp or any other place with short directory path.

The PCIe device will show as Xilinx Ethernet Adapter with Device ID 0x0666 on the target system by default. For instructions how to change the device id and other advanced build properties check out the section below for information.

Customizing PCIe device type, vendor ID and product ID:
=================
Please note that many combinations of device types, vendor IDs and product IDs will make computers not boot, hang and otherwise perform badly when the PCIe device is connected. If that happens please try another combination of values.

* Please first generate the initial project as outlined in points 1-4 above.
* Open the project in Vivado Web Pack 2018.3 or later by double clicking on `pciescreamer.xpr` in the generated pciescreamer sub-folder.
* In the PROJECT MANAGER - pciescreamer window expand: Design Sources > pcileech_pciescreamer_top > i_pcileech_pcie_a7.
* Double click on i_pcie_7x_0 shown in the expanded hierarchy from above to open the PCIe core designer GUI.
* Navigate to the IDs tab. Alter ID Initial Values and Class Code to custom values.
* (Optionally navigate to the BARs tab and alter the Bar0 Enabled memory values currently set to 1MB. It is not recommended to disable or go lower than 4kB).
* Click OK to save the changes to the PCIe core. Click Generate in the following dialogue.
* After the PCIe core is rebuilt - exit Vivado and resume building of the project from point 5 in the Building section above. (Optionally one may keep Vivado open and build the project by clicking on Generate Bitstream in the lower left instead).
