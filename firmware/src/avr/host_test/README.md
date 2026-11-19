# Host stand of the AVR firmware

```sh
firmware/src/avr/host_test/run.sh [BASE_REF] [WORK_DIR]   # BASE_REF default origin/master
```

The firmware of `src/` (except `hal.c` and `ps2_kbd.c`) is built for the PC with gcc and runs
one scenario against models of the hardware (`sim.c`): the FPGA link v1, a PS/2 keyboard (the
codes of `ps2_kbd.h`), PS/2 mouse reports (put into the queue of `mouse.c` by `mouse_wrap.c`),
an Atari stick and a 3-button Sega pad on the joystick pins, the DS1307, the EEPROM and the two
board buttons. Time is virtual (it moves by SPI bytes and by the delays of the firmware), so a
run always gives the same log: one line per SPI frame (time, bytes, LED pins).

The scenario: start, typing (shift, cursor keys, the bracket macros of the Spectrum layout),
every hotkey with Menu, pause, the joystick in both modes, the mouse (and the middle button
swap), CPU writes into the RTC, LED frames, the OSD menu with its pages, the board buttons,
Ctrl+Alt+Del and Ctrl+Alt+Backspace. It runs twice: with an erased EEPROM and with saved
settings (ROM bank +3e over bank 1, turbo 2, Spectrum layout, ...).

`run.sh` builds this checkout and `BASE_REF` (`git archive`), compares their logs, then mutates
the link of this checkout (menu value mapping, mouse toggle, joystick buttons, scancode bits,
...) and fails if a mutation leaves the log unchanged. About 20 seconds.

`include/` holds stubs of the avr-libc headers and a copy of `include/hal.h` whose chip select
is a function of the stand (the stand sees where a frame starts and ends).
