#!/bin/sh
# Build everything that goes into a Profi release into firmware/build/.
# Pack it like the CI release does with:
#   scripts/package_release.sh <name> firmware/build
set -e
cd "$(dirname "$0")"
./build_avr.sh
./build_profi.sh
./build_cpld.sh
