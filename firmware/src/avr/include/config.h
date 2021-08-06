#ifndef config_h
#define config_h

#define DEBUG_MODE 1
#define DEBUG_TIME 0

#ifndef USE_HW_BUTTONS
#define USE_HW_BUTTONS 1
#endif

#define MOUSE_POLL_INTERVAL 10 // ms
#define MOUSE_SWAP_INTERVAL 1000 // ms
#define MOUSE_INIT_TRIES 2

#ifndef MOUSE_POLL_TYPE
#define MOUSE_POLL_TYPE 0 // 1 = poll, 0 = stream
#endif

#ifndef ALLOW_LED_OVERRIDE
#define ALLOW_LED_OVERRIDE 1
#endif

#ifndef BUILD_VER
#define BUILD_VER "DEVBUILD"
#endif

// ---- Pins for Atmega328
#define PIN_KBD_CLK 2 // pin 28 (CLKK)
#define PIN_KBD_DAT 4 // pin 27 (DATK)

#define PIN_MOUSE_CLK 3 // pin 26 (CLKM)
#define PIN_MOUSE_DAT 5 // pin 25 (DATM)

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

// joystick
#define PIN_JOY_UP 6
#define PIN_JOY_DOWN 8
#define PIN_JOY_LEFT 9
#define PIN_JOY_RIGHT 10
#define PIN_JOY_FIRE1 A0
#define PIN_JOY_FIRE2 A3

#define EEPROM_VALUE_TRUE 10
#define EEPROM_VALUE_FALSE 20

// Joystick signals
#define ZX_JOY_FIRE 0
#define ZX_JOY_FIRE2 1
#define ZX_JOY_UP 2
#define ZX_JOY_DOWN 3
#define ZX_JOY_LEFT 4
#define ZX_JOY_RIGHT 5
#define ZX_JOY_A 6
#define ZX_JOY_B 7

// mouse commands
#define CMD_MOUSE_X 0x0A
#define CMD_MOUSE_Y 0x0B
#define CMD_MOUSE_Z 0x0C

// joystick commands
#define CMD_JOY 0x0D

// LED command
#define CMD_LED_WRITE 0x0E

// OSD commands
#define CMD_OSD_CLS 0x0F
#define CMD_OSD_SET_X 0x10
#define CMD_OSD_SET_Y 0x11
#define CMD_OSD_PUT_C 0x12
#define CMD_OSD_ATTR  0x13


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

#endif
