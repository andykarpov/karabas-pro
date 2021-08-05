/**
                                                                                                                
#       #######                                                 #                                               
#                                                               #                                               
#                                                               #                                               
############### ############### ############### ############### ############### ############### ############### 
#             #               # #                             # #             #               # #               
#             # ############### #               ############### #             # ############### ############### 
#             # #             # #               #             # #             # #             #               # 
#             # ############### #               ############### ############### ############### ############### 
                                                                                                                
        ####### ####### ####### #######                         ############### ############### ############### 
                                                                #             # #               #             # 
                                                                ############### #               #             # 
                                                                #               #               #             # 
https://github.com/andykarpov/karabas-pro                       #               #               ############### 

AVR firmware for Karabas-Pro

@author Andy Karpov <andy.karpov@gmail.com>
Ukraine, 2021
*/

#include "Arduino.h"
#include "PS2KeyAdvanced.h"
#include "PS2Mouse.h"
#include "SegaController.h"
#include "matrix.h"
#include <EEPROM.h>
#include "SBWire.h"
#include "RTC.h"
#include "OSD.h"
#include <SPI.h>
#include "config.h"
#include "utils.h"

PS2KeyAdvanced kbd;
PS2Mouse mice;
SegaController sega;
static DS1307 rtc;
OSD osd;

bool matrix[ZX_MATRIX_FULL_SIZE]; // matrix of pressed keys + mouse reports to be transmitted on CPLD side by simple serial protocol
bool joy[8]; // joystic states
bool last_joy[8];
word sega_joy_state;
bool profi_mode = true; // false = zx spectrum mode (switched by PrtSrc button in run-time)
bool is_turbo = false; // turbo toggle (switched by ScrollLock button)
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
bool osd_overlay = false; // osd overlay enable
bool prev_osd_overlay = true; // prev state of osd overlay
bool init_done = false; // init done
uint8_t cfg = 0; // cfg byte from fpga side

bool is_wait = false; // wait mode
bool mouse_present = false; // mouse present flag (detected by signal change on CLKM pin)
bool blink_state = false;
bool flags_changed = false; // changed flags is_turbo / profi_mode

bool led1_state = false;
bool led2_state = false;
bool led1_overwrite = false;
bool led2_overwrite = false;

bool ms_btn1 = false;
bool ms_btn2 = false;
bool ms_btn3 = false;

unsigned long t = 0;  // current time
unsigned long tl1, tl2 = 0; // led1/2 time
unsigned long tm = 0; // mouse poll time
unsigned long tl = 0; // blink poll time
unsigned long tr = 0; // rtc poll time
unsigned long te = 0; // eeprom store time
unsigned long tb, tb1, tb2 = 0; // hw buttons poll time
unsigned long ts = 0; // mouse swap time
unsigned long tosd = 0; // osd last press toggle time
unsigned long tk = 0; // last keypress

int mouse_tries; // number of triers to init mouse

uint8_t mouse_x = 0; // current mouse X
uint8_t mouse_y = 0; // current mouse Y
uint8_t mouse_z = 0; // current mousr Z
uint8_t mouse_btns = 0; // mouse buttons state
bool mouse_new_packet = false; // new packet to send (toggle flag)

int rtc_year = 0;
uint8_t rtc_month = 0;
uint8_t rtc_day = 1;
uint8_t rtc_hours = 0;
uint8_t rtc_minutes = 0;
uint8_t rtc_seconds = 0;

uint8_t rtc_seconds_alarm = 0;
uint8_t rtc_minutes_alarm = 0;
uint8_t rtc_hours_alarm = 0;
uint8_t rtc_week = 1;

uint8_t rtc_last_write_reg = 0;
uint8_t rtc_last_write_data = 0;

bool rtc_init_done = false;
bool rtc_is_bcd = false;
bool rtc_is_24h = true;

int capsed_keys[20] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
int capsed_keys_size = 0;

uint8_t build_num[8] = {0,0,0,0,0,0,0,0};

// osd global states
enum osd_state_e {
  state_main = 0,
  state_rtc,
  state_test
};

// osd main states
enum osd_main_state_e {
  state_main_rom_bank = 0,
  state_main_turbofdc,
  state_main_covox,
  state_main_stereo,
  state_main_ssg,
  state_main_video,
  state_main_sync,
  state_main_turbo,
  state_main_swap_ab,
  state_main_joy_type,
  state_main_keyboard_type,
  state_main_pause
};

// osd rtc states
enum osd_rtc_state_e {
  state_rtc_hour = 0,
  state_rtc_minute,
  state_rtc_second,
  state_rtc_day,
  state_rtc_month,
  state_rtc_year,
  state_rtc_dow
};

uint8_t osd_state = state_main;
uint8_t osd_prev_state = state_main;
uint8_t osd_main_state = state_main_rom_bank;
uint8_t osd_prev_main_state = state_main_rom_bank;
uint8_t osd_rtc_state = state_rtc_dow;
uint8_t osd_prev_rtc_state = state_rtc_dow;

bool cursor_up = false;
bool cursor_down = false;
bool cursor_left = false;
bool cursor_right = false;
bool is_enter = false;
bool is_esc = false;

typedef struct {
  uint8_t key;
  uint8_t zxkey;
  unsigned long timestamp;
  bool up;
} delayed_matrix_type;

delayed_matrix_type delayed_matrix[8];
uint8_t delayed_matrix_size = 0;

SPISettings settingsA(1000000, MSBFIRST, SPI_MODE0); // SPI transmission settings

void push_capsed_key(int key);
void pop_capsed_key(int key);
void process_capsed_key(int key, bool up);
void set_rombank(uint8_t bank);
void set_turbofdc();
void set_covox();
void set_stereo(uint8_t stereo);
void set_ssg();
void set_video();
void set_vsync();
void set_turbo();
void set_swap_ab();
void set_keyboard_type();
void fill_kbd_matrix(uint16_t sc, unsigned long n);
void delayed_keypress(uint8_t key, uint8_t zxkey1, uint8_t zxkey2, bool up);
void process_delayed_keypress();
void send_macros(uint8_t pos);
uint8_t get_matrix_byte(uint8_t pos);
uint8_t get_joy_byte();
void spi_send(uint8_t addr, uint8_t data);
void transmit_keyboard_matrix();
void transmit_joy_data();
void transmit_mouse_data();
void rtc_save();
void rtc_fix_invalid_time();
void rtc_send(uint8_t reg, uint8_t data);
void rtc_send_time();
void rtc_send_all();
void process_in_cmd(uint8_t cmd, uint8_t data);
void init_mouse();
void do_reset();
void do_full_reset();
void do_magic();
void do_caps();
void do_pause();
void clear_matrix(int clear_size);
bool eeprom_restore_value(int addr, bool default_value);
void eeprom_store_value(int addr, bool value);
void eeprom_restore_values();
void eeprom_store_values();
void update_led(uint8_t led, bool state);
void osd_print_header();
void osd_init_overlay();
void osd_init_rtc_overlay();
void osd_init_test_overlay();
void osd_popup_footer();
void osd_handle_rombank();
void osd_handle_turbofdc();
void osd_handle_covox();
void osd_handle_stereo();
void osd_handle_ssg();
void osd_handle_video();
void osd_handle_vsync();
void osd_handle_turbo();
void osd_handle_swap_ab();
void osd_handle_joy_type();
void osd_handle_keyboard_type();
void osd_handle_pause();
void osd_handle_rtc_hour();
void osd_handle_rtc_minute();
void osd_handle_rtc_second();
void osd_handle_rtc_day();
void osd_handle_rtc_month();
void osd_handle_rtc_year();
void osd_handle_rtc_dow();
void osd_update_rombank();
void osd_update_turbofdc();
void osd_update_covox();
void osd_update_stereo();
void osd_update_ssg();
void osd_update_video();
void osd_update_vsync();
void osd_update_turbo();
void osd_update_swap_ab();
void osd_update_joystick();
void osd_update_keyboard_type();
void osd_update_pause();
void osd_update_rtc_hour();
void osd_update_rtc_minute();
void osd_update_rtc_second();
void osd_update_rtc_day();
void osd_update_rtc_month();
void osd_update_rtc_year();
void osd_update_rtc_dow();
void osd_update_time();
void osd_update_scancode(uint16_t c);
void osd_update_mouse();
void osd_update_joy_state();
void setup();
void loop();

/* ------------------------------------------------------------ */

void push_capsed_key(int key)
{
  int i = 0;
  bool found = false;
  if (capsed_keys_size > 0) {
    for (i=0; i<capsed_keys_size; i++) {
      if (capsed_keys[i] == key) {
        found = true;
      }
    }
  }
  if (!found && capsed_keys_size < 20) {
    capsed_keys[capsed_keys_size] = key;
    capsed_keys_size++;
  }
}

void pop_capsed_key(int key)
{
  int i = 0;
  int j = 0;
  int tmp_array[20] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
  if (capsed_keys_size > 0) {
    for (i=0; i<capsed_keys_size; i++) {
      if (capsed_keys[i] != key) {
        tmp_array[j] = capsed_keys[i];
        j++;
      }
    }
  }
  if (j > 0) {
    for (i=0; i<j; i++) {
      capsed_keys[i] = tmp_array[i];
    }
  }
  capsed_keys_size = j;
}

void process_capsed_key(int key, bool up)
{
  if (!up) {
    push_capsed_key(key);
  } else {
    pop_capsed_key(key);
  }
}

void set_rombank(uint8_t bank) {
  switch (bank) {
    case 0: is_sw3 = false; is_sw4 = false; break;
    case 1: is_sw3 = true; is_sw4 = false; break;
    case 2: is_sw3 = false; is_sw4 = true; break;
    case 3: is_sw3 = true; is_sw4 = true; break;
  }
  eeprom_store_value(EEPROM_SW3_ADDRESS, is_sw3);
  eeprom_store_value(EEPROM_SW4_ADDRESS, is_sw4);
  matrix[ZX_K_SW3] = is_sw3;
  matrix[ZX_K_SW4] = is_sw4;
}

void set_turbofdc() {
  // menu + F5 = SW5
  is_sw5 = !is_sw5;
  eeprom_store_value(EEPROM_SW5_ADDRESS, is_sw5);
  matrix[ZX_K_SW5] = is_sw5;
}

void set_covox() {
  // menu + F6 = SW6
  is_sw6 = !is_sw6;
  eeprom_store_value(EEPROM_SW6_ADDRESS, is_sw6);
  matrix[ZX_K_SW6] = is_sw6;
}

