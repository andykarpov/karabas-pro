# Karabas-Pro ZX Next firmware pre-release

A very stripped down version of the ZX Next firmware

## How to flash FPGA and CPLD things

1) Open Quartus Programmer file karabas_pro_next.cdf
2) Check all chips you want to flash (EPM3128, EP4CE6 and it's configuration device EPCS16), then click Program button

## How to flash the AVR microcontroller:

Use any available programmer, like avrdude.

**Fusebits**

- Low: 0xFF
- High: 0xDE
- Extended: 0xFD

### Example usage:

`avrdude -c usbasp -p m328p -U flash:w:karabas_pro.hex -U lfuse:w:0xFF:m -U hfuse:w:0xDE:m -U efuse:w:0xFD:m`
