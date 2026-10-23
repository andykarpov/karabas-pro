#include "keyboard.h"
#include "keyboard_map.h"
#include "ps2_kbd.h"
#include "hal.h"
#include "zxosd.h"
#include <avr/pgmspace.h>
#include <avr/eeprom.h>

const uint8_t default_eeprom[] __attribute__((used, section(".eeprom"))) = {
  0,                  // 0x00: EEPROM_TURBO_ADDRESS
  EEPROM_VALUE_TRUE,  // 0x01: EEPROM_MODE_ADDRESS (profi_mode = true)
  EEPROM_VALUE_FALSE, // 0x02: EEPROM_SW1_ADDRESS
  EEPROM_VALUE_FALSE, // 0x03: EEPROM_SW2_ADDRESS
  EEPROM_VALUE_FALSE, // 0x04: EEPROM_SW3_ADDRESS
  EEPROM_VALUE_FALSE, // 0x05: EEPROM_SW4_ADDRESS
  EEPROM_VALUE_FALSE, // 0x06: EEPROM_SW5_ADDRESS
  EEPROM_VALUE_FALSE, // 0x07: EEPROM_SW6_ADDRESS
  EEPROM_VALUE_FALSE, // 0x08: EEPROM_SW7_ADDRESS
  EEPROM_VALUE_FALSE, // 0x09: EEPROM_SW8_ADDRESS
  EEPROM_VALUE_FALSE, // 0x0A: EEPROM_SW9_ADDRESS
  EEPROM_VALUE_FALSE, // 0x0B: EEPROM_SW10_ADDRESS
  EEPROM_VALUE_FALSE, // 0x0C: EEPROM_MOUSE_SWAP_ADDRESS
  EEPROM_VALUE_FALSE, // 0x0D: EEPROM_JOY_TYPE_ADDRESS
  0,                  // 0x0E: EEPROM_SCREEN_MODE_ADDRESS
  0,                  // 0x0F: EEPROM_JOY_MODE_ADDRESS
  EEPROM_VALUE_FALSE, // 0x10: EEPROM_DIVMMC_ADDRESS
  EEPROM_VALUE_FALSE, // 0x11: EEPROM_NEMOIDE_ADDRESS
  EEPROM_VALUE_FALSE, // 0x12: EEPROM_LED_OVERRIDE_ADDRESS (20 = disabled for Rev D+)
  EEPROM_VALUE_TRUE,  // 0x13: EEPROM_HW_BUTTONS_ADDRESS  (10 = enabled)
};

static bool s_is_started = false;
static bool s_kbd_detected = false;
static uint32_t s_last_probe_time = 0;
static uint32_t s_last_activity_time = 0;

static bool s_is_led_override = false;
static bool s_use_hw_buttons = true;

static bool s_matrix[ZX_MATRIX_FULL_SIZE];
static bool s_profi_mode = true;
static uint8_t s_turbo = 0;
static uint8_t s_max_turbo = 3;
static uint8_t s_screen_mode = 0;
static uint8_t s_max_screen_mode = 1;
static bool s_is_mouse_swap = false;

static bool s_is_menu = false;
static bool s_is_win = false;
static bool s_is_ctrl = false;
static bool s_is_alt = false;

static bool s_is_sw1 = false;
static bool s_is_sw2 = false;
static bool s_is_sw3 = false;
static bool s_is_sw4 = false;
static bool s_is_sw5 = false;
static bool s_is_sw6 = false;
static bool s_is_sw7 = false;
static bool s_is_sw8 = false;
static bool s_is_sw9 = false;
static bool s_is_sw10 = false;

static bool s_joy_type = false;
static uint8_t s_joy_mode = 0;
static bool s_is_divmmc = false;
static bool s_is_nemoide = false;
static bool s_is_wait = false;
static bool s_osd_overlay = false;
static bool s_osd_popup = false;
static uint32_t s_tosd = 0;

static bool s_cursor_up = false;
static bool s_cursor_down = false;
static bool s_cursor_left = false;
static bool s_cursor_right = false;
static bool s_is_enter = false;
static bool s_is_esc = false;

static int s_capsed_keys[10] = {0};
static int s_capsed_keys_size = 0;

typedef struct {
  uint8_t key;
  uint8_t zxkey;
  uint32_t timestamp;
  bool up;
} delayed_matrix_t;

static delayed_matrix_t s_delayed_matrix[8];
static uint8_t s_delayed_matrix_size = 0;

static void push_capsed_key(int key)
{
  for (int i = 0; i < s_capsed_keys_size; i++) {
    if (s_capsed_keys[i] == key) return;
  }
  if (s_capsed_keys_size < 10) {
    s_capsed_keys[s_capsed_keys_size++] = key;
  }
}

static void pop_capsed_key(int key)
{
  int j = 0;
  int tmp[10];
  for (int i = 0; i < s_capsed_keys_size; i++) {
    if (s_capsed_keys[i] != key) {
      tmp[j++] = s_capsed_keys[i];
    }
  }
  for (int i = 0; i < j; i++) {
    s_capsed_keys[i] = tmp[i];
  }
  s_capsed_keys_size = j;
}

