# Karabas-Pro Radio-86RK firmware

## How to flash FPGA and CPLD things

### For PCB rev.A and rev.B:

1) Open Quartus Programmer file karabas_pro_rk86_revA_tda1543.cdf or karabas_pro_rk86_revA_tda1543a.cdf (depends on the DAC model on your board)
2) Check all chips you want to flash (EPM3128, EP4CE6 and it's configuration device EPCS16), then click Program button

### For PCB rev.C and up:

1) Open Quartus Programmer file karabas_pro_rk86.cdf
2) Check all chips you want to flash (EPM3128, EP4CE6 and it's configuration device EPCS16), then click Program button

## How to flash the AVR microcontroller:

Use any available programmer, like avrdude.

A single universal firmware (`karabas_pro.hex`) supports all PCB revisions, native PS/2 keyboards, USB keyboards (via passive adapters), and KVM switches.

Hardware configuration is stored in the EEPROM. Pre-configured `.eep` files are provided for each PCB revision:
- **`karabas_pro_revD.eep`** (or `karabas_pro.eep`): for **PCB Rev. D, Rev. DS, Rev. E, Rev. EU, Rev. F** and newer.
- **`karabas_pro_revC.eep`**: for **PCB Rev. C**, or Rev. A / Rev. B with pullup resistors mod on SW1/SW2 buttons.
- **`karabas_pro_revA.eep`**: for **PCB Rev. A / Rev. B** without hardware buttons mod.

**Fusebits**

- Low: 0xFF
- High: 0xD7
- Extended: 0xFF

### Example usage:

For PCB Rev. D and higher:
`avrdude -c usbasp -p m328p -U flash:w:karabas_pro.hex -U eeprom:w:karabas_pro_revD.eep -U lfuse:w:0xFF:m -U hfuse:w:0xD7:m`

For PCB Rev. C:
`avrdude -c usbasp -p m328p -U flash:w:karabas_pro.hex -U eeprom:w:karabas_pro_revC.eep -U lfuse:w:0xFF:m -U hfuse:w:0xD7:m`

For PCB Rev. A / Rev. B:
`avrdude -c usbasp -p m328p -U flash:w:karabas_pro.hex -U eeprom:w:karabas_pro_revA.eep -U lfuse:w:0xFF:m -U hfuse:w:0xD7:m`
