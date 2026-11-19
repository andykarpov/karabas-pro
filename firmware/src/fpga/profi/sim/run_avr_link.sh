#!/bin/bash
# The AVR link v2 (docs/AVR_LINK_V2.md), FPGA and AVR side. Needs iverilog, ghdl, gcc, git,
# python3. About 30 minutes (the old module in GHDL takes most of it).
#
#  1. tb_avr_link.v: rtl/avr/avr_link.v alone, every command, at clk 24 / 28 MHz x SCK 1 / 4 /
#     8 MHz;
#  2. the AVR host stand (firmware/src/avr/host_test/run.sh): the firmware on link v1 (eba1f0a)
#     and on link v2 run the same scenarios; their SPI logs become replay files (avr_replay.py);
#  3. the v1 frames go into the old avr.vhd (sim/ref, GHDL, tb_avr_replay_v1.vhd), the v2
#     packets into avr_link.v (iverilog, tb_avr_replay_v2.v); the core side at every pass of the
#     AVR main loop, every OSD video memory write and the RTC registers at the end must be the
#     same. Intended differences: the old module had no initial value for MS_Z / MS_EVENT (0 in
#     the chip: printed as 0 here), the v1 firmware sent all RTC registers twice at the start
#     (only the registers at the end are compared);
#  4. mutations of avr_link.v (caught by step 1) and of the v2 firmware (caught by steps 2-3).
#
# Usage: firmware/src/fpga/profi/sim/run_avr_link.sh [WORK_DIR]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RTL=$HERE/../rtl
AVR=$(cd "$HERE/../../../avr" && pwd)
W=${1:-$(mktemp -d)}
mkdir -p "$W"
cd "$W"
G="--std=08 -fsynopsys -frelaxed"
fail=0

ghdl_run() { # $1 = dir (holds v1.rep, gets v1.state / v1.osd)
  local cmd="cd '$1' && ghdl -r $G --workdir='$W/ghdl' tb_avr_replay_v1 --ieee-asserts=disable"
  if command -v systemd-run > /dev/null && systemd-run --user --scope -q true 2> /dev/null; then
    systemd-run --user --scope -q -p MemoryMax=4G -p MemorySwapMax=0 bash -c "$cmd"
  else
    bash -c "$cmd"
  fi
}

norm() { sed -e 's/MZ=X/MZ=0/; s/ME=U/ME=0/' "$1" | tr a-f A-F; }

unit() { # $1 = avr_link.v, $2.. = "clk_ns sck_ns" pairs; 0 all pass, 1 errors, 2 no build
  local src=$1 ok=0 cs; shift
  for cs in "$@"; do
    set -- $cs
    iverilog -g2005 -DCLK_NS=$1 -DSCK_NS=$2 -o unit "$HERE/tb_avr_link.v" "$src" > /dev/null 2>&1 || return 2
    vvp -n unit | grep 'tb_avr_link clk' >> unit.txt || true
    tail -1 unit.txt | grep ' 0 errors' > /dev/null || ok=1
  done
  return $ok
}

# ---- 1. the module alone
: > unit.txt
SWEEP=("35.714 1000.0" "35.714 250.0" "35.714 125.0" "41.667 1000.0" "41.667 250.0" "41.667 125.0")
unit "$RTL/avr/avr_link.v" "${SWEEP[@]}" || fail=1
cat unit.txt

# ---- 2. the AVR host stand
"$AVR/host_test/run.sh" eba1f0a "$W/host" || fail=1

# ---- 3. old and new module on the replays
mkdir -p ghdl
sed -e 's/when (N) =>/when 24 =>/' -e 's/when (N-1) downto (PREFETCH+3) =>/when 23 downto 5 =>/' \
    -e 's/when (PREFETCH+2) downto 2 =>/when 4 downto 2 =>/' \
    -e 's/signal state_next : natural range N+1 downto 0 := 0;/signal state_next : integer := 0;/' \
    -e 's/signal state_reg : natural range N+1 downto 0 := 0;/signal state_reg : integer := 0;/' \
    -e "s/state_dbg_o <= std_logic_vector(to_unsigned(state_reg, 6));/state_dbg_o <= (others => '0');/" \
    "$HERE/ref/spi_slave.vhd" > ghdl/spi_slave_sim.vhd
ghdl -a $G --workdir=ghdl "$HERE/avr_ip_models.vhd" ghdl/spi_slave_sim.vhd "$HERE/ref/avr_ref.vhd" \
  "$HERE/tb_avr_replay_v1.vhd"
# (no ghdl -e: the mcode build elaborates at -r, and elaboration opens the replay file)
iverilog -g2005 -o v2r "$HERE/tb_avr_replay_v2.v" "$RTL/avr/avr_link.v"

replay_v2() { # $1 = host log dir, $2 = scenario, $3 = vvp binary, $4 = out prefix
  python3 -I "$HERE/avr_replay.py" v2 "$1/v2.$2.log" "$4.rep"
  vvp -n "$3" +REPLAY="$4.rep" +STATE="$4.state" +OSD="$4.osd" > /dev/null
}

same_as_v1() { # $1 = scenario, $2 = v2 out prefix
  diff -q <(norm "v1$1/v1.state") <(norm "$2.state") > /dev/null &&
  diff -q <(norm "v1$1/v1.osd") <(norm "$2.osd") > /dev/null
}