static void process_capsed_key(int key, bool up)
{
  if (!up) push_capsed_key(key);
  else pop_capsed_key(key);
}

static bool eeprom_restore_bool(int addr, bool default_val)
{
  uint8_t val = hal_eeprom_read(addr);
  if (val == EEPROM_VALUE_TRUE || val == EEPROM_VALUE_FALSE) {
    return (val == EEPROM_VALUE_TRUE);
  }
  hal_eeprom_update(addr, default_val ? EEPROM_VALUE_TRUE : EEPROM_VALUE_FALSE);
  return default_val;
}

static void eeprom_store_bool(int addr, bool val)
{
  hal_eeprom_update(addr, val ? EEPROM_VALUE_TRUE : EEPROM_VALUE_FALSE);
}

static void eeprom_restore_values(void)
{
  s_turbo = hal_eeprom_read(EEPROM_TURBO_ADDRESS);
  if (s_turbo > s_max_turbo) {
    s_turbo = s_max_turbo;
    hal_eeprom_update(EEPROM_TURBO_ADDRESS, s_turbo);
  }

  s_profi_mode   = eeprom_restore_bool(EEPROM_MODE_ADDRESS, s_profi_mode);
  s_is_sw1       = eeprom_restore_bool(EEPROM_SW1_ADDRESS, s_is_sw1);
  s_is_sw2       = eeprom_restore_bool(EEPROM_SW2_ADDRESS, s_is_sw2);
  s_is_sw3       = eeprom_restore_bool(EEPROM_SW3_ADDRESS, s_is_sw3);
  s_is_sw4       = eeprom_restore_bool(EEPROM_SW4_ADDRESS, s_is_sw4);
  s_is_sw5       = eeprom_restore_bool(EEPROM_SW5_ADDRESS, s_is_sw5);
  s_is_sw6       = eeprom_restore_bool(EEPROM_SW6_ADDRESS, s_is_sw6);
  s_is_sw7       = eeprom_restore_bool(EEPROM_SW7_ADDRESS, s_is_sw7);
  s_is_sw8       = eeprom_restore_bool(EEPROM_SW8_ADDRESS, s_is_sw8);
  s_is_sw9       = eeprom_restore_bool(EEPROM_SW9_ADDRESS, s_is_sw9);
  s_is_sw10      = eeprom_restore_bool(EEPROM_SW10_ADDRESS, s_is_sw10);
  s_is_mouse_swap = eeprom_restore_bool(EEPROM_MOUSE_SWAP_ADDRESS, s_is_mouse_swap);
  s_joy_type     = eeprom_restore_bool(EEPROM_JOY_TYPE_ADDRESS, s_joy_type);

  s_screen_mode = hal_eeprom_read(EEPROM_SCREEN_MODE_ADDRESS);
  if (s_screen_mode > s_max_screen_mode) {
    s_screen_mode = 0;
    hal_eeprom_update(EEPROM_SCREEN_MODE_ADDRESS, 0);
  }

  s_joy_mode = hal_eeprom_read(EEPROM_JOY_MODE_ADDRESS);
  if (s_joy_mode > 4) {
    s_joy_mode = 0;
    hal_eeprom_update(EEPROM_JOY_MODE_ADDRESS, 0);
  }

  s_is_divmmc      = eeprom_restore_bool(EEPROM_DIVMMC_ADDRESS, s_is_divmmc);
  s_is_nemoide     = eeprom_restore_bool(EEPROM_NEMOIDE_ADDRESS, s_is_nemoide);
  s_is_led_override = eeprom_restore_bool(EEPROM_LED_OVERRIDE_ADDRESS, s_is_led_override);
  s_use_hw_buttons  = eeprom_restore_bool(EEPROM_HW_BUTTONS_ADDRESS, s_use_hw_buttons);

  // Apply restored values to matrix
  s_matrix[ZX_K_TURBO]        = bitRead(s_turbo, 0);
  s_matrix[ZX_K_TURBO2]       = bitRead(s_turbo, 1);
  s_matrix[ZX_K_SW1]          = s_is_sw1;
  s_matrix[ZX_K_SW2]          = s_is_sw2;
  s_matrix[ZX_K_SW3]          = s_is_sw3;
  s_matrix[ZX_K_SW4]          = s_is_sw4;
  s_matrix[ZX_K_SW5]          = s_is_sw5;
  s_matrix[ZX_K_SW6]          = s_is_sw6;
  s_matrix[ZX_K_SW7]          = s_is_sw7;
  s_matrix[ZX_K_SW8]          = s_is_sw8;
  s_matrix[ZX_K_SW9]          = s_is_sw9;
  s_matrix[ZX_K_SW10]         = s_is_sw10;
  s_matrix[ZX_K_KBD_MODE]     = s_profi_mode;
  s_matrix[ZX_K_JOY_TYPE]     = s_joy_type;
  s_matrix[ZX_K_SCREEN_MODE0] = bitRead(s_screen_mode, 0);
  s_matrix[ZX_K_SCREEN_MODE1] = bitRead(s_screen_mode, 1);
  s_matrix[ZX_K_JOY_MODE0]    = bitRead(s_joy_mode, 0);
  s_matrix[ZX_K_JOY_MODE1]    = bitRead(s_joy_mode, 1);
  s_matrix[ZX_K_JOY_MODE2]    = bitRead(s_joy_mode, 2);
  s_matrix[ZX_K_DIVMMC]       = s_is_divmmc;
  s_matrix[ZX_K_NEMOIDE]      = s_is_nemoide;
}

