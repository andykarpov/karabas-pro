#ifndef config_h
#define config_h

#ifndef BUILD_VER
#define BUILD_VER DEVBUILD
#endif

// ---- Pins for Atmega328

// 13,12,11 - SPI
#define PIN_SCK 13
#define PIN_MISO 12
#define PIN_MOSI 11
#define PIN_SS 7 // SPI slave select

// leds
#define PIN_LED1 A2 // Busy LED
#define PIN_LED2 A1 // Busy LED

// buttons
#define PIN_BTN1 A6
#define PIN_BTN2 A7

// i2c
#define PIN_SDA A4 // pin 23 
#define PIN_SCL A5 // ping 24

// the commands of the FPGA link are in src/link_v1.c

// Popup timeouts
#define POPUP_TIMEOUT 1000
#define BOOT_POPUP_TIMEOUT 3500

#endif
