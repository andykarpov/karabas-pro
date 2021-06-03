#!/bin/sh

export PATH=/opt/altera/quartus/bin:$PATH

echo "Building Profi +3e FPGA sources for EP4CE6"

cd fpga/profi_plus3e/syn/ep4ce6

make clean
make all
make jic

cp karabas_pro_ep4ce6_tda1543.jic ../../../../../releases/profi_plus3e/ep4ce6/karabas_pro_ep4ce6_tda1543.jic
cp karabas_pro_ep4ce6_tda1543a.jic ../../../../../releases/profi_plus3e/ep4ce6/karabas_pro_ep4ce6_tda1543a.jic
cp karabas_pro_ep4ce6_revDS_tda1543.jic ../../../../../releases/profi_plus3e/ep4ce6/karabas_pro_ep4ce6_revDS_tda1543.jic
cp karabas_pro_ep4ce6_revDS_tda1543a.jic ../../../../../releases/profi_plus3e/ep4ce6/karabas_pro_ep4ce6_revDS_tda1543a.jic
cp karabas_pro_ep4ce6.rbf ../../../../../releases/profi_plus3e/ep4ce6/karabas_pro_ep4ce6.rbf
cp karabas_pro_ep4ce6.sof ../../../../../releases/profi_plus3e/ep4ce6/karabas_pro_ep4ce6.sof

make clean

echo "Done"

cd ../../../../

echo "Building Profi +3e FPGA sources for EP4CE10"

cd fpga/profi_plus3e/syn/ep4ce10

make clean
make all
make jic

cp karabas_pro_ep4ce10_tda1543.jic ../../../../../releases/profi_plus3e/ep4ce10/karabas_pro_ep4ce10_tda1543.jic
cp karabas_pro_ep4ce10_tda1543a.jic ../../../../../releases/profi_plus3e/ep4ce10/karabas_pro_ep4ce10_tda1543a.jic
cp karabas_pro_ep4ce10_revDS_tda1543.jic ../../../../../releases/profi_plus3e/ep4ce10/karabas_pro_ep4ce10_revDS_tda1543.jic
cp karabas_pro_ep4ce10_revDS_tda1543a.jic ../../../../../releases/profi_plus3e/ep4ce10/karabas_pro_ep4ce10_revDS_tda1543a.jic
cp karabas_pro_ep4ce10.rbf ../../../../../releases/profi_plus3e/ep4ce10/karabas_pro_ep4ce10.rbf
cp karabas_pro_ep4ce10.sof ../../../../../releases/profi_plus3e/ep4ce10/karabas_pro_ep4ce10.sof

make clean

echo "Done"

cd ../../../../

echo "Building Profi +3e FPGA sources for EP3C10"

cd fpga/profi_plus3e/syn/ep3c10

make clean
make all
make jic

cp karabas_pro_ep3c10_tda1543.jic ../../../../../releases/profi_plus3e/ep3c10/karabas_pro_ep3c10_tda1543.jic
cp karabas_pro_ep3c10_tda1543a.jic ../../../../../releases/profi_plus3e/ep3c10/karabas_pro_ep3c10_tda1543a.jic
cp karabas_pro_ep3c10_revDS_tda1543.jic ../../../../../releases/profi_plus3e/ep3c10/karabas_pro_ep3c10_revDS_tda1543.jic
cp karabas_pro_ep3c10_revDS_tda1543a.jic ../../../../../releases/profi_plus3e/ep3c10/karabas_pro_ep3c10_revDS_tda1543a.jic
cp karabas_pro_ep3c10.rbf ../../../../../releases/profi_plus3e/ep3c10/karabas_pro_ep3c10.rbf
cp karabas_pro_ep3c10.sof ../../../../../releases/profi_plus3e/ep3c10/karabas_pro_ep3c10.sof

make clean

echo "Done"

cd ../../../../
