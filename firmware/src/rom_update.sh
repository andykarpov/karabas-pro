#!/bin/sh

export PATH=/opt/altera/quartus/bin:$HOME/.platformio/penv/bin:$PATH

echo "Building Profi FPGA JIC for EP4CE6"

cd fpga/profi/syn/ep4ce6

cp ../../../../../releases/profi/ep4ce6/karabas_pro_ep4ce6.sof karabas_pro_ep4ce6.sof
make jic

cp karabas_pro_ep4ce6_tda1543.jic ../../../../../releases/profi/ep4ce6/karabas_pro_ep4ce6_tda1543.jic
cp karabas_pro_ep4ce6_tda1543a.jic ../../../../../releases/profi/ep4ce6/karabas_pro_ep4ce6_tda1543a.jic
cp karabas_pro_ep4ce6_revDS_tda1543.jic ../../../../../releases/profi/ep4ce6/karabas_pro_ep4ce6_revDS_tda1543.jic
cp karabas_pro_ep4ce6_revDS_tda1543a.jic ../../../../../releases/profi/ep4ce6/karabas_pro_ep4ce6_revDS_tda1543a.jic

make clean

echo "Done"

cd ../../../../

echo "Building Profi FPGA JIC for EP4CE10"

cd fpga/profi/syn/ep4ce10

cp ../../../../../releases/profi/ep4ce10/karabas_pro_ep4ce10.sof karabas_pro_ep4ce10.sof
make jic

cp karabas_pro_ep4ce10_tda1543.jic ../../../../../releases/profi/ep4ce10/karabas_pro_ep4ce10_tda1543.jic
cp karabas_pro_ep4ce10_tda1543a.jic ../../../../../releases/profi/ep4ce10/karabas_pro_ep4ce10_tda1543a.jic
cp karabas_pro_ep4ce10_revDS_tda1543.jic ../../../../../releases/profi/ep4ce10/karabas_pro_ep4ce10_revDS_tda1543.jic
cp karabas_pro_ep4ce10_revDS_tda1543a.jic ../../../../../releases/profi/ep4ce10/karabas_pro_ep4ce10_revDS_tda1543a.jic

make clean

echo "Done"

cd ../../../../

echo "Building Profi FPGA JIC for EP3C10"

cd fpga/profi/syn/ep3c10

cp ../../../../../releases/profi/ep3c10/karabas_pro_ep3c10.sof karabas_pro_ep3c10.sof
make jic

cp karabas_pro_ep3c10_tda1543.jic ../../../../../releases/profi/ep3c10/karabas_pro_ep3c10_tda1543.jic
cp karabas_pro_ep3c10_tda1543a.jic ../../../../../releases/profi/ep3c10/karabas_pro_ep3c10_tda1543a.jic
cp karabas_pro_ep3c10_revDS_tda1543.jic ../../../../../releases/profi/ep3c10/karabas_pro_ep3c10_revDS_tda1543.jic
cp karabas_pro_ep3c10_revDS_tda1543a.jic ../../../../../releases/profi/ep3c10/karabas_pro_ep3c10_revDS_tda1543a.jic

make clean

echo "Done"

cd ../../../../