for s in a b; do
  mkdir -p "v1$s"
  python3 -I "$HERE/avr_replay.py" v1 "$W/host/v1.$s.log" "v1$s/v1.rep"
  ghdl_run "$W/v1$s"
  replay_v2 "$W/host" $s v2r "v2$s"
  st=$(grep -c '^S' "v1$s/v1.state"); osd=$(wc -l < "v1$s/v1.osd")
  if same_as_v1 $s "v2$s"; then
    echo "scenario $s: old and new module the same ($st states, $osd OSD writes, 256 RTC registers)"
  else
    echo "scenario $s: old and new module differ:" >&2
    diff <(norm "v1$s/v1.state") <(norm "v2$s.state") | head -5 >&2 || true
    diff <(norm "v1$s/v1.osd") <(norm "v2$s.osd") | head -5 >&2 || true
    fail=1
  fi
done
[ $fail = 0 ] || { echo "FAIL" >&2; exit 1; }

# ---- 4. mutations
mutate() { # file, old text, new text -> prints the mutated copy's path
  local src=$1 dst=$2
  python3 -I -c 'import sys; p,o,a,b=sys.argv[1:]; t=open(p,encoding="utf-8").read(); assert t.count(a)==1, a; open(o,"w",encoding="utf-8").write(t.replace(a,b))' \
    "$src" "$dst" "$3" "$4"
}

mut_v() { # name, old, new: avr_link.v, caught by the unit bench (fast and slow SCK)
  mutate "$RTL/avr/avr_link.v" mut.v "$2" "$3"
  : > unit.txt
  local r=0
  unit mut.v "35.714 1000.0" "41.667 125.0" || r=$?
  case $r in
    0) echo "mutation $1: NOT caught" >&2; fail=1 ;;
    1) echo "mutation $1: caught" ;;
    *) echo "mutation $1: does not build" >&2; fail=1 ;;
  esac
}
mut_v status-byte "		di <= status;" "		di <= 8'h00;"
mut_v rombank-keep "8'h00: if (d == 8'd4) plus3e <= 1'b1;" "8'h00: if (d == 8'd4) begin plus3e <= 1'b1; soft_sw[2] <= d[0]; soft_sw[3] <= d[1]; end"
mut_v fifo-pop-early "wire       f_pop = stb && t_rtc && cmd_r == 8'h02 && n == 10'd2 && get_ok;" "wire       f_pop = rq && t_rtc && cmd == 8'h02 && rq_m == 10'd2 && get_ok;"
mut_v osd-long-run "		if (osd_hdr == 2'd0)" "		if (n == 10'd0)"
mut_v kempston "assign joy = { joy_btn[5], joy_btn[6], joy_btn[8], joy_btn[7]," "assign joy = { joy_btn[5], joy_btn[6], joy_btn[7], joy_btn[8],"
mut_v mouse-sum "						cur_x <= cur_x + m_x;" "						cur_x <= m_x;"
mut_v byte-toggle-early "always @(negedge avr_sck)
	if (!cs_n_f && bitcnt == 3'd0 && !first)
		byte_tgl <= ~byte_tgl;" "always @(posedge avr_sck)
	if (!cs_n_f && bitcnt == 3'd7)
		byte_tgl <= ~byte_tgl;"

mut_c() { # name, old, new: src/link_v2.c or another firmware file, caught by steps 2-3
  local name=$1 file=$2
  rm -rf mutavr; cp -r "$AVR" mutavr; rm -rf mutavr/.pio
  mutate "$AVR/$file" "mutavr/$file" "$3" "$4"
  local caught=0
  "$AVR/host_test/run.sh" eba1f0a "$W/muthost" "$W/mutavr" > /dev/null 2>&1 || caught=1
  if [ $caught = 0 ]; then
    for s in a b; do
      replay_v2 "$W/muthost" $s v2r "mut$s"
      same_as_v1 $s "mut$s" || caught=1
    done
  fi
  if [ $caught = 1 ]; then echo "mutation $name: caught"; else echo "mutation $name: NOT caught" >&2; fail=1; fi
}
mut_c osd-address src/link_v2.c "  uint16_t addr = (uint16_t)y * 32 + x;" "  uint16_t addr = (uint16_t)y * 33 + x;"
mut_c joy-bytes src/link_v2.c "  xfer(buttons & 0xFF);
  xfer(buttons >> 8);" "  xfer(buttons >> 8);
  xfer(buttons & 0xFF);"
mut_c mouse-buttons src/link_v2.c "  xfer(z & 0x7F);" "  xfer(z & 0x0F);"
mut_c rtc-value src/link_v2.c "  xfer(val);
  s_next = (uint8_t)(reg + 1);" "  xfer(val ^ 1);
  s_next = (uint8_t)(reg + 1);"
mut_c rtc-get-empty src/link_v2.c "    if (s_status & ST_RTC_PEND) {
      link_on_rtc_write(reg, val);" "    {
      link_on_rtc_write(reg, val);"
mut_c rombank-order src/keyboard.c "  link_setval(LV_ROMBANK, (s_is_sw3 ? 1 : 0) | (s_is_sw4 ? 2 : 0));
  if (s_is_plus3e) link_setval(LV_ROMBANK, 4);" "  if (s_is_plus3e) link_setval(LV_ROMBANK, 4);
  link_setval(LV_ROMBANK, (s_is_sw3 ? 1 : 0) | (s_is_sw4 ? 2 : 0));"

[ $fail = 0 ] && echo "OK: avr link v2" || { echo "FAIL" >&2; exit 1; }
