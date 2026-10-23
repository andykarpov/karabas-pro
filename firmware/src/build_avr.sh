#!/bin/sh

export PATH=$HOME/.platformio/penv/bin:$PATH

echo "Building universal AVR firmware"

cd avr

BUILD_VER=`date +%y%m%d%H`
echo "Build version: $BUILD_VER"

pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DBUILD_VER=$BUILD_VER -Wall"
pio run

# Extract EEPROM Intel HEX file
~/.platformio/packages/toolchain-atmelavr/bin/avr-objcopy -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0 .pio/build/ATmega328/firmware.elf .pio/build/ATmega328/firmware.eep

# Distribute universal firmware to release folders
TARGET_DIRS="../../releases/profi/avr ../../releases/profi_plus3e/avr ../../releases/pong ../../releases/rk86"

for DIR in $TARGET_DIRS; do
  cp .pio/build/ATmega328/firmware.hex "$DIR/karabas_pro.hex"
  cp .pio/build/ATmega328/firmware.eep "$DIR/karabas_pro.eep"
done

pio run -t clean

echo "Done"

cd ..
