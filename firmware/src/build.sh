#!/bin/sh

echo "Building AVR sources"

cd avr

make clean
sed -i 's/USE_HW_BUTTONS 0/USE_HW_BUTTONS 1/g' config.h
make
cp build-uno/avr.hex ../../releases/profi/karabas_pro.hex

make clean
sed -i 's/USE_HW_BUTTONS 1/USE_HW_BUTTONS 0/g' config.h
make
cp build-uno/avr.hex ../../releases/profi/karabas_pro_revA.hex

echo "Done"

cd ..

echo "Building FPGA sources"

cd fpga/profi/syn

make clean
make all
make jic

cp karabas_pro.jic ../../../../releases/profi/karabas_pro.jic
cp karabas_pro_revA_tda1543.jic ../../../../releases/profi/karabas_pro_revA_tda1543.jic
cp karabas_pro_revA_tda1543a.jic ../../../../releases/profi/karabas_pro_revA_tda1543a.jic
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

