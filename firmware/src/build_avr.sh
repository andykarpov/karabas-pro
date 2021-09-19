#!/bin/sh

export PATH=$HOME/.platformio/penv/bin:$PATH

echo "Building AVR sources"

cd avr

BUILD_VER=`date +%y%m%d%H`
echo "Build version: $BUILD_VER"

# without hw buttons, without echo
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=0 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=1 -DSEND_ECHO_ON_START=0 -DBUILD_VER=$BUILD_VER -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/avr/karabas_pro_revA.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/profi_plus3e/avr/karabas_pro_revA.hex

# without hw buttons, with echo
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=0 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=1 -DSEND_ECHO_ON_START=1 -DBUILD_VER=$BUILD_VER -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/avr/karabas_pro_revA_usb.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/profi_plus3e/avr/karabas_pro_revA_usb.hex

# hw buttons + disabled led override, without echo
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=0 -DSEND_ECHO_ON_START=0 -DBUILD_VER=$BUILD_VER -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/avr/karabas_pro_revD.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/profi_plus3e/avr/karabas_pro_revD.hex

# hw buttons + disabled led override, with echo
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=0 -DSEND_ECHO_ON_START=1 -DBUILD_VER=$BUILD_VER -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/avr/karabas_pro_revD_usb.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/profi_plus3e/avr/karabas_pro_revD_usb.hex

# hw buttons, without echo
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=1 -DSEND_ECHO_ON_START=0 -DBUILD_VER=$BUILD_VER -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/avr/karabas_pro.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/pong/karabas_pro.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/rk86/karabas_pro.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/profi_plus3e/avr/karabas_pro.hex

# hw buttons, with echo
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=1 -DSEND_ECHO_ON_START=1 -DBUILD_VER=$BUILD_VER -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/avr/karabas_pro_usb.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/pong/karabas_pro_usb.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/rk86/karabas_pro_usb.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/profi_plus3e/avr/karabas_pro_usb.hex

pio run -t clean

echo "Done"

cd ..
