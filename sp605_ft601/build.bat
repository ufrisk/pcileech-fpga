@echo off
echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 1/6 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/s6_pcie_v2_4.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 2/6 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_64_64_thin.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 3/6 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_64_64.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 4/6 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_64_32.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 5/6 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_34_34_deep.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 6/6 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_32_64.xco

echo "---------------------------------------------------------------"
echo " BUILDING PROJECT ...                                          "
echo "---------------------------------------------------------------"
xtclsh pcileech_sp605.tcl rebuild_project

echo "---------------------------------------------------------------"
echo " GENERATE MCS FILE ...                                         "
echo "---------------------------------------------------------------"
promgen -w -p mcs -c FF -o pcileech -s 8192 -u 0000 pcileech_top.bit -spi
