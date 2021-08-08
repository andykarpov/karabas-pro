# Karabas-Pro Pong firmware

## A simple Pong game (backport from ZX EVO)

### Keyboard controls:

**Left player:**
- Q - move up
- A - move down 

**Right player:**
- P or joystick up - move up
- L or joystick down - move down

**Global keys:**
- Space or Ctrl+Alt+Del - restart game
- Menu+F11 - toggle the scanlines effect


## How to flash FPGA and CPLD things

1) Open Quartus Programmer file karabas_pro_pong.cdf
2) Check all chips you want to flash (EPM3128, EP4CE6 and it's configuration device EPCS16), then click Program button

## How to flash the AVR microcontroller:

Use any available programmer, like avrdude.

**Fusebits**

- Low: 0xFF
- High: 0xD7
- Extended: 0xFF

### Example usage:

`avrdude -c usbasp -p m328p -U flash:w:karabas_pro.hex -U lfuse:w:0xFF:m -U hfuse:w:0xD7:m`
