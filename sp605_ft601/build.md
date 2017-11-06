PCILeech SP605 / FT601 Advanced Build
=================
This readme details some customizations that are possible to perform prior to building/flashing the FPGA. For general information please check out the general [readme](readme.md).

Building:
=================
1) Install Xilinx ISE Development Environment.
2) Open ISE Design Suite 64-Bit Command Prompt.
3) Run `build.bat` to generate Xilinx proprietary IP cores and build bitstream.
4) Finished !!!

Customizing PCIe device type, vendor ID and product ID:
=================
Please note that many combinations of device types, vendor IDs and product IDs will make computers not boot, hang and otherwise perform badly when the PCIe device is connected. If that happens please try another combination of values.

* Please first perform an initial build as detailed in Building above.
* Open the project in ISE Design Suite by double-clicking on `pcileech_sp605.xise`.
* Open the Core Generator by clicking Tools > Core Genrator in ISE Design Suite.
* Double click, in Core Generator, on the core: s6_pcie_v2_4.
* In the Spartan-6 Integrated Block for PCI Express wizard skip forward to Page 3/9 and change the values to something desirable. 
* After changing the values click "Generate".
* After successfully re-genrating altered PCIe close Core Generator and ISE Design Suite.
* Open ISE Design Suite 64-Bit Command Prompt.
* Run: `xtclsh pcileech_sp605.tcl rebuild_project` to re-generate the project with the new core.
* Run: `promgen -w -p mcs -c FF -o pcileech -s 8192 -u 0000 pcileech_top.bit -spi` to create a new mcs-file for flashing.
* Run: `flash.bat` to flash the newly generated .mcs file onto the board.
