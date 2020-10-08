/*
 * AVR keyboard & mouse firmware for Karabas-Pro
 * 
 * Designed to build on Arduino IDE.
 * 
 * @author Andy Karpov <andy.karpov@gmail.com>
 * Ukraine, 2020
 */

#include "ps2.h"
#include "matrix.h"
#include "ps2_codes.h"
#include "ps2mouse.h"
#include <RTC.h>
#include <EEPROM.h>
#include <Wire.h>
#include <SPI.h>

#define DEBUG_MODE 0
#define DEBUG_TIME 0

// ---- Pins for Atmega328
#define PIN_KBD_CLK 2 // pin 28 (CLKK)
#define PIN_KBD_DAT 4 // pin 27 (DATK)

#define PIN_MOUSE_CLK 3 // pin 26 (CLKM)
#define PIN_MOUSE_DAT 5 // pin 25 (DATM)

// 13,12,11 - hardware SPI
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
#define EEPROM_RTC_OFFSET 0x10

#define EEPROM_VALUE_TRUE 10
#define EEPROM_VALUE_FALSE 20

PS2KeyRaw kbd;
PS2Mouse mouse(PIN_MOUSE_CLK, PIN_MOUSE_DAT);
static DS1307 rtc;

bool matrix[ZX_MATRIX_FULL_SIZE]; // matrix of pressed keys + mouse reports to be transmitted on CPLD side by simple serial protocol
bool joy[6]; // joystic states
bool profi_mode = true; // false = zx spectrum mode (switched by PrtSrc button in run-time)
bool is_turbo = false; // turbo toggle (switched by ScrollLock button)
bool is_sw1 = false; // SW1 state
bool is_sw2 = false; // SW2 state
bool is_wait = false; // wait mode
bool mouse_present = false; // mouse present flag (detected by signal change on CLKM pin)
bool blink_state = false;
bool flags_changed = false; // changed flags is_turbo / profi_mode

bool led1_state = false;
bool led2_state = false;
bool led1_overwrite = false;
bool led2_overwrite = false;

unsigned long t = 0;  // current time
unsigned long tl1 = 0; // led1 time
unsigned long tl2 = 0; // led1 time
unsigned long tm = 0; // mouse poll time
unsigned long tl = 0; // blink poll time
unsigned long tr = 0; // rtc poll time
unsigned long te = 0; // eeprom store time
unsigned long tb = 0; // hw buttons poll time
int mouse_tries = 2; // number of triers to init mouse

uint8_t mouse_x = 0; // current mouse X
uint8_t mouse_y = 0; // current mouse Y
uint8_t mouse_z = 0; // current mousr Z
uint8_t mouse_btns = 0; // mouse buttons state
bool mouse_new_packet = false; // new packet to send (toggle flag)

int rtc_year = 0;
uint8_t rtc_month = 0;
uint8_t rtc_day = 0;
uint8_t rtc_hours = 0;
uint8_t rtc_minutes = 0;
uint8_t rtc_seconds = 0;

uint8_t rtc_seconds_alarm = 0;
uint8_t rtc_minutes_alarm = 0;
uint8_t rtc_hours_alarm = 0;
uint8_t rtc_week = 0;

uint8_t rtc_last_write_reg = 0;
uint8_t rtc_last_write_data = 0;

bool rtc_init_done = false;

const int buf_len = 128; 
char buf[buf_len];
byte index = 0;
bool buffering = true;

SPISettings settingsA(8000000, MSBFIRST, SPI_MODE0); // SPI transmission settings

