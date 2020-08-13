# Karabas-Pro

**Yet another FPGA ZX Spectrum clone ;)**

## Intro

ZX Spectrum compatible machine with a soft CPU, FDD and HDD (CF card) controllers, PS/2 keyboard/mouse, VGA output and all logic inside the Altera FPGA **EP4CE6**.

## The idea

The idea was to make a smaller Profi (Профи) ZX Spectrum clone, with real FDD and HDD controllers. The board size should fit the dimensions of the real 3.5" floppy drive. 

## Firmwares

**The main firmware is still in progress. Currently it implements:**

1) ZX Spectrum classic and profi hi-res hi-color mode (512x240)
2) ZX Profi ports
3) FDD controller that works both in CP/M and classic modes
4) HDD controller (works only in Profi CP/M mode)
5) PS/2 keyboard and mouse
6) VGA output (requires a monitor with 50Hz support)
7) Turbosound (2 x AY-3-8912), Soundrive and SAA1099
8) Kempston joystick support
9) RTC (profi), emulated read-only yet, set time via atmega UART
10) SD card access via Z-Controller emulation

**The things that should be implemented (means a TODO list):**

1) Wi-Fi support in TR-DOS and CP/M modes
2) RTC ports read/write to set time from the profi interface
3) Profi palette

## More info

**ERRATA for PCB rev.A:** [See ERRATA Rev.A](https://github.com/andykarpov/karabas-pro/blob/master/ERRATA-REVA.md).

**ERRATA for PCB rev.B:** [See ERRATA Rev.B](https://github.com/andykarpov/karabas-pro/blob/master/ERRATA-REVB.md).

**Latest revision:** rev.C.

**Profi firmware** [Download a Profi firmware](https://github.com/andykarpov/karabas-pro/tree/master/firmware/releases/profi).

### Pre-production renders:

![image](https://github.com/andykarpov/karabas-pro/raw/master/docs/photos/karabas-pro-revC-top.png)

![image](https://github.com/andykarpov/karabas-pro/raw/master/docs/photos/karabas-pro-revC-bot.png)

![image](https://github.com/andykarpov/karabas-pro/raw/master/docs/photos/karabas-pro-revC-back.png)

