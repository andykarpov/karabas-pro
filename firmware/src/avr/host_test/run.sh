#!/bin/bash
# Host stand of the AVR firmware (README.md). Builds this checkout (link v2) and BASE_REF (link
# v1, default eba1f0a: the last commit before link v2) for the PC with the models of sim.c, runs
# the scenario on both (erased EEPROM "a", saved settings "b") and checks that
#   - neither switches the SPI off with CS low;
#   - both reach the same number of passes (lines "M");
#   - the EEPROM and the DS1307 are the same at the end (menu values saved, the CPU writes into
#     the RTC that came back from the FPGA by CMD_RTC / RTC GET).
# The logs (WORK_DIR/v1.?.log, v2.?.log) are the input of fpga/profi/sim/run_avr_link.sh, which
# replays them into the old and the new FPGA module.
#
# Usage: firmware/src/avr/host_test/run.sh [BASE_REF] [WORK_DIR] [AVR_DIR]
#   AVR_DIR  the link v2 sources (default: this checkout; run_avr_link.sh passes mutated copies)
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
BASE=${1:-eba1f0a}
W=${2:-$(mktemp -d)}
AVR=${3:-$(cd "$HERE/.." && pwd)}
mkdir -p "$W"

build() { # $1 = avr source dir, $2 = output binary, $3 = extra flags of sim.c and the firmware
  local src=$1 out=$2 objs=() f def
  rm -rf "$out.o"; mkdir -p "$out.o"
  for f in "$src"/src/*.c; do
    case $(basename "$f") in hal.c|ps2_kbd.c|mouse.c) continue ;; esac
    def=""
    case $(basename "$f") in link_v*.c) def="-Dlink_keys=link_keys_real" ;; esac
    gcc -std=gnu11 -O1 -w -DBUILD_VER=HOSTTEST -Dmain=avr_main $def $3 -I "$HERE/include" -I "$src/include" \
      -c "$f" -o "$out.o/$(basename "$f").o"
    objs+=("$out.o/$(basename "$f").o")
  done
  gcc -std=gnu11 -O1 -w -I "$HERE/include" -I "$src/include" -I "$src/src" -c "$HERE/mouse_wrap.c" -o "$out.o/mouse_wrap.o"
  gcc -std=gnu11 -O1 -w $3 -I "$HERE/include" -I "$src/include" -c "$HERE/sim.c" -o "$out.o/sim.o"
  gcc -o "$out" "${objs[@]}" "$out.o/mouse_wrap.o" "$out.o/sim.o"
}

rm -rf "$W/base"; mkdir -p "$W/base"
git -C "$HERE/.." archive "$BASE" -- . | tar -x -C "$W/base"
BASE_AVR=$W/base
[ -d "$BASE_AVR/src" ] || { echo "no firmware/src/avr in $BASE" >&2; exit 1; }
build "$BASE_AVR" "$W/v1bin" -DLINK_V1
build "$AVR" "$W/v2bin" ""

fail=0
for s in a b; do
  "$W/v1bin" "$W/v1.$s.log" $s
  "$W/v2bin" "$W/v2.$s.log" $s
  m1=$(grep -c '^M ' "$W/v1.$s.log"); m2=$(grep -c '^M ' "$W/v2.$s.log")
  p1=$(grep -c '^[0-9]*:' "$W/v1.$s.log"); p2=$(grep -c '^[0-9]*:' "$W/v2.$s.log")
  echo "scenario $s: v1 $p1 frames, v2 $p2 packets, $m2 passes"
  if grep -q 'ERROR' "$W/v1.$s.log" "$W/v2.$s.log"; then
    grep -m3 'ERROR' "$W/v1.$s.log" "$W/v2.$s.log" >&2; fail=1
  fi
  [ "$m1" = "$m2" ] || { echo "scenario $s: $m1 passes on v1, $m2 on v2" >&2; fail=1; }
  if ! diff <(sed -n '/^EEPROM/,$p' "$W/v1.$s.log") <(sed -n '/^EEPROM/,$p' "$W/v2.$s.log") > "$W/dump.$s.diff"; then
    echo "scenario $s: EEPROM / DS1307 differ at the end:" >&2; head -8 "$W/dump.$s.diff" >&2; fail=1
  fi
done

# the debug build (env ATmega328_debug): its link check reads STATUS on idle passes and must count
# no errors on a link without errors; the same passes as the release build
build "$AVR" "$W/v2dbg" -DLINK_DEBUG
"$W/v2dbg" "$W/v2dbg.a.log" a
md=$(grep -c '^M ' "$W/v2dbg.a.log"); last=$(grep '^U link checks' "$W/v2dbg.a.log" | tail -1)
echo "debug build: $md passes, $last"
[ "$md" = "$(grep -c '^M ' "$W/v2.a.log")" ] || { echo "debug build: $md passes" >&2; fail=1; }
case "$last" in *" errors 0") ;; *) echo "debug build: link check failed: $last" >&2; fail=1 ;; esac
grep -q '^U link up, SCK 8 MHz' "$W/v2dbg.a.log" || { echo "debug build: no link up line" >&2; fail=1; }
if grep -q 'ERROR' "$W/v2dbg.a.log"; then grep -m3 'ERROR' "$W/v2dbg.a.log" >&2; fail=1; fi

[ $fail = 0 ] && echo "OK: same passes, EEPROM and DS1307 on v1 and v2" || { echo "FAIL" >&2; exit 1; }