// transform PS/2 scancodes into internal matrix of pressed keys
void fill_kbd_matrix(int sc)
{

  static bool is_up=false, is_e=false, is_e1=false;
  static bool is_ctrl=false, is_alt=false, is_del=false, is_win = false, is_menu = false, is_bksp = false, is_shift = false, is_esc = false, is_ss_used = false, is_cs_used = false;
  static int scancode = 0;

  // is extended scancode prefix
  if (sc == 0xE0) {
    is_e = 1;
    return;
  }

 if (sc == 0xE1) {
    is_e = 1;
    is_e1 = 1;
    return;
  }

  // is key released prefix
  if (sc == 0xF0 && !is_up) {
    is_up = 1;
    return;
  }

  scancode = sc + ((is_e || is_e1) ? 0x100 : 0);

  is_ss_used = false;
  is_cs_used = false;

  matrix[ZX_K_IS_UP] = is_up;
  matrix[ZX_K_SCANCODE15] = bitRead(scancode, 15);
  matrix[ZX_K_SCANCODE14] = bitRead(scancode, 14);
  matrix[ZX_K_SCANCODE13] = bitRead(scancode, 13);
  matrix[ZX_K_SCANCODE12] = bitRead(scancode, 12);
  matrix[ZX_K_SCANCODE11] = bitRead(scancode, 11);
  matrix[ZX_K_SCANCODE10] = bitRead(scancode, 10);
  matrix[ZX_K_SCANCODE9] = bitRead(scancode, 9);
  matrix[ZX_K_SCANCODE8] = bitRead(scancode, 8);
  matrix[ZX_K_SCANCODE7] = bitRead(scancode, 7);
  matrix[ZX_K_SCANCODE6] = bitRead(scancode, 6);
  matrix[ZX_K_SCANCODE5] = bitRead(scancode, 5);
  matrix[ZX_K_SCANCODE4] = bitRead(scancode, 4);
  matrix[ZX_K_SCANCODE3] = bitRead(scancode, 3);
  matrix[ZX_K_SCANCODE2] = bitRead(scancode, 2);
  matrix[ZX_K_SCANCODE1] = bitRead(scancode, 1);
  matrix[ZX_K_SCANCODE0] = bitRead(scancode, 0);

  switch (scancode) {
  
    // Shift -> SS for Profi, CS for ZX
    case PS2_L_SHIFT: 
    case PS2_R_SHIFT:
      matrix[profi_mode ? ZX_K_SS : ZX_K_CS] = !is_up;
      is_shift = !is_up;
      break;

    // Ctrl -> CS for Profi, SS for ZX
    case PS2_L_CTRL:
    case PS2_R_CTRL:
      matrix[profi_mode ? ZX_K_CS : ZX_K_SS] = !is_up;
      is_ctrl = !is_up;
      break;

    // Alt (L) -> SS+Enter for Profi, SS+CS for ZX
    case PS2_L_ALT:
      matrix[ZX_K_SS] = !is_up;
      matrix[profi_mode ? ZX_K_ENT : ZX_K_CS] = !is_up;
      if (!profi_mode) {
        is_cs_used = !is_up;
      }
      is_alt = !is_up;
      break;

    // Alt (R) -> SS + Space for Profi, SS+CS for ZX
    case PS2_R_ALT:
      matrix[ZX_K_SS] = !is_up;
      matrix[profi_mode ? ZX_K_SP : ZX_K_CS] = !is_up;
      if (!profi_mode) {
        is_cs_used = !is_up;
      }
      is_alt = !is_up;
      break;

    // Del -> P+b6 for Profi, SS+C for ZX
    case PS2_DELETE:
      if (profi_mode) {
         matrix[ZX_K_P] = !is_up;
         matrix[ZX_K_BIT6] = !is_up;
      } else {
        matrix[ZX_K_SS] = !is_up;
        matrix[ZX_K_C] =  !is_up;
      }
      is_del = !is_up;
    break;

    // Win
    case PS2_L_WIN:
    case PS2_R_WIN:
      is_win = !is_up;
    break;

    // Menu
    case PS2_MENU:
      is_menu = !is_up;
    break;

    // Ins -> O+b6 for Profi, SS+A for ZX
    case PS2_INSERT:
      if (profi_mode) {
        matrix[ZX_K_O] = !is_up;
        matrix[ZX_K_BIT6] = !is_up;
      } else {
        matrix[ZX_K_SS] = !is_up;
        matrix[ZX_K_A] =  !is_up;
      }
    break;

    // Cursor -> CS + 5,6,7,8
    case PS2_UP:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_7] = !is_up;
      is_cs_used = !is_up;
      break;
    case PS2_DOWN:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_6] = !is_up;
      is_cs_used = !is_up;
      break;
    case PS2_LEFT:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_5] = !is_up;
      is_cs_used = !is_up;
      break;
    case PS2_RIGHT:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_8] = !is_up;
      is_cs_used = !is_up;
      break;

    // ESC -> CS+1 for Profi, CS+SPACE for ZX
    case PS2_ESC:
      matrix[ZX_K_CS] = !is_up;
      matrix[profi_mode ? ZX_K_1 : ZX_K_SP] = !is_up;
      is_cs_used = !is_up;
      is_esc = !is_up;
      break;

    // Backspace -> CS+0
    case PS2_BACKSPACE:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_0] = !is_up;
      is_cs_used = !is_up;
      is_bksp = !is_up;
      break;

    // Enter
    case PS2_ENTER:
    case PS2_KP_ENTER:
      matrix[ZX_K_ENT] = !is_up;
      break;

    // Space
    case PS2_SPACE:
      matrix[ZX_K_SP] = !is_up;
      break;

    // Letters & numbers
    case PS2_A: matrix[ZX_K_A] = !is_up; break;
    case PS2_B: matrix[ZX_K_B] = !is_up; break;
    case PS2_C: matrix[ZX_K_C] = !is_up; break;
    case PS2_D: matrix[ZX_K_D] = !is_up; break;
    case PS2_E: matrix[ZX_K_E] = !is_up; break;
    case PS2_F: matrix[ZX_K_F] = !is_up; break;
    case PS2_G: matrix[ZX_K_G] = !is_up; break;
    case PS2_H: matrix[ZX_K_H] = !is_up; break;
    case PS2_I: matrix[ZX_K_I] = !is_up; break;
    case PS2_J: matrix[ZX_K_J] = !is_up; break;
    case PS2_K: matrix[ZX_K_K] = !is_up; break;
    case PS2_L: matrix[ZX_K_L] = !is_up; break;
    case PS2_M: matrix[ZX_K_M] = !is_up; break;
    case PS2_N: matrix[ZX_K_N] = !is_up; break;
    case PS2_O: matrix[ZX_K_O] = !is_up; break;
    case PS2_P: matrix[ZX_K_P] = !is_up; break;
    case PS2_Q: matrix[ZX_K_Q] = !is_up; break;
    case PS2_R: matrix[ZX_K_R] = !is_up; break;
    case PS2_S: matrix[ZX_K_S] = !is_up; break;
    case PS2_T: matrix[ZX_K_T] = !is_up; break;
    case PS2_U: matrix[ZX_K_U] = !is_up; break;
    case PS2_V: matrix[ZX_K_V] = !is_up; break;
    case PS2_W: matrix[ZX_K_W] = !is_up; break;
    case PS2_X: matrix[ZX_K_X] = !is_up; break;
    case PS2_Y: matrix[ZX_K_Y] = !is_up; break;
    case PS2_Z: matrix[ZX_K_Z] = !is_up; break;

    // digits
    case PS2_0: matrix[ZX_K_0] = !is_up; break;
    case PS2_1: matrix[ZX_K_1] = !is_up; break;
    case PS2_2: matrix[ZX_K_2] = !is_up; break;
    case PS2_3: matrix[ZX_K_3] = !is_up; break;
    case PS2_4: matrix[ZX_K_4] = !is_up; break;
    case PS2_5: matrix[ZX_K_5] = !is_up; break;
    case PS2_6: matrix[ZX_K_6] = !is_up; break;
    case PS2_7: matrix[ZX_K_7] = !is_up; break;
    case PS2_8: matrix[ZX_K_8] = !is_up; break;
    case PS2_9: matrix[ZX_K_9] = !is_up; break;

    // Keypad digits
    case PS2_KP_0: matrix[ZX_K_0] = !is_up; break;
    case PS2_KP_1: matrix[ZX_K_1] = !is_up; break;
    case PS2_KP_2: matrix[ZX_K_2] = !is_up; break;
    case PS2_KP_3: matrix[ZX_K_3] = !is_up; break;
    case PS2_KP_4: matrix[ZX_K_4] = !is_up; break;
    case PS2_KP_5: matrix[ZX_K_5] = !is_up; break;
    case PS2_KP_6: matrix[ZX_K_6] = !is_up; break;
    case PS2_KP_7: matrix[ZX_K_7] = !is_up; break;
    case PS2_KP_8: matrix[ZX_K_8] = !is_up; break;
    case PS2_KP_9: matrix[ZX_K_9] = !is_up; break;

    // '/" -> SS+P / SS+7
    case PS2_QUOTE:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_P : ZX_K_7] = !is_up;
      if (is_up) {
        matrix[ZX_K_P] = false;
        matrix[ZX_K_7] = false;
      }
      is_ss_used = is_shift;
      break;

    // ,/< -> SS+N / SS+R
    case PS2_COMMA:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_R : ZX_K_N] = !is_up;
      if (is_up) {
        matrix[ZX_K_R] = false;
        matrix[ZX_K_N] = false;
      }
      is_ss_used = is_shift;
      break;

    // ./> -> SS+M / SS+T
    case PS2_PERIOD:
    case PS2_KP_PERIOD:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_T : ZX_K_M] = !is_up;
      if (is_up) {
        matrix[ZX_K_T] = false;
        matrix[ZX_K_M] = false;
      }
      is_ss_used = is_shift;
      break;

    // ;/: -> SS+O / SS+Z
    case PS2_SEMICOLON:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_Z : ZX_K_O] = !is_up;
      if (is_up) {
        matrix[ZX_K_Z] = false;
        matrix[ZX_K_O] = false;
      }
      is_ss_used = is_shift;
      break;

    // [,{ -> SS+Y / SS+F
    case PS2_L_BRACKET:
      if (!profi_mode) {
        if (!is_up) {
          send_macros(is_shift ? ZX_K_F : ZX_K_Y);
        }
      } else {
        matrix[ZX_K_SS] = !is_up;        
        matrix[is_shift ? ZX_K_F : ZX_K_Y] = !is_up;
        if (is_up) {
          matrix[ZX_K_F] = false;
          matrix[ZX_K_Y] = false;
        }
      }  
      break;

    // ],} -> SS+U / SS+G
    case PS2_R_BRACKET:
      if (!profi_mode) {
        if (!is_up) {
          send_macros(is_shift ? ZX_K_G : ZX_K_U);
        }
      } else {
        matrix[ZX_K_SS] = !is_up;        
        matrix[is_shift ? ZX_K_G : ZX_K_U] = !is_up;
        if (is_up) {
          matrix[ZX_K_G] = false;
          matrix[ZX_K_U] = false;
        }
      }
      break;

    // /,? -> SS+V / SS+C
    case PS2_SLASH:
    case PS2_KP_SLASH:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_C : ZX_K_V] = !is_up;
      if (is_up) {
        matrix[ZX_K_C] = false;
        matrix[ZX_K_V] = false;
      }
      is_ss_used = is_shift;
      break;

    // \,| -> SS+D / SS+S
    case PS2_BACK_SLASH:
      if (!profi_mode) {
        if (!is_up) {
          send_macros(is_shift ? ZX_K_S : ZX_K_D);
        }
      } else {
        matrix[ZX_K_SS] = !is_up;        
        matrix[is_shift ? ZX_K_S : ZX_K_D] = !is_up;
        if (is_up) {
          matrix[ZX_K_S] = false;
          matrix[ZX_K_D] = false;
        }
      }
      break;

    // =,+ -> SS+L / SS+K
    case PS2_EQUALS:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_K : ZX_K_L] = !is_up;
      if (is_up) {
        matrix[ZX_K_K] = false;
        matrix[ZX_K_L] = false;
      }
      is_ss_used = is_shift;
      break;

    // -,_ -> SS+J / SS+0
    case PS2_MINUS:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_0 : ZX_K_J] = !is_up;
      if (is_up) {
        matrix[ZX_K_0] = false;
        matrix[ZX_K_J] = false;
      }
      is_ss_used = is_shift;
      break;

    // `,~ -> SS+X / SS+A
    case PS2_ACCENT:
      if (is_shift and !is_up) {
        send_macros(is_shift ? ZX_K_A : ZX_K_X);
      }
      if (!is_shift) {
        matrix[ZX_K_SS] = !is_up;
        matrix[ZX_K_X] = !is_up;
      }
      is_ss_used = is_shift;
      break;

    // Keypad * -> SS+B
    case PS2_KP_STAR:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_B] = !is_up;
      break;

    // Keypad - -> SS+J
    case PS2_KP_MINUS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_J] = !is_up;
      break;

    // Keypad + -> SS+K
    case PS2_KP_PLUS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_K] = !is_up;
      break;

    // Tab
    case PS2_TAB:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_I] = !is_up;
      is_cs_used = !is_up;
      break;

    // CapsLock
    case PS2_CAPS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_CS] = !is_up;
      is_cs_used = !is_up;
      break;

    // PgUp -> M+BIT6 for Profi, CS+3 for ZX
    case PS2_PGUP:
      if (profi_mode) {
        matrix[ZX_K_M] = !is_up;
        matrix[ZX_K_BIT6] = !is_up;        
      } else {
        matrix[ZX_K_CS] = !is_up;
        matrix[ZX_K_3] = !is_up;
        is_cs_used = !is_up;
      }
      break;

    // PgDn -> N+BIT6 for Profi, CS+4 for ZX
    case PS2_PGDN:
      if (profi_mode) {
        matrix[ZX_K_N] = !is_up;
        matrix[ZX_K_BIT6] = !is_up;        
      } else {
        matrix[ZX_K_CS] = !is_up;
        matrix[ZX_K_4] = !is_up;
        is_cs_used = !is_up;
      }
      break;

    // Home -> K+BIT6 for Profi
    case PS2_HOME:
      matrix[ZX_K_K] = !is_up;
      matrix[ZX_K_BIT6] = !is_up;
      break;

    // End -> L+BIT6 for Profi
    case PS2_END:
      matrix[ZX_K_L] = !is_up;
      matrix[ZX_K_BIT6] = !is_up;
      break;


    // Fn keys
    case PS2_F1:
      if (is_menu && !is_up) {
        // menu + F1 = SW1
        is_sw1 = !is_sw1;
        eeprom_store_value(EEPROM_SW1_ADDRESS, is_sw1);
        matrix[ZX_K_SW1] = is_sw1;
      } else {
        matrix[ZX_K_A] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
      }    
    case PS2_F2: 
      if (is_menu && !is_up) {
        // menu + F2 = SW2
        is_sw2 = !is_sw2;
        eeprom_store_value(EEPROM_SW2_ADDRESS, is_sw2);
        matrix[ZX_K_SW2] = is_sw2;
      } else {
        matrix[ZX_K_B] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
      }
    case PS2_F3: matrix[ZX_K_C] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F4: matrix[ZX_K_D] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F5: matrix[ZX_K_E] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F6: matrix[ZX_K_F] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F7: matrix[ZX_K_G] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F8: matrix[ZX_K_H] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F9: matrix[ZX_K_I] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F10: matrix[ZX_K_J] = !is_up; matrix[ZX_K_BIT6] = !is_up; break;
    case PS2_F11: 
      if (is_menu && !is_up) {
        // menu + F11 = turbo
        is_turbo = !is_turbo;
        eeprom_store_value(EEPROM_TURBO_ADDRESS, is_turbo);
        matrix[ZX_K_TURBO] = is_turbo;
      } else {
        matrix[ZX_K_Q] = !is_up; matrix[ZX_K_SS] = !is_up; 
      }
    break;
    case PS2_F12: 
      if (is_menu && !is_up) {
        // menu + F12 = magic
        do_magic();
      } else {
        matrix[ZX_K_W] = !is_up; matrix[ZX_K_SS] = !is_up; 
      }
    break;

    // Scroll Lock -> Wait
    case PS2_SCROLL:
      if (is_up) {
        is_wait = !is_wait;
        matrix[ZX_K_WAIT] = is_wait; 
      }
    break;

    // PrtScr -> Mode profi / zx
    case PS2_PSCR1:
      if (is_up) {
        profi_mode = !profi_mode;
        eeprom_store_value(EEPROM_MODE_ADDRESS, profi_mode);
      }
    break;

    // TODO:
    // Windows L / Home -> SS+F
    // Windiws R / End -> SS+G
  
  }

  if (is_ss_used and !is_cs_used) {
      matrix[ZX_K_CS] = false;
  }

  // Ctrl+Alt+Del -> RESET
  if (is_ctrl && is_alt && is_del) {
    is_ctrl = false;
    is_alt = false;
    is_del = false;
    is_shift = false;
    is_ss_used = false;
    is_cs_used = false; 
    do_reset();
  }
  //digitalWrite(PIN_RESET, (is_ctrl && is_alt && is_del) ? LOW : HIGH);

  // Ctrl+Alt+Esc -> MAGIC
  if (is_ctrl && is_alt && is_esc) {
    is_ctrl = false;
    is_alt = false;
    is_esc = false;
    is_shift = false;
    is_ss_used = false;
    is_cs_used = false;    
    do_magic();
  }  

  // Ctrl+Alt+Bksp -> REINIT controller
  if (is_ctrl && is_alt && is_bksp) {
      is_ctrl = false;
      is_alt = false;
      is_bksp = false;
      is_shift = false;
      is_ss_used = false;
      is_cs_used = false;      
      clear_matrix(ZX_MATRIX_SIZE);
      matrix[ZX_K_RESET] = 1;
      transmit_keyboard_matrix();
      matrix[ZX_K_S] = 1;
      transmit_keyboard_matrix();
      delay(500);
      matrix[ZX_K_RESET] = 0;
      transmit_keyboard_matrix();
      delay(500);
      matrix[ZX_K_S] = 0;
      //setup();
  }

   // clear flags
   is_up = 0;
   if (is_e1) {
    is_e1 = 0;
   } else {
     is_e = 0;
   }
}

