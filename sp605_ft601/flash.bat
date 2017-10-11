@echo off
echo "-------------------------------------------------------------------"
echo " FLASHING BITSTREAM ONTO SP605 ...                                 "
echo " ENSURE SP605 IS CONNECTED TO PC WITH THE JTAG USB CABLE           "
echo " If command line flash does not work please use ISE iMPACT instead."
echo "-------------------------------------------------------------------"
set INPUT=
set /P INPUT=Continue (Y/N): %=%
If /I "%INPUT%"=="y" goto yes 
goto no

:yes
impact -batch pcileech_impact_config.txt
:no