void set_stereo(uint8_t stereo) {

  is_sw7 = bitRead(stereo, 0);
  is_sw9 = bitRead(stereo, 1);

  eeprom_store_value(EEPROM_SW7_ADDRESS, is_sw7);
  eeprom_store_value(EEPROM_SW9_ADDRESS, is_sw9);
  matrix[ZX_K_SW7] = is_sw7;
  matrix[ZX_K_SW9] = is_sw9;
}

void set_ssg() {
  // menu + F8 = SW8
  is_sw8 = !is_sw8;
  eeprom_store_value(EEPROM_SW8_ADDRESS, is_sw8);
  matrix[ZX_K_SW8] = is_sw8;
}

void set_video() {
    // menu + F9 = SW1
  is_sw1 = !is_sw1;
  eeprom_store_value(EEPROM_SW1_ADDRESS, is_sw1);
  matrix[ZX_K_SW1] = is_sw1;
}

void set_vsync() {
  // menu + F10 = SW2
  is_sw2 = !is_sw2;
  eeprom_store_value(EEPROM_SW2_ADDRESS, is_sw2);
  matrix[ZX_K_SW2] = is_sw2;
}

void set_turbo() {
  // menu + F11 = turbo
  is_turbo = !is_turbo;
  eeprom_store_value(EEPROM_TURBO_ADDRESS, is_turbo);
  matrix[ZX_K_TURBO] = is_turbo;
}

void set_swap_ab() {
    // menu + TAB = SW10
  is_sw10 = !is_sw10;
  eeprom_store_value(EEPROM_SW10_ADDRESS, is_sw10);
  matrix[ZX_K_SW10] = is_sw10;
}

void set_joy_type() {
  // menu + J = JOY_TYPE
  joy_type = !joy_type;
  eeprom_store_value(EEPROM_JOY_TYPE_ADDRESS, joy_type);
  matrix[ZX_K_JOY_TYPE] = joy_type;
}

void set_keyboard_type() {
  profi_mode = !profi_mode;
  eeprom_store_value(EEPROM_MODE_ADDRESS, profi_mode);
  matrix[ZX_K_KBD_MODE] = profi_mode;
}