static uint8_t get_matrix_byte(uint8_t pos)
{
  uint8_t result = 0;
  for (uint8_t i = 0; i < 8; i++) {
    uint8_t k = pos * 8 + i;
    if (k < ZX_MATRIX_FULL_SIZE) {
      if (s_matrix[k]) result |= (1 << i);
    }
  }
  return result;
}

static void send_cs(void)
{
  uint8_t cs_data = get_matrix_byte(0);
  uint8_t end_data = get_matrix_byte(5);
  spi_send(CMD_KEYBOARD, 1, cs_data);
  spi_send(CMD_KEYBOARD, 6, end_data);
  delay_ms(20);
}

static void send_macros(uint8_t code, uint8_t zxkey)
{
  if (s_delayed_matrix_size > 0) return;

  uint32_t tnow = millis();
  uint8_t kdelay = 50; // 50 ms

  // CS on
  s_delayed_matrix[0].timestamp = tnow;
  s_delayed_matrix[0].up = false;
  s_delayed_matrix[0].zxkey = ZX_K_CS;
  s_delayed_matrix[0].key = code;

  // SS on
  s_delayed_matrix[1].timestamp = tnow + kdelay;
  s_delayed_matrix[1].up = false;
  s_delayed_matrix[1].zxkey = ZX_K_SS;
  s_delayed_matrix[1].key = code;

  // SS off
  s_delayed_matrix[2].timestamp = tnow + kdelay * 2;
  s_delayed_matrix[2].up = true;
  s_delayed_matrix[2].zxkey = ZX_K_SS;
  s_delayed_matrix[2].key = code;

  // key on
  s_delayed_matrix[3].timestamp = tnow + kdelay * 3;
  s_delayed_matrix[3].up = false;
  s_delayed_matrix[3].zxkey = zxkey;
  s_delayed_matrix[3].key = code;

  // key off
  s_delayed_matrix[4].timestamp = tnow + kdelay * 4;
  s_delayed_matrix[4].up = true;
  s_delayed_matrix[4].zxkey = zxkey;
  s_delayed_matrix[4].key = code;

  // CS off
  s_delayed_matrix[5].timestamp = tnow + kdelay * 5;
  s_delayed_matrix[5].up = true;
  s_delayed_matrix[5].zxkey = ZX_K_CS;
  s_delayed_matrix[5].key = code;

  s_delayed_matrix_size = 6;
}

static void process_delayed_keypress(void)
{
  if (s_delayed_matrix_size == 0) return;

  uint32_t tnow = millis();

  for (uint8_t i = 0; i < s_delayed_matrix_size; i++) {
    if (s_delayed_matrix[i].timestamp <= tnow) {
      s_matrix[s_delayed_matrix[i].zxkey] = !s_delayed_matrix[i].up;
      if (s_delayed_matrix[i].zxkey == ZX_K_CS) {
        process_capsed_key(s_delayed_matrix[i].key, s_delayed_matrix[i].up);
      }
    }
  }

  delayed_matrix_t tmp[8];
  uint8_t tmp_size = 0;
  for (uint8_t i = 0; i < s_delayed_matrix_size; i++) {
    if (s_delayed_matrix[i].timestamp > tnow) {
      tmp[tmp_size++] = s_delayed_matrix[i];
    }
  }

  for (uint8_t i = 0; i < tmp_size; i++) {
    s_delayed_matrix[i] = tmp[i];
  }
  s_delayed_matrix_size = tmp_size;

  if (s_delayed_matrix_size > 0 || s_capsed_keys_size > 0) {
    s_matrix[ZX_K_CS] = true;
  }
}

