#!/bin/sh

export PATH=$HOME/.platformio/penv/bin:$PATH

echo "Building AVR sources"

cd avr

# without hw buttons
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=0 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=1 -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/avr/karabas_pro_revA.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/profi_plus3e/avr/karabas_pro_revA.hex

# hw buttons + disabled led override
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=0 -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/avr/karabas_pro_revD.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/profi_plus3e/avr/karabas_pro_revD.hex

# hw buttons
pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DUSE_HW_BUTTONS=1 -DMOUSE_POLL_TYPE=0 -DALLOW_LED_OVERRIDE=1 -Wall"
pio run
cp .pio/build/ATmega328/firmware.hex ../../releases/profi/avr/karabas_pro.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/pong/karabas_pro.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/rk86/karabas_pro.hex
cp .pio/build/ATmega328/firmware.hex ../../releases/profi_plus3e/avr/karabas_pro.hex

pio run -t clean

echo "Done"

cd ..