// transmit keyboard macros (sequence of keyboard clicks) to emulate typing some special symbols [, ], {, }, ~, |, `
void send_macros(uint8_t pos)
{
  clear_matrix(ZX_MATRIX_SIZE);
  transmit_keyboard_matrix();
  delay(20);
  matrix[ZX_K_CS] = true;
  transmit_keyboard_matrix();
  delay(20);
  matrix[ZX_K_SS] = true;
  transmit_keyboard_matrix();
  delay(20);
  matrix[ZX_K_SS] = false;
  transmit_keyboard_matrix();
  delay(20);
  matrix[pos] = true;
  transmit_keyboard_matrix();
  delay(20);
  matrix[ZX_K_CS] = false;
  matrix[pos] = false;
  transmit_keyboard_matrix();
  delay(20);
}

uint8_t get_matrix_byte(uint8_t pos)
{
  uint8_t result = 0;
  for (uint8_t i=0; i<8; i++) {
    uint8_t k = pos*8 + i;
    if (k < ZX_MATRIX_FULL_SIZE) {
      bitWrite(result, i, matrix[k]);
    }
  }
  return result;
}

uint8_t get_joy_byte()
{
  uint8_t result = 0;
  for (uint8_t i=0; i<6; i++) {
      bitWrite(result, i, joy[i]);
  }
  return result;
}