static bool handle_hotkey(uint8_t code, uint32_t n, bool is_up)
{
  if (!keyboard_get_is_menu()) return false;

  for (uint8_t i = 0; i < HOTKEY_COUNT; i++) {
    uint8_t hk_code = pgm_read_byte(&s_hotkey_map[i].code);
    if (hk_code == code) {
      if (!is_up) {
        uint8_t action = pgm_read_byte(&s_hotkey_map[i].action);
        switch (action) {
          case HK_OSD_OVERLAY:
            if (n - s_tosd > 200) {
              keyboard_toggle_osd_overlay();
              s_tosd = n;
            }
            break;
          case HK_SWAP_AB:
            keyboard_toggle_swap_ab();
            zxosd_on_key_event(EVENT_OSD_SWAP_AB);
            break;
          case HK_DIVMMC:
            keyboard_toggle_divmmc();
            zxosd_on_key_event(EVENT_OSD_DIVMMC);
            break;
          case HK_JOYSTICK:
            keyboard_toggle_joy_type();
            zxosd_on_key_event(EVENT_OSD_JOYSTICK);
            break;
          case HK_JOYSTICK_MODE:
            s_joy_mode = (s_joy_mode < 4) ? s_joy_mode + 1 : 0;
            keyboard_set_joy_mode(s_joy_mode);
            zxosd_on_key_event(EVENT_OSD_JOYSTICK_MODE);
            break;
          case HK_NEMOIDE:
            keyboard_toggle_nemoide();
            zxosd_on_key_event(EVENT_OSD_NEMOIDE);
            break;
          case HK_SCREEN_MODE:
            s_screen_mode = (s_screen_mode < s_max_screen_mode) ? s_screen_mode + 1 : 0;
            keyboard_set_screen_mode(s_screen_mode);
            zxosd_on_key_event(EVENT_OSD_SCREEN_MODE);
            break;
          case HK_ROMBANK_0:
          case HK_ROMBANK_1:
          case HK_ROMBANK_2:
          case HK_ROMBANK_3: {
            uint8_t b = action - HK_ROMBANK_0;
            keyboard_set_rombank(b);
            zxosd_on_key_event(EVENT_OSD_ROMBANK);
            break;
          }
          case HK_TURBOFDC:
            keyboard_toggle_turbofdc();
            zxosd_on_key_event(EVENT_OSD_TURBOFDC);
            break;
          case HK_COVOX:
            keyboard_toggle_covox();
            zxosd_on_key_event(EVENT_OSD_COVOX);
            break;
          case HK_STEREO: {
            uint8_t stereo = (s_is_sw7 ? 1 : 0) | (s_is_sw9 ? 2 : 0);
            stereo = (stereo < 2) ? stereo + 1 : 0;
            keyboard_toggle_stereo(stereo);
            zxosd_on_key_event(EVENT_OSD_STEREO);
            break;
          }
          case HK_SSG:
            keyboard_toggle_ssg();
            zxosd_on_key_event(EVENT_OSD_SSG);
            break;
          case HK_VIDEO:
            keyboard_toggle_video();
            zxosd_on_key_event(EVENT_OSD_VIDEO);
            break;
          case HK_VSYNC:
            keyboard_toggle_vsync();
            zxosd_on_key_event(EVENT_OSD_VSYNC);
            break;
          case HK_TURBO:
            s_turbo = (s_turbo < s_max_turbo) ? s_turbo + 1 : 0;
            keyboard_set_turbo(s_turbo);
            zxosd_on_key_event(EVENT_OSD_TURBO);
            break;
          case HK_MAGIC:
            keyboard_do_magic();
            break;
        }
      }
      return true;
    }
  }
  return false;
}

