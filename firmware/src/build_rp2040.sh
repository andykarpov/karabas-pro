#!/bin/sh

export PATH=$HOME/.platformio/penv/bin:$PATH

echo "Building RP2040 sources"

cd rp2040

BUILD_VER=`date +%y%m%d%H`
echo "Build version: $BUILD_VER"

pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DBUILD_VER=$BUILD_VER"
pio run
cp .pio/build/pico/firmware.uf2 ../../releases/profi/rp2040/karabas_pro.uf2

pio run -t clean

echo "Done"

cd ..
