#!/bin/bash
# Frame INT of the video controller (tb_int.vhd) in all six screen modes, the CPU at 3.5 MHz
# (clock-by-clock equal to the old controller in sim/ref) and faster (INT ends at the acknowledge),
# then mutations of the RTL that the bench must catch. Needs ghdl.
#
# Usage: firmware/src/fpga/profi/sim/run_int.sh [WORK_DIR]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RTL=$HERE/../rtl/video
W=${1:-$(mktemp -d)}
mkdir -p "$W"
cd "$W"
G="--std=08 -fsynopsys"
# long runs under a memory cap when systemd-run is there
RUN=()
if command -v systemd-run >/dev/null && systemd-run --user --scope -q true 2>/dev/null; then
  RUN=(systemd-run --user --scope -q -p MemoryMax=4G -p MemorySwapMax=0)
fi

build() { # $1 = dir with pentagon_video.vhd profi_video.vhd video.vhd
  rm -f work-obj08.cf
  ghdl -a $G "$HERE/ref/pentagon_video_ref.vhd" "$HERE/ref/profi_video_ref.vhd" "$HERE/ref/video_ref.vhd" \
    "$1/pentagon_video.vhd" "$1/profi_video.vhd" "$1/video.vhd" "$HERE/tb_int.vhd"
  ghdl -e $G tb_int
}

run() { # ds80 mode60 scr ack -> one result line, 0 if no errors
  local out
  out=$("${RUN[@]}" ghdl -r $G tb_int -gG_DS80=$1 -gG_MODE60=$2 -gG_SCR=$3 -gG_ACK=$4 2>&1 || true)
  echo "$out" | grep -E 'ERROR' | head -3 >&2 || true
  echo "$out" | grep -o 'tb_int ds80=.*'
  echo "$out" | grep -q ' 0 errors' && ! echo "$out" | grep -q 'ERROR'
}

MODES=("0 0 0" "0 1 0" "0 0 1" "0 1 1" "1 0 0" "1 1 0")
fail=0
build "$RTL"
for m in "${MODES[@]}"; do
  for a in 0 1; do
    run $m $a || fail=1
  done
done
[ $fail = 0 ] && echo "OK: tb_int 0 errors in all modes" || { echo "FAIL: tb_int" >&2; exit 1; }

# mutations: each must give errors in at least one run
mut() { # name, file, python replacement old -> new, modes to run
  local name=$1 file=$2 old=$3 new=$4; shift 4
  rm -rf mut; mkdir mut; cp "$RTL"/pentagon_video.vhd "$RTL"/profi_video.vhd "$RTL"/video.vhd mut/
  python3 -I -c 'import sys; p,a,b=sys.argv[1:]; t=open(p,encoding="utf-8").read(); assert t.count(a)==1, a; open(p,"w",encoding="utf-8").write(t.replace(a,b))' \
    "mut/$file" "$old" "$new"
  build mut >/dev/null
  local caught=0
  for r in "$@"; do run $r >/dev/null 2>&1 || caught=1; done
  if [ $caught = 1 ]; then echo "mutation $name: caught"; else echo "mutation $name: NOT caught" >&2; fail=1; fi
}
mut ack-always video.vhd "elsif INT_ACK = '1' and INTA = '0' then" "elsif INTA = '0' then" "0 0 0 0" "1 0 0 0"
mut ack-never video.vhd "int_ack_r <= '1';" "int_ack_r <= '0';" "0 0 0 1" "1 0 0 1"
mut ack-sticky video.vhd "if int_frame = '1' then" "if false then" "0 0 0 1"
mut pentagon-int-late pentagon_video.vhd 'ver_cnt = 29 and chr_row_cnt = 7' 'ver_cnt = 29 and chr_row_cnt = 6' "0 0 0 0"
mut classic-int-late pentagon_video.vhd 'ver_cnt = 31 and chr_row_cnt = 0' 'ver_cnt = 31 and chr_row_cnt = 1' "0 0 1 1"
mut profi-int-short profi_video.vhd 'if h_cnt > pcpm_h_int_on and v_cnt' 'if h_cnt > pcpm_h_int_on + 50 and v_cnt' "1 0 0 1"
[ $fail = 0 ] && echo "OK: all mutations caught" || { echo "FAIL: a mutation was not caught" >&2; exit 1; }
