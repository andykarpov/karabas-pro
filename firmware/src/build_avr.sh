#!/bin/sh
# Build the universal AVR firmware with PlatformIO and collect the outputs in
# firmware/build/karabas-pro-avr-firmware/. BUILD_VER (YYMMDDHH) can be given in
# the environment, the default is the current UTC time.
set -e
cd "$(dirname "$0")"
FW=$(cd .. && pwd)
export PATH=$HOME/.platformio/penv/bin:$PATH
BUILD_VER=${BUILD_VER:-$(date -u +%y%m%d%H)}
export BUILD_VER

echo "Building universal AVR firmware, BUILD_VER=$BUILD_VER"
(cd avr && pio run -t clean && pio run)
out="$FW/build/karabas-pro-avr-firmware"
rm -rf "$out"; mkdir -p "$out"
cp avr/.pio/build/ATmega328/karabas_pro.hex avr/.pio/build/ATmega328/*.eep "$out/"
echo "$BUILD_VER" > "$out/build_ver.txt"
echo "Done: $out"
