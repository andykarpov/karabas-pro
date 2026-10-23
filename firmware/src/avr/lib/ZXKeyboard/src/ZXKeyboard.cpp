/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

// STL headers
// C headers
#include <avr/pgmspace.h>
// Framework headers
#include <hal.h>
#include <ZXKeyboard.h>
#include "ZXKeyboardMap.h"

/****************************************************************************/

ZXKeyboard::ZXKeyboard(void)
{
}

/****************************************************************************/

void ZXKeyboard::begin(spi_cb act, event_cb evt, bool send_echo)
{
  action = act;
  event = evt;

  pinMode(PIN_KBD_CLK, INPUT_PULLUP);
  pinMode(PIN_KBD_DAT, INPUT_PULLUP);

  kbd.begin(PIN_KBD_DAT, PIN_KBD_CLK);

  // send echo command on start - to force USB keyboards work as ps/2
  if (send_echo) {
    kbd.echo(); // ping keyboard to see if there
    delay(6);
    uint16_t c = kbd.read();
    if( (c & 0xFF) == PS2_KEY_ECHO || (c & 0xFF) == PS2_KEY_BAT ) {
      // Response was Echo or power up
      //kbd.setNoBreak(0);
      //kbd.setNoRepeat(0);
      //kbd.typematic(0xb, 1);
      kbd.setLock(PS2_LOCK_SCROLL);
    }
  }

  // clear full matrix
  clear(ZX_MATRIX_FULL_SIZE);

  // restore saved modes from EEPROM
  eepromRestoreValues();
  is_started = true;
}

bool ZXKeyboard::started() {
  return is_started;
}

/****************************************************************************/

void ZXKeyboard::handle(void)
{
  unsigned long n = millis();
  uint16_t c = 0;

	if (kbd.available()) {
    c = kbd.read();
    fill(c, n);
    event(EVENT_OSD_SCANCODE, c);
  }

  // process delayed sequences
  processDelayedKeypress();
}

void ZXKeyboard::setKey(uint8_t key, bool pressed)
{
  if (key < ZX_MATRIX_FULL_SIZE) {
    matrix[key] = pressed;
  }
}

bool ZXKeyboard::getKey(uint8_t key)
{
  if (key < ZX_MATRIX_FULL_SIZE) {
    return matrix[key];
  } else {
    return false;
  }
}

/* ------------------------------------------------------------ */

void ZXKeyboard::pushCapsedKey(int key)
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
  if (!found && capsed_keys_size < 10) {
    capsed_keys[capsed_keys_size] = key;
    capsed_keys_size++;
  }
}