static void fill_key(uint16_t sc, uint32_t n)
{
  static bool is_del = false, is_bksp = false, is_shift = false, is_ss_used = false;

  uint8_t code = sc & 0xFF;
  uint8_t status = sc >> 8;
  bool is_up = (sc & PS2_BREAK) != 0;

  is_ss_used = false;

  s_matrix[ZX_K_IS_UP] = is_up;
  s_matrix[ZX_K_SCANCODE7] = bitRead(code, 7);
  s_matrix[ZX_K_SCANCODE6] = bitRead(code, 6);
  s_matrix[ZX_K_SCANCODE5] = bitRead(code, 5);
  s_matrix[ZX_K_SCANCODE4] = bitRead(code, 4);
  s_matrix[ZX_K_SCANCODE3] = bitRead(code, 3);
  s_matrix[ZX_K_SCANCODE2] = bitRead(code, 2);
  s_matrix[ZX_K_SCANCODE1] = bitRead(code, 1);
  s_matrix[ZX_K_SCANCODE0] = bitRead(code, 0);

  // hotfix
  if (status == 0 && code == PS2_KEY_L_SHIFT) {
    keyboard_do_pause();
    return;
  }

  if (handle_hotkey(code, n, is_up)) {
    return;
  }

  if (code < sizeof(s_key_map) / sizeof(s_key_map[0])) {
    KeyDesc desc;
    desc.type = pgm_read_byte(&s_key_map[code].type);
    desc.zx1  = pgm_read_byte(&s_key_map[code].zx1);
    desc.zx2  = pgm_read_byte(&s_key_map[code].zx2);

    switch (desc.type) {
      case KT_DIRECT:
        s_matrix[desc.zx1] = !is_up;
        if (desc.zx1 == ZX_K_ENT) s_is_enter = !is_up;
        break;

      case KT_COMBO:
        s_matrix[desc.zx1] = !is_up;
        s_matrix[desc.zx2] = !is_up;
        break;

      case KT_CURSOR:
        if (!is_shift) {
          if (code == PS2_KEY_UP_ARROW) s_cursor_up = !is_up;
          else if (code == PS2_KEY_DN_ARROW) s_cursor_down = !is_up;
          else if (code == PS2_KEY_L_ARROW) s_cursor_left = !is_up;
          else if (code == PS2_KEY_R_ARROW) s_cursor_right = !is_up;

          s_matrix[ZX_K_CS] = !is_up;
          if (!is_up) send_cs();
          s_matrix[desc.zx1] = !is_up;
          process_capsed_key(code, is_up);
        }
        break;

      case KT_SHIFT_PAIR:
        s_matrix[ZX_K_SS] = !is_up;
        s_matrix[is_shift ? desc.zx2 : desc.zx1] = !is_up;
        if (is_up) {
          s_matrix[desc.zx1] = false;
          s_matrix[desc.zx2] = false;
        }
        is_ss_used = is_shift;
        break;

      case KT_MACRO_BRACKET: {
        uint8_t zx = is_shift ? desc.zx2 : desc.zx1;
        if (!s_profi_mode) {
          if (!is_up) send_macros(code, zx);
        } else {
          s_matrix[ZX_K_SS] = !is_up;
          s_matrix[zx] = !is_up;
          if (is_up) {
            s_matrix[desc.zx1] = false;
            s_matrix[desc.zx2] = false;
          }
        }
        break;
      }

      case KT_SINGLE_QUOTE:
        if (is_shift && !is_up) {
          send_macros(code, ZX_K_A);
        }
        if (!is_shift && s_delayed_matrix_size == 0) {
          s_matrix[ZX_K_SS] = !is_up;
          s_matrix[ZX_K_X] = !is_up;
        }
        is_ss_used = is_shift;
        break;

      case KT_MODIFIER_SHIFT:
        s_matrix[s_profi_mode ? ZX_K_SS : ZX_K_CS] = !is_up;
        is_shift = !is_up;
        break;

      case KT_MODIFIER_CTRL:
        s_matrix[s_profi_mode ? ZX_K_CS : ZX_K_SS] = !is_up;
        s_is_ctrl = !is_up;
        break;

      case KT_MODIFIER_ALT:
        if (!s_is_ctrl || is_up) {
          s_matrix[ZX_K_SS] = !is_up;
          s_matrix[s_profi_mode ? desc.zx1 : ZX_K_CS] = !is_up;
          if (!s_profi_mode) process_capsed_key(code, is_up);
        }
        s_is_alt = !is_up;
        break;

      case KT_MODIFIER_WIN:
        s_is_win = !is_up;
        break;

      case KT_MODIFIER_MENU:
        s_is_menu = !is_up;
        break;

      case KT_EDIT_ESC:
        s_is_esc = !is_up;
        s_matrix[ZX_K_CS] = !is_up;
        s_matrix[s_profi_mode ? ZX_K_1 : ZX_K_SP] = !is_up;
        process_capsed_key(code, is_up);
        break;

      case KT_EDIT_BS:
        s_matrix[ZX_K_CS] = !is_up;
        s_matrix[ZX_K_0] = !is_up;
        process_capsed_key(code, is_up);
        is_bksp = !is_up;
        break;

      case KT_EDIT_DEL:
        if (!is_shift) {
          if (s_profi_mode) {
            s_matrix[desc.zx1] = !is_up;
            s_matrix[ZX_K_BIT6] = !is_up;
          } else {
            s_matrix[ZX_K_SS] = !is_up;
            s_matrix[desc.zx2] = !is_up;
          }
          is_del = !is_up;
        }
        break;

      case KT_EDIT_INS:
        if (!is_shift) {
          if (s_profi_mode) {
            s_matrix[desc.zx1] = !is_up;
            s_matrix[ZX_K_BIT6] = !is_up;
          } else {
            s_matrix[ZX_K_SS] = !is_up;
            s_matrix[desc.zx2] = !is_up;
          }
        }
        break;

      case KT_EDIT_TAB:
        s_matrix[ZX_K_CS] = !is_up;
        s_matrix[ZX_K_I] = !is_up;
        process_capsed_key(code, is_up);
        break;

      case KT_EDIT_CAPS:
        s_matrix[ZX_K_CS] = !is_up;
        s_matrix[ZX_K_SS] = !is_up;
        process_capsed_key(code, is_up);
        break;

      case KT_EDIT_PAGE:
        if (!is_shift) {
          if (s_profi_mode) {
            s_matrix[desc.zx1] = !is_up;
            s_matrix[ZX_K_BIT6] = !is_up;
          } else {
            s_matrix[ZX_K_CS] = !is_up;
            s_matrix[desc.zx2] = !is_up;
            process_capsed_key(code, is_up);
          }
        }
        break;

      case KT_EDIT_HOME_END:
        if (!is_shift) {
          s_matrix[desc.zx1] = !is_up;
          s_matrix[desc.zx2] = !is_up;
        }
        break;

      case KT_SPECIAL_PAUSE:
        keyboard_do_pause();
        break;

      case KT_SPECIAL_PRTSCR:
        if (!is_shift && !is_up) {
          keyboard_toggle_keyboard_type();
          zxosd_on_key_event(EVENT_OSD_KEYBOARD_TYPE);
        }
        break;

      default:
        break;
    }
  }

  if (is_ss_used && s_capsed_keys_size == 0) {
    s_matrix[ZX_K_CS] = false;
  }
  if (s_capsed_keys_size > 0) {
    s_matrix[ZX_K_CS] = true;
  }

  // Ctrl+Alt+Del -> RESET
  if (s_is_ctrl && s_is_alt && is_del) {
    s_is_ctrl = false;
    s_is_alt = false;
    is_del = false;
    is_shift = false;
    is_ss_used = false;
    s_capsed_keys_size = 0;
    keyboard_do_reset();
  }

  // Ctrl+Alt+Bksp -> REINIT controller
  if (s_is_ctrl && s_is_alt && is_bksp) {
    s_is_ctrl = false;
    s_is_alt = false;
    is_bksp = false;
    is_shift = false;
    is_ss_used = false;
    s_capsed_keys_size = 0;
    keyboard_do_full_reset();
  }
}

