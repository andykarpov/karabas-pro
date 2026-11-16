#!/bin/sh
# Build everything that goes into a Profi release into firmware/build/.
# Pack it like the CI release does with:
#   scripts/package_release.sh <name> firmware/build
# (pong, rk86 and profi_plus3e are not part of the release, see docs/BACKLOG.md)
set -e
cd "$(dirname "$0")"
./build_avr.sh
./build_profi.sh
./build_cpld.sh