// transform PS/2 scancodes into internal matrix of pressed keys
void fill_kbd_matrix(uint16_t sc, unsigned long n)
{

  static bool is_up = false;
  static bool is_del = false, is_bksp = false, is_shift = false, is_ss_used = false;

  uint8_t code = sc & 0xFF;
  uint8_t status = sc >> 8;
  is_up = sc & PS2_BREAK;

  is_ss_used = false;

  matrix[ZX_K_IS_UP] = is_up;
  matrix[ZX_K_SCANCODE7] = bitRead(code, 7);
  matrix[ZX_K_SCANCODE6] = bitRead(code, 6);
  matrix[ZX_K_SCANCODE5] = bitRead(code, 5);
  matrix[ZX_K_SCANCODE4] = bitRead(code, 4);
  matrix[ZX_K_SCANCODE3] = bitRead(code, 3);
  matrix[ZX_K_SCANCODE2] = bitRead(code, 2);
  matrix[ZX_K_SCANCODE1] = bitRead(code, 1);
  matrix[ZX_K_SCANCODE0] = bitRead(code, 0); 

  // hotfix
  if ((status == 0) && (code == PS2_KEY_L_SHIFT )) {
    do_pause();
    return;
  }

  switch (code) {

    // Pause -> Wait
    case PS2_KEY_PAUSE:
      do_pause();
    break;

    // Shift -> SS for Profi, CS for ZX
    case PS2_KEY_L_SHIFT:
    case PS2_KEY_R_SHIFT:
      matrix[profi_mode ? ZX_K_SS : ZX_K_CS] = !is_up;
      is_shift = !is_up;
      break;

    // Ctrl -> CS for Profi, SS for ZX
    case PS2_KEY_L_CTRL:
    case PS2_KEY_R_CTRL:
      matrix[profi_mode ? ZX_K_CS : ZX_K_SS] = !is_up;
      is_ctrl = !is_up;
      break;

    // Alt (L) -> SS+Enter for Profi, SS+CS for ZX
    case PS2_KEY_L_ALT:
      matrix[ZX_K_SS] = !is_up;
      matrix[profi_mode ? ZX_K_ENT : ZX_K_CS] = !is_up;
      if (!profi_mode) {
        process_capsed_key(code, is_up);
      }
      is_alt = !is_up;
      break;

    // Alt (R) -> SS + Space for Profi, SS+CS for ZX
    case PS2_KEY_R_ALT:
      matrix[ZX_K_SS] = !is_up;
      matrix[profi_mode ? ZX_K_SP : ZX_K_CS] = !is_up;
      if (!profi_mode) {
        process_capsed_key(code, is_up);
      }
      is_alt = !is_up;
      break;

    // Del -> P+b6 for Profi, SS+C for ZX
    case PS2_KEY_DELETE:
      if (!is_shift) {
        if (profi_mode) {
          matrix[ZX_K_P] = !is_up;
          matrix[ZX_K_BIT6] = !is_up;
        } else {
          matrix[ZX_K_SS] = !is_up;
          matrix[ZX_K_C] =  !is_up;
        }
        is_del = !is_up;
      }
      break;

    // Win
    case PS2_KEY_L_GUI:
    case PS2_KEY_R_GUI:
      is_win = !is_up;
    break;

    // Menu
    case PS2_KEY_MENU:
      is_menu = !is_up;
      break;

    // Ins -> O+b6 for Profi, SS+A for ZX
    case PS2_KEY_INSERT:
      if (!is_shift) {
        if (profi_mode) {
          matrix[ZX_K_O] = !is_up;
          matrix[ZX_K_BIT6] = !is_up;
        } else {
          matrix[ZX_K_SS] = !is_up;
          matrix[ZX_K_A] =  !is_up;
        }
      }
      break;

    // Cursor -> CS + 5,6,7,8
    case PS2_KEY_UP_ARROW:
      if (!is_shift) {
        cursor_up = !is_up;
        delayed_keypress(code, ZX_K_CS, ZX_K_7, is_up);
      }
      break;
    case PS2_KEY_DN_ARROW:
      if (!is_shift) {
        cursor_down = !is_up;
        delayed_keypress(code, ZX_K_CS, ZX_K_6, is_up);
      }
      break;
    case PS2_KEY_L_ARROW:
      if (!is_shift) {
        cursor_left = !is_up;
        delayed_keypress(code, ZX_K_CS, ZX_K_5, is_up);
      }
      break;
    case PS2_KEY_R_ARROW:
      if (!is_shift) {
        cursor_right = !is_up;
        delayed_keypress(code, ZX_K_CS, ZX_K_8, is_up);
      }
      break;

    // ESC -> CS+1 for Profi, CS+SPACE for ZX
    case PS2_KEY_ESC:

      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          // menu + ESC = OSD_OVERLAY
          if (n - tosd > 200) {
            osd_overlay = !osd_overlay;
            matrix[ZX_K_OSD_OVERLAY] = osd_overlay;
            tosd = n;
            // re-init osd
            if (osd_overlay) {
              osd_state = state_main;
              osd_init_overlay();
            }
          }
        }
      } else {
        is_esc = !is_up;
        matrix[ZX_K_CS] = !is_up;
        matrix[profi_mode ? ZX_K_1 : ZX_K_SP] = !is_up;
        process_capsed_key(code, is_up);
      }
      break;

    // Backspace -> CS+0
    case PS2_KEY_BS:
      matrix[ZX_K_CS] = !is_up;
      matrix[ZX_K_0] = !is_up;
      process_capsed_key(code, is_up);
      is_bksp = !is_up;
      break;

    // Enter
    case PS2_KEY_ENTER:
    case PS2_KEY_KP_ENTER:
      matrix[ZX_K_ENT] = !is_up;
      is_enter = !is_up;
      break;

    // Space
    case PS2_KEY_SPACE:
      matrix[ZX_K_SP] = !is_up;
      break;

    // Letters & numbers
    case PS2_KEY_A: matrix[ZX_K_A] = !is_up; break;
    case PS2_KEY_B: matrix[ZX_K_B] = !is_up; break;
    case PS2_KEY_C: matrix[ZX_K_C] = !is_up; break;
    case PS2_KEY_D: matrix[ZX_K_D] = !is_up; break;
    case PS2_KEY_E: matrix[ZX_K_E] = !is_up; break;
    case PS2_KEY_F: matrix[ZX_K_F] = !is_up; break;
    case PS2_KEY_G: matrix[ZX_K_G] = !is_up; break;
    case PS2_KEY_H: matrix[ZX_K_H] = !is_up; break;
    case PS2_KEY_I: matrix[ZX_K_I] = !is_up; break;
    case PS2_KEY_J: 
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          set_joy_type();
          osd_update_joystick();
        }
      } else {
        matrix[ZX_K_J] = !is_up; 
      }
    break;
    case PS2_KEY_K: matrix[ZX_K_K] = !is_up; break;
    case PS2_KEY_L: matrix[ZX_K_L] = !is_up; break;
    case PS2_KEY_M: matrix[ZX_K_M] = !is_up; break;
    case PS2_KEY_N: matrix[ZX_K_N] = !is_up; break;
    case PS2_KEY_O: matrix[ZX_K_O] = !is_up; break;
    case PS2_KEY_P: matrix[ZX_K_P] = !is_up; break;
    case PS2_KEY_Q: matrix[ZX_K_Q] = !is_up; break;
    case PS2_KEY_R: matrix[ZX_K_R] = !is_up; break;
    case PS2_KEY_S: matrix[ZX_K_S] = !is_up; break;
    case PS2_KEY_T: matrix[ZX_K_T] = !is_up; break;
    case PS2_KEY_U: matrix[ZX_K_U] = !is_up; break;
    case PS2_KEY_V: matrix[ZX_K_V] = !is_up; break;
    case PS2_KEY_W: matrix[ZX_K_W] = !is_up; break;
    case PS2_KEY_X: matrix[ZX_K_X] = !is_up; break;
    case PS2_KEY_Y: matrix[ZX_K_Y] = !is_up; break;
    case PS2_KEY_Z: matrix[ZX_K_Z] = !is_up; break;

    // digits
    case PS2_KEY_0: matrix[ZX_K_0] = !is_up; break;
    case PS2_KEY_1: matrix[ZX_K_1] = !is_up; break;
    case PS2_KEY_2: matrix[ZX_K_2] = !is_up; break;
    case PS2_KEY_3: matrix[ZX_K_3] = !is_up; break;
    case PS2_KEY_4: matrix[ZX_K_4] = !is_up; break;
    case PS2_KEY_5: matrix[ZX_K_5] = !is_up; break;
    case PS2_KEY_6: matrix[ZX_K_6] = !is_up; break;
    case PS2_KEY_7: matrix[ZX_K_7] = !is_up; break;
    case PS2_KEY_8: matrix[ZX_K_8] = !is_up; break;
    case PS2_KEY_9: matrix[ZX_K_9] = !is_up; break;

    // Keypad digits
    case PS2_KEY_KP0: matrix[ZX_K_0] = !is_up; break;
    case PS2_KEY_KP1: matrix[ZX_K_1] = !is_up; break;
    case PS2_KEY_KP2: matrix[ZX_K_2] = !is_up; break;
    case PS2_KEY_KP3: matrix[ZX_K_3] = !is_up; break;
    case PS2_KEY_KP4: matrix[ZX_K_4] = !is_up; break;
    case PS2_KEY_KP5: matrix[ZX_K_5] = !is_up; break;
    case PS2_KEY_KP6: matrix[ZX_K_6] = !is_up; break;
    case PS2_KEY_KP7: matrix[ZX_K_7] = !is_up; break;
    case PS2_KEY_KP8: matrix[ZX_K_8] = !is_up; break;
    case PS2_KEY_KP9: matrix[ZX_K_9] = !is_up; break;

    // '/" -> SS+P / SS+7
    case PS2_KEY_APOS:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_P : ZX_K_7] = !is_up;
      if (is_up) {
        matrix[ZX_K_P] = false;
        matrix[ZX_K_7] = false;
      }
      is_ss_used = is_shift;
      break;

    // ,/< -> SS+N / SS+R
    case PS2_KEY_COMMA:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_R : ZX_K_N] = !is_up;
      if (is_up) {
        matrix[ZX_K_R] = false;
        matrix[ZX_K_N] = false;
      }
      is_ss_used = is_shift;
      break;

    // ./> -> SS+M / SS+T
    case PS2_KEY_DOT:
    case PS2_KEY_KP_DOT:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_T : ZX_K_M] = !is_up;
      if (is_up) {
        matrix[ZX_K_T] = false;
        matrix[ZX_K_M] = false;
      }
      is_ss_used = is_shift;
      break;

    // ;/: -> SS+O / SS+Z
    case PS2_KEY_SEMI:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_Z : ZX_K_O] = !is_up;
      if (is_up) {
        matrix[ZX_K_Z] = false;
        matrix[ZX_K_O] = false;
      }
      is_ss_used = is_shift;
      break;

    // [,{ -> SS+Y / SS+F
    case PS2_KEY_OPEN_SQ:
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
    case PS2_KEY_CLOSE_SQ:
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
    case PS2_KEY_DIV:
    case PS2_KEY_KP_DIV:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_C : ZX_K_V] = !is_up;
      if (is_up) {
        matrix[ZX_K_C] = false;
        matrix[ZX_K_V] = false;
      }
      is_ss_used = is_shift;
      break;

    // \,| -> SS+D / SS+S
    case PS2_KEY_BACK:
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
    case PS2_KEY_EQUAL:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_K : ZX_K_L] = !is_up;
      if (is_up) {
        matrix[ZX_K_K] = false;
        matrix[ZX_K_L] = false;
      }
      is_ss_used = is_shift;
      break;

    // -,_ -> SS+J / SS+0
    case PS2_KEY_MINUS:
      matrix[ZX_K_SS] = !is_up;
      matrix[is_shift ? ZX_K_0 : ZX_K_J] = !is_up;
      if (is_up) {
        matrix[ZX_K_0] = false;
        matrix[ZX_K_J] = false;
      }
      is_ss_used = is_shift;
      break;

    // `,~ -> SS+X / SS+A
    case PS2_KEY_SINGLE:
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
    case PS2_KEY_KP_TIMES:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_B] = !is_up;
      break;

    // Keypad - -> SS+J
    case PS2_KEY_KP_MINUS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_J] = !is_up;
      break;

    // Keypad + -> SS+K
    case PS2_KEY_KP_PLUS:
      matrix[ZX_K_SS] = !is_up;
      matrix[ZX_K_K] = !is_up;
      break;

    // Tab
    case PS2_KEY_TAB:
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          set_swap_ab();
          osd_update_swap_ab();
        }
      } else {
        matrix[ZX_K_CS] = !is_up;
        matrix[ZX_K_I] = !is_up;
        process_capsed_key(code, is_up);
      }
      break;

    // CapsLock
    case PS2_KEY_CAPS:
      do_caps();
      break;

    // PgUp -> M+BIT6 for Profi, CS+3 for ZX
    case PS2_KEY_PGUP:
      if (!is_shift) {
        if (profi_mode) {
          matrix[ZX_K_M] = !is_up;
          matrix[ZX_K_BIT6] = !is_up;
        } else {
          matrix[ZX_K_CS] = !is_up;
          matrix[ZX_K_3] = !is_up;
          process_capsed_key(code, is_up);
        }
      }
      break;

    // PgDn -> N+BIT6 for Profi, CS+4 for ZX
    case PS2_KEY_PGDN:
      if (!is_shift) {
        if (profi_mode) {
          matrix[ZX_K_N] = !is_up;
          matrix[ZX_K_BIT6] = !is_up;
        } else {
          matrix[ZX_K_CS] = !is_up;
          matrix[ZX_K_4] = !is_up;
          process_capsed_key(code, is_up);
        }
      }
      break;

    // Home -> K+BIT6 for Profi
    case PS2_KEY_HOME:
      if (!is_shift) {
        matrix[ZX_K_K] = !is_up;
        matrix[ZX_K_BIT6] = !is_up;
      }
      break;

    // End -> L+BIT6 for Profi
    case PS2_KEY_END:
      if (!is_shift) {
        matrix[ZX_K_L] = !is_up;
        matrix[ZX_K_BIT6] = !is_up;
      }
      break;

    // Fn keys
    case PS2_KEY_F1:
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          // menu + F1, ctrl+alt = ROMSET 00
          set_rombank(0);
          osd_update_rombank();
        }
      } else {
        matrix[ZX_K_A] = !is_up; matrix[ZX_K_BIT6] = !is_up;
      }
      break;
    case PS2_KEY_F2:
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          // menu + F2 = ROMSET 01
          set_rombank(1);
          osd_update_rombank();
        }
      } else {
        matrix[ZX_K_B] = !is_up; matrix[ZX_K_BIT6] = !is_up; 
      }
      break;
    case PS2_KEY_F3:
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          // menu + F3 = ROMSET 10
          set_rombank(2);
          osd_update_rombank();
        }
      } else {
        matrix[ZX_K_C] = !is_up; matrix[ZX_K_BIT6] = !is_up; 
      }
      break;
    case PS2_KEY_F4:
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          // menu + F4 = ROMSET 11
          set_rombank(3);         
          osd_update_rombank();
        }
      } else {
        matrix[ZX_K_D] = !is_up; matrix[ZX_K_BIT6] = !is_up; 
      }
      break;
    case PS2_KEY_F5:
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          set_turbofdc();
          osd_update_turbofdc();
        }
      } else {
        matrix[ZX_K_E] = !is_up; matrix[ZX_K_BIT6] = !is_up; 
      }
      break;

    case PS2_KEY_F6: 
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          set_covox();
          osd_update_covox();
        }
      } else {
        matrix[ZX_K_F] = !is_up; matrix[ZX_K_BIT6] = !is_up;
      }
      break;
    case PS2_KEY_F7: 
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          uint8_t stereo = 0;
          bitWrite(stereo, 0, is_sw7);
          bitWrite(stereo, 1, is_sw9);
          if (stereo < 2) 
            stereo++; 
          else 
            stereo = 0;
          set_stereo(stereo);
          osd_update_stereo();
        }
      } else {
        matrix[ZX_K_G] = !is_up; matrix[ZX_K_BIT6] = !is_up; 
      }
      break;
    case PS2_KEY_F8: 
      if (is_menu || (is_ctrl && is_alt)) {
        if (!is_up) {
          set_ssg();
          osd_update_ssg();
        }
      } else {
        matrix[ZX_K_H] = !is_up; matrix[ZX_K_BIT6] = !is_up;
      }
      break;
    case PS2_KEY_F9: 
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          set_video();
          osd_update_video();
        }
      } else {
          matrix[ZX_K_I] = !is_up; matrix[ZX_K_BIT6] = !is_up;
      }
      break;
    case PS2_KEY_F10: 
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          set_vsync();
          osd_update_vsync();
        }
      } else {
        matrix[ZX_K_J] = !is_up; matrix[ZX_K_BIT6] = !is_up;
      }
      break;    
    case PS2_KEY_F11:
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          set_turbo();
          osd_update_turbo();
        }
      } else {
        matrix[ZX_K_Q] = !is_up; matrix[ZX_K_SS] = !is_up;
      }
      break;
    case PS2_KEY_F12:
      if (is_menu || is_win || (is_ctrl && is_alt)) {
        if (!is_up) {
          // menu + F12 = magic
          do_magic();
        }
      } else {
        matrix[ZX_K_W] = !is_up; matrix[ZX_K_SS] = !is_up;
      }
      break;

    // Scroll Lock -> Nothing
    case PS2_KEY_SCROLL:
      // TODO
    break;

    // PrtScr -> Mode profi / zx
    case PS2_KEY_PRTSCR:
      if (!is_shift) {
        if (!is_up) {
          set_keyboard_type();
          osd_update_keyboard_type();
        }
      }
    break;

      // TODO:
      // Windows L / Home -> SS+F
      // Windiws R / End -> SS+G

  }

  if (is_ss_used && capsed_keys_size == 0) {
    matrix[ZX_K_CS] = false;
  }
  
  if (capsed_keys_size > 0) {
    matrix[ZX_K_CS] = true;
  }

  // Ctrl+Alt+Del -> RESET
  if (is_ctrl && is_alt && is_del) {
    is_ctrl = false;
    is_alt = false;
    is_del = false;
    is_shift = false;
    is_ss_used = false;
    capsed_keys_size = 0;
    do_reset();
  }
  //digitalWrite(PIN_RESET, (is_ctrl && is_alt && is_del) ? LOW : HIGH);

  // Ctrl+Alt+Bksp -> REINIT controller
  if (is_ctrl && is_alt && is_bksp) {
    is_ctrl = false;
    is_alt = false;
    is_bksp = false;
    is_shift = false;
    is_ss_used = false;
    capsed_keys_size = 0;
    do_full_reset();
  }
}