void spi_send(uint8_t addr, uint8_t data) 
{
      SPI.beginTransaction(settingsA);
      digitalWrite(PIN_SS, LOW);
      uint8_t cmd = SPI.transfer(addr); // command (1...6)
      uint8_t res = SPI.transfer(data); // data byte
      digitalWrite(PIN_SS, HIGH);
      SPI.endTransaction();
      if (cmd > 0) {
        process_in_cmd(cmd, res);
      }  
}

// transmit keyboard matrix from AVR to CPLD side via SPI
void transmit_keyboard_matrix()
{
    uint8_t bytes = 8;
    for (uint8_t i=0; i<bytes; i++) {
      uint8_t data = get_matrix_byte(i);
      spi_send(i+1, data);
    }
}

void transmit_joy_data()
{
  uint8_t data = get_joy_byte();
  spi_send(CMD_JOY, data);
}

void transmit_mouse_data()
{
  uint8_t cmd = 0;
  uint8_t res = 0;

  spi_send(CMD_MOUSE_X, mouse_x);
  spi_send(CMD_MOUSE_Y, mouse_y);
  spi_send(CMD_MOUSE_Z, mouse_z);
}

void rtc_save() {
  rtc.setHourMode(CLOCK_H24);
  rtc.setDay(rtc_day);
  rtc.setMonth(rtc_month);
  rtc.setYear(rtc_year);
  rtc.setWeek(rtc_week);
  rtc.setHours(rtc_hours);
  rtc.setMinutes(rtc_minutes);
  rtc.setSeconds(rtc_seconds);
}

