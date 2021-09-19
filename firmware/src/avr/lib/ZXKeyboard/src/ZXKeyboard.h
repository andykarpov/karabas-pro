/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __ZXKEYBOARD_H__
#define __ZXKEYBOARD_H__

// STL headers
// C headers
// Framework headers
#if ARDUINO < 100
#include <WProgram.h>
#else
#include <Arduino.h>
#endif

// Library headers
// Project headers
#include <avr/pgmspace.h>
#include <PS2KeyAdvanced.h>

#define PIN_KBD_CLK 2 // pin 28 (CLKK)
#define PIN_KBD_DAT 4 // pin 27 (DATK)

#define ZX_MATRIX_FULL_SIZE 72 // 40 keys + service signals
#define ZX_MATRIX_SIZE 41 // only mechanical keys state + bit6

#define ZX_K_CS  0
#define ZX_K_A   1
#define ZX_K_Q   2
#define ZX_K_1   3
#define ZX_K_0   4
#define ZX_K_P   5
#define ZX_K_ENT 6
#define ZX_K_SP  7
#define ZX_K_Z   8
#define ZX_K_S   9
#define ZX_K_W   10
#define ZX_K_2   11
#define ZX_K_9   12
#define ZX_K_O   13
#define ZX_K_L   14
#define ZX_K_SS  15
#define ZX_K_X   16
#define ZX_K_D   17
#define ZX_K_E   18
#define ZX_K_3   19
#define ZX_K_8   20
#define ZX_K_I   21
#define ZX_K_K   22
#define ZX_K_M   23
#define ZX_K_C   24
#define ZX_K_F   25
#define ZX_K_R   26
#define ZX_K_4   27
#define ZX_K_7   28
#define ZX_K_U   29
#define ZX_K_J   30
#define ZX_K_N   31
#define ZX_K_V   32
#define ZX_K_G   33
#define ZX_K_T   34
#define ZX_K_5   35
#define ZX_K_6   36
#define ZX_K_Y   37
#define ZX_K_H   38
#define ZX_K_B   39

// Fn keys ext bit
#define ZX_K_BIT6  40

// special signals
#define ZX_K_RESET  41
#define ZX_K_TURBO  42
#define ZX_K_MAGICK 43
#define ZX_K_IS_UP 44

// WAIT signal
#define ZX_K_WAIT 45

// Soft Switches
#define ZX_K_SW1 46
#define ZX_K_SW2 47

#define ZX_K_SCANCODE0 48
#define ZX_K_SCANCODE1 49
#define ZX_K_SCANCODE2 50
#define ZX_K_SCANCODE3 51
#define ZX_K_SCANCODE4 52
#define ZX_K_SCANCODE5 53
#define ZX_K_SCANCODE6 54
#define ZX_K_SCANCODE7 55
#define ZX_K_SCANCODE8 56

#define ZX_K_SW3 57
#define ZX_K_SW4 58
#define ZX_K_SW5 59

#define ZX_K_KBD_MODE 60

#define ZX_K_SW6 61
#define ZX_K_SW7 62
#define ZX_K_SW8 63

#define ZX_K_SW9 64
#define ZX_K_SW10 65

#define ZX_K_JOY_TYPE 66
#define ZX_K_OSD_OVERLAY 67

#define ZX_K_TURBO2 68
#define ZX_K_SCREEN_MODE0 69
#define ZX_K_SCREEN_MODE1 70

#define ZX_K_OSD_POPUP 71

// kbd commands
#define CMD_KBD_BYTE1 0x01
#define CMD_KBD_BYTE2 0x02
#define CMD_KBD_BYTE3 0x03
#define CMD_KBD_BYTE4 0x04
#define CMD_KBD_BYTE5 0x05
#define CMD_KBD_BYTE6 0x06
#define CMD_KBD_BYTE7 0x07 // scancode
#define CMD_KBD_BYTE8 0x08 // scancode

// eeprom addresses to store states
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
#define EEPROM_SW9_ADDRESS 0x0A
#define EEPROM_SW10_ADDRESS 0x0B
#define EEPROM_MOUSE_SWAP_ADDRESS 0x0C
#define EEPROM_JOY_TYPE_ADDRESS 0x0D
#define EEPROM_SCREEN_MODE_ADDRESS 0x0E

#define EEPROM_VALUE_TRUE 10
#define EEPROM_VALUE_FALSE 20

/****************************************************************************/

class ZXKeyboard
{

