@echo off
echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 1/7 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/s6_pcie_v2_4.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 2/7 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_256_32.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 3/7 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_64_32.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 4/7 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_34_34_deep.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 5/7 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_34_34.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 6/7 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_32_64.xco

echo "---------------------------------------------------------------"
echo " Generating Xilinx IP Core 7/7 ...                             "
echo "---------------------------------------------------------------"
coregen -p ipcore_dir -b ipcore_dir/fifo_32_32_deep.xco

echo "---------------------------------------------------------------"
echo " BUILDING PROJECT ...                                          "
echo "---------------------------------------------------------------"
xtclsh pcileech_sp605.tcl rebuild_project

echo "---------------------------------------------------------------"
echo " GENERATE MCS FILE ...                                         "
echo "---------------------------------------------------------------"
promgen -w -p mcs -c FF -o pcileech -s 8192 -u 0000 pcileech_top.bit -spi