void delayed_keypress(uint8_t code, uint8_t zxkey1, uint8_t zxkey2, bool up) {
  unsigned long tnow = millis();
  if (delayed_matrix_size > 8) return;

  delayed_matrix[delayed_matrix_size].timestamp = tnow + (up ? 10 : 0);
  delayed_matrix[delayed_matrix_size].up = up;
  delayed_matrix[delayed_matrix_size].zxkey = zxkey1;
  delayed_matrix[delayed_matrix_size].key = code;
  delayed_matrix_size++;

  delayed_matrix[delayed_matrix_size].timestamp = tnow + (up ? 0 : 10); 
  delayed_matrix[delayed_matrix_size].up = up;
  delayed_matrix[delayed_matrix_size].zxkey = zxkey2;
  delayed_matrix[delayed_matrix_size].key = code;
  delayed_matrix_size++;
}

void process_delayed_keypress()
{
  if (delayed_matrix_size == 0) return;

  unsigned long tnow = millis();

  // send pressed/released keys
  for (uint8_t i=0; i<delayed_matrix_size; i++) {
    if (delayed_matrix[i].timestamp <= tnow) {
        matrix[delayed_matrix[i].zxkey] = !delayed_matrix[i].up;
        if (delayed_matrix[i].zxkey == ZX_K_CS) {
          process_capsed_key(delayed_matrix[i].key, delayed_matrix[i].up);
        }
    }
  }

  // remove processed keys
  delayed_matrix_type tmp_matrix[8];
  uint8_t tmp_size = 0;
  for (uint8_t i=0; i<delayed_matrix_size; i++) {
    if (delayed_matrix[i].timestamp > tnow) {
      tmp_matrix[tmp_size] = delayed_matrix[i];
      tmp_size++;
    }
  }

  // copy tmp matrix into delayed matrix
  for (uint8_t i=0; i<tmp_size; i++) {
    delayed_matrix[i] = tmp_matrix[i];
  }
  delayed_matrix_size = tmp_size;

  if (delayed_matrix_size > 0 || capsed_keys_size > 0) {
    matrix[ZX_K_CS] = true;
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
  for (uint8_t i = 0; i < 8; i++) {
    uint8_t k = pos * 8 + i;
    if (k < ZX_MATRIX_FULL_SIZE) {
      bitWrite(result, i, matrix[k]);
    }
  }
  return result;
}

uint8_t get_joy_byte()
{
  uint8_t result = 0;
  for (uint8_t i = 0; i < 8; i++) {
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
  uint8_t bytes = ZX_MATRIX_FULL_SIZE/8; // count of bytes to send
  for (uint8_t i = 0; i < bytes; i++) {
    uint8_t data = get_matrix_byte(i);
    spi_send(i + 1, data);
  }
}

void transmit_joy_data()
{
  uint8_t data = get_joy_byte();
  spi_send(CMD_JOY, data);
}

void transmit_mouse_data()
{
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
  if (!rtc.isRunning()) {
    rtc.startClock();
  }
}

void rtc_fix_invalid_time() {
  if (rtc_day < 1 || rtc_day > 31) rtc_day = 1;
  if (rtc_month < 1 || rtc_month > 12) rtc_month = 1;
  if (rtc_year < 2000 || rtc_year > 4095) rtc_year = 2000;
  if (rtc_hours > 23) rtc_hours = 0;
  if (rtc_minutes > 59) rtc_minutes = 0;
  if (rtc_seconds > 59) rtc_seconds = 0;
  if (rtc_week < 1 || rtc_week > 7) rtc_week = 1;
  rtc_save();
}

void rtc_send(uint8_t reg, uint8_t data) {
  spi_send(CMD_RTC_READ + reg, data);
}


void rtc_send_time() {
  //uint8_t data;
  //data = EEPROM.read(EEPROM_RTC_OFFSET + 0xA); bitClear(data, 7); rtc_send(0xA, data);
  //data = EEPROM.read(EEPROM_RTC_OFFSET + 0xB); rtc_send(0xB, data);
  rtc_send(0, rtc_is_bcd ? bin2bcd(rtc_seconds) : rtc_seconds);
  rtc_send(2, rtc_is_bcd ? bin2bcd(rtc_minutes) : rtc_minutes);
  rtc_send(4, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours) : rtc_hours) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours)) : time_to12h(rtc_hours)));
  rtc_send(6, rtc_is_bcd ? bin2bcd(rtc_week) : rtc_week);
  rtc_send(7, rtc_is_bcd ? bin2bcd(rtc_day) : rtc_day);
  rtc_send(8, rtc_is_bcd ? bin2bcd(rtc_month) : rtc_month);
  rtc_send(9, rtc_is_bcd ? bin2bcd(get_year(rtc_year)) : get_year(rtc_year));
}

void rtc_send_all() {
  uint8_t data;
  for (uint8_t reg = 0; reg < 64; reg++) {
    switch (reg) {
      case 0: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_seconds) : rtc_seconds); break;
      case 1: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_seconds_alarm) : rtc_seconds_alarm); break;
      case 2: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_minutes) : rtc_minutes); break;
      case 3: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_minutes_alarm) : rtc_minutes_alarm); break;
      case 4: rtc_send(reg, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours) : rtc_hours) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours)) : time_to12h(rtc_hours))); break;
      case 5: rtc_send(reg, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours_alarm) : rtc_hours_alarm) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours_alarm)) : time_to12h(rtc_hours_alarm))); break;
      case 6: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_week) : rtc_week); break;
      case 7: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_day) : rtc_day); break;
      case 8: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_month) : rtc_month); break;
      case 9: rtc_send(reg, rtc_is_bcd ? bin2bcd(get_year(rtc_year)) : get_year(rtc_year)); break;
      case 0xA: data = EEPROM.read(EEPROM_RTC_OFFSET + reg); bitClear(data, 7); rtc_send(reg, data); break;
      case 0xB: data = EEPROM.read(EEPROM_RTC_OFFSET + reg); rtc_send(reg, data); break;
      case 0xC: rtc_send(reg, 0x0); break;
      case 0xD: rtc_send(reg, 0x80); break;
      default: rtc_send(reg, EEPROM.read(EEPROM_RTC_OFFSET + reg));
    }
  }
}

void process_in_cmd(uint8_t cmd, uint8_t data)
{
  uint8_t reg;

  if (cmd == CMD_INIT_REQ && !init_done) {
      Serial.print(F("FPGA init request..."));
      init_done = true;
      transmit_keyboard_matrix();
      rtc_send_all();
      do_reset();
      Serial.println(F("done"));
      cfg = data;
      Serial.print(F("FPGA board revision is: "));
      switch (data) {
        case 0:
          Serial.println(F("Rev.A/B/C/D with TDA1543 DAC"));
        break;
        case 1:
          Serial.println(F("Rev.A/B/C/D with TDA1543A DAC"));
        break;
        case 4:
          Serial.println(F("Rev.DS with TDA1543 DAC"));
        break;
        case 5:
          Serial.println(F("Rev.DS with TDA1543A DAC"));
        break;
        default:
          Serial.println(F("Unknown"));
      }
  }

  if (cmd == CMD_RTC_INIT_REQ && !rtc_init_done) {
    Serial.print(F("RTC init request..."));
    rtc_init_done = true;
    rtc_send_all();
    Serial.println(F("done"));
  }

  if (cmd >= CMD_BUILD_REQ0 && cmd <= CMD_BUILD_REQ7) {
    switch(cmd) {
      case CMD_BUILD_REQ0: build_num[0] = data; break;
      case CMD_BUILD_REQ1: build_num[1] = data; break;
      case CMD_BUILD_REQ2: build_num[2] = data; break;
      case CMD_BUILD_REQ3: build_num[3] = data; break;
      case CMD_BUILD_REQ4: build_num[4] = data; break;
      case CMD_BUILD_REQ5: build_num[5] = data; break;
      case CMD_BUILD_REQ6: build_num[6] = data; break;
      case CMD_BUILD_REQ7: build_num[7] = data; break;
    }
  }

#if ALLOW_LED_OVERRIDE
  if (cmd == CMD_LED_WRITE) {
    led1_state = bitRead(data, 0);
    led2_state = bitRead(data, 1);
    led1_overwrite = bitRead(data, 2);
    led2_overwrite = bitRead(data, 3);
  }
#endif

  if (cmd >= CMD_RTC_WRITE && cmd < CMD_RTC_WRITE + 64) {
    // write rtc register
    reg = cmd - CMD_RTC_WRITE;

    // skip double write
    if (rtc_last_write_reg == reg && rtc_last_write_data == data) return;

    rtc_last_write_reg = reg;
    rtc_last_write_data = data;

    switch (reg) {
      case 0: rtc_seconds = rtc_is_bcd ? bcd2bin(data) : data; rtc.setSeconds(rtc_seconds); break;
      case 1: rtc_seconds_alarm = rtc_is_bcd ? bcd2bin(data) : data; break;
      case 2: rtc_minutes = rtc_is_bcd ? bcd2bin(data) : data; rtc.setMinutes(rtc_minutes); break;
      case 3: rtc_minutes_alarm = rtc_is_bcd ? bcd2bin(data) : data;  break;
      case 4: rtc_hours = rtc_is_bcd ? bcd2bin(data) : data; rtc.setHourMode(CLOCK_H24); rtc.setHours(rtc_hours); break;
      case 5: rtc_hours_alarm = rtc_is_bcd ? bcd2bin(data) : data; break;
      case 6: rtc_week = rtc_is_bcd ? bcd2bin(data) : data; rtc.setWeek(rtc_week); break;
      case 7: rtc_day = rtc_is_bcd ? bcd2bin(data) : data; rtc.setDay(rtc_day); break;
      case 8: rtc_month = rtc_is_bcd ? bcd2bin(data) : data; rtc.setMonth(rtc_month); break;
      case 9: rtc_year = 2000 + (rtc_is_bcd ? bcd2bin(data) : data); rtc.setYear(rtc_year); break;
      case 0xA: bitClear(data, 7); EEPROM.write(EEPROM_RTC_OFFSET + reg, data); break;
      case 0xB: rtc_is_bcd = !bitRead(data, 2); rtc_is_24h = bitRead(data, 1); EEPROM.write(EEPROM_RTC_OFFSET + reg, data); break;
      case 0xC: // C and D are read-only registers
      case 0xD: break;
      default: EEPROM.write(EEPROM_RTC_OFFSET + reg, data);
    }
  }
}

