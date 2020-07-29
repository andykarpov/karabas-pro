## Fusebits:

- Low: 0xFF
- High: 0xDE
- Extended: 0xFD

## Example usage:

`avrdude -c usbasp -p m328p -U flash:w:avr.ino.standard.hex -U lfuse:w:0xFF:m -U hfuse:w:0xDE:m -U efuse:w:0xFD:m`
