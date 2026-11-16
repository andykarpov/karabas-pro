#!/bin/bash
# GHDL benches for avr.vhd (RTC) and the audio path (audio_mixer, tda1543).
# Exits with an error if a check fails.
#
# Usage: firmware/src/fpga/profi/sim/run_avr_audio.sh [WORK_DIR]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RTL=$HERE/../rtl
W=${1:-$(mktemp -d)}
mkdir -p "$W"
cd "$W"
G="--std=08 -fsynopsys -frelaxed"
fail=0

# spi_slave uses generics in case choices and a state range that GHDL rejects;
# simulate a copy with the values of the avr instance (N = 24, PREFETCH = 2)
sed -e 's/when (N) =>/when 24 =>/' -e 's/when (N-1) downto (PREFETCH+3) =>/when 23 downto 5 =>/' \
    -e 's/when (PREFETCH+2) downto 2 =>/when 4 downto 2 =>/' \
    -e 's/signal state_next : natural range N+1 downto 0 := 0;/signal state_next : integer := 0;/' \
    -e 's/signal state_reg : natural range N+1 downto 0 := 0;/signal state_reg : integer := 0;/' \
    -e "s/state_dbg_o <= std_logic_vector(to_unsigned(state_reg, 6));/state_dbg_o <= (others => '0');/" \
    "$RTL/spi/spi_slave.vhd" > spi_slave_sim.vhd

ghdl -a $G "$HERE/avr_ip_models.vhd" spi_slave_sim.vhd "$RTL/avr/avr.vhd" "$HERE/tb_rtc.vhd"
ghdl -e $G tb_rtc
ghdl -r $G tb_rtc 2>&1 | grep 'report note' | sed 's/.*(report note): //' | tee rtc.txt
grep -q 'tb_rtc: 0 errors' rtc.txt || fail=1

ghdl -a $G "$RTL/sound/audio_mixer.vhd" "$RTL/dac/tda1543.vhd" "$HERE/tb_audio.vhd"
ghdl -e $G tb_audio
ghdl -r $G tb_audio 2>&1 | grep 'report note' | sed 's/.*(report note): //' | tee audio.txt
grep -q 'mismatches 0' audio.txt || fail=1
[ "$(grep -c ', wrong 0' audio.txt)" -eq 2 ] || fail=1

if [ $fail = 0 ]; then echo "OK"; else echo "FAIL" >&2; exit 1; fi
