#!/bin/sh

export PATH=/opt/altera/quartus/bin:$HOME/.platformio/penv/bin:$PATH

echo "Building AVR sources"

cd avr

# without hw buttons
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=0 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=1 -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/karabas_pro_revA.hex

# hw buttons + disabled led override
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=0 -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/karabas_pro_revD.hex

# hw buttons
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=1 -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/karabas_pro.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/pong/karabas_pro.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/rk86/karabas_pro.hex

pio run -t clean

#exit

echo "Done"

cd ..

echo "Building Profi FPGA sources"

cd fpga/profi/syn

make clean
make all
make jic

cp karabas_pro_tda1543.jic ../../../../releases/profi/karabas_pro_tda1543.jic
cp karabas_pro_tda1543a.jic ../../../../releases/profi/karabas_pro_tda1543a.jic
cp karabas_pro.rbf ../../../../releases/profi/karabas_pro.rbf
cp karabas_pro.sof ../../../../releases/profi/karabas_pro.sof

make clean

echo "Done"

cd ../../../

echo "Building CPLD sources"

cd cpld/syn

make clean
make all

cp karabas_pro_cpld.pof ../../../releases/profi/karabas_pro_cpld.pof
cp karabas_pro_cpld.pof ../../../releases/pong/karabas_pro_cpld.pof
cp karabas_pro_cpld.pof ../../../releases/rk86/karabas_pro_cpld.pof

make clean

echo "Done"

cd ../../

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
