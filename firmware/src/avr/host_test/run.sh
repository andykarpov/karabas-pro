#!/bin/bash
# Host stand of the AVR firmware: builds the firmware of this checkout and of BASE (a git ref,
# default origin/master) for the PC with the models of sim.c, runs the same scenario on both
# (with an erased EEPROM and with saved settings) and compares the SPI frames to the FPGA.
# Then mutates the link of this checkout and checks that the comparison catches it.
# Needs gcc and git.
#
# Usage: firmware/src/avr/host_test/run.sh [BASE_REF] [WORK_DIR]
#   BASE_REF  - (a dash) runs only this checkout and prints the frame count
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
AVR=$(cd "$HERE/.." && pwd)
BASE=${1:-origin/master}
W=${2:-$(mktemp -d)}
mkdir -p "$W"

build() { # $1 = avr source dir, $2 = output binary
  local src=$1 out=$2 objs=() f
  rm -rf "$out.o"; mkdir -p "$out.o"
  for f in "$src"/src/*.c; do
    case $(basename "$f") in hal.c|ps2_kbd.c|mouse.c) continue ;; esac
    gcc -std=gnu11 -O1 -w -DBUILD_VER=HOSTTEST -Dmain=avr_main -I "$HERE/include" -I "$src/include" \
      -c "$f" -o "$out.o/$(basename "$f").o"
    objs+=("$out.o/$(basename "$f").o")
  done
  gcc -std=gnu11 -O1 -w -I "$HERE/include" -I "$src/include" -I "$src/src" -c "$HERE/mouse_wrap.c" -o "$out.o/mouse_wrap.o"
  gcc -std=gnu11 -O1 -w -I "$HERE/include" -I "$src/include" -c "$HERE/sim.c" -o "$out.o/sim.o"
  gcc -o "$out" "${objs[@]}" "$out.o/mouse_wrap.o" "$out.o/sim.o"
}

runs() { # $1 = binary, $2 = log prefix
  "$1" "$2.a.log" a
  "$1" "$2.b.log" b
}

same() { # $1, $2 = log prefixes
  cmp -s "$1.a.log" "$2.a.log" && cmp -s "$1.b.log" "$2.b.log"
}

build "$AVR" "$W/new"
runs "$W/new" "$W/new"
echo "this checkout: $(wc -l < "$W/new.a.log") + $(wc -l < "$W/new.b.log") frames"
[ "$BASE" = "-" ] && exit 0

rm -rf "$W/base"; mkdir -p "$W/base"
git -C "$AVR" archive "$BASE" -- . | tar -x -C "$W/base"
build "$W/base" "$W/old"
runs "$W/old" "$W/old"
if same "$W/old" "$W/new"; then
  echo "OK: the SPI frames are the same as in $BASE"
else
  echo "FAIL: the SPI frames differ from $BASE (first differences):" >&2
  { diff "$W/old.a.log" "$W/new.a.log" | head -10; diff "$W/old.b.log" "$W/new.b.log" | head -10; } >&2 || true
  exit 1
fi

# mutations of the link: each must change the frames
fail=0
mut() { # name, file, old text, new text
  rm -rf "$W/mut"; cp -r "$AVR" "$W/mut"
  python3 -I -c 'import sys; p,a,b=sys.argv[1:]; t=open(p,encoding="utf-8").read(); assert t.count(a)==1, a; open(p,"w",encoding="utf-8").write(t.replace(a,b))' \
    "$W/mut/$2" "$3" "$4"
  build "$W/mut" "$W/mutbin"
  runs "$W/mutbin" "$W/mut"
  if same "$W/old" "$W/mut"; then echo "mutation $1: NOT caught" >&2; fail=1; else echo "mutation $1: caught"; fi
}
mut psg-mix src/link_v1.c 'bit_set(B_SW7, val & 1); bit_set(B_SW9, val & 2);' 'bit_set(B_SW7, val & 2); bit_set(B_SW9, val & 1);'
mut rombank-keep src/link_v1.c '      if (val != 4) {' '      if (1) {'
mut plus3e-at-start src/keyboard.c '  if (s_is_plus3e) link_setval(LV_ROMBANK, 4);' ''
mut turbo2 src/link_v1.c 'bit_set(B_TURBO2, val & 2);' 'bit_set(B_TURBO2, 0);'
mut joy-start src/link_v1.c 'if (buttons & LJ_START) flags |= 0x80;' 'if (buttons & LJ_A) flags |= 0x80;'
mut mouse-toggle src/link_v1.c 'static bool s_mouse_toggle = false;' 'static bool s_mouse_toggle = true;'
mut osd-popup src/link_v1.c 'bit_set(B_OSD_POPUP, val & LV_OSD_POPUP);' ''
mut scancode src/link_v1.c 'bit_set(B_SCANCODE + i, (code >> i) & 1);' 'bit_set(B_SCANCODE + 7 - i, (code >> i) & 1);'
mut pause src/keyboard.c '  link_setval(LV_PAUSE, s_is_wait);
  zxosd_on_key_event(EVENT_OSD_PAUSE);' '  zxosd_on_key_event(EVENT_OSD_PAUSE);'
[ $fail = 0 ] && echo "OK: all mutations caught" || { echo "FAIL: a mutation was not caught" >&2; exit 1; }