void keyboard_init(void)
{
  ps2_kbd_init();
  keyboard_clear(ZX_MATRIX_FULL_SIZE);
  eeprom_restore_values();
  s_is_started = true;
  s_kbd_detected = false;
  s_last_probe_time = 0;
  s_last_activity_time = 0;
}

bool keyboard_started(void)
{
  return s_is_started;
}

bool keyboard_handle(void)
{
  bool activity = false;
  uint32_t n = millis();

  if (ps2_kbd_available()) {
    uint16_t c = ps2_kbd_read();
    uint8_t scancode = c & 0xFF;
    if (scancode == PS2_KEY_BAT || scancode == PS2_KEY_ECHO) {
      s_kbd_detected = true;
      s_last_activity_time = n;
    } else if (scancode != 0) {
      s_kbd_detected = true;
      s_last_activity_time = n;
      fill_key(c, n);
      if (s_osd_overlay) {
        zxosd_update_scancode(c);
      }
      activity = true;
    }
  }

  // Periodic keyboard probe
  if (!s_kbd_detected) {
    if (n - s_last_probe_time >= 1500) {
      s_last_probe_time = n;
      if (!ps2_kbd_is_tx_busy()) {
        ps2_kbd_echo();
      }
    }
  } else {
    // If idle for 5s, verify keyboard is still alive (supports hot-unplug / KVM switch)
    if (n - s_last_activity_time >= 5000 && n - s_last_probe_time >= 5000) {
      s_last_probe_time = n;
      if (!ps2_kbd_is_tx_busy()) {
        ps2_kbd_echo();
      }
    }
  }

  // If TX timed out, keyboard was disconnected or unresponsive
  if (ps2_kbd_check_tx_timeout()) {
    s_kbd_detected = false;
  }

  process_delayed_keypress();
  return activity;
}

void keyboard_set_key(uint8_t key, bool pressed)
{
  if (key < ZX_MATRIX_FULL_SIZE) {
    s_matrix[key] = pressed;
  }
}

bool keyboard_get_key(uint8_t key)
{
  return (key < ZX_MATRIX_FULL_SIZE) ? s_matrix[key] : false;
}

void keyboard_clear(int clear_size)
{
  for (int i = 0; i < clear_size; i++) {
    s_matrix[i] = false;
  }
}

void keyboard_transmit(void)
{
  uint8_t bytes = ZX_MATRIX_FULL_SIZE / 8;
  for (uint8_t i = 0; i < bytes; i++) {
    uint8_t data = get_matrix_byte(i);
    spi_send(CMD_KEYBOARD, i + 1, data);
  }
}

void keyboard_do_special(uint8_t key1, uint8_t key2)
{
  keyboard_clear(ZX_MATRIX_SIZE);
  s_matrix[key1] = 1;
  s_matrix[key2] = 1;
  keyboard_transmit();
  delay_ms(100);
  keyboard_clear(ZX_MATRIX_SIZE);
  s_matrix[key1] = 0;
  s_matrix[key2] = 0;
  keyboard_transmit();
}

void keyboard_do_reset(void)
{
  keyboard_do_special(ZX_K_RESET, ZX_K_RESET);
}

void keyboard_do_full_reset(void)
{
  ps2_kbd_init();
  s_kbd_detected = false;
  s_last_probe_time = 0;
  keyboard_clear(ZX_MATRIX_SIZE);
  s_matrix[ZX_K_RESET] = 1;
  keyboard_transmit();
  s_matrix[ZX_K_SP] = 1;
  keyboard_transmit();
  delay_ms(500);
  s_matrix[ZX_K_RESET] = 0;
  keyboard_transmit();
  delay_ms(500);
  s_matrix[ZX_K_SP] = 0;
}

void keyboard_do_magic(void)
{
  keyboard_do_special(ZX_K_MAGICK, ZX_K_MAGICK);
}

void keyboard_do_caps(void)
{
  s_matrix[ZX_K_SS] = true;
  s_matrix[ZX_K_CS] = true;
  keyboard_transmit();
  delay_ms(100);
  s_matrix[ZX_K_SS] = false;
  s_matrix[ZX_K_CS] = false;
}

void keyboard_do_pause(void)
{
  s_is_wait = !s_is_wait;
  s_matrix[ZX_K_WAIT] = s_is_wait;
  zxosd_on_key_event(EVENT_OSD_PAUSE);
}

void keyboard_toggle_osd_overlay(void)
{
  s_osd_overlay = !s_osd_overlay;
  s_matrix[ZX_K_OSD_OVERLAY] = s_osd_overlay;
  if (s_osd_overlay) {
    zxosd_init_overlay();
  }
}

void keyboard_set_osd_popup(bool val)
{
  s_osd_popup = val;
  s_matrix[ZX_K_OSD_POPUP] = s_osd_popup;
}

void keyboard_set_rombank(uint8_t bank)
{
  s_is_sw3 = (bank & 1) != 0;
  s_is_sw4 = (bank & 2) != 0;
  eeprom_store_bool(EEPROM_SW3_ADDRESS, s_is_sw3);
  eeprom_store_bool(EEPROM_SW4_ADDRESS, s_is_sw4);
  s_matrix[ZX_K_SW3] = s_is_sw3;
  s_matrix[ZX_K_SW4] = s_is_sw4;
}