void ZXKeyboard::popCapsedKey(int key)
{
  int i = 0;
  int j = 0;
  int tmp_array[10] = {0,0,0,0,0,0,0,0,0,0};
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

void ZXKeyboard::processCapsedKey(int key, bool up)
{
  if (!up) {
    pushCapsedKey(key);
  } else {
    popCapsedKey(key);
  }
}

void ZXKeyboard::toggleOsdOverlay() {
  osd_overlay = !osd_overlay;
  matrix[ZX_K_OSD_OVERLAY] = osd_overlay;
  // re-init osd
  if (osd_overlay) {
    event(EVENT_OSD_OVERLAY, 0);
  }
}

void ZXKeyboard::setOsdPopup(bool value) {
  osd_popup = value;
  matrix[ZX_K_OSD_POPUP] = osd_popup;
  // re-init osd
  if (osd_popup) {
    event(EVENT_OSD_POPUP, 0);
  }
}

void ZXKeyboard::setRombank(uint8_t bank) {
  switch (bank) {
    case 0: is_sw3 = false; is_sw4 = false; break;
    case 1: is_sw3 = true; is_sw4 = false; break;
    case 2: is_sw3 = false; is_sw4 = true; break;
    case 3: is_sw3 = true; is_sw4 = true; break;
  }
  eepromStoreBool(EEPROM_SW3_ADDRESS, is_sw3);
  eepromStoreBool(EEPROM_SW4_ADDRESS, is_sw4);
  matrix[ZX_K_SW3] = is_sw3;
  matrix[ZX_K_SW4] = is_sw4;
}

void ZXKeyboard::toggleTurbofdc() {
  // menu + F5 = SW5
  is_sw5 = !is_sw5;
  eepromStoreBool(EEPROM_SW5_ADDRESS, is_sw5);
  matrix[ZX_K_SW5] = is_sw5;
}

void ZXKeyboard::toggleCovox() {
  // menu + F6 = SW6
  is_sw6 = !is_sw6;
  eepromStoreBool(EEPROM_SW6_ADDRESS, is_sw6);
  matrix[ZX_K_SW6] = is_sw6;
}

void ZXKeyboard::toggleStereo(uint8_t stereo) {

  is_sw7 = bitRead(stereo, 0);
  is_sw9 = bitRead(stereo, 1);

  eepromStoreBool(EEPROM_SW7_ADDRESS, is_sw7);
  eepromStoreBool(EEPROM_SW9_ADDRESS, is_sw9);
  matrix[ZX_K_SW7] = is_sw7;
  matrix[ZX_K_SW9] = is_sw9;
}

void ZXKeyboard::toggleSsg() {
  // menu + F8 = SW8
  is_sw8 = !is_sw8;
  eepromStoreBool(EEPROM_SW8_ADDRESS, is_sw8);
  matrix[ZX_K_SW8] = is_sw8;
}

void ZXKeyboard::toggleVideo() {
    // menu + F9 = SW1
  is_sw1 = !is_sw1;
  eepromStoreBool(EEPROM_SW1_ADDRESS, is_sw1);
  matrix[ZX_K_SW1] = is_sw1;
}

void ZXKeyboard::toggleVsync() {
  // menu + F10 = SW2
  is_sw2 = !is_sw2;
  eepromStoreBool(EEPROM_SW2_ADDRESS, is_sw2);
  matrix[ZX_K_SW2] = is_sw2;
}

void ZXKeyboard::setTurbo(uint8_t val) {
  // menu + F11 = turbo swith 0 1 2 3
  turbo = val;
  hal_eeprom_update(EEPROM_TURBO_ADDRESS, turbo);
  matrix[ZX_K_TURBO] = bitRead(turbo, 0);
  matrix[ZX_K_TURBO2] = bitRead(turbo, 1);
}

void ZXKeyboard::setMaxTurbo(uint8_t val) {
  max_turbo = val;
  if (turbo > max_turbo) {
    setTurbo(max_turbo);
  }
}

void ZXKeyboard::toggleSwapAB() {
    // menu + TAB = SW10
  is_sw10 = !is_sw10;
  eepromStoreBool(EEPROM_SW10_ADDRESS, is_sw10);
  matrix[ZX_K_SW10] = is_sw10;
}

void ZXKeyboard::toggleJoyType() {
  // menu + J = JOY_TYPE
  joy_type = !joy_type;
  eepromStoreBool(EEPROM_JOY_TYPE_ADDRESS, joy_type);
  matrix[ZX_K_JOY_TYPE] = joy_type;
}

void ZXKeyboard::toggleKeyboardType() {
  profi_mode = !profi_mode;
  eepromStoreBool(EEPROM_MODE_ADDRESS, profi_mode);
  matrix[ZX_K_KBD_MODE] = profi_mode;
}

void ZXKeyboard::setScreenMode(uint8_t val) {
  val = constrain(val, 0, max_screen_mode);
  screen_mode = val;
  hal_eeprom_update(EEPROM_SCREEN_MODE_ADDRESS, val);
  matrix[ZX_K_SCREEN_MODE0] = bitRead(val, 0);
  matrix[ZX_K_SCREEN_MODE1] = bitRead(val, 1);
}

void ZXKeyboard::setJoyMode(uint8_t val) {
  val = constrain(val, 0, 4);
  joy_mode = val;
  hal_eeprom_update(EEPROM_JOY_MODE_ADDRESS, val);
  matrix[ZX_K_JOY_MODE0] = bitRead(val, 0);
  matrix[ZX_K_JOY_MODE1] = bitRead(val, 1);
  matrix[ZX_K_JOY_MODE2] = bitRead(val, 2);
}

void ZXKeyboard::setDivmmc(bool value) {
  is_divmmc = value;
  eepromStoreBool(EEPROM_DIVMMC_ADDRESS, is_divmmc);
  matrix[ZX_K_DIVMMC] = is_divmmc;
}

void ZXKeyboard::toggleDivmmc() {
  is_divmmc = !is_divmmc;
  setDivmmc(is_divmmc);
}

void ZXKeyboard::setNemoIDE(bool value) {
  is_nemoide = value;
  eepromStoreBool(EEPROM_NEMOIDE_ADDRESS, is_nemoide);
  matrix[ZX_K_NEMOIDE] = is_nemoide;
}

void ZXKeyboard::toggleNemoIDE() {
  is_nemoide = !is_nemoide;
  setNemoIDE(is_nemoide);
}


bool ZXKeyboard::handleHotkey(uint8_t code, unsigned long n, bool is_up)
{
  if (!getIsMenu()) return false;

  for (uint8_t i = 0; i < HOTKEY_COUNT; i++) {
    uint8_t hk_code = pgm_read_byte(&s_hotkey_map[i].code);
    if (hk_code == code) {
      if (!is_up) {
        uint8_t action = pgm_read_byte(&s_hotkey_map[i].action);
        switch (action) {
          case HK_OSD_OVERLAY:
            if (n - tosd > 200) {
              toggleOsdOverlay();
              tosd = n;
            }
            break;
          case HK_SWAP_AB:
            toggleSwapAB();
            event(EVENT_OSD_SWAP_AB, 0);
            break;
          case HK_DIVMMC:
            toggleDivmmc();
            event(EVENT_OSD_DIVMMC, 0);
            break;
          case HK_JOYSTICK:
            toggleJoyType();
            event(EVENT_OSD_JOYSTICK, 0);
            break;
          case HK_JOYSTICK_MODE:
            joy_mode = (joy_mode < 4) ? joy_mode + 1 : 0;
            setJoyMode(joy_mode);
            event(EVENT_OSD_JOYSTICK_MODE, 0);
            break;
          case HK_NEMOIDE:
            toggleNemoIDE();
            event(EVENT_OSD_NEMOIDE, 0);
            break;
          case HK_SCREEN_MODE:
            screen_mode = (screen_mode < max_screen_mode) ? screen_mode + 1 : 0;
            setScreenMode(screen_mode);
            event(EVENT_OSD_SCREEN_MODE, 0);
            break;
          case HK_ROMBANK_0:
          case HK_ROMBANK_1:
          case HK_ROMBANK_2:
          case HK_ROMBANK_3: {
            uint8_t b = action - HK_ROMBANK_0;
            setRombank(b);
            event(EVENT_OSD_ROMBANK, b);
            break;
          }
          case HK_TURBOFDC:
            toggleTurbofdc();
            event(EVENT_OSD_TURBOFDC, 0);
            break;
          case HK_COVOX:
            toggleCovox();
            event(EVENT_OSD_COVOX, 0);
            break;
          case HK_STEREO: {
            uint8_t stereo = (is_sw7 ? 1 : 0) | (is_sw9 ? 2 : 0);
            stereo = (stereo < 2) ? stereo + 1 : 0;
            toggleStereo(stereo);
            event(EVENT_OSD_STEREO, 0);
            break;
          }
          case HK_SSG:
            toggleSsg();
            event(EVENT_OSD_SSG, 0);
            break;
          case HK_VIDEO:
            toggleVideo();
            event(EVENT_OSD_VIDEO, 0);
            break;
          case HK_VSYNC:
            toggleVsync();
            event(EVENT_OSD_VSYNC, 0);
            break;
          case HK_TURBO:
            turbo = (turbo < max_turbo) ? turbo + 1 : 0;
            setTurbo(turbo);
            event(EVENT_OSD_TURBO, turbo);
            break;
          case HK_MAGIC:
            doMagic();
            break;
        }
      }
      return true;
    }
  }
  return false;
}

// transform PS/2 scancodes into internal matrix of pressed keys
void ZXKeyboard::fill(uint16_t sc, unsigned long n)
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
    doPause();
    return;
  }

  // Check hotkeys first when modifier (Menu / Win / Ctrl+Alt) is held
  if (handleHotkey(code, n, is_up)) {
    return;
  }

  if (code < sizeof(s_key_map) / sizeof(s_key_map[0])) {
    KeyDesc desc;
    desc.type = pgm_read_byte(&s_key_map[code].type);
    desc.zx1  = pgm_read_byte(&s_key_map[code].zx1);
    desc.zx2  = pgm_read_byte(&s_key_map[code].zx2);

    switch (desc.type) {
      case KT_DIRECT:
        matrix[desc.zx1] = !is_up;
        if (desc.zx1 == ZX_K_ENT) {
          is_enter = !is_up;
        }
        break;

      case KT_COMBO:
        matrix[desc.zx1] = !is_up;
        matrix[desc.zx2] = !is_up;
        break;

      case KT_CURSOR:
        if (!is_shift) {
          if (code == PS2_KEY_UP_ARROW) cursor_up = !is_up;
          else if (code == PS2_KEY_DN_ARROW) cursor_down = !is_up;
          else if (code == PS2_KEY_L_ARROW) cursor_left = !is_up;
          else if (code == PS2_KEY_R_ARROW) cursor_right = !is_up;

          matrix[ZX_K_CS] = !is_up;
          if (!is_up) { sendCS(); }
          matrix[desc.zx1] = !is_up;
          processCapsedKey(code, is_up);
        }
        break;

      case KT_SHIFT_PAIR:
        matrix[ZX_K_SS] = !is_up;
        matrix[is_shift ? desc.zx2 : desc.zx1] = !is_up;
        if (is_up) {
          matrix[desc.zx1] = false;
          matrix[desc.zx2] = false;
        }
        is_ss_used = is_shift;
        break;

      case KT_MACRO_BRACKET: {
        uint8_t zx = is_shift ? desc.zx2 : desc.zx1;
        if (!profi_mode) {
          if (!is_up) {
            sendMacros(code, zx);
          }
        } else {
          matrix[ZX_K_SS] = !is_up;
          matrix[zx] = !is_up;
          if (is_up) {
            matrix[desc.zx1] = false;
            matrix[desc.zx2] = false;
          }
        }
        break;
      }

      case KT_SINGLE_QUOTE:
        if (is_shift && !is_up) {
          sendMacros(code, ZX_K_A);
        }
        if (!is_shift && delayed_matrix_size == 0) {
          matrix[ZX_K_SS] = !is_up;
          matrix[ZX_K_X] = !is_up;
        }
        is_ss_used = is_shift;
        break;

      case KT_MODIFIER_SHIFT:
        matrix[profi_mode ? ZX_K_SS : ZX_K_CS] = !is_up;
        is_shift = !is_up;
        break;

      case KT_MODIFIER_CTRL:
        matrix[profi_mode ? ZX_K_CS : ZX_K_SS] = !is_up;
        is_ctrl = !is_up;
        break;

      case KT_MODIFIER_ALT:
        if (!is_ctrl || is_up) {
          matrix[ZX_K_SS] = !is_up;
          matrix[profi_mode ? desc.zx1 : ZX_K_CS] = !is_up;
          if (!profi_mode) {
            processCapsedKey(code, is_up);
          }
        }
        is_alt = !is_up;
        break;

      case KT_MODIFIER_WIN:
        is_win = !is_up;
        break;

      case KT_MODIFIER_MENU:
        is_menu = !is_up;
        break;

      case KT_EDIT_ESC:
        is_esc = !is_up;
        matrix[ZX_K_CS] = !is_up;
        matrix[profi_mode ? ZX_K_1 : ZX_K_SP] = !is_up;
        processCapsedKey(code, is_up);
        break;

      case KT_EDIT_BS:
        matrix[ZX_K_CS] = !is_up;
        matrix[ZX_K_0] = !is_up;
        processCapsedKey(code, is_up);
        is_bksp = !is_up;
        break;

      case KT_EDIT_DEL:
        if (!is_shift) {
          if (profi_mode) {
            matrix[desc.zx1] = !is_up;
            matrix[ZX_K_BIT6] = !is_up;
          } else {
            matrix[ZX_K_SS] = !is_up;
            matrix[desc.zx2] = !is_up;
          }
          is_del = !is_up;
        }
        break;

      case KT_EDIT_INS:
        if (!is_shift) {
          if (profi_mode) {
            matrix[desc.zx1] = !is_up;
            matrix[ZX_K_BIT6] = !is_up;
          } else {
            matrix[ZX_K_SS] = !is_up;
            matrix[desc.zx2] = !is_up;
          }
        }
        break;

      case KT_EDIT_TAB:
        matrix[ZX_K_CS] = !is_up;
        matrix[ZX_K_I] = !is_up;
        processCapsedKey(code, is_up);
        break;

      case KT_EDIT_CAPS:
        matrix[ZX_K_CS] = !is_up;
        matrix[ZX_K_SS] = !is_up;
        processCapsedKey(code, is_up);
        break;

      case KT_EDIT_PAGE:
        if (!is_shift) {
          if (profi_mode) {
            matrix[desc.zx1] = !is_up;
            matrix[ZX_K_BIT6] = !is_up;
          } else {
            matrix[ZX_K_CS] = !is_up;
            matrix[desc.zx2] = !is_up;
            processCapsedKey(code, is_up);
          }
        }
        break;

      case KT_EDIT_HOME_END:
        if (!is_shift) {
          matrix[desc.zx1] = !is_up;
          matrix[desc.zx2] = !is_up;
        }
        break;

      case KT_SPECIAL_PAUSE:
        doPause();
        break;

      case KT_SPECIAL_PRTSCR:
        if (!is_shift && !is_up) {
          toggleKeyboardType();
          event(EVENT_OSD_KEYBOARD_TYPE, 0);
        }
        break;

      default:
        break;
    }
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
    doReset();
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
    doFullReset();
  }
}

