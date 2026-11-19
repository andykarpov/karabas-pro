# Host stand of the AVR firmware

```sh
firmware/src/avr/host_test/run.sh [BASE_REF] [WORK_DIR] [AVR_DIR]   # BASE_REF default eba1f0a
```

The firmware of `src/` (except `hal.c` and `ps2_kbd.c`) is built for the PC with gcc and runs
one scenario against models of the hardware (`sim.c`): the FPGA (link v1 with `-DLINK_V1`, as
`avr.vhd` of master answered; link v2 otherwise, docs/AVR_LINK_V2.md), a PS/2 keyboard (the
codes of `ps2_kbd.h`), PS/2 mouse reports (put into the queue of `mouse.c` by `mouse_wrap.c`),
an Atari stick and a 3-button Sega pad on the joystick pins, the DS1307, the EEPROM and the two
board buttons. The log has one line per SPI packet (time, bytes, LED pins), a line `M` at every
call of `link_keys()` (once per pass of the main loop; `link_v*.c` is built with
`-Dlink_keys=link_keys_real` and `sim.c` wraps it) and the EEPROM and DS1307 at the end.

Time is virtual and moves by the calls of `millis()` and by the delays outside the link (the
`delay_us()` of the link is not charged), so a run on link v1 and a run on link v2 reach every
`M` at the same moment.

The scenario: start, typing (shift, cursor keys, the bracket macros of the Spectrum layout),
every hotkey with Menu, pause, the joystick in both modes, the mouse (and the middle button
swap), CPU writes into the RTC, LED bits, the OSD menu with its pages, the board buttons,
Ctrl+Alt+Del and Ctrl+Alt+Backspace. It runs twice: with an erased EEPROM (`a`) and with saved
settings (`b`: ROM bank +3e over bank 1, turbo 2, Spectrum layout, Sega, ...).

`run.sh` builds `BASE_REF` (the last firmware on link v1) and this checkout (link v2), runs both
and checks: the SPI is never switched off with CS low, both reach the same number of passes,
the EEPROM and the DS1307 are the same at the end. The logs are the input of
`firmware/src/fpga/profi/sim/run_avr_link.sh`, which replays them into the old and the new FPGA
module and mutates the firmware.

`include/` holds stubs of the avr-libc headers and a copy of `include/hal.h` whose chip select
is a function of the stand (the stand sees where a packet starts and ends).