void keyboard_toggle_turbofdc(void)
{
  s_is_sw5 = !s_is_sw5;
  eeprom_store_bool(EEPROM_SW5_ADDRESS, s_is_sw5);
  s_matrix[ZX_K_SW5] = s_is_sw5;
}

void keyboard_toggle_covox(void)
{
  s_is_sw6 = !s_is_sw6;
  eeprom_store_bool(EEPROM_SW6_ADDRESS, s_is_sw6);
  s_matrix[ZX_K_SW6] = s_is_sw6;
}

void keyboard_toggle_stereo(uint8_t stereo)
{
  s_is_sw7 = bitRead(stereo, 0);
  s_is_sw9 = bitRead(stereo, 1);
  eeprom_store_bool(EEPROM_SW7_ADDRESS, s_is_sw7);
  eeprom_store_bool(EEPROM_SW9_ADDRESS, s_is_sw9);
  s_matrix[ZX_K_SW7] = s_is_sw7;
  s_matrix[ZX_K_SW9] = s_is_sw9;
}

void keyboard_toggle_ssg(void)
{
  s_is_sw8 = !s_is_sw8;
  eeprom_store_bool(EEPROM_SW8_ADDRESS, s_is_sw8);
  s_matrix[ZX_K_SW8] = s_is_sw8;
}

void keyboard_toggle_video(void)
{
  s_is_sw1 = !s_is_sw1;
  eeprom_store_bool(EEPROM_SW1_ADDRESS, s_is_sw1);
  s_matrix[ZX_K_SW1] = s_is_sw1;
}

void keyboard_toggle_vsync(void)
{
  s_is_sw2 = !s_is_sw2;
  eeprom_store_bool(EEPROM_SW2_ADDRESS, s_is_sw2);
  s_matrix[ZX_K_SW2] = s_is_sw2;
}

void keyboard_set_turbo(uint8_t val)
{
  s_turbo = val;
  hal_eeprom_update(EEPROM_TURBO_ADDRESS, s_turbo);
  s_matrix[ZX_K_TURBO] = bitRead(s_turbo, 0);
  s_matrix[ZX_K_TURBO2] = bitRead(s_turbo, 1);
}

void keyboard_set_max_turbo(uint8_t val)
{
  s_max_turbo = val;
  if (s_turbo > s_max_turbo) {
    keyboard_set_turbo(s_max_turbo);
  }
}

void keyboard_toggle_swap_ab(void)
{
  s_is_sw10 = !s_is_sw10;
  eeprom_store_bool(EEPROM_SW10_ADDRESS, s_is_sw10);
  s_matrix[ZX_K_SW10] = s_is_sw10;
}

void keyboard_toggle_joy_type(void)
{
  s_joy_type = !s_joy_type;
  eeprom_store_bool(EEPROM_JOY_TYPE_ADDRESS, s_joy_type);
  s_matrix[ZX_K_JOY_TYPE] = s_joy_type;
}

void keyboard_toggle_keyboard_type(void)
{
  s_profi_mode = !s_profi_mode;
  eeprom_store_bool(EEPROM_MODE_ADDRESS, s_profi_mode);
  s_matrix[ZX_K_KBD_MODE] = s_profi_mode;
}

void keyboard_set_mouse_swap(bool val)
{
  s_is_mouse_swap = val;
  eeprom_store_bool(EEPROM_MOUSE_SWAP_ADDRESS, s_is_mouse_swap);
}

bool keyboard_get_mouse_swap(void)
{
  return s_is_mouse_swap;
}

void keyboard_set_screen_mode(uint8_t val)
{
  s_screen_mode = constrain(val, 0, s_max_screen_mode);
  hal_eeprom_update(EEPROM_SCREEN_MODE_ADDRESS, s_screen_mode);
  s_matrix[ZX_K_SCREEN_MODE0] = bitRead(s_screen_mode, 0);
  s_matrix[ZX_K_SCREEN_MODE1] = bitRead(s_screen_mode, 1);
}

void keyboard_set_joy_mode(uint8_t val)
{
  s_joy_mode = constrain(val, 0, 4);
  hal_eeprom_update(EEPROM_JOY_MODE_ADDRESS, s_joy_mode);
  s_matrix[ZX_K_JOY_MODE0] = bitRead(s_joy_mode, 0);
  s_matrix[ZX_K_JOY_MODE1] = bitRead(s_joy_mode, 1);
  s_matrix[ZX_K_JOY_MODE2] = bitRead(s_joy_mode, 2);
}

void keyboard_set_divmmc(bool val)
{
  s_is_divmmc = val;
  eeprom_store_bool(EEPROM_DIVMMC_ADDRESS, s_is_divmmc);
  s_matrix[ZX_K_DIVMMC] = s_is_divmmc;
}

void keyboard_toggle_divmmc(void)
{
  keyboard_set_divmmc(!s_is_divmmc);
}

bool keyboard_get_divmmc(void)
{
  return s_is_divmmc;
}

