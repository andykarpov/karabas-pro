# Karabas-Pro Radio-86RK firmware

## How to flash FPGA and CPLD things

### For PCB rev.A and rev.B:

1) Open Quartus Programmer file karabas_pro_rk86_revA_tda1543.cdf or karabas_pro_rk86_revA_tda1543a.cdf (depends on the DAC model on your board)
2) Check all chips you want to flash (EPM3128, EP4CE6 and it's configuration device EPCS16), then click Program button

### For PCB rev.C and up:

1) Open Quartus Programmer file karabas_pro_rk86.cdf
2) Check all chips you want to flash (EPM3128, EP4CE6 and it's configuration device EPCS16), then click Program butt

## How to flash the AVR microcontroller:

Use any available programmer, like avrdude.

**Fusebits**

- Low: 0xFF
- High: 0xD7
- Extended: 0xFF

### Example usage:

`avrdude -c usbasp -p m328p -U flash:w:karabas_pro.hex -U lfuse:w:0xFF:m -U hfuse:w:0xD7:m`