void rtc_send(uint8_t reg, uint8_t data) {

#if DEBUG_MODE
#if DEBUG_TIME
    Serial.print(F("RTC send: "));
    Serial.print(F("\treg="));
    Serial.print(reg, HEX);
    Serial.print(F("\tdata="));
    Serial.print(data);
    Serial.println();
#endif
#endif

  spi_send(CMD_RTC_READ + reg, data);
}

uint8_t get_year(int year) {
  int res = year % 100;
  return lowByte(res);
}

void rtc_send_time() {
  rtc_send(0, rtc_seconds);
  rtc_send(2, rtc_minutes);
  rtc_send(4, rtc_hours);
  rtc_send(6, rtc_week+1);
  rtc_send(7, rtc_day);
  rtc_send(8, rtc_month);
  rtc_send(9, get_year(rtc_year)); // TODO
}

void rtc_send_all() {
  for (uint8_t reg; reg<64; reg++) {
    switch (reg) {
      case 0:
        rtc_send(reg, rtc_seconds);
      break;
      case 1:
        rtc_send(reg, rtc_seconds_alarm);
      break;
      case 2:
        rtc_send(reg, rtc_minutes);
      break;
      case 3:
        rtc_send(reg, rtc_minutes_alarm);
      break;
      case 4:
        rtc_send(reg, rtc_hours);
      break;
      case 5:
        rtc_send(reg, rtc_hours_alarm);
      break;
      case 6:
        rtc_send(reg, rtc_week+1);
      break;
      case 7:
        rtc_send(reg, rtc_day);
      break;
      case 8:
        rtc_send(reg, rtc_month);
      break;
      case 9:
        rtc_send(reg, get_year(rtc_year)); // TODO
      break;
      default:
        rtc_send(reg, EEPROM.read(EEPROM_RTC_OFFSET + reg));
   } 
  }
}

