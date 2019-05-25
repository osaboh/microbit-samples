#!/bin/sh


PROJROOT=$(cat ./project_path.txt)
PROJROOT=$(eval echo $PROJROOT)
PROJNAME=$(basename $PROJROOT)
ELF=$PROJROOT/build/bbc-microbit-classic-gcc/source/$PROJNAME
HEX=$PROJROOT/build/bbc-microbit-classic-gcc/source/$PROJNAME.hex
CMBHEX=$PROJROOT/build/bbc-microbit-classic-gcc/source/microbit-samples-combined.hex
DEVICE="NRF51822_XXAA"
GDBSERVER_ONLY="0"

gen_jlinkscript()
{
cat <<EOF > ./jlinkscript.txt
reset
loadfile $HEX
exit
EOF
}

gen_gdbscript()
{
cat <<EOF > ./gdbscript.txt
target remote localhost:2331
monitor device $DEVICE
monitor reset
load $ELF
monitor go
disconnect
quit
EOF
}


info_help()
{
  echo "Usage: write_flash.sh [options]"
  echo ""
  echo "Options:"
  echo ""
  echo "  --elf         write elf image."
  echo "  --full        write elf image with bootloader and softdevice."
  echo "  --gdb         start gdbserver only."
  echo "  --kill        kill gdbserver."
  echo "  --help        view help."
}


cd $PROJROOT/scripts


if [ $# = 0 ]; then
  info_help
  exit 0
fi


# write image with bootloader and softdevice.
if [ $# = 1 -a $1 = "--full" ]; then
  gen_jlinkscript
  /opt/SEGGER/JLink/JLinkExe -device $DEVICE -if SWD -speed auto -autoconnect 1 -CommanderScript ./jlinkscript.txt
  exit 0
fi

# kill gdb server
if [ $# = 1 -a $1 = "--kill" ]; then
  killall JLinkGDBServer
  exit 0
fi

# help
if [ $# = 1 -a $1 = "--help" ]; then
  info_help
  exit 0
fi


# start gdbserver only
if  [ $# = 1 -a $1 = "--gdb" ]; then
  GDBSERVER_ONLY="1"
elif [ $# = 1 -a $1 = "--elf" ]; then
  GDBSERVER_ONLY="0"
fi

/opt/SEGGER/JLink/JLinkGDBServer -select USB -device $DEVICE -endian little -if SWD -speed auto -ir -noLocalhostOnly &
sleep 1
if [ $GDBSERVER_ONLY = "1" ]; then
  echo "gdbserver only"
  exit 1
fi

# write elf image
gen_gdbscript
arm-none-eabi-gdb -x ./gdbscript.txt -silent

killall JLinkGDBServer
