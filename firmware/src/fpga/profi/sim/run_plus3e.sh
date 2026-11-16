#!/bin/bash
# GHDL bench for memory.vhd in the +3e mode (tb_plus3e.vhd): the ZX Spectrum +3
# memory map for random #1FFD / #7FFD values. Exits with an error on a mismatch.
#
# Usage: firmware/src/fpga/profi/sim/run_plus3e.sh [WORK_DIR]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RTL=$HERE/../rtl
W=${1:-$(mktemp -d)}
mkdir -p "$W"
cd "$W"
G="--std=08 -fsynopsys -frelaxed"

ghdl -a $G "$RTL/memory/memory.vhd" "$HERE/tb_plus3e.vhd"
ghdl -e $G tb_plus3e
ghdl -r $G tb_plus3e 2>&1 | grep 'report' | sed 's/.*(report [a-z]*): //' | tee plus3e.txt
if grep -q ', 0 errors' plus3e.txt; then echo "OK"; else echo "FAIL" >&2; exit 1; fi
