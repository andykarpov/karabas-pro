#ifndef config_h
#define config_h

#ifndef USE_HW_BUTTONS
#define USE_HW_BUTTONS 1
#endif

#ifndef ALLOW_LED_OVERRIDE
#define ALLOW_LED_OVERRIDE 0
#endif

#ifndef SEND_ECHO_ON_START
#define SEND_ECHO_ON_START 0
#endif

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

// LED command
#define CMD_LED_WRITE 0x0E

// INIT command
#define CMD_INIT_REQ 0xFD // init req

// BUILD version commands
#define CMD_BUILD_REQ0 0xF0
#define CMD_BUILD_REQ1 0xF1
#define CMD_BUILD_REQ2 0xF2
#define CMD_BUILD_REQ3 0xF3
#define CMD_BUILD_REQ4 0xF4
#define CMD_BUILD_REQ5 0xF5
#define CMD_BUILD_REQ6 0xF6
#define CMD_BUILD_REQ7 0xF7

// NOP command
#define CMD_NONE 0xFF

// Popup timeouts
#define POPUP_TIMEOUT 1000
#define BOOT_POPUP_TIMEOUT 3500

#endif
