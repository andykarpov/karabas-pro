# Karabas-Pro PCB changelog:

## Rev.Ї (EU):
- All PCB labels translated to Ukrainian language

## Rev.Ё (ER):
- Added russian labels on the board
- Changed TRRS footprints to a universal SMT/THT
- Added a standalone 3.3V LDO for ESP-8266
- Changed uSD footprint

## Rev.E:
- Added 2 more SRAM chips, up to 6 MB SRAM total, 4 MB available as host RAM, 1-2 MB as host ROM
- Changed uBus with 5-pin header for secondary UART
- Minimum Cyclone chip is EP4CE10 since this revision

## Rev.DS':
- Fixed Q2 footprint 
- Updated R nominals for buzzer and tape in for better compatibility

## Rev.DS:

- Removed DIP switches from the design
- Added an expansion connector for external joystick
- Added support for SEGA 3-button joysticks (mapped vcc and select pins to atmega)
- Added (optional) tape in/out connectors and logic
- Added on-board buzzer with jumper to disable it
- Increased pads length for so-8 flash ics (to support both W25Q16 and M25P16)
- Added free fpga pins 7,25 to the uBus connector
- Increased an fpga pin_145 (thermal pad) diameter from 3mm to 5mm

## Rev.D:

- Added ICs to source the board from 12V power supply instead of 5V
- Added a slide switch to power on/off the board
- Added fuses and supressor to protect the 5V rail from the accidental incorrect power source
- Added more LEDs on the board
- CF card LED mapped to a dedicated CD card "busy" pin
- SD card LED mapped to a /SD_CS signal
- Added a secondary flash chip and jumper
- Added optional 300 Ohm terminators for the FDD
- Added a ferrite filter for the 2.5V rail
- Added more powerful LDO on the 3.3V rail
- Added TurboFDC support
- Added connector with free ESP-12 module pins
- Added a diode assembly to power the RTC chip without battery
- Added a series of additional resistors on CF card /WR, /RD, /CS0, /CS1 pins

## Rev.C1:

- SD CMD pin rerouted to a dedicated FPGA pin 115
- CF card now uses 3.3v rails instead of 5v
- CF card pin 44 (/REG) pulled up to 3.3v

## Rev.C:

- Added 10k pull-up on /AVR_CS line
- Added 10k pull-ups on BTN1, BTN2 lines
- Changed footprint for DB9 connector
- Added DIP-switches on free FPGA lines

## Rev.B:

- Added missing 10k pull-ups on FDC_RDATA,FDC_WPRT, FDC_TR00, FDC_INTRQ, FDC_DRQ
- Changed R25 to 820 Ohm
- Changed R26,R27 to 750 Ohm
- Changed C1,C2 to 10uF
- Moved sound jack a bit left
- Added a restricted zone under the ESP-12 antenna

## Rev.A: 

- Initial revision
