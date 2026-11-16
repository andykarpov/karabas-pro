#!/bin/bash
# Whole-core GHDL run of the Profi core with the ROM bank +3e (tb_boot.vhd).
# Not in CI: 1250 ms of machine time take about 1.5 hours.
#
# Usage: firmware/src/fpga/profi/sim/run_boot.sh [RUN_MS] [WORK_DIR]
# Expected at 14 MHz: the ROM tests the eight RAM banks (#7FFD 07..00), writes
# #1FFD = 04 and prints the +3e copyright lines (~400 ms), polls the SD card on
# port #57 until it times out (there is no card in the bench), then shows
# "Physical drives: 0 floppy, 0 MMC" and the main menu "128 +2e" (~1200 ms;
# +2e because there is no floppy controller). screen5.png has the last screen.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
RTL=$HERE/../rtl
RUN_MS=${1:-1250}
W=${2:-$(mktemp -d)}
mkdir -p "$W"
cd "$W"
G="--std=08 -fsynopsys -frelaxed"

python3 -I "$HERE/mkroms.py" "$RTL/video" .
python3 -I -c "import sys; d = open(sys.argv[1], 'rb').read(); open('plus3e.txt', 'w').write(''.join('%02X\n' % b for b in d))" \
  "$HERE/../rom/plus3e_mmc.rom"
sed -e 's/when (N) =>/when 24 =>/' -e 's/when (N-1) downto (PREFETCH+3) =>/when 23 downto 5 =>/' \
    -e 's/when (PREFETCH+2) downto 2 =>/when 4 downto 2 =>/' \
    -e 's/signal state_next : natural range N+1 downto 0 := 0;/signal state_next : integer := 0;/' \
    -e 's/signal state_reg : natural range N+1 downto 0 := 0;/signal state_reg : integer := 0;/' \
    -e "s/state_dbg_o <= std_logic_vector(to_unsigned(state_reg, 6));/state_dbg_o <= (others => '0');/" \
    "$RTL/spi/spi_slave.vhd" > spi_slave_sim.vhd

ghdl -a $G "$HERE/top_models.vhd" "$HERE/ip_models.vhd" "$HERE/avr_ip_models.vhd" spi_slave_sim.vhd \
  "$RTL/spi/spi_master.vhd" "$RTL/flash/flash.vhd" "$RTL/sd/zc_spi.vhd" "$RTL/memory/memory.vhd" \
  "$RTL/t80se/T80_Pack.vhd" "$RTL/t80se/T80_ALU.vhd" "$RTL/t80se/T80_MCode.vhd" "$RTL/t80se/T80_Reg.vhd" \
  "$RTL/t80se/T80.vhd" "$RTL/t80se/T80a.vhd" "$RTL/video/pentagon_video.vhd" "$RTL/video/profi_video.vhd" \
  "$RTL/video/video.vhd" "$RTL/video/icons.vhd" "$RTL/video/overlay.vhd" "$RTL/video/scandoubler.vhd" \
  "$RTL/sound/turbosound/turbosound.vhd" "$RTL/sound/covox/covox.vhd" "$RTL/sound/audio_mixer.vhd" \
  "$RTL/dac/tda1543.vhd" "$RTL/storage/bus_port.vhd" "$RTL/avr/avr.vhd" "$RTL/mouse/hw_int.vhd" \
  "$RTL/mouse/serial_mouse.vhd" "$RTL/board/board.vhd" "$RTL/karabas_pro.vhd" "$HERE/tb_boot.vhd" 2>&1 | grep -v warning || true
ghdl -e $G tb_boot 2>&1 | grep -v -i 'warning\|^[[:space:]]*\^\|^U[0-9]' || true

# cap the memory if systemd is there: a run that does not stop can eat all RAM
RUN="ghdl -r $G tb_boot -gRUN_MS=$RUN_MS -gTURBO=10 --ieee-asserts=disable"
if command -v systemd-run > /dev/null && systemd-run --user --scope -q true 2> /dev/null; then
  RUN="systemd-run --user --scope -q -p MemoryMax=4G -p MemorySwapMax=0 $RUN"
fi
$RUN 2>&1 | grep 'report note' | sed 's/.*(report note): //' | tee boot.txt
python3 -I "$HERE/render_screen.py" screen5.txt screen5.png 2> /dev/null && echo "screen: $W/screen5.png" || true
