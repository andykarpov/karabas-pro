#ifndef config_h
#define config_h

#define DEBUG_MODE 1
#define DEBUG_TIME 0

#define USE_HW_BUTTONS 0

#define MOUSE_POLL_INTERVAL 10 // ms
#define MOUSE_SWAP_INTERVAL 1000 // ms

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

#define RTC_ADDRESS 0xA0

#define EEPROM_TURBO_ADDRESS 0x00
#define EEPROM_MODE_ADDRESS 0x01
#define EEPROM_SW1_ADDRESS 0x02
#define EEPROM_SW2_ADDRESS 0x03
#define EEPROM_SW3_ADDRESS 0x04
#define EEPROM_SW4_ADDRESS 0x05
#define EEPROM_SW5_ADDRESS 0x06
#define EEPROM_SW6_ADDRESS 0x07
#define EEPROM_SW7_ADDRESS 0x08
#define EEPROM_SW8_ADDRESS 0x09
#define EEPROM_MOUSE_SWAP_ADDRESS 0x0A

#define EEPROM_RTC_OFFSET 0x10

#define EEPROM_VALUE_TRUE 10
#define EEPROM_VALUE_FALSE 20

#endif
