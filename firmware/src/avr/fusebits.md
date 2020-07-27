## Fusebits:

- Low: 0xFF
- High: 0xDE
- Extended: 0x05

## Example usage:

`avrdude -c usbasp -p m328p -U lfuse:w:0xFF:m -U hfuse:w:0xDE:m -U efuse:w:0x05:m`
