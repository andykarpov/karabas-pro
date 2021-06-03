#!/bin/sh

export PATH=/opt/altera/quartus/bin:$PATH

echo "Building Pong FPGA sources"

cd fpga/pong/syn

make clean
make all
make jic

cp karabas_pro_pong_revA_tda1543.jic ../../../../releases/pong/karabas_pro_pong_revA_tda1543.jic
cp karabas_pro_pong_revA_tda1543a.jic ../../../../releases/pong/karabas_pro_pong_revA_tda1543a.jic

make clean

echo "Done"

cd ../../../