void ZXKeyboard::sendCS() {
  // send 2 bytes of the keyboard matrix with CS pressed
#if SEND_ECHO_ON_START
#else
  uint8_t cs_data = getMatrixByte(0);
  uint8_t end_data = getMatrixByte(5);
  action(CMD_KBD, 1, cs_data);
  action(CMD_KBD, 6, end_data);
  delay(20);
#endif
}

void ZXKeyboard::delayedKeypress(uint8_t code, uint8_t zxkey1, uint8_t zxkey2, bool up) {
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

void ZXKeyboard::processDelayedKeypress()
{
  if (delayed_matrix_size == 0) return;

  unsigned long tnow = millis();

  // send pressed/released keys
  for (uint8_t i=0; i<delayed_matrix_size; i++) {
    if (delayed_matrix[i].timestamp <= tnow) {
        matrix[delayed_matrix[i].zxkey] = !delayed_matrix[i].up;
        if (delayed_matrix[i].zxkey == ZX_K_CS) {
          processCapsedKey(delayed_matrix[i].key, delayed_matrix[i].up);
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
void ZXKeyboard::sendMacros(uint8_t code, uint8_t zxkey)
{
  if (delayed_matrix_size > 0) return;

  unsigned long tnow = millis();
  uint8_t kdelay = 250; // 50 ms

  // CS on
  delayed_matrix[delayed_matrix_size].timestamp = tnow;
  delayed_matrix[delayed_matrix_size].up = false;
  delayed_matrix[delayed_matrix_size].zxkey = ZX_K_CS;
  delayed_matrix[delayed_matrix_size].key = code;
  delayed_matrix_size++;

  // SS on
  delayed_matrix[delayed_matrix_size].timestamp = tnow + kdelay; 
  delayed_matrix[delayed_matrix_size].up = false;
  delayed_matrix[delayed_matrix_size].zxkey = ZX_K_SS;
  delayed_matrix[delayed_matrix_size].key = code;
  delayed_matrix_size++;

  // SS off
  delayed_matrix[delayed_matrix_size].timestamp = tnow + kdelay + kdelay; 
  delayed_matrix[delayed_matrix_size].up = true;
  delayed_matrix[delayed_matrix_size].zxkey = ZX_K_SS;
  delayed_matrix[delayed_matrix_size].key = code;
  delayed_matrix_size++;

  // key on
  delayed_matrix[delayed_matrix_size].timestamp = tnow + kdelay + kdelay + kdelay; 
  delayed_matrix[delayed_matrix_size].up = false;
  delayed_matrix[delayed_matrix_size].zxkey = zxkey;
  delayed_matrix[delayed_matrix_size].key = code;
  delayed_matrix_size++;

  // key off
  delayed_matrix[delayed_matrix_size].timestamp = tnow + kdelay + kdelay + kdelay + kdelay; 
  delayed_matrix[delayed_matrix_size].up = true;
  delayed_matrix[delayed_matrix_size].zxkey = zxkey;
  delayed_matrix[delayed_matrix_size].key = code;
  delayed_matrix_size++;

  // CS off
  delayed_matrix[delayed_matrix_size].timestamp = tnow + kdelay + kdelay + kdelay + kdelay + kdelay; 
  delayed_matrix[delayed_matrix_size].up = true;
  delayed_matrix[delayed_matrix_size].zxkey = ZX_K_CS;
  delayed_matrix[delayed_matrix_size].key = code;
  delayed_matrix_size++;
}

uint8_t ZXKeyboard::getMatrixByte(uint8_t pos)
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

// transmit keyboard matrix from AVR to CPLD side via SPI
void ZXKeyboard::transmit()
{
  uint8_t bytes = ZX_MATRIX_FULL_SIZE/8; // count of bytes to send
  for (uint8_t i = 0; i < bytes; i++) {
    uint8_t data = getMatrixByte(i);
    action(CMD_KBD, i + 1, data);
  }
}

void ZXKeyboard::doSpecial(uint8_t key1, uint8_t key2)
{
  clear(ZX_MATRIX_SIZE);
  matrix[key1] = 1;
  matrix[key2] = 1;
  transmit();
  delay(100);
  clear(ZX_MATRIX_SIZE);
  matrix[key1] = 0;
  matrix[key2] = 0;
  transmit();
}

void ZXKeyboard::doReset()
{
  doSpecial(ZX_K_RESET, ZX_K_RESET);
}

void ZXKeyboard::doFullReset()
{
  clear(ZX_MATRIX_SIZE);
  matrix[ZX_K_RESET] = 1;
  transmit();
  matrix[ZX_K_SP] = 1;
  transmit();
  delay(500);
  matrix[ZX_K_RESET] = 0;
  transmit();
  delay(500);
  matrix[ZX_K_SP] = 0;
}

void ZXKeyboard::doMagic()
{
  doSpecial(ZX_K_MAGICK, ZX_K_MAGICK);
}

void ZXKeyboard::doCaps()
{
  matrix[ZX_K_SS] = true;
  matrix[ZX_K_CS] = true;
  transmit();
  delay(100);
  matrix[ZX_K_SS] = false;
  matrix[ZX_K_CS] = false;
}

void ZXKeyboard::doPause()
{
  is_wait = !is_wait;
  matrix[ZX_K_WAIT] = is_wait;
  event(EVENT_OSD_PAUSE, 0);
}

void ZXKeyboard::clear(int clear_size)
{
  // all keys up
  for (int i = 0; i < clear_size; i++) {
    matrix[i] = false;
  }
}

bool ZXKeyboard::eepromRestoreBool(int addr, bool default_value)
{
  uint8_t val;
  val = hal_eeprom_read(addr);
  if ((val == EEPROM_VALUE_TRUE) || (val == EEPROM_VALUE_FALSE)) {
    return (val == EEPROM_VALUE_TRUE) ? true : false;
  } else {
    hal_eeprom_update(addr, (default_value ? EEPROM_VALUE_TRUE : EEPROM_VALUE_FALSE));
    return default_value;
  }
}

void ZXKeyboard::eepromStoreBool(int addr, bool value)
{
  uint8_t val = (value ? EEPROM_VALUE_TRUE : EEPROM_VALUE_FALSE);
  hal_eeprom_update(addr, val);
}

uint8_t ZXKeyboard::eepromRestoreInt(int addr, uint8_t default_value)
{
  return hal_eeprom_read(addr);
}

void ZXKeyboard::eepromStoreInt(int addr, uint8_t value)
{
  hal_eeprom_update(addr, value);
}

void ZXKeyboard::eepromRestoreValues()
{
  turbo = hal_eeprom_read(EEPROM_TURBO_ADDRESS);
  if (turbo > max_turbo) {
    turbo = max_turbo;
    hal_eeprom_update(EEPROM_TURBO_ADDRESS, turbo);
  }
  profi_mode = eepromRestoreBool(EEPROM_MODE_ADDRESS, profi_mode);
  is_sw1 = eepromRestoreBool(EEPROM_SW1_ADDRESS, is_sw1);
  is_sw2 = eepromRestoreBool(EEPROM_SW2_ADDRESS, is_sw2);
  is_sw3 = eepromRestoreBool(EEPROM_SW3_ADDRESS, is_sw3);
  is_sw4 = eepromRestoreBool(EEPROM_SW4_ADDRESS, is_sw4);
  is_sw5 = eepromRestoreBool(EEPROM_SW5_ADDRESS, is_sw5);
  is_sw6 = eepromRestoreBool(EEPROM_SW6_ADDRESS, is_sw6);
  is_sw7 = eepromRestoreBool(EEPROM_SW7_ADDRESS, is_sw7);
  is_sw8 = eepromRestoreBool(EEPROM_SW8_ADDRESS, is_sw8);
  is_sw9 = eepromRestoreBool(EEPROM_SW9_ADDRESS, is_sw9);
  is_sw10 = eepromRestoreBool(EEPROM_SW10_ADDRESS, is_sw10);
  is_mouse_swap = eepromRestoreBool(EEPROM_MOUSE_SWAP_ADDRESS, is_mouse_swap);
  joy_type = eepromRestoreBool(EEPROM_JOY_TYPE_ADDRESS, joy_type);
  screen_mode = hal_eeprom_read(EEPROM_SCREEN_MODE_ADDRESS);
  if (screen_mode > max_screen_mode) {
    screen_mode = 0;
    hal_eeprom_update(EEPROM_SCREEN_MODE_ADDRESS, 0);
  }
  screen_mode = constrain(screen_mode, 0, max_screen_mode);
  joy_mode = hal_eeprom_read(EEPROM_JOY_MODE_ADDRESS);
  if (joy_mode > 4) {
    joy_mode = 0;
    hal_eeprom_update(EEPROM_JOY_MODE_ADDRESS, 0);
  }
  joy_mode = constrain(joy_mode, 0, 4);
  is_divmmc = eepromRestoreBool(EEPROM_DIVMMC_ADDRESS, is_divmmc);
  is_nemoide = eepromRestoreBool(EEPROM_NEMOIDE_ADDRESS, is_nemoide);
  
  // apply restored values
  matrix[ZX_K_TURBO] = bitRead(turbo, 0);
  matrix[ZX_K_TURBO2] = bitRead(turbo, 1);
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
  matrix[ZX_K_SCREEN_MODE0] = bitRead(screen_mode, 0);
  matrix[ZX_K_SCREEN_MODE1] = bitRead(screen_mode, 1);
  matrix[ZX_K_JOY_MODE0] = bitRead(joy_mode, 0);
  matrix[ZX_K_JOY_MODE1] = bitRead(joy_mode, 1);
  matrix[ZX_K_JOY_MODE2] = bitRead(joy_mode, 2);
  matrix[ZX_K_DIVMMC] = is_divmmc;
  matrix[ZX_K_NEMOIDE] = is_nemoide;
}

  bool ZXKeyboard::getIsOsdOverlay() {
    return osd_overlay;
  }

  bool ZXKeyboard::getIsOsdPopup() {
    return osd_popup;
  }

  uint8_t ZXKeyboard::getRombank() {
    uint8_t rombank = 0;
    bitWrite(rombank, 0, is_sw3);
    bitWrite(rombank, 1, is_sw4);
    return rombank;
  }

  bool ZXKeyboard::getTurbofdc() {
    return is_sw5;
  }

  bool ZXKeyboard::getCovox() {
    return is_sw6;
  }

  uint8_t ZXKeyboard::getStereo() {
    uint8_t stereo = 0;
    bitWrite(stereo, 0, is_sw7);
    bitWrite(stereo, 1, is_sw9);
    return stereo;
  }

  bool ZXKeyboard::getSsg() {
    return is_sw8;
  }

  bool ZXKeyboard::getVideo() {
    return is_sw1;
  }

  bool ZXKeyboard::getVsync() {
    return is_sw2;
  }

  uint8_t ZXKeyboard::getTurbo() {
    if (turbo > max_turbo) {
      setTurbo(max_turbo);
    }
    return turbo;
  }

  uint8_t ZXKeyboard::getMaxTurbo() {
    return max_turbo;
  }

  bool ZXKeyboard::getSwapAB() {
    return is_sw10;
  }

  bool ZXKeyboard::getJoyType() {
    return joy_type;
  }

  bool ZXKeyboard::getKeyboardType() {
    return profi_mode;
  }

  uint8_t ZXKeyboard::getScreenMode() {
    return screen_mode;
  }

  uint8_t ZXKeyboard::getMaxScreenMode() {
    return max_screen_mode;
  }

  uint8_t ZXKeyboard::getJoyMode() {
    return joy_mode;
  }

  bool ZXKeyboard::getDivmmc() {
    return is_divmmc;
  }

  bool ZXKeyboard::getNemoIDE() {
    return is_nemoide;
  }

  bool ZXKeyboard::getPause() {
    return matrix[ZX_K_WAIT];
  }

  bool ZXKeyboard::getIsCursorUp() {
    return cursor_up;
  }

  bool ZXKeyboard::getIsCursorDown() {
    return cursor_down;
  }

  bool ZXKeyboard::getIsCursorLeft() {
    return cursor_left;
  }

  bool ZXKeyboard::getIsCursorRight() {
    return cursor_right;
  }

  bool ZXKeyboard::getIsEnter() {
    return is_enter;
  }

  bool ZXKeyboard::getIsEscape() {
    return is_esc;
  }

  void ZXKeyboard::resetOsdControls() {
    cursor_up = false;
    cursor_down = false;
    cursor_left = false;
    cursor_right = false;
    is_enter = false;
    is_esc = false;
  }

  void ZXKeyboard::setMouseSwap(bool value) {
    is_mouse_swap = value;
      eepromStoreBool(EEPROM_MOUSE_SWAP_ADDRESS, is_mouse_swap);
  }

  bool ZXKeyboard::getMouseSwap() {
    return is_mouse_swap;
  }

  bool ZXKeyboard::getIsMenu() {
    return is_menu || is_win || (is_ctrl && is_alt);
  }


/****************************************************************************/

// Preinstantiate Objects //////////////////////////////////////////////////////

ZXKeyboard zxkbd = ZXKeyboard();

// vim:cin:ai:sts=2 sw=2 ft=cpp