void init_mouse()
{
#if (MOUSE_POLL_TYPE == 1)
  mouse_present = mice.initialize();
#else 
  mouse_present = mice.streamInitialize();
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

void do_full_reset()
{
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

void do_caps()
{
  matrix[ZX_K_SS] = true;
  matrix[ZX_K_CS] = true;
  transmit_keyboard_matrix();
  delay(100);
  matrix[ZX_K_SS] = false;
  matrix[ZX_K_CS] = false;
}

void do_pause()
{
  is_wait = !is_wait;
  matrix[ZX_K_WAIT] = is_wait;
  osd_update_pause();
}

void clear_matrix(int clear_size)
{
  // all keys up
  for (int i = 0; i < clear_size; i++) {
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
  is_sw3 = eeprom_restore_value(EEPROM_SW3_ADDRESS, is_sw3);
  is_sw4 = eeprom_restore_value(EEPROM_SW4_ADDRESS, is_sw4);
  is_sw5 = eeprom_restore_value(EEPROM_SW5_ADDRESS, is_sw5);
  is_sw6 = eeprom_restore_value(EEPROM_SW6_ADDRESS, is_sw6);
  is_sw7 = eeprom_restore_value(EEPROM_SW7_ADDRESS, is_sw7);
  is_sw8 = eeprom_restore_value(EEPROM_SW8_ADDRESS, is_sw8);
  is_sw9 = eeprom_restore_value(EEPROM_SW9_ADDRESS, is_sw9);
  is_sw10 = eeprom_restore_value(EEPROM_SW10_ADDRESS, is_sw10);
  is_mouse_swap = eeprom_restore_value(EEPROM_MOUSE_SWAP_ADDRESS, is_mouse_swap);
  joy_type = eeprom_restore_value(EEPROM_JOY_TYPE_ADDRESS, joy_type);
  
  // apply restored values
  matrix[ZX_K_TURBO] = is_turbo;
  matrix[ZX_K_SW1] = is_sw1;
  matrix[ZX_K_SW2] = is_sw2;
  matrix[ZX_K_SW3] = is_sw3;
  matrix[ZX_K_SW4] = is_sw4;
  matrix[ZX_K_SW5] = is_sw5;
  matrix[ZX_K_SW6] = is_sw6;
  matrix[ZX_K_SW7] = is_sw7;
  matrix[ZX_K_SW8] = is_sw8;
  matrix[ZX_K_SW9] = is_sw9;
  matrix[ZX_K_SW10] = is_sw10;
  matrix[ZX_K_KBD_MODE] = profi_mode;
  matrix[ZX_K_JOY_TYPE] = joy_type;
}

void eeprom_store_values()
{
  eeprom_store_value(EEPROM_TURBO_ADDRESS, is_turbo);
  eeprom_store_value(EEPROM_MODE_ADDRESS, profi_mode);
  eeprom_store_value(EEPROM_SW1_ADDRESS, is_sw1);
  eeprom_store_value(EEPROM_SW2_ADDRESS, is_sw2);
  eeprom_store_value(EEPROM_SW3_ADDRESS, is_sw3);
  eeprom_store_value(EEPROM_SW4_ADDRESS, is_sw4);
  eeprom_store_value(EEPROM_SW5_ADDRESS, is_sw5);
  eeprom_store_value(EEPROM_SW6_ADDRESS, is_sw6);
  eeprom_store_value(EEPROM_SW7_ADDRESS, is_sw7);
  eeprom_store_value(EEPROM_SW8_ADDRESS, is_sw8);
  eeprom_store_value(EEPROM_SW9_ADDRESS, is_sw9);
  eeprom_store_value(EEPROM_SW10_ADDRESS, is_sw10);
  eeprom_store_value(EEPROM_MOUSE_SWAP_ADDRESS, is_mouse_swap);
  eeprom_store_value(EEPROM_JOY_TYPE_ADDRESS, joy_type);
}

// update led state
void update_led(uint8_t led, bool state)
{
  if (led == PIN_LED2 && joy_type) {
    digitalWrite(PIN_LED2, HIGH);
    return;
  }
  digitalWrite(led, state);
}

void osd_print_header()
{
  // OSD Header
  osd.setPos(0,0);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("Karabas Pro"));
  osd.setPos(0,1);
  for (uint8_t i=0; i<32; i++) {
    osd.print(F("_"));
  }
  osd.setPos(0,2);

  // board revision
  switch (cfg) {
    case 0:
    case 1:
      osd.print(F("Rev.A  "));
      break;
    case 4:
    case 5:
      osd.print(F("Rev.DS "));
      break;
  }

  // dac type
  switch (cfg) {
    case 0:
    case 4:
      osd.print(F("TDA1543 "));
      break;
    case 1:
    case 5:
      osd.print(F("TDA1543A"));
      break;
  }
  osd.setPos(0,3);
  osd.print(F("Build  "));
  osd.write(build_num[0]);
  osd.write(build_num[1]);
  osd.write(build_num[2]);
  osd.write(build_num[3]);
  osd.write(build_num[4]);
  osd.write(build_num[5]);
  osd.write(build_num[6]);
  osd.write(build_num[7]);
}

// init osd
void osd_init_overlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  osd_print_header();

  // ROM Bank
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,5); osd.print(F("ROM Bank:"));
  osd_update_rombank();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,5); osd.print(F("Menu+F1-F4"));

  // Turbo FDC
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,6); osd.print(F("TurboFDC:"));
  osd_update_turbofdc();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,6); osd.print(F("Menu+F5"));

  // Covox
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,7); osd.print(F("Covox:"));
  osd_update_covox();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,7); osd.print(F("Menu+F6"));

  // Stereo
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,8); osd.print(F("PSG mix:"));
  osd_update_stereo();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,8); osd.print(F("Menu+F7"));

  // SSG type
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,9); osd.print(F("PSG type:"));
  osd_update_ssg();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,9); osd.print(F("Menu+F8"));

  // RGB/VGA
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,10); osd.print(F("Video:"));
  osd_update_video();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,10); osd.print(F("Menu+F9"));

  // VSync
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,11); osd.print(F("VSync:"));
  osd_update_vsync();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,11); osd.print(F("Menu+F10"));

  // Turbo
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,12); osd.print(F("Turbo 2x:"));
  osd_update_turbo();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,12); osd.print(F("Menu+F11"));

  // FDC Swap
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,13); osd.print(F("Swap FDD:"));
  osd_update_swap_ab();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,13); osd.print(F("Menu+Tab"));

  // Joy type
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,14); osd.print(F("Joy type:"));
  osd_update_joystick();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,14); osd.print(F("Menu+J"));

  // Keyboard
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,15); osd.print(F("Keyboard:"));
  osd_update_keyboard_type();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,15); osd.print(F("PrtScr"));

  // Pause
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,16); osd.print(F("Pause:"));
  osd_update_pause();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,16); osd.print(F("Pause"));

  // Scancode
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,18); osd.print(F("Scancode:"));
  osd_update_scancode(0);

  // Mouse
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,19); osd.print(F("Mouse:"));
  osd_update_mouse();

  // Joy
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,20); osd.print(F("Port #1F:"));
  osd_update_joy_state();

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(20,19); osd.print(F("Press "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_FLASH);
  osd.print(F("E"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" to "));
  osd.setPos(20,20); osd.print(F("set up RTC"));

  // footer
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,22); osd.print(F("Press "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F("Ctrl+Alt+Del"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" to reboot"));

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,23); osd.print(F("Press "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F("Menu+ESC"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" to toggle OSD"));
}

// init rtc osd
void osd_init_rtc_overlay()
{
  rtc_fix_invalid_time(); // try to fix invalid time

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  osd_print_header();

  osd.setPos(0,5);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("RTC setup:"));

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,7); osd.print(F("Hours:"));
  osd_update_rtc_hour();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,8); osd.print(F("Minutes:"));
  osd_update_rtc_minute();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,9); osd.print(F("Seconds:"));
  osd_update_rtc_second();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,11); osd.print(F("Day:"));
  osd_update_rtc_day();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,12); osd.print(F("Month:"));
  osd_update_rtc_month();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,13); osd.print(F("Year:"));
  osd_update_rtc_year();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,15); osd.print(F("DOW:"));
  osd_update_rtc_dow();

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0, 17);
  osd.print(F("Please use arrows "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.write(17);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" and "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.write(16);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0, 18);
  osd.print(F("to change values, "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.write(30);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" and "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.write(31);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0, 19);
  osd.print(F("to navigate by menu items"));

  osd_popup_footer();
}

// init test osd
void osd_init_test_overlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  osd_print_header();

  osd.setPos(0,5);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("Color test:"));

  uint8_t color = 0;
  for (uint8_t x = 0; x<32; x++) {
    for (uint8_t y = 7; y<22; y++) {
      color = x/2;
      switch (color) {
        case 0: osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_BLACK); break;
        case 1: osd.setColor(OSD::COLOR_RED, OSD::COLOR_BLACK); break;
        case 2: osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK); break;
        case 3: osd.setColor(OSD::COLOR_YELLOW, OSD::COLOR_BLACK); break;
        case 4: osd.setColor(OSD::COLOR_YELLOW_I, OSD::COLOR_BLACK); break;
        case 5: osd.setColor(OSD::COLOR_GREEN, OSD::COLOR_BLACK); break;
        case 6: osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK); break;
        case 7: osd.setColor(OSD::COLOR_CYAN, OSD::COLOR_BLACK); break;
        case 8: osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); break;
        case 9: osd.setColor(OSD::COLOR_BLUE, OSD::COLOR_BLACK); break;
        case 10: osd.setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK); break;
        case 11: osd.setColor(OSD::COLOR_MAGENTA, OSD::COLOR_BLACK); break;
        case 12: osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK); break;
        case 13: osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK); break;
        case 14: osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); break;
        case 15: osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_BLACK); break;
      }
      osd.setPos(x, y); osd.write(219);
    }
  }

  osd_popup_footer();

}

void osd_popup_footer() {
  // footer
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,23); osd.print(F("Press "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F("ESC"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" to return"));
}

void osd_handle_rombank() {
  uint8_t romset = 0;
  bitWrite(romset, 0, is_sw3);
  bitWrite(romset, 1, is_sw4);

  if (cursor_left) {
    romset = romset-1;
    if (romset > 3) romset = 3;
    set_rombank(romset);
    osd_update_rombank();
  }
  if (cursor_right || is_enter) {
    romset = romset+1;
    if (romset >3) romset = 0;
    set_rombank(romset);
    osd_update_rombank();
  }
}

void osd_handle_turbofdc() {
  if (cursor_left || cursor_right || is_enter) {
    set_turbofdc();
    osd_update_turbofdc();
  }
}

void osd_handle_covox() {
  if (cursor_left || cursor_right || is_enter) {
    set_covox();
    osd_update_covox();
  }
}

