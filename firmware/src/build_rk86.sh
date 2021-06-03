#!/bin/sh

export PATH=/opt/altera/quartus/bin:$PATH

echo "Building RK86 FPGA sources"

cd fpga/rk86/syn

make clean
make all
make jic

cp karabas_pro_rk86_revA_tda1543.jic ../../../../releases/rk86/karabas_pro_rk86_revA_tda1543.jic
cp karabas_pro_rk86_revA_tda1543a.jic ../../../../releases/rk86/karabas_pro_rk86_revA_tda1543a.jic

make clean

echo "Done"

cd ../../../