void process_in_cmd(uint8_t cmd, uint8_t data)
{
  uint8_t reg;

//  if (cmd == CMD_RTC_INIT_REQ && !rtc_init_done) {
//
//#if DEBUG_MODE
//    Serial.println(F("RTC INIT REQUEST"));
//#endif
//    
//    rtc_send_all();
//    rtc_init_done = true;
//  }

  if (cmd == CMD_LED_WRITE) {
    led1_state = bitRead(data, 0);
    led2_state = bitRead(data, 1);
    led1_overwrite = bitRead(data, 2);
    led2_overwrite = bitRead(data, 3);
  }
  
  if (cmd >= CMD_RTC_WRITE && cmd < CMD_RTC_WRITE+64) {
    // write rtc register
   reg = cmd - CMD_RTC_WRITE;

   // skip double write
   if (rtc_last_write_reg == reg && rtc_last_write_data == data) return;

   rtc_last_write_reg = reg;
   rtc_last_write_data = data;

#if DEBUG_MODE
    Serial.print(F("RTC write: "));
    Serial.print(F("\treg="));
    Serial.print(reg, HEX);
    Serial.print(F("\tdata="));
    Serial.print(data);
    Serial.println();
#endif
   
   switch (reg) {
      case 2:
        rtc_minutes = data;
        rtc_save();
      break;
      case 4:
        rtc_hours = data;
        rtc_save();
      break;
      case 6:
        rtc_week = data-1;
        rtc_save();
      break;
      case 7:
        rtc_day = data;
        rtc_save();
      break;
      case 8:
        rtc_month = data;
        rtc_save();
      break;
      case 9:
        rtc_year = 2000 + data; // TODO
        rtc_save();
      break;
      default:
        EEPROM.write(EEPROM_RTC_OFFSET + reg, data);
   }
  }
}

void init_mouse()
{
    mouse_present = mouse.initialize();
  
#if DEBUG_MODE
  if (!mouse_present) {
    Serial.println(F("Mouse does not exists"));
  } else {
    Serial.println(F("Mouse present"));
  }
#endif

}

void do_reset()
{
  clear_matrix(ZX_MATRIX_SIZE);
  matrix[ZX_K_RESET] = 1;
  transmit_keyboard_matrix();
  delay(100);
  clear_matrix(ZX_MATRIX_SIZE);
  matrix[ZX_K_RESET] = 0;
  transmit_keyboard_matrix();
}

void do_magic()
{
  clear_matrix(ZX_MATRIX_SIZE);
  matrix[ZX_K_MAGICK] = 1;
  transmit_keyboard_matrix();
  delay(100);
  clear_matrix(ZX_MATRIX_SIZE);
  matrix[ZX_K_MAGICK] = 0;
  transmit_keyboard_matrix();
}

void clear_matrix(int clear_size)
{
    // all keys up
  for (int i=0; i<clear_size; i++) {
      matrix[i] = false;
  }
}

bool eeprom_restore_value(int addr, bool default_value)
{
  byte val;  
  val = EEPROM.read(addr);
  if ((val == EEPROM_VALUE_TRUE) || (val == EEPROM_VALUE_FALSE)) {
    return (val == EEPROM_VALUE_TRUE) ? true : false;
  } else {
    EEPROM.update(addr, (default_value ? EEPROM_VALUE_TRUE : EEPROM_VALUE_FALSE));
    return default_value;
  }
}

void eeprom_store_value(int addr, bool value)
{
  byte val = (value ? EEPROM_VALUE_TRUE : EEPROM_VALUE_FALSE);
  EEPROM.update(addr, val);
}

void eeprom_restore_values()
{
  is_turbo = eeprom_restore_value(EEPROM_TURBO_ADDRESS, is_turbo);
  profi_mode = eeprom_restore_value(EEPROM_MODE_ADDRESS, profi_mode);
  is_sw1 = eeprom_restore_value(EEPROM_SW1_ADDRESS, is_sw1);
  is_sw2 = eeprom_restore_value(EEPROM_SW2_ADDRESS, is_sw2);
  // apply restored values
  matrix[ZX_K_TURBO] = is_turbo;
  matrix[ZX_K_SW1] = is_sw1;
  matrix[ZX_K_SW2] = is_sw2;
}

void eeprom_store_values()
{
  eeprom_store_value(EEPROM_TURBO_ADDRESS, is_turbo);
  eeprom_store_value(EEPROM_MODE_ADDRESS, profi_mode);
  eeprom_store_value(EEPROM_SW1_ADDRESS, is_sw1);
  eeprom_store_value(EEPROM_SW2_ADDRESS, is_sw2);  
}

