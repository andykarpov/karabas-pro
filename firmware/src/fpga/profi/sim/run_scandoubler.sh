#!/bin/bash
# Simulate video controller -> OSD overlay -> scandoubler in all screen modes
# with GHDL and print the measured VGA timing. Needs ghdl and python3.
#
# Usage: firmware/src/fpga/profi/sim/run_scandoubler.sh [WORK_DIR]
# Exits with an error when the result differs from expected_scandoubler.txt
# (update that file together with an intended change of the VGA timing).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RTL=$HERE/../rtl/video
W=${1:-$(mktemp -d)}
mkdir -p "$W"
cd "$W"
python3 -I "$HERE/mkroms.py" "$RTL" .
G="ghdl -a --std=08 -fsynopsys"
$G "$HERE/ip_models.vhd" "$RTL/icons.vhd" "$RTL/overlay.vhd" "$RTL/pentagon_video.vhd" \
   "$RTL/profi_video.vhd" "$RTL/video.vhd" "$RTL/scandoubler.vhd" "$HERE/tb_scandoubler.vhd"
ghdl -e --std=08 -fsynopsys tb_scandoubler
for m in "0 0 0 pentagon50" "0 1 0 pentagon60" "0 0 1 classic50" "0 1 1 classic60" \
         "1 0 0 profi50" "1 1 0 profi60"; do
  set -- $m
  printf "%-10s " "$4"
  ghdl -r --std=08 -fsynopsys tb_scandoubler -gG_DS80=$1 -gG_MODE60=$2 -gG_SCR=$3 --stop-time=200ms 2>&1 \
    | grep -E 'report note|error' | grep -v 'paper rgb' | sed 's/.*(report note): //'
done | tee result.txt

if diff -u "$HERE/expected_scandoubler.txt" result.txt; then
  echo "OK: matches expected_scandoubler.txt"
else
  echo "FAIL: differs from expected_scandoubler.txt" >&2
  exit 1
fi