void osd_handle_stereo() {

  uint8_t stereo = 0;
  bitWrite(stereo, 0, is_sw7);
  bitWrite(stereo, 1, is_sw9);

  if (cursor_left) {
    stereo = stereo-1;
    if (stereo > 2) stereo = 2;
    set_stereo(stereo);
    osd_update_stereo();
  }
  if (cursor_right || is_enter) {
    stereo = stereo+1;
    if (stereo >2) stereo = 0;
    set_stereo(stereo);
    osd_update_stereo();
  }
}

void osd_handle_ssg() {
  if (cursor_left || cursor_right || is_enter) {
    set_ssg();
    osd_update_ssg();
  }
}

void osd_handle_video() {
  if (cursor_left || cursor_right || is_enter) {
    set_video();
    osd_update_video();
  }
}

void osd_handle_vsync() {
  if (cursor_left || cursor_right || is_enter) {
    set_vsync();
    osd_update_vsync();
  }
}

void osd_handle_turbo() {
  if (cursor_left || cursor_right || is_enter) {
    set_turbo();
    osd_update_turbo();
  }
}

void osd_handle_swap_ab() {
  if (cursor_left || cursor_right || is_enter) {
    set_swap_ab();
    osd_update_swap_ab();
  }
}

void osd_handle_joy_type() {
  if (cursor_left || cursor_right || is_enter) {
    set_joy_type();
    osd_update_joystick();
  }
}

void osd_handle_keyboard_type() {
  if (cursor_left || cursor_right || is_enter) {
    set_keyboard_type();
    osd_update_keyboard_type();
  }
}

void osd_handle_pause() {
  if (cursor_left || cursor_right || is_enter) {
    do_pause();
    osd_update_pause();
  }
}

void osd_handle_rtc_hour() {
  if (cursor_left) {
    rtc_hours = rtc_hours-1;
    if (rtc_hours > 23) rtc_hours = 0;
    rtc_save();
    osd_update_rtc_hour();
  }
  if (cursor_right || is_enter) {
    rtc_hours = rtc_hours+1;
    if (rtc_hours >23) rtc_hours = 0;
    rtc_save();
    osd_update_rtc_hour();
  }
}

void osd_handle_rtc_minute() {
  if (cursor_left) {
    rtc_minutes = rtc_minutes-1;
    if (rtc_minutes > 59) rtc_minutes = 59;
    rtc_save();
    osd_update_rtc_minute();
  }
  if (cursor_right || is_enter) {
    rtc_minutes = rtc_minutes+1;
    if (rtc_minutes >59) rtc_minutes = 0;
    rtc_save();
    osd_update_rtc_minute();
  }
}

void osd_handle_rtc_second() {
  if (cursor_left) {
    rtc_seconds = rtc_seconds-1;
    if (rtc_seconds > 59) rtc_seconds = 59;
    rtc_save();
    osd_update_rtc_second();
  }
  if (cursor_right || is_enter) {
    rtc_seconds = rtc_seconds+1;
    if (rtc_seconds >59) rtc_seconds = 0;
    rtc_save();
    osd_update_rtc_second();
  }
}

void osd_handle_rtc_day() {
  if (cursor_left) {
    rtc_day = rtc_day-1;
    if (rtc_day < 1 || rtc_day > 31) rtc_day = 31;
    rtc_save();
    osd_update_rtc_day();
  }
  if (cursor_right || is_enter) {
    rtc_day = rtc_day+1;
    if (rtc_day > 31) rtc_day = 1;
    rtc_save();
    osd_update_rtc_day();
  }
}

void osd_handle_rtc_month() {
  if (cursor_left) {
    rtc_month = rtc_month-1;
    if (rtc_month < 1 || rtc_month > 12) rtc_month = 12;
    rtc_save();
    osd_update_rtc_month();
  }
  if (cursor_right || is_enter) {
    rtc_month = rtc_month+1;
    if (rtc_month > 12) rtc_month = 1;
    rtc_save();
    osd_update_rtc_month();
  }
}

void osd_handle_rtc_year() {
  if (cursor_left) {
    rtc_year = rtc_year-1;
    if (rtc_year < 2000 || rtc_year > 4095) rtc_year = 2000;
    rtc_save();
    osd_update_rtc_year();
  }
  if (cursor_right || is_enter) {
    rtc_year = rtc_year+1;
    if (rtc_year < 2000 || rtc_year > 4096) rtc_year = 2000;
    rtc_save();
    osd_update_rtc_year();
  }
}

void osd_handle_rtc_dow() {
  if (cursor_left) {
    rtc_week = rtc_week-1;
    if (rtc_week < 1 || rtc_week > 7) rtc_week = 7;
    rtc_save();
    osd_update_rtc_dow();
  }
  if (cursor_right || is_enter) {
    rtc_week = rtc_week+1;
    if (rtc_week < 1 || rtc_week > 7) rtc_week = 1;
    rtc_save();
    osd_update_rtc_dow();
  }
}

void osd_update_rombank()
{
  if (osd_state != state_main) return;

  uint8_t romset = 0;
  bitWrite(romset, 0, is_sw3);
  bitWrite(romset, 1, is_sw4);

  if (osd_main_state == state_main_rom_bank) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,5);
  switch (romset) {
    case 0: osd.print(F("Default")); break;
    case 1: osd.print(F("PQ-DOS")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 2: osd.print(F("Flasher")); break;
    case 3: osd.print(F("FDImage")); break;
  }
}

void osd_update_turbofdc() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_turbofdc) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,6);
  if (is_sw5) { 
    osd.print(F("On")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" "));
  } else { 
    osd.print(F("Off")); 
  }
}

void osd_update_covox() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_covox) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,7);
  if (is_sw6) { 
    osd.print(F("On"));
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Off")); 
  }
}

void osd_update_stereo() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_stereo) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,8);
  uint8_t stereo = 0;
  bitWrite(stereo, 0, is_sw7);
  bitWrite(stereo, 1, is_sw9);
  switch (stereo) {
    case 1: osd.print(F("ABC")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 0: osd.print(F("ACB")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    default: osd.print(F("Mono")); 
  }
}

void osd_update_ssg() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_ssg) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,9);
  if (is_sw8) { osd.print(F("AY3-8912")); } else { osd.print(F("YM2149F")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); }
}

void osd_update_video() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_video) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,10);
  if (is_sw1) { osd.print(F("RGB 15kHz")); } else { osd.print(F("VGA 30kHz")); }
}

void osd_update_vsync() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_sync) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,11);
  if (is_sw2) { osd.print(F("60 Hz")); } else { osd.print(F("50 Hz")); }
}

void osd_update_turbo() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_turbo) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,12);
  if (is_turbo) { 
    osd.print(F("On")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Off")); 
  }
}

void osd_update_swap_ab() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_swap_ab) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,13);
  if (is_sw10) { 
    osd.print(F("On")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Off")); 
  }
}

void osd_update_joystick() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_joy_type) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,14);
  if (joy_type) { 
    osd.print(F("SEGA")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Atari")); 
  }
}

void osd_update_keyboard_type() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_keyboard_type) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,15);
  if (profi_mode) { osd.print(F("Profi XT")); } else { osd.print(F("Spectrum")); }
}

void osd_update_pause() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_pause) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,16);
  if (is_wait) { osd.print(F("On")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); } else { osd.print(F("Off")); }
}

void osd_update_rtc_hour() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_hour) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,7);
  if (rtc_hours < 10) osd.print(F("0"));
  osd.print(rtc_hours, DEC);
}

void osd_update_rtc_minute() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_minute) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,8);
  if (rtc_minutes < 10) osd.print(F("0"));
  osd.print(rtc_minutes, DEC);
}

void osd_update_rtc_second() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_second) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,9);
  if (rtc_seconds < 10) osd.print(F("0"));
  osd.print(rtc_seconds, DEC);
}

void osd_update_rtc_day() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_day) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,11);
  if (rtc_day < 10) osd.print(F("0"));
  osd.print(rtc_day, DEC);
}

void osd_update_rtc_month() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_month) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,12);
  switch (rtc_month) {
    case 1:  osd.print(F("January"));  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("  ")); break;
    case 2:  osd.print(F("February")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 3:  osd.print(F("March"));    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("    ")); break;
    case 4:  osd.print(F("April"));    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("    ")); break;
    case 5:  osd.print(F("May"));      osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("      ")); break;
    case 6:  osd.print(F("June"));     osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("     ")); break;
    case 7:  osd.print(F("July"));     osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("     ")); break;
    case 8:  osd.print(F("August"));   osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("   ")); break;
    case 9:  osd.print(F("September")); break;
    case 10: osd.print(F("October"));  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("  ")); break;
    case 11: osd.print(F("November")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 12: osd.print(F("December")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    default: osd.print(F("___")); 
  }
}

void osd_update_rtc_year() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_year) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,13);
  if (rtc_year < 1000) osd.print(F("0"));
  if (rtc_year < 100) osd.print(F("0"));
  if (rtc_year < 10) osd.print(F("0"));
  osd.print(rtc_year, DEC);
}

void osd_update_rtc_dow() {
if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_dow) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,15);
  switch (rtc_week) {
    case 2: osd.print(F("Mon")); break;
    case 3: osd.print(F("Tue")); break;
    case 4: osd.print(F("Wed")); break;
    case 5: osd.print(F("Thu")); break;
    case 6: osd.print(F("Fri")); break;
    case 7: osd.print(F("Sat")); break;
    case 1: osd.print(F("Sun")); break;
    default: osd.print(F("___")); 
  }
}

void osd_update_time() {
  osd.setColor(OSD::COLOR_YELLOW_I, OSD::COLOR_BLACK);
  osd.setPos(24,0);
  if (rtc_hours < 10) osd.print("0"); 
  osd.print(rtc_hours, DEC); osd.print(F(":"));
  if (rtc_minutes < 10) osd.print("0"); 
  osd.print(rtc_minutes, DEC); osd.print(F(":"));
  if (rtc_seconds < 10) osd.print("0"); 
  osd.print(rtc_seconds, DEC);
  osd.setPos(22,2);
  if (rtc_day < 10) osd.print("0"); 
  osd.print(rtc_day, DEC); osd.print(F("."));
  if (rtc_month < 10) osd.print("0"); 
  osd.print(rtc_month, DEC); osd.print(F("."));
  osd.print(rtc_year, DEC);
  if (osd_state == state_rtc) {
    osd_update_rtc_hour();
    osd_update_rtc_minute();
    osd_update_rtc_second();
    osd_update_rtc_day();
    osd_update_rtc_month();
    osd_update_rtc_year();
    osd_update_rtc_dow();
  }
}

void osd_update_scancode(uint16_t c) {

  if (osd_state != state_main) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(10,18);
  if ((c >> 8) < 0x10) osd.print(F("0")); 
  osd.print(c >> 8, HEX);
  osd.print(F(" "));
  if ((c & 0xFF) < 0x10) osd.print(F("0")); 
  osd.print(c & 0xFF, HEX);
}