void checkSerialInput()
{
  readLine();
   if (!buffering) {
     processInput();
     index = 0;
     buf[index] = '\0';
     buffering = true;
   }
}

void readLine() {
   if (Serial.available())  {
     while (Serial.available()) {
         char c = Serial.read();
         if (c == '\n' || c == '\r' || index >= buf_len) {
           buffering = false;
         } else {
           buffering = true;
           buf[index] = c;
           index++;
           buf[index] = '\0';
         }
     }
   }
 }

 void processInput() {
     String content = String(buf);

    if (content.compareTo("HELP") == 0) {
      Serial.println(F("HELP:"));
      Serial.println(F("GET - will print a current date/time"));
      Serial.println(F("SET YYYY MM DD HH II SS W - will set RTC to the given arguments"));
      Serial.println();
      return;
    }

    if (content.compareTo("GET") == 0) {
      Serial.println(F("GET:"));
      Serial.println(F("Current time is:"));
      printTime();
      Serial.println();
      return;
    }

    if (content.indexOf("SET") == 0) {
      if (content.length() == 25) {

        String s_year = content.substring(4, 8);
        String s_month = content.substring(9, 11);
        String s_day = content.substring(12, 14);
        String s_hour = content.substring(15, 17);
        String s_min = content.substring(18, 20);
        String s_sec = content.substring(21, 23);
        String s_week = content.substring(24,25);

        rtc_year = stringToInt(s_year);
        rtc_month = stringToByte(s_month);
        rtc_day = stringToByte(s_day);
        rtc_hours = stringToByte(s_hour);
        rtc_minutes = stringToByte(s_min);
        rtc_seconds = stringToByte(s_sec);
        rtc_week = stringToByte(s_week);
        rtc_save();

        printTime();        
        Serial.println(F("Set time OK"));
        Serial.println();
      } else {
        Serial.println(F("Invalid format given. Please use the command to set date time: SET YYYY MM DD HH II SS W"));
        Serial.println();
      }
    }
 }

void printTime() {
  Serial.print(rtc_year);
  Serial.print(F("-"));
  Serial.print(rtc_month);
  Serial.print(F("-"));
  Serial.print(rtc_day);
  Serial.print(F(" "));
  Serial.print(rtc_hours);
  Serial.print(F(":"));
  Serial.print(rtc_minutes);
  Serial.print(F(":"));
  Serial.print(rtc_seconds);
  Serial.print(F(" ("));
  Serial.print(rtc_week);
  Serial.print(F(")"));
  Serial.println();
}

int stringToInt(String s) {
     char this_char[s.length() + 1];
     s.toCharArray(this_char, sizeof(this_char));
     int result = atoi(this_char);     
     return result;
}

uint8_t stringToByte(String s) {
     char this_char[s.length() + 1];
     s.toCharArray(this_char, sizeof(this_char));
     int result = atoi(this_char);
     return lowByte(result);
}

// initial setup
void setup()
{
  Serial.begin(115200);
  Serial.flush();
  rtc.begin();
  SPI.begin();

  pinMode(PIN_SS, OUTPUT);
  digitalWrite(PIN_SS, HIGH);

  pinMode(PIN_LED1, OUTPUT);
  digitalWrite(PIN_LED1, HIGH);

  pinMode(PIN_LED2, OUTPUT);
  digitalWrite(PIN_LED2, HIGH);

  pinMode(PIN_BTN1, INPUT_PULLUP);
  pinMode(PIN_BTN2, INPUT_PULLUP);

  // ps/2

  pinMode(PIN_KBD_CLK, INPUT_PULLUP);
  pinMode(PIN_KBD_DAT, INPUT_PULLUP);

  pinMode(PIN_MOUSE_CLK, INPUT_PULLUP);
  pinMode(PIN_MOUSE_DAT, INPUT_PULLUP);

  // joy
  pinMode(PIN_JOY_UP, INPUT_PULLUP);
  pinMode(PIN_JOY_DOWN, INPUT_PULLUP);
  pinMode(PIN_JOY_LEFT, INPUT_PULLUP);
  pinMode(PIN_JOY_RIGHT, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE1, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE2, INPUT_PULLUP);
  
  // clear full matrix
  clear_matrix(ZX_MATRIX_FULL_SIZE);

  // restore saved modes from EEPROM
  eeprom_restore_values();

Serial.println(F("ZX Keyboard / mouse / rtc controller v1.0"));

#if DEBUG_MODE
  Serial.println(F("Reset on boot..."));
#endif

  do_reset();

#if DEBUG_MODE
  Serial.println(F("done"));
  Serial.println(F("Keyboard init..."));
#endif

  kbd.begin(PIN_KBD_DAT, PIN_KBD_CLK);

#if DEBUG_MODE
  Serial.println(F("done"));
  Serial.println(F("Mouse init..."));
#endif

  init_mouse();

#if DEBUG_MODE
  Serial.println(F("done"));
  Serial.println(F("RTC init..."));
#endif

  rtc_year = rtc.getYear();
  rtc_month = rtc.getMonth();
  rtc_day = rtc.getDay();
  rtc_week = rtc.getWeek();

  rtc_hours = rtc.getHours();
  rtc_minutes = rtc.getMinutes();
  rtc_seconds = rtc.getSeconds();

  rtc_send_time();

#if DEBUG_MODE
  Serial.println(F("done"));
#endif

  if (!rtc_init_done) {
#if DEBUG_MODE
  Serial.println(F("RTC send all registers on boot"));
#endif
     rtc_send_all();
#if DEBUG_MODE
  Serial.println(F("done"));
#endif     
  }

  Serial.println(F("Builtin commands: HELP, SET, GET"));

  digitalWrite(PIN_LED1, LOW);
  
}


