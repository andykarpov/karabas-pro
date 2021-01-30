#!/bin/sh

export PATH=/opt/altera/quartus/bin:$PATH

echo "Building AVR sources"

cd avr

# normal firmware
make clean
sed -i 's/USE_HW_BUTTONS 0/USE_HW_BUTTONS 1/g' config.h # with hw buttons
set -i 's/MOUSE_POLL_TYPE 0/MOUSE_POLL_TYPE 1/g' config.h # mouse poll type : poll
make
cp build-uno/avr.hex ../../releases/profi/karabas_pro.hex

make clean
sed -i 's/USE_HW_BUTTONS 1/USE_HW_BUTTONS 0/g' config.h # without hw buttons
set -i 's/MOUSE_POLL_TYPE 0/MOUSE_POLL_TYPE 1/g' config.h # mouse poll type : poll
make
cp build-uno/avr.hex ../../releases/profi/karabas_pro_revA.hex

# kvm ready firmware
make clean
sed -i 's/USE_HW_BUTTONS 0/USE_HW_BUTTONS 1/g' config.h # with hw buttons
set -i 's/MOUSE_POLL_TYPE 1/MOUSE_POLL_TYPE 0/g' config.h # mouse poll type : stream
make
cp build-uno/avr.hex ../../releases/profi/karabas_pro_kvm.hex

make clean
sed -i 's/USE_HW_BUTTONS 1/USE_HW_BUTTONS 0/g' config.h # without hw buttons
set -i 's/MOUSE_POLL_TYPE 1/MOUSE_POLL_TYPE 0/g' config.h # mouse poll type : stream
make
cp build-uno/avr.hex ../../releases/profi/karabas_pro_revA_kvm.hex

git checkout config.h # revert changes

echo "Done"

cd ..

echo "Building FPGA sources"

cd fpga/profi/syn

make clean
make version
make all
make jic
make unversion

cp karabas_pro_tda1543.jic ../../../../releases/profi/karabas_pro_tda1543.jic
cp karabas_pro_tda1543a.jic ../../../../releases/profi/karabas_pro_tda1543a.jic
cp karabas_pro.rbf ../../../../releases/profi/karabas_pro.rbf

make clean

echo "Done"

cd ../../../

echo "Building CPLD sources"

cd cpld/syn

make clean
make all

cp karabas_pro_cpld.pof ../../../releases/profi/karabas_pro_cpld.pof

make clean

echo "Done"

cd ../../