void osd_update_mouse() {

  if (osd_state != state_main) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(10,19);
  if (mouse_x < 0x10) osd.print(F("0")); 
  osd.print(mouse_x, HEX);
  osd.print(F(" "));
  if (mouse_y < 0x10) osd.print(F("0")); 
  osd.print(mouse_y, HEX);
  osd.print(F(" "));
  if (mouse_z < 0x10) osd.print(F("0")); 
  osd.print(mouse_z, HEX);
}

void osd_update_joy_state() {

  if (osd_state != state_main) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(10,20);
  osd.print(joy[ZX_JOY_B], DEC);
  osd.print(joy[ZX_JOY_A], DEC);
  osd.print(joy[ZX_JOY_FIRE2], DEC);
  osd.print(joy[ZX_JOY_FIRE], DEC);
  osd.print(joy[ZX_JOY_UP], DEC);
  osd.print(joy[ZX_JOY_DOWN], DEC);
  osd.print(joy[ZX_JOY_LEFT], DEC);
  osd.print(joy[ZX_JOY_RIGHT], DEC);
}


// initial setup
void setup()
{
  Serial.begin(115200);
  Serial.flush();
  pinMode(PIN_JOY_RIGHT, OUTPUT);
  digitalWrite(PIN_JOY_RIGHT, LOW);
  SPI.begin();

  // set up fast ADC
  // Bit 7 - ADEN: ADC Enable
  // Bit 6 - ADSC: ADC Start Conversion
  // Bit 5 - ADATE: ADC Auto Trigger Enable
  // Bit 4 - ADIF: ADC Interrupt Flag
  // Bit 3 - ADIE: ADC Interrupt Enable
  // Bits 2:0 - ADPS[2:0]: ADC Prescaler Select Bits
  ADCSRA = (ADCSRA & B11111000) | 4;

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
//  pinMode(PIN_JOY_RIGHT, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE1, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE2, INPUT_PULLUP);

  // clear full matrix
  clear_matrix(ZX_MATRIX_FULL_SIZE);

  // restore saved modes from EEPROM
  eeprom_restore_values();

  Serial.println(F("Karabas Pro"));

  Serial.println(F("Waiting for FPGA init request"));
  // waiting for init
  while (!init_done) {
    spi_send(CMD_NONE, 0x00);
  }

  // request build num from the fpga
  spi_send(CMD_BUILD_REQ0, 0x00);
  spi_send(CMD_BUILD_REQ1, 0x00);
  spi_send(CMD_BUILD_REQ2, 0x00);
  spi_send(CMD_BUILD_REQ3, 0x00);
  spi_send(CMD_BUILD_REQ4, 0x00);
  spi_send(CMD_BUILD_REQ5, 0x00);
  spi_send(CMD_BUILD_REQ6, 0x00);
  spi_send(CMD_BUILD_REQ7, 0x00);

  // setup osd library with callback to send spi command
  osd.begin(spi_send);

  // setup sega controller
  sega.begin(PIN_LED2, PIN_JOY_UP, PIN_JOY_DOWN, PIN_JOY_LEFT, PIN_JOY_RIGHT, PIN_JOY_FIRE1, PIN_JOY_FIRE2);

  Serial.print(F("Kbd init..."));
  kbd.begin(PIN_KBD_DAT, PIN_KBD_CLK);
  kbd.echo(); // ping keyboard to see if there
  delay(6);
  uint16_t c = kbd.read();
  if( (c & 0xFF) == PS2_KEY_ECHO || (c & 0xFF) == PS2_KEY_BAT ) {
    Serial.println(F("done")); // Response was Echo or power up
    //kbd.setNoBreak(0);
    //kbd.setNoRepeat(0);
    //kbd.typematic(0xb, 1);
    kbd.setLock(PS2_LOCK_SCROLL);
  } else {
    if( ( c & 0xFF ) == 0 ) {
      Serial.println(F("not found"));
    } else {
      Serial.print( F("invalid code "));
      Serial.println( c, HEX );
    }
  }

  mouse_tries = MOUSE_INIT_TRIES;

  Serial.print(F("Mouse init..."));
  mice.begin(PIN_MOUSE_CLK, PIN_MOUSE_DAT);
  init_mouse();
  Serial.println("done");

  Serial.print(F("RTC init..."));
  rtc.begin();

  if (!rtc.isRunning()) {
     Serial.println(F("Staring RTC..."));
     rtc.startClock();
  }

  rtc_year = rtc.getYear();
  rtc_month = rtc.getMonth();
  rtc_day = rtc.getDay();
  rtc_week = rtc.getWeek();

  rtc_hours = rtc.getHours();
  rtc_minutes = rtc.getMinutes();
  rtc_seconds = rtc.getSeconds();

  // read is_bcd, is_24h
  uint8_t reg_b = EEPROM.read(EEPROM_RTC_OFFSET + 0xB);
  rtc_is_bcd = !bitRead(reg_b, 2);
  rtc_is_24h = bitRead(reg_b, 1);

  rtc_send_time();
  Serial.println(F("done"));  

  if (!rtc_init_done) {
    Serial.print(F("RTC send all..."));
    rtc_send_all();
    Serial.println(F("done"));  
  }

  Serial.println(F("Starting main loop"));
  digitalWrite(PIN_LED1, LOW);
}


// main loop
void loop()
{
  unsigned long n = millis();

  if (kbd.available()) {
    uint16_t c = kbd.read();
    tl = n;
    if (!led1_overwrite) {
      update_led(PIN_LED1, HIGH);
    }
    fill_kbd_matrix(c, n);
    Serial.print(F(" Status: "));
    Serial.print(c >> 8, HEX);
    Serial.print(F(" Code: "));
    Serial.println(c & 0xFF, HEX);
    if (osd_overlay) {
      osd_update_scancode(c);
    }
  }

  // switch betweeen main osd states
  if (osd_overlay) {
    switch (osd_state) {
      case state_main:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          osd_main_state = state_main_rom_bank;
          osd_prev_main_state = state_main_rom_bank;
          osd_init_overlay();
        }

        if (osd_main_state != osd_prev_main_state) {
          osd_prev_main_state = osd_main_state;
          switch(osd_main_state) {
            case state_main_rom_bank: osd_update_pause(); osd_update_rombank(); osd_update_turbofdc(); break;
            case state_main_turbofdc: osd_update_rombank(); osd_update_turbofdc(); osd_update_covox(); break;
            case state_main_covox: osd_update_turbofdc(); osd_update_covox(); osd_update_stereo(); break;
            case state_main_stereo: osd_update_covox(); osd_update_stereo(); osd_update_ssg(); break;
            case state_main_ssg: osd_update_stereo(); osd_update_ssg(); osd_update_video(); break;
            case state_main_video: osd_update_ssg(); osd_update_video(); osd_update_vsync(); break;
            case state_main_sync: osd_update_video(); osd_update_vsync(); osd_update_turbo(); break;
            case state_main_turbo: osd_update_vsync(); osd_update_turbo(); osd_update_swap_ab(); break;
            case state_main_swap_ab: osd_update_turbo(); osd_update_swap_ab(); osd_update_joystick(); break;
            case state_main_joy_type: osd_update_swap_ab(); osd_update_joystick(); osd_update_keyboard_type(); break;
            case state_main_keyboard_type: osd_update_joystick(); osd_update_keyboard_type(); osd_update_pause(); break;
            case state_main_pause: osd_update_keyboard_type(); osd_update_pause(); osd_update_rombank(); break;
          }
        }

      break;
      case state_rtc:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          osd_rtc_state = state_rtc_hour;
          osd_prev_rtc_state = state_rtc_hour;
          osd_init_rtc_overlay();
        }

        if (osd_rtc_state != osd_prev_rtc_state) {
          osd_prev_rtc_state = osd_rtc_state;
          switch(osd_rtc_state) {
            case state_rtc_hour: osd_update_rtc_dow(); osd_update_rtc_hour(); osd_update_rtc_minute(); break;
            case state_rtc_minute: osd_update_rtc_hour(); osd_update_rtc_minute(); osd_update_rtc_second(); break;
            case state_rtc_second: osd_update_rtc_minute(); osd_update_rtc_second(); osd_update_rtc_day(); break;
            case state_rtc_day: osd_update_rtc_second(); osd_update_rtc_day(); osd_update_rtc_month(); break;
            case state_rtc_month: osd_update_rtc_day(); osd_update_rtc_month(); osd_update_rtc_year(); break;
            case state_rtc_year: osd_update_rtc_month(); osd_update_rtc_year(); osd_update_rtc_dow(); break;
            case state_rtc_dow: osd_update_rtc_year(); osd_update_rtc_dow(); osd_update_rtc_hour(); break;
          }
        }

      break;

      case state_test:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          osd_init_test_overlay();
        }
    }
  }

  // process osd overlay keyboard actions here
  if (osd_overlay) {
    switch (osd_state) {
      case state_main:

        if (cursor_down) {
          osd_main_state++;
          if (osd_main_state > state_main_pause) osd_main_state = state_main_rom_bank;
        }

        if (cursor_up) {
          osd_main_state--;
          if (osd_main_state > state_main_pause) osd_main_state = state_main_pause;
        }

        if (matrix[ZX_K_E]) {
          osd_state = state_rtc;
        }

        if (matrix[ZX_K_T]) {
          osd_state = state_test;
        }

        switch (osd_main_state) {
          case state_main_rom_bank: osd_handle_rombank(); break;
          case state_main_turbofdc: osd_handle_turbofdc(); break;
          case state_main_covox: osd_handle_covox(); break;
          case state_main_stereo: osd_handle_stereo(); break;
          case state_main_ssg: osd_handle_ssg(); break;
          case state_main_video: osd_handle_video(); break;
          case state_main_sync: osd_handle_vsync(); break;
          case state_main_turbo: osd_handle_turbo(); break;
          case state_main_swap_ab: osd_handle_swap_ab(); break;
          case state_main_joy_type: osd_handle_joy_type(); break;
          case state_main_keyboard_type: osd_handle_keyboard_type(); break;
          case state_main_pause: osd_handle_pause(); break;
        }
      break;
      case state_rtc:

        if (cursor_down) {
          osd_rtc_state++;
          if (osd_rtc_state > state_rtc_dow) osd_rtc_state = state_rtc_hour;
        }

        if (cursor_up) {
          osd_rtc_state--;
          if (osd_rtc_state > state_rtc_dow) osd_rtc_state = state_rtc_dow;
        }

        if (is_esc) {
          osd_state = state_main;
        }

        switch (osd_rtc_state) {
          case state_rtc_hour: osd_handle_rtc_hour(); break;
          case state_rtc_minute: osd_handle_rtc_minute(); break;
          case state_rtc_second: osd_handle_rtc_second(); break;
          case state_rtc_day: osd_handle_rtc_day(); break;
          case state_rtc_month: osd_handle_rtc_month(); break;
          case state_rtc_year: osd_handle_rtc_year(); break;
          case state_rtc_dow: osd_handle_rtc_dow(); break;
        }

      break;

      case state_test:

        if (is_esc) {
          osd_state = state_main;
        }

      break;
    }
  }

  // process delayed sequences
  process_delayed_keypress();

  // empty keyboard matrix in overlay mode before transmitting it onto FPGA side
  if (osd_overlay) {
    clear_matrix(ZX_MATRIX_SIZE);
  }

  // transmit kbd always
  transmit_keyboard_matrix();

  // read joystick
  // Due to conflict with the hardware SPI, we should stop the HW SPI and switch the joy_right as input before reading
  // WARNING: a 100-500 Ohm resistor is required on the PIN_JOY_RIGHT line
  //SPI.end();
  //interrupts(); // SPI.end() calls noInterrupts()
  SPCR &= ~_BV(SPE);

  // set JOY_RIGHT pin as input to read joystick signal
  pinMode(PIN_JOY_RIGHT, INPUT_PULLUP);

  if (joy_type == false) {
    // kempston joy read
    joy[ZX_JOY_UP] = digitalRead(PIN_JOY_UP) == LOW;
    joy[ZX_JOY_DOWN] = digitalRead(PIN_JOY_DOWN) == LOW;
    joy[ZX_JOY_LEFT] = digitalRead(PIN_JOY_LEFT) == LOW;
    joy[ZX_JOY_RIGHT] = digitalRead(PIN_JOY_RIGHT) == LOW;
    joy[ZX_JOY_FIRE] = digitalRead(PIN_JOY_FIRE1) == LOW;
    joy[ZX_JOY_FIRE2] = digitalRead(PIN_JOY_FIRE2) == LOW;
    joy[ZX_JOY_A] = false;
    joy[ZX_JOY_B] = false;
  } else {
    // sega joy read
    sega_joy_state = sega.getState();
    joy[ZX_JOY_UP] = sega_joy_state & SC_BTN_UP;
    joy[ZX_JOY_DOWN] = sega_joy_state & SC_BTN_DOWN;
    joy[ZX_JOY_LEFT] = sega_joy_state & SC_BTN_LEFT;
    joy[ZX_JOY_RIGHT] = sega_joy_state & SC_BTN_RIGHT;
    joy[ZX_JOY_FIRE] = sega_joy_state & SC_BTN_B;
    joy[ZX_JOY_FIRE2] = sega_joy_state & SC_BTN_C;
    joy[ZX_JOY_A] = sega_joy_state & SC_BTN_A;
    joy[ZX_JOY_B] = sega_joy_state & SC_BTN_START;
  }

  // set JOY_RIGHT as output to avoid intersection with hardware SPI SS pin
  pinMode(PIN_JOY_RIGHT, OUTPUT);
  digitalWrite(PIN_JOY_RIGHT, LOW);

  //SPI.begin();
  //interrupts(); // SPI.begin() calls noInterrupts()
  SPCR |= _BV(MSTR);
  SPCR |= _BV(SPE);

  if (joy[0] != last_joy[0] || joy[1] != last_joy[1] || joy[2] != last_joy[2] || joy[3] != last_joy[3] || joy[4] != last_joy[4] || joy[5] != last_joy[5] || joy[6] != last_joy[6] || joy[7] != last_joy[7]) {
    last_joy[0] = joy[0];
    last_joy[1] = joy[1];
    last_joy[2] = joy[2];
    last_joy[3] = joy[3];
    last_joy[4] = joy[4];
    last_joy[5] = joy[5];
    last_joy[6] = joy[6];
    last_joy[7] = joy[7];
    if (joy_type) {
      Serial.print(F("SEGA: "));
      Serial.print(sega.getIsOn() ? F("(ON) ") : F("(OFF) "));
      Serial.print(sega.getSixButtonMode() ? F("(6 btn) ") : F("(3 btn) "));
    } else {
      Serial.print(F("Kempston: "));
    }
    Serial.print(F(" U:")); Serial.print(joy[ZX_JOY_UP]);
    Serial.print(F(" D:")); Serial.print(joy[ZX_JOY_DOWN]);
    Serial.print(F(" L:")); Serial.print(joy[ZX_JOY_LEFT]);
    Serial.print(F(" R:")); Serial.print(joy[ZX_JOY_RIGHT]);
    Serial.print(F(" F1:")); Serial.print(joy[ZX_JOY_FIRE]);
    Serial.print(F(" F2:")); Serial.print(joy[ZX_JOY_FIRE2]);
    Serial.print(F(" J:")); Serial.print(joy[ZX_JOY_A]);
    Serial.print(F(" P:")); Serial.println(joy[ZX_JOY_B]);

    if (osd_overlay) {
      osd_update_joy_state();
    }

  }

  // transmit joy matrix
  transmit_joy_data();

  // react on hardware buttons every 100ms
