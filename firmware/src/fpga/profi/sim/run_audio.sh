#!/bin/bash
# GHDL benches of the audio path (audio_mixer, tda1543). The AVR link has its own
# script (run_avr_link.sh, iverilog).
# Exits with an error if a check fails.
#
# Usage: firmware/src/fpga/profi/sim/run_audio.sh [WORK_DIR]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RTL=$HERE/../rtl
W=${1:-$(mktemp -d)}
mkdir -p "$W"
cd "$W"
G="--std=08 -fsynopsys -frelaxed"
fail=0

ghdl -a $G "$RTL/sound/audio_mixer.vhd" "$RTL/dac/tda1543.vhd" "$HERE/tb_audio.vhd"
ghdl -e $G tb_audio
ghdl -r $G tb_audio 2>&1 | grep 'report note' | sed 's/.*(report note): //' | tee audio.txt
grep -q 'mismatches 0' audio.txt || fail=1
[ "$(grep -c ', wrong 0' audio.txt)" -eq 2 ] || fail=1

if [ $fail = 0 ]; then echo "OK"; else echo "FAIL" >&2; exit 1; fi
