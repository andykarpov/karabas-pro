# Karabas-Pro

**Yet another FPGA ZX Spectrum clone ;)**

## Intro

ZX Spectrum compatible machine with a soft CPU, FDD and HDD (CF card) controllers, PS/2 keyboard/mouse, VGA output and all logic inside the Altera FPGA **EP4CE6**.

## The idea

The idea was to make a smaller Profi (Профи) ZX Spectrum clone, with real FDD and HDD controllers. The board size should fit the dimensions of the real 3.5" floppy drive. 

## Firmwares

**The main firmware is almost finished, but some features are still in progress. Currently it implements:**

1) ZX Spectrum classic and profi hi-res hi-color mode (with palette) (512x240)
2) ZX Profi CMR ports for extended peripherial
3) FDD controller that works both in CP/M and classic modes
4) HDD controller (works in Profi CP/M mode and PQ-DOS mode)
5) PS/2 keyboard (XT keyboard emulation)
6) PS/2 mouse (kempston mouse and serial MS mouse emulation)
7) VGA output (requires a monitor with 50Hz support)
8) Turbosound (2 x AY-3-8912), Soundrive and SAA1099 (SAA will work only on EP4CE10 due to lack of free LEs in EP4CE6)
9) Kempston joystick support
10) RTC (profi), emulated read/write support
11) SD card access via Z-Controller emulation
12) Turbo 7 MHz
13) ZX UNO simple UART @115200 for ESP8266 module (with ability to enable a secondary ZX UNO UART on uBus connector)

## More info

**ERRATA for PCB rev.A:** [See ERRATA Rev.A](https://github.com/andykarpov/karabas-pro/blob/master/ERRATA-REVA.md).

**ERRATA for PCB rev.B:** [See ERRATA Rev.B](https://github.com/andykarpov/karabas-pro/blob/master/ERRATA-REVB.md).

**ERRATA for PCB rev.С:** [See ERRATA Rev.С](https://github.com/andykarpov/karabas-pro/blob/master/ERRATA-REVC.md).

**Latest revision:** rev.DS.

**Latest development revision:** rev.E.

**PCB changelog:** [PCB changelog](https://github.com/andykarpov/karabas-pro/blob/master/CHANGELOG-PCB.md).

**Profi firmware** [Download a Profi firmware](https://github.com/andykarpov/karabas-pro/tree/master/firmware/releases/profi).

## Donations

Our team is looking for some donations to release new features.
Most important one - a ROM image to extract FDD images (TRD, FDI, TD0) to real floppy disks.

Feel free to send any amount of USD/EUR/etc to support development of this project:

[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://paypal.me/dexius?locale.x=ru_RU)

WMID: 305965057957

Card: 4817 7601 6316 7095

Thanks in advance to all bakers! :)

Your support matters!

### Pre-production renders:

![image](https://github.com/andykarpov/karabas-pro/raw/master/docs/photos/karabas-pro-revDS-top.png)

![image](https://github.com/andykarpov/karabas-pro/raw/master/docs/photos/karabas-pro-revDS-bot.png)