void keyboard_set_nemoide(bool val)
{
  s_is_nemoide = val;
  eeprom_store_bool(EEPROM_NEMOIDE_ADDRESS, s_is_nemoide);
  s_matrix[ZX_K_NEMOIDE] = s_is_nemoide;
}

void keyboard_toggle_nemoide(void)
{
  keyboard_set_nemoide(!s_is_nemoide);
}

bool keyboard_get_nemoide(void)
{
  return s_is_nemoide;
}

void keyboard_set_led_override(bool val)
{
  s_is_led_override = val;
  eeprom_store_bool(EEPROM_LED_OVERRIDE_ADDRESS, val);
}

bool keyboard_get_led_override(void)
{
  return s_is_led_override;
}

void keyboard_set_hw_buttons(bool val)
{
  s_use_hw_buttons = val;
  eeprom_store_bool(EEPROM_HW_BUTTONS_ADDRESS, val);
}

bool keyboard_get_hw_buttons(void)
{
  return s_use_hw_buttons;
}

bool keyboard_get_is_osd_overlay(void) { return s_osd_overlay; }
bool keyboard_get_is_osd_popup(void)   { return s_osd_popup; }

uint8_t keyboard_get_rombank(void)
{
  uint8_t rombank = 0;
  if (s_is_sw3) rombank |= 1;
  if (s_is_sw4) rombank |= 2;
  return rombank;
}

bool keyboard_get_turbofdc(void) { return s_is_sw5; }
bool keyboard_get_covox(void)    { return s_is_sw6; }

uint8_t keyboard_get_stereo(void)
{
  uint8_t stereo = 0;
  if (s_is_sw7) stereo |= 1;
  if (s_is_sw9) stereo |= 2;
  return stereo;
}

bool keyboard_get_ssg(void)       { return s_is_sw8; }
bool keyboard_get_video(void)     { return s_is_sw1; }
bool keyboard_get_vsync(void)     { return s_is_sw2; }
uint8_t keyboard_get_turbo(void)  { return s_turbo; }
uint8_t keyboard_get_max_turbo(void) { return s_max_turbo; }
bool keyboard_get_swap_ab(void)   { return s_is_sw10; }
bool keyboard_get_joy_type(void)  { return s_joy_type; }
bool keyboard_get_keyboard_type(void) { return s_profi_mode; }
bool keyboard_get_pause(void)     { return s_matrix[ZX_K_WAIT]; }
uint8_t keyboard_get_screen_mode(void) { return s_screen_mode; }
uint8_t keyboard_get_max_screen_mode(void) { return s_max_screen_mode; }
uint8_t keyboard_get_joy_mode(void) { return s_joy_mode; }

bool keyboard_get_is_cursor_up(void)    { return s_cursor_up; }
bool keyboard_get_is_cursor_down(void)  { return s_cursor_down; }
bool keyboard_get_is_cursor_left(void)  { return s_cursor_left; }
bool keyboard_get_is_cursor_right(void) { return s_cursor_right; }
bool keyboard_get_is_enter(void)        { return s_is_enter; }
bool keyboard_get_is_escape(void)       { return s_is_esc; }

void keyboard_reset_osd_controls(void)
{
  s_cursor_up = false;
  s_cursor_down = false;
  s_cursor_left = false;
  s_cursor_right = false;
  s_is_enter = false;
  s_is_esc = false;
}

bool keyboard_get_is_menu(void)
{
  return s_is_menu || s_is_win || (s_is_ctrl && s_is_alt);
}

void keyboard_apply_joy(uint8_t data)
{
  switch (s_joy_mode) {
    case 1: // sinclair 1
      s_matrix[ZX_K_1] = bitRead(data, 1); // L
      s_matrix[ZX_K_2] = bitRead(data, 0); // R
      s_matrix[ZX_K_3] = bitRead(data, 2); // D
      s_matrix[ZX_K_4] = bitRead(data, 3); // U
      s_matrix[ZX_K_5] = bitRead(data, 4); // F
      break;
    case 2: // sinclair 2
      s_matrix[ZX_K_6] = bitRead(data, 1); // L
      s_matrix[ZX_K_7] = bitRead(data, 0); // R
      s_matrix[ZX_K_8] = bitRead(data, 2); // D
      s_matrix[ZX_K_9] = bitRead(data, 3); // U
      s_matrix[ZX_K_0] = bitRead(data, 4); // F
      break;
    case 3: // cursor
      s_matrix[ZX_K_5] = bitRead(data, 1); // L
      s_matrix[ZX_K_6] = bitRead(data, 2); // D
      s_matrix[ZX_K_7] = bitRead(data, 3); // U
      s_matrix[ZX_K_8] = bitRead(data, 0); // R
      s_matrix[ZX_K_0] = bitRead(data, 4); // F
      break;
    case 4: // qaop
      s_matrix[ZX_K_Q] = bitRead(data, 3); // U
      s_matrix[ZX_K_A] = bitRead(data, 2); // D
      s_matrix[ZX_K_O] = bitRead(data, 1); // L
      s_matrix[ZX_K_P] = bitRead(data, 0); // R
      s_matrix[ZX_K_M] = bitRead(data, 4); // F
      break;
  }
}