#if USE_HW_BUTTONS
  if (n - tb >= 100) {
    if (analogRead(PIN_BTN1) < 3 && (n - tb1 >= 500) ) {
      tb1 = n;
      update_led(PIN_LED2, HIGH);
      Serial.print(F("BTN1: Magic..."));
      do_magic();
      Serial.println(F("done"));
       update_led(PIN_LED2, LOW);
    }

    if (analogRead(PIN_BTN2) < 3 && (n - tb2 >= 500) ) {
      tb2 = n;
      update_led(PIN_LED1, HIGH);
      Serial.print(F("BTN2: Reset..."));
      do_reset();
      Serial.println(F("done"));
      update_led(PIN_LED1, LOW);
    }
    tb = n;
  }
#endif

  // read time from rtc
  if (n - tr >= 500) {

    rtc_year = rtc.getYear();
    rtc_month = rtc.getMonth();
    rtc_day = rtc.getDay();
    rtc_week = rtc.getWeek();

    rtc_hours = rtc.getHours();
    rtc_minutes = rtc.getMinutes();
    rtc_seconds = rtc.getSeconds();

    rtc_send_time();

    // show time in the overlay
    if (osd_overlay) {
      osd_update_time();
    }

    tr = n;
  }

  // try to re-init mouse every 100us if not present, up to N tries
  if (mouse_tries > 0 && !mouse_present && n - tm > 100) {
    mouse_tries--;
    Serial.print(F("Retry mouse init: ")); Serial.println(mouse_tries);
    init_mouse();
    Serial.print(F("Mouse: ")); Serial.println(mouse_present);
    tm = n;
  }

  // polling for mouse data
  #if MOUSE_POLL_TYPE == 1
  if (mouse_present && n - t > MOUSE_POLL_INTERVAL) {

    MouseData m = mice.readData();

    mouse_new_packet = !mouse_new_packet;
    mouse_x = m.position.x;
    mouse_y = m.position.y;
    mouse_z = m.wheel;

    ms_btn1 = bitRead(m.status, 0);
    ms_btn2 = bitRead(m.status, 1);
    ms_btn3 = bitRead(m.status, 2);
    bitWrite(mouse_z, 4, is_mouse_swap ? ms_btn2 : ms_btn1); // left
    bitWrite(mouse_z, 5, is_mouse_swap ? ms_btn1 : ms_btn2); // right
    bitWrite(mouse_z, 6, ms_btn3); // middle
    bitWrite(mouse_z, 7, mouse_new_packet);

    transmit_mouse_data();

    if (osd_overlay) {
      osd_update_mouse();
    }

    t = n;
  }
  #else
  // mouse stream report read
  if (mice.reportAvailable() > 0 ) {
    MouseData m = mice.readReport();

    //if ((bitRead(m.status, 3) == 1) and (bitRead(m.status, 6) == 0) and (bitRead(m.status,7)== 0)) {
      mouse_new_packet = !mouse_new_packet;
      mouse_x = m.position.x;
      mouse_y = m.position.y;
      mouse_z = m.wheel;
  
      ms_btn1 = bitRead(m.status, 0);
      ms_btn2 = bitRead(m.status, 1);
      ms_btn3 = bitRead(m.status, 2);
      bitWrite(mouse_z, 4, is_mouse_swap ? ms_btn2 : ms_btn1); // left
      bitWrite(mouse_z, 5, is_mouse_swap ? ms_btn1 : ms_btn2); // right
      bitWrite(mouse_z, 6, ms_btn3); // middle
      bitWrite(mouse_z, 7, mouse_new_packet);
  
      transmit_mouse_data();    

      if (osd_overlay) {
        osd_update_mouse();
      }
    //}
  }

  #endif

  // swap mouse buttons
  if (mouse_present && n - ts > MOUSE_SWAP_INTERVAL) {
    if ((is_menu || is_win || (is_ctrl && is_alt)) && ms_btn1) {
      is_mouse_swap = !is_mouse_swap;
      eeprom_store_value(EEPROM_MOUSE_SWAP_ADDRESS, is_mouse_swap);
      update_led(PIN_LED1, HIGH);
      delay(100);
      update_led(PIN_LED1, LOW);
      delay(100);
      update_led(PIN_LED1, HIGH);
      delay(100);
      update_led(PIN_LED1, LOW);
    }
    ts = n;
  }

  // control led1
#if ALLOW_LED_OVERRIDE
  if (led1_overwrite) {
    if (led1_state == 1) {
      update_led(PIN_LED1, HIGH);
    }
    if (n - tl1 >= 100) {
      tl1 = n;
      if (led1_state == false) {
        update_led(PIN_LED1, LOW);
      }
    }
  }

  // control led2
  if (led2_overwrite) {
      if (led2_state == 1) {
        update_led(PIN_LED2, HIGH);
      }
      if (n - tl2 >= 100) {
        tl2 = n;
        if (led2_state == false) {
          update_led(PIN_LED2, LOW);
        }
    }
  }
#else 
  if (is_wait) {
    if (n - tl2 >= 500) {
      tl2 = n;
      blink_state = !blink_state;
      update_led(PIN_LED2, blink_state);
    }
  } else {
    update_led(PIN_LED2, HIGH);
  }

  if (n - tl >= 100) {
    update_led(PIN_LED1, LOW);
  }
#endif

// reset pressed keys for OSD
cursor_up = false;
cursor_down = false;
cursor_left = false;
cursor_right = false;
is_enter = false;
is_esc = false;

delayMicroseconds(1);

}
