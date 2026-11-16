# Profi core simulation

GHDL testbenches for parts of the Profi core that can be checked without
hardware.

## Scandoubler

```sh
firmware/src/fpga/profi/sim/run_scandoubler.sh
```

The real `video` controller drives the OSD `overlay` and the `scandoubler`
in all six screen modes (Pentagon / Classic at 50 / 60 Hz, Profi at 50 / 60 Hz).
The bench measures the VGA output of the third frame:

- line period and horizontal sync width, in CLK cycles;
- the active window and the paper area in x (from the start of HSYNC);
- lines per frame, vertical sync width, the active lines and the paper lines
  (from the start of VSYNC);
- `pairs bad`: VGA line pairs whose two copies of an input line differ.

Expected result (also in `expected_scandoubler.txt`; the script fails when the output differs, and CI runs it in `.github/workflows/sim.yml`):

```
pentagon50 line period=896 hsync=107 | act x 159..876 paper x 262..773 | lines/frame=640 vsync=2 act lines 36..629 paper lines 142..525 | pairs bad 0/297
pentagon60 line period=896 hsync=107 | act x 159..876 paper x 262..773 | lines/frame=528 vsync=2 act lines 36..517 paper lines 86..469 | pairs bad 0/241
classic50  line period=896 hsync=107 | act x 159..876 paper x 262..773 | lines/frame=624 vsync=2 act lines 36..613 paper lines 134..517 | pairs bad 0/289
classic60  line period=896 hsync=107 | act x 159..876 paper x 262..773 | lines/frame=512 vsync=2 act lines 36..501 paper lines 78..461 | pairs bad 0/233
profi50    line period=768 hsync=92 | act x 138..751 paper x 189..700 | lines/frame=624 vsync=2 act lines 36..613 paper lines 86..565 | pairs bad 0/289
profi60    line period=768 hsync=92 | act x 138..751 paper x 189..700 | lines/frame=528 vsync=2 act lines 36..517 paper lines 38..517 | pairs bad 0/241
```

The border is the same on both sides of the paper: 103 clocks for Spectrum, 51
for Profi. If a change in the video path moves the picture, adjust
`SPEC_PAPER` / `PROF_PAPER` in `rtl/video/scandoubler.vhd`.

## avr RTC and audio

```sh
firmware/src/fpga/profi/sim/run_avr_audio.sh
```

- `tb_rtc.vhd`: `avr.vhd` with an SPI master playing the AVR. A register sent by
  the AVR is written into the RTC RAM once, a CPU write is not overwritten
  afterwards, and one CPU write sends exactly one `CMD_RTC` packet to the AVR.
- `tb_audio.vhd`: `audio_mixer` against an integer model (random inputs,
  extremes, ACB / ABC / mono / mute), and `tda1543` decoded the way the DAC
  chips do (I2S for TDA1543, LSB-justified for TDA1543A), compared with the
  samples it loaded.

The script exits with an error if a check fails. `avr_ip_models.vhd` holds
models of the RTC RAM, the SPI queue and the message ROM.

## +3e memory map

```sh
firmware/src/fpga/profi/sim/run_plus3e.sh
```

`tb_plus3e.vhd` drives `memory.vhd` with `PLUS3E = '1'`, random `#1FFD` /
`#7FFD` values, addresses and RAM bank, and checks every CPU access against the
ZX Spectrum +3 memory map: the ROM page `#1FFD(2) & #7FFD(4)` read from SRAM
`#150000`, banks 5 / 2 / `#7FFD(2..0)` in the normal mode, the four layouts of
the special mode (`#1FFD(0) = 1`: 0-1-2-3, 4-5-6-7, 4-5-6-3, 4-7-6-3), no writes
to the ROM and the chip select of a 6 MB board.

## Models

`ip_models.vhd` contains behavioural models of the Quartus IP used by the
overlay. `mkroms.py` converts their ROM contents for GHDL.
