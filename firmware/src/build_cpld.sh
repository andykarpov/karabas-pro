#!/bin/sh

export PATH=/opt/altera/quartus/bin:$PATH

echo "Building CPLD sources"

cd cpld/syn

make clean
make all

cp karabas_pro_cpld.pof ../../../releases/profi/epm3128/karabas_pro_cpld.pof
cp karabas_pro_cpld.pof ../../../releases/profi_plus3e/epm3128/karabas_pro_cpld.pof
cp karabas_pro_cpld.pof ../../../releases/pong/karabas_pro_cpld.pof
cp karabas_pro_cpld.pof ../../../releases/rk86/karabas_pro_cpld.pof

make clean

echo "Done"

cd ../../