  using spi_cb = void (*)(uint8_t addr, uint8_t data); // alias function pointer
  using event_cb = void (*)(uint8_t event_type, uint16_t scancode);

private:
  PS2KeyAdvanced kbd;
  spi_cb action;
  event_cb event;
  bool is_started = false;
  bool matrix[ZX_MATRIX_FULL_SIZE]; // matrix of pressed keys + mouse reports to be transmitted on CPLD side by simple serial protocol
  bool profi_mode = true; // false = zx spectrum mode (switched by PrtSrc button in run-time)
  uint8_t turbo = 0; // turbo mode
  uint8_t max_turbo = 3; // max turbo
  uint8_t screen_mode = 0; // screen mode
  uint8_t max_screen_mode = 1; // max screen mode
  bool is_mouse_swap = false; // mouse buttons swap
  bool is_menu = false; // menu button pressed
  bool is_win = false; // win button pressed
  bool is_ctrl = false; // Ctrl button
  bool is_alt = false;  // Alt button
  bool is_sw1 = false; // SW1 state
  bool is_sw2 = false; // SW2 state
  bool is_sw3 = false; // SW3 state
  bool is_sw4 = false; // SW4 state
  bool is_sw5 = false; // SW5 state
  bool is_sw6 = false; // SW6 state
  bool is_sw7 = false; // SW7 state
  bool is_sw8 = false; // SW8 state
  bool is_sw9 = false; // SW9 state 
  bool is_sw10 = false; // SW10 state
  bool joy_type = false; // joy type - 0 = kempston, 1 = sega
  bool is_wait = false; // wait mode
  bool osd_overlay = false; // osd overlay enable
  bool osd_popup = false; // osd popup (small 2-row overlay)
  unsigned long tosd = 0; // osd last press toggle time
  bool prev_osd_overlay = true; // prev state of osd overlay
  bool cursor_up = false;
  bool cursor_down = false;
  bool cursor_left = false;
  bool cursor_right = false;
  bool is_enter = false;
  bool is_esc = false;
  int capsed_keys[10] = {0,0,0,0,0,0,0,0,0,0};
  int capsed_keys_size = 0;
  typedef struct {
    uint8_t key;
    uint8_t zxkey;
    unsigned long timestamp;
    bool up;
  } delayed_matrix_type;
  delayed_matrix_type delayed_matrix[8];
  uint8_t delayed_matrix_size = 0;

  void pushCapsedKey(int key);
  void popCapsedKey(int key);
  void processCapsedKey(int key, bool up);

  void fill(uint16_t sc, unsigned long n);
  void delayedKeypress(uint8_t key, uint8_t zxkey1, uint8_t zxkey2, bool up);
  void processDelayedKeypress();
  void sendMacros(uint8_t code, uint8_t zxkey);
  uint8_t getMatrixByte(uint8_t pos);

  bool eepromRestoreBool(int addr, bool default_value);
  void eepromStoreBool(int addr, bool value);
  uint8_t eepromRestoreInt(int addr, uint8_t default_value);
  void eepromStoreInt(int addr, uint8_t value);
  void eepromRestoreValues();

protected:

public:

  static const uint8_t EVENT_OSD_OVERLAY = 0;
  static const uint8_t EVENT_OSD_SCANCODE = 1;
  static const uint8_t EVENT_OSD_JOYSTICK = 2;
  static const uint8_t EVENT_OSD_SWAP_AB = 3;
  static const uint8_t EVENT_OSD_ROMBANK = 4;
  static const uint8_t EVENT_OSD_TURBOFDC = 5;
  static const uint8_t EVENT_OSD_COVOX = 6;
  static const uint8_t EVENT_OSD_STEREO = 7;
  static const uint8_t EVENT_OSD_SSG = 8;
  static const uint8_t EVENT_OSD_VIDEO = 9;
  static const uint8_t EVENT_OSD_VSYNC = 10;
  static const uint8_t EVENT_OSD_KEYBOARD_TYPE = 12;
  static const uint8_t EVENT_OSD_PAUSE = 13;
  static const uint8_t EVENT_OSD_TURBO = 14;
  static const uint8_t EVENT_OSD_SCREEN_MODE = 15;
  static const uint8_t EVENT_OSD_POPUP = 16;

  ZXKeyboard();

  void begin(spi_cb act, event_cb evt, bool send_echo);
  bool started();
  void handle();

  void setKey(uint8_t key, bool pressed);
  bool getKey(uint8_t key);

  void clear(int clear_size);
  void transmit();

  void doReset();
  void doFullReset();
  void doMagic();
  void doCaps();
  void doPause();

  void toggleOsdOverlay();
  void setOsdPopup(bool value);
  void setRombank(uint8_t bank);
  void toggleTurbofdc();
  void toggleCovox();
  void toggleStereo(uint8_t stereo);
  void toggleSsg();
  void toggleVideo();
  void toggleVsync();
  void setTurbo(uint8_t val);
  void setMaxTurbo(uint8_t val);
  void toggleSwapAB();
  void toggleJoyType();
  void toggleKeyboardType();
  void setMouseSwap(bool value);
  bool getMouseSwap();
  void setScreenMode(uint8_t val);

  bool getIsOsdOverlay();
  bool getIsOsdPopup();
  uint8_t getRombank();
  bool getTurbofdc();
  bool getCovox();
  uint8_t getStereo();
  bool getSsg();
  bool getVideo();
  bool getVsync();
  uint8_t getTurbo();
  uint8_t getMaxTurbo();
  bool getSwapAB();
  bool getJoyType();
  bool getKeyboardType();
  bool getPause();
  uint8_t getScreenMode();
  uint8_t getMaxScreenMode();

  bool getIsCursorUp();
  bool getIsCursorDown();
  bool getIsCursorLeft();
  bool getIsCursorRight();
  bool getIsEnter();
  bool getIsEscape();
  bool getIsMenu();
  void resetOsdControls();

};

extern ZXKeyboard zxkbd;

#endif // __ZXKEYBOARD_H__
// vim:cin:ai:sts=2 sw=2 ft=cpp
