# Karabas-Pro Profi firmware

## How to flash FPGA and CPLD things

1) Open Quartus Programmer file target/karabas_pro_target_tda1543.cdf or target/karabas_pro_target_tda1543a.cdf (depends of the DAC model on your board)
2) Check all chips you want to flash (EPM3128, EP4CEXX and it's configuration device EPCS16), then click Program button

## How to flash the AVR microcontroller:

Use any available programmer, like avrdude.

A single universal firmware (`karabas_pro.hex`) supports all PCB revisions (Rev. A–E), native PS/2 keyboards, USB keyboards (via passive adapters), and KVM switches.

Hardware configuration (LED override, hardware buttons, boot defaults) is stored in the EEPROM (`karabas_pro.eep`). Make sure to flash both Flash and EEPROM:

**Fusebits**

- Low: 0xFF
- High: 0xD7
- Extended: 0xFF

### Example usage:

`avrdude -c usbasp -p m328p -U flash:w:karabas_pro.hex -U eeprom:w:karabas_pro.eep -U lfuse:w:0xFF:m -U hfuse:w:0xD7:m`

### EEPROM Configuration Map:

| Address | Parameter | Values | Default |
|---|---|---|---|
| 0x00 | Turbo mode | 0..3 | 0 (Normal) |
| 0x01 | Mode | 10 (Profi), 20 (ZX 128) | 10 (Profi) |
| 0x02..0x0B | Soft Switches SW1..SW10 | 10 (On), 20 (Off) | 20 (Off) |
| 0x0C | Mouse Swap buttons | 10 (Swapped), 20 (Normal) | 20 (Normal) |
| 0x0D | Joystick type | 10 (Sinclair), 20 (Kempston) | 20 (Kempston) |
| 0x0E | Screen mode | 0..1 | 0 |
| 0x0F | Joystick mode | 0..4 | 0 |
| 0x10 | DivMMC enable | 10 (Enabled), 20 (Disabled) | 20 (Disabled) |
| 0x11 | NemoIDE enable | 10 (Enabled), 20 (Disabled) | 20 (Disabled) |
| 0x12 | LED override by FPGA | 10 (Enabled), 20 (Disabled) | 10 (Enabled) |
| 0x13 | HW buttons (Reset/Magic) | 10 (Enabled), 20 (Disabled) | 10 (Enabled, set 20 for Rev.A) |
