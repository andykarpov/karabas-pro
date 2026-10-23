#!/bin/sh

export PATH=$HOME/.platformio/penv/bin:$PATH

echo "Building universal AVR firmware"

cd avr

pio run -t clean
pio run

echo "Done"

cd ..
