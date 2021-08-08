# Karabas-Pro Profi +3e firmware

## How to flash FPGA and CPLD things

1) Open Quartus Programmer file target/karabas_pro_target_tda1543.cdf or target/karabas_pro_target_tda1543a.cdf (depends of the DAC model on your board)
2) Check all chips you want to flash (EPM3128, EP4CEXX and it's configuration device EPCS16), then click Program button

## How to flash the AVR microcontroller:

Use any available programmer, like avrdude.

Please flash the karabas_pro_revD.hex for PCB rev.D and higher, karabas_pro.hex only on PCBs rev.C or rev.A/rev.B with additional pullup resistors on SW1, SW2 buttons.
Otherwise please flash karabas_pro_revA.hex with hardware buttons disabled.

**Fusebits**

- Low: 0xFF
- High: 0xD7
- Extended: 0xFF

### Example usage:

`avrdude -c usbasp -p m328p -U flash:w:karabas_pro_revD.hex -U lfuse:w:0xFF:m -U hfuse:w:0xD7:m`