// main loop
void loop()
{
  unsigned long n = millis();
  
  if (kbd.available()) {
    int c = kbd.read();
    blink_state = true;
    tl = n;
    if (!led1_overwrite) {
      digitalWrite(PIN_LED1, HIGH);
    }
#if DEBUG_MODE    
    Serial.print(F("Scancode: "));
    Serial.println(c, HEX);
#endif
    fill_kbd_matrix(c);
  }

  // transmit kbd always
  transmit_keyboard_matrix();

  // react on hardware buttons every 200ms
//  if (n - tb >= 200) {
//    if (analogRead(PIN_BTN1) < 100) {
//      digitalWrite(PIN_LED2, LOW);
//      do_reset();
//      digitalWrite(PIN_LED2, HIGH);
//    }
//  
//    if (analogRead(PIN_BTN2) < 100) {
//      digitalWrite(PIN_LED1, LOW);
//      do_magic();
//      digitalWrite(PIN_LED1, HIGH);
//    }
//    tb = n;
//  }

  // read joystick
  joy[ZX_JOY_UP] = digitalRead(PIN_JOY_UP) == LOW;
  joy[ZX_JOY_DOWN] = digitalRead(PIN_JOY_DOWN) == LOW;
  joy[ZX_JOY_LEFT] = digitalRead(PIN_JOY_LEFT) == LOW;
  joy[ZX_JOY_RIGHT] = digitalRead(PIN_JOY_RIGHT) == LOW;
  joy[ZX_JOY_FIRE] = digitalRead(PIN_JOY_FIRE1) == LOW;
  joy[ZX_JOY_FIRE2] = digitalRead(PIN_JOY_FIRE2) == LOW;

  if (joy[0] || joy[1] || joy[2] || joy[3] || joy[4] || joy[5]) {
    if (!led1_overwrite) {
      digitalWrite(PIN_LED1, HIGH);
    }
    blink_state = true;
    tl = n;
  }

  // transmit joy matrix
  transmit_joy_data();

  if (n - tl >= 200) {
    if (!led1_overwrite) {
      digitalWrite(PIN_LED1, LOW);
    }
    blink_state = false;
  }

  // read time from rtc
  if (n - tr >= 1000) {

    rtc_year = rtc.getYear();
    rtc_month = rtc.getMonth();
    rtc_day = rtc.getDay();
    rtc_week = rtc.getWeek();

    rtc_hours = rtc.getHours();
    rtc_minutes = rtc.getMinutes();
    rtc_seconds = rtc.getSeconds();

#if DEBUG_MODE
    Serial.print(F("RTC: "));
    Serial.print(rtc_hours);
    Serial.print(F(":"));
    Serial.print(rtc_minutes);
    Serial.print(F(":"));
    Serial.print(rtc_seconds);
    Serial.println();
#endif

    rtc_send_time();

    tr = n;
  }

  // try to re-init mouse every 1s if not present, up to N tries
  if (mouse_tries > 0 && !mouse_present && n - tm > 1000) {
    mouse_tries--;
    init_mouse();
    tm = n;
  }

  // polling for mouse data every 100ms
  if (mouse_present && n - t > 100) {

    MouseData m = mouse.readData();

    mouse_new_packet = !mouse_new_packet;
    mouse_x = m.position.x;
    mouse_y = m.position.y;
    mouse_z = m.wheel;

    bool btn1 = bitRead(m.status, 0);
    bool btn2 = bitRead(m.status, 1);
    bool btn3 = bitRead(m.status, 2);    
    bitWrite(mouse_z, 4, btn1);
    bitWrite(mouse_z, 5, btn2);
    bitWrite(mouse_z, 6, btn3);
    bitWrite(mouse_z, 7, mouse_new_packet);

    // transmit mouse only if present, every 100ms
    transmit_mouse_data();

    t = n;

#if DEBUG_MODE
    if (mouse_x != 0 && mouse_y != 0) {
      Serial.print(F("Mouse: "));
      Serial.print(m.status, BIN);
      Serial.print(F("\tx="));
      Serial.print(m.position.x);
      Serial.print(F("\ty="));
      Serial.print(m.position.y);
      Serial.print(F("\tw="));
      Serial.print(m.wheel);
      Serial.println();
    }
#endif

  }

  checkSerialInput();

  // control led1
  if (led1_overwrite) {
    if (led1_state == 1) {
      digitalWrite(PIN_LED1, HIGH);
    }
    if (n - tl1 >= 100) {
      tl1 = n;
      if (led1_state == false) {
        digitalWrite(PIN_LED1, LOW);
      }
    }
  }

  // control led2
  if (led2_overwrite) {
    if (led2_state == 1) {
      digitalWrite(PIN_LED2, HIGH);
    }
    if (n - tl2 >= 100) {
      tl2 = n;
      if (led2_state == false) {
        digitalWrite(PIN_LED2, LOW);
      }
    }
  }
  
}
