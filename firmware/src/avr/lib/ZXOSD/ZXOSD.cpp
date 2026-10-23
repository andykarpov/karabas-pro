/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#include <avr/pgmspace.h>
#include <string.h>
#include <hal.h>
#include <OSD.h>
#include <ZXKeyboard.h>
#include <ZXRTC.h>
#include "ZXOSD.h"

/****************************************************************************/
// Menu Item Descriptors & Tables
/****************************************************************************/

typedef uint8_t (*menu_get_fn)();
typedef void (*menu_set_fn)(uint8_t);
typedef uint8_t (*menu_max_fn)();

struct MenuItem {
  const char *title;
  const char *hint;
  uint8_t y_pos;
  uint8_t max_val;
  const char * const *labels;
  menu_get_fn get_val;
  menu_set_fn set_val;
  menu_max_fn get_max;
};

// Item 0: ROM Bank
static uint8_t get_rombank() { return zxkbd.getRombank(); }
static void set_rombank(uint8_t v) { zxkbd.setRombank(v); }

// Item 1: Turbo FDC
static uint8_t get_turbofdc() { return zxkbd.getTurbofdc() ? 1 : 0; }
static void set_turbofdc(uint8_t) { zxkbd.toggleTurbofdc(); }

// Item 2: Covox
static uint8_t get_covox() { return zxkbd.getCovox() ? 1 : 0; }
static void set_covox(uint8_t) { zxkbd.toggleCovox(); }

// Item 3: PSG Mix (0: ACB, 1: ABC, 2: Mono)
static uint8_t get_stereo() { return zxkbd.getStereo(); }
static void set_stereo(uint8_t v) { zxkbd.toggleStereo(v); }

// Item 4: PSG Type (0: YM, 1: AY)
static uint8_t get_ssg() { return zxkbd.getSsg() ? 1 : 0; }
static void set_ssg(uint8_t) { zxkbd.toggleSsg(); }

// Item 5: Video (0: VGA, 1: RGB)
static uint8_t get_video() { return zxkbd.getVideo() ? 1 : 0; }
static void set_video(uint8_t) { zxkbd.toggleVideo(); }

// Item 6: VSync (0: 50Hz, 1: 60Hz)
static uint8_t get_vsync() { return zxkbd.getVsync() ? 1 : 0; }
static void set_vsync(uint8_t) { zxkbd.toggleVsync(); }

// Item 7: Turbo (0: Off, 1: 2x, 2: 4x, 3: 8x)
static uint8_t get_turbo() { return zxkbd.getTurbo(); }
static void set_turbo(uint8_t v) { zxkbd.setTurbo(v); }
static uint8_t get_turbo_max() { return zxkbd.getMaxTurbo(); }

// Item 8: Swap FDD (0: Off, 1: On)
static uint8_t get_swap_ab() { return zxkbd.getSwapAB() ? 1 : 0; }
static void set_swap_ab(uint8_t) { zxkbd.toggleSwapAB(); }

// Item 9: Joy Type (0: Atari, 1: Sega)
static uint8_t get_joy_type() { return zxkbd.getJoyType() ? 1 : 0; }
static void set_joy_type(uint8_t) { zxkbd.toggleJoyType(); }

// Item 10: Joy Mode (0: Kempston, 1: Sinclair1, 2: Sinclair2, 3: Cursor, 4: QAOP)
static uint8_t get_joy_mode() { return zxkbd.getJoyMode(); }
static void set_joy_mode(uint8_t v) { zxkbd.setJoyMode(v); }

// Item 11: Screen Mode (0: Pentagon, 1: Classic)
static uint8_t get_screen_mode() { return zxkbd.getScreenMode(); }
static void set_screen_mode(uint8_t v) { zxkbd.setScreenMode(v); }
static uint8_t get_screen_mode_max() { return zxkbd.getMaxScreenMode(); }

// Item 12: DivMMC (0: Off, 1: On)
static uint8_t get_divmmc() { return zxkbd.getDivmmc() ? 1 : 0; }
static void set_divmmc(uint8_t) { zxkbd.toggleDivmmc(); }

// Item 13: Nemo IDE (0: Off, 1: On)
static uint8_t get_nemoide() { return zxkbd.getNemoIDE() ? 1 : 0; }
static void set_nemoide(uint8_t) { zxkbd.toggleNemoIDE(); }

// Item 14: Keyboard Type (0: Spectrum, 1: Profi XT)
static uint8_t get_kbd_type() { return zxkbd.getKeyboardType() ? 1 : 0; }
static void set_kbd_type(uint8_t) { zxkbd.toggleKeyboardType(); }

// Item 15: Pause (0: Off, 1: On)
static uint8_t get_pause() { return zxkbd.getPause() ? 1 : 0; }
static void set_pause(uint8_t) { zxkbd.doPause(); }

// Label arrays in PROGMEM
static const char * const val_rom_bank[] PROGMEM = { msg_default, msg_pqdos, msg_flasher, msg_fdimage };
static const char * const val_on_off[] PROGMEM   = { msg_off, msg_on };
static const char * const val_psg_mix[] PROGMEM  = { msg_acb, msg_abc, msg_mono };
static const char * const val_psg_type[] PROGMEM = { msg_ym, msg_ay };
static const char * const val_video[] PROGMEM    = { msg_vga, msg_rgb };
static const char * const val_vsync[] PROGMEM    = { msg_50hz, msg_60hz };
static const char * const val_turbo[] PROGMEM    = { msg_off, msg_2x, msg_4x, msg_8x };
static const char * const val_joy_type[] PROGMEM = { msg_atari, msg_sega };
static const char * const val_joy_mode[] PROGMEM = { msg_joy_kempston, msg_joy_sinclair1, msg_joy_sinclair2, msg_joy_cursor, msg_joy_qaop };
static const char * const val_screen[] PROGMEM   = { msg_pentagon, msg_classic };
static const char * const val_keyboard[] PROGMEM = { msg_spectrum, msg_profi_xt };

static const MenuItem main_menu_items[MAIN_MENU_ITEMS_COUNT] PROGMEM = {
  { msg_rom_bank,  msg_menu_f1_f4,  5, 3, val_rom_bank, get_rombank,     set_rombank,     nullptr },
  { msg_turbofdc,  msg_menu_f5,     6, 1, val_on_off,   get_turbofdc,    set_turbofdc,    nullptr },
  { msg_covox,     msg_menu_f6,     7, 1, val_on_off,   get_covox,       set_covox,       nullptr },
  { msg_psg_mix,   msg_menu_f7,     8, 2, val_psg_mix,  get_stereo,      set_stereo,      nullptr },
  { msg_psg_type,  msg_menu_f8,     9, 1, val_psg_type, get_ssg,         set_ssg,         nullptr },
  { msg_video,     msg_menu_f9,    10, 1, val_video,    get_video,       set_video,       nullptr },
  { msg_vsync,     msg_menu_f10,   11, 1, val_vsync,    get_vsync,       set_vsync,       nullptr },
  { msg_turbo,     msg_menu_f11,   12, 3, val_turbo,    get_turbo,       set_turbo,       get_turbo_max },
  { msg_swap_fdd,  msg_menu_tab,   13, 1, val_on_off,   get_swap_ab,     set_swap_ab,     nullptr },
  { msg_joy_type,  msg_menu_j,     14, 1, val_joy_type, get_joy_type,    set_joy_type,    nullptr },
  { msg_joy_mode,  msg_menu_m,     15, 4, val_joy_mode, get_joy_mode,    set_joy_mode,    nullptr },
  { msg_screen,    msg_menu_v,     16, 1, val_screen,   get_screen_mode, set_screen_mode, get_screen_mode_max },
  { msg_divmmc,    msg_menu_d,     17, 1, val_on_off,   get_divmmc,      set_divmmc,      nullptr },
  { msg_nemoide,   msg_menu_n,     18, 1, val_on_off,   get_nemoide,     set_nemoide,     nullptr },
  { msg_keyboard,  msg_prtscr,     19, 1, val_keyboard, get_kbd_type,    set_kbd_type,    nullptr },
  { msg_pause,     msg_pause,      20, 1, val_on_off,   get_pause,       set_pause,       nullptr },
};

/****************************************************************************/
// RTC Field Descriptors & Tables
/****************************************************************************/

typedef uint16_t (*rtc_get_fn)();
typedef void (*rtc_set_fn)(uint16_t);

struct RtcField {
  const char *title;
  uint8_t y_pos;
  uint16_t min_val;
  uint16_t max_val;
  rtc_get_fn get_val;
  rtc_set_fn set_val;
};

static uint16_t get_rtc_hour()   { return zxrtc.getHour(); }
static void     set_rtc_hour(uint16_t v) { zxrtc.setHour((uint8_t)v); }

static uint16_t get_rtc_min()    { return zxrtc.getMinute(); }
static void     set_rtc_min(uint16_t v) { zxrtc.setMinute((uint8_t)v); }

static uint16_t get_rtc_sec()    { return zxrtc.getSecond(); }
static void     set_rtc_sec(uint16_t v) { zxrtc.setSecond((uint8_t)v); }

static uint16_t get_rtc_day()    { return zxrtc.getDay(); }
static void     set_rtc_day(uint16_t v) { zxrtc.setDay((uint8_t)v); }

static uint16_t get_rtc_month()  { return zxrtc.getMonth(); }
static void     set_rtc_month(uint16_t v) { zxrtc.setMonth((uint8_t)v); }

static uint16_t get_rtc_year()   { return zxrtc.getYear(); }
static void     set_rtc_year(uint16_t v) { zxrtc.setYear((int)v); }

static uint16_t get_rtc_dow()    { return zxrtc.getWeek(); }
static void     set_rtc_dow(uint16_t v) { zxrtc.setWeek((uint8_t)v); }

static const char * const val_months[] PROGMEM = {
  msg_month_jan, msg_month_feb, msg_month_mar, msg_month_apr,
  msg_month_may, msg_month_jun, msg_month_jul, msg_month_aug,
  msg_month_sep, msg_month_oct, msg_month_nov, msg_month_dec
};

// Week day: Sunday = 1, Monday = 2, ..., Saturday = 7
static const char * const val_dows[] PROGMEM = {
  msg_dow_sun, msg_dow_mon, msg_dow_tue, msg_dow_wed, msg_dow_thu, msg_dow_fri, msg_dow_sat
};

static const RtcField rtc_fields[RTC_FIELDS_COUNT] PROGMEM = {
  { msg_hours,    7,  0,    23,   get_rtc_hour,  set_rtc_hour },
  { msg_minutes,  8,  0,    59,   get_rtc_min,   set_rtc_min },
  { msg_seconds,  9,  0,    59,   get_rtc_sec,   set_rtc_sec },
  { msg_day,     11,  1,    31,   get_rtc_day,   set_rtc_day },
  { msg_month,   12,  1,    12,   get_rtc_month, set_rtc_month },
  { msg_year,    13,  2000, 4095, get_rtc_year,  set_rtc_year },
  { msg_dow,     15,  1,    7,    get_rtc_dow,   set_rtc_dow },
};

/****************************************************************************/

ZXOSD::ZXOSD(void)
{
}

void ZXOSD::begin(spi_cb act)
{
  action = act;
  tstart = millis();
  osd.begin(action);
  is_started = true;
}

bool ZXOSD::started()
{
  return is_started;
}

/****************************************************************************/
// Menu Rendering & Value Changes
/****************************************************************************/

void ZXOSD::renderMenuItem(uint8_t idx, bool is_active)
{
  if (idx >= MAIN_MENU_ITEMS_COUNT) return;

  MenuItem item;
  memcpy_P(&item, &main_menu_items[idx], sizeof(MenuItem));

  osd.setPos(0, item.y_pos);
  param(PGMT(item.title));

  renderMenuItemValue(idx, is_active);

  osd.setPos(20, item.y_pos);
  hint(PGMT(item.hint));
}

void ZXOSD::renderMenuItemValue(uint8_t idx, bool is_active)
{
  if (idx >= MAIN_MENU_ITEMS_COUNT) return;

  MenuItem item;
  memcpy_P(&item, &main_menu_items[idx], sizeof(MenuItem));

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(is_active);
    osd.setPos(10, item.y_pos);
  }

  uint8_t cur_v = item.get_val();
  uint8_t max_v = item.get_max ? item.get_max() : item.max_val;
  if (cur_v > max_v) cur_v = max_v;

  const char *lbl = (const char *)pgm_read_ptr(&item.labels[cur_v]);
  osd.print(PGMT(lbl));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);

  // Clear any remaining characters up to column 20 (9 chars total width)
  size_t len = strlen_P(lbl);
  for (size_t i = len; i < 9; i++) {
    osd.print(PGMT(msg_space));
  }
}

void ZXOSD::changeMenuItem(uint8_t idx, int8_t dir)
{
  if (idx >= MAIN_MENU_ITEMS_COUNT) return;

  MenuItem item;
  memcpy_P(&item, &main_menu_items[idx], sizeof(MenuItem));

  uint8_t max_v = item.get_max ? item.get_max() : item.max_val;
  uint8_t cur_v = item.get_val();

  if (max_v == 1) {
    // 2-state toggle
    item.set_val(cur_v ? 0 : 1);
  } else {
    // Multi-choice enum
    if (dir < 0) {
      cur_v = (cur_v == 0) ? max_v : cur_v - 1;
    } else {
      cur_v = (cur_v >= max_v) ? 0 : cur_v + 1;
    }
    item.set_val(cur_v);
  }
  renderMenuItemValue(idx, true);
}

void ZXOSD::renderRtcFieldValue(uint8_t idx, bool is_active)
{
  if (osd_state != state_rtc || idx >= RTC_FIELDS_COUNT) return;
  highlight(is_active);

  RtcField f;
  memcpy_P(&f, &rtc_fields[idx], sizeof(RtcField));
  osd.setPos(10, f.y_pos);

  uint16_t val = f.get_val();

  if (idx == 4) { // Month
    if (val >= 1 && val <= 12) {
      const char *m = (const char *)pgm_read_ptr(&val_months[val - 1]);
      osd.print(PGMT(m));
    } else {
      osd.print(PGMT(msg_unknown));
    }
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    printSpace();
  } else if (idx == 6) { // DOW
    if (val >= 1 && val <= 7) {
      const char *d = (const char *)pgm_read_ptr(&val_dows[val - 1]);
      osd.print(PGMT(d));
    } else {
      osd.print(PGMT(msg_unknown));
    }
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    printSpace();
  } else if (idx == 5) { // Year (4 digits)
    if (val < 1000) osd.print(PGMT(msg_0));
    if (val < 100)  osd.print(PGMT(msg_0));
    if (val < 10)   osd.print(PGMT(msg_0));
    osd.print(val, DEC);
  } else { // 2 digits (Hour, Minute, Second, Day)
    if (val < 10) osd.print(PGMT(msg_0));
    osd.print(val, DEC);
  }
}

void ZXOSD::changeRtcField(uint8_t idx, int8_t dir)
{
  if (idx >= RTC_FIELDS_COUNT) return;

  RtcField f;
  memcpy_P(&f, &rtc_fields[idx], sizeof(RtcField));
  int32_t val = (int32_t)f.get_val();

  if (dir < 0) {
    val = (val <= f.min_val) ? f.max_val : val - 1;
  } else {
    val = (val >= f.max_val) ? f.min_val : val + 1;
  }
  f.set_val((uint16_t)val);
  zxrtc.save();
  renderRtcFieldValue(idx, true);
}

int8_t ZXOSD::eventToMenuItem(uint8_t event_type)
{
  switch (event_type) {
    case ZXKeyboard::EVENT_OSD_ROMBANK:       return 0;
    case ZXKeyboard::EVENT_OSD_TURBOFDC:      return 1;
    case ZXKeyboard::EVENT_OSD_COVOX:         return 2;
    case ZXKeyboard::EVENT_OSD_STEREO:        return 3;
    case ZXKeyboard::EVENT_OSD_SSG:           return 4;
    case ZXKeyboard::EVENT_OSD_VIDEO:         return 5;
    case ZXKeyboard::EVENT_OSD_VSYNC:         return 6;
    case ZXKeyboard::EVENT_OSD_TURBO:         return 7;
    case ZXKeyboard::EVENT_OSD_SWAP_AB:       return 8;
    case ZXKeyboard::EVENT_OSD_JOYSTICK:      return 9;
    case ZXKeyboard::EVENT_OSD_JOYSTICK_MODE: return 10;
    case ZXKeyboard::EVENT_OSD_SCREEN_MODE:   return 11;
    case ZXKeyboard::EVENT_OSD_DIVMMC:        return 12;
    case ZXKeyboard::EVENT_OSD_NEMOIDE:       return 13;
    case ZXKeyboard::EVENT_OSD_KEYBOARD_TYPE: return 14;
    case ZXKeyboard::EVENT_OSD_PAUSE:         return 15;
    default: return -1;
  }
}

/****************************************************************************/
// State Machine & Event Handling
/****************************************************************************/

void ZXOSD::handle()
{
  if (!zxkbd.getIsOsdOverlay()) return;

  switch (osd_state) {
    case state_main:
      if (osd_prev_state != osd_state) {
        osd_prev_state = osd_state;
        osd_main_state = 0;
        osd_prev_main_state = 0;
        initOverlay();
      }

      if (zxkbd.getIsCursorDown()) {
        uint8_t prev = osd_main_state;
        osd_main_state = (osd_main_state + 1) % MAIN_MENU_ITEMS_COUNT;
        renderMenuItemValue(prev, false);
        renderMenuItemValue(osd_main_state, true);
      }
      if (zxkbd.getIsCursorUp()) {
        uint8_t prev = osd_main_state;
        osd_main_state = (osd_main_state == 0) ? (MAIN_MENU_ITEMS_COUNT - 1) : osd_main_state - 1;
        renderMenuItemValue(prev, false);
        renderMenuItemValue(osd_main_state, true);
      }

      if (zxkbd.getKey(ZX_K_S)) {
        osd_state = state_rtc;
      }
      if (zxkbd.getKey(ZX_K_A)) {
        osd_state = state_about;
      }
      if (zxkbd.getKey(ZX_K_I)) {
        osd_state = state_info;
      }

      if (zxkbd.getIsCursorLeft()) {
        changeMenuItem(osd_main_state, -1);
      }
      if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
        changeMenuItem(osd_main_state, 1);
      }
      break;

    case state_rtc:
      if (osd_prev_state != osd_state) {
        osd_prev_state = osd_state;
        osd_rtc_state = 0;
        osd_prev_rtc_state = 0;
        initRtcOverlay();
      }

      if (zxkbd.getIsCursorDown()) {
        uint8_t prev = osd_rtc_state;
        osd_rtc_state = (osd_rtc_state + 1) % RTC_FIELDS_COUNT;
        renderRtcFieldValue(prev, false);
        renderRtcFieldValue(osd_rtc_state, true);
      }
      if (zxkbd.getIsCursorUp()) {
        uint8_t prev = osd_rtc_state;
        osd_rtc_state = (osd_rtc_state == 0) ? (RTC_FIELDS_COUNT - 1) : osd_rtc_state - 1;
        renderRtcFieldValue(prev, false);
        renderRtcFieldValue(osd_rtc_state, true);
      }

      if (zxkbd.getIsEscape()) {
        osd_state = state_main;
      }

      if (zxkbd.getIsCursorLeft()) {
        changeRtcField(osd_rtc_state, -1);
      }
      if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
        changeRtcField(osd_rtc_state, 1);
      }
      break;

    case state_about:
      if (osd_prev_state != osd_state) {
        osd_prev_state = osd_state;
        initAboutOverlay();
      }
      if (zxkbd.getIsEscape()) {
        osd_state = state_main;
      }
      break;

    case state_info:
      if (osd_prev_state != osd_state) {
        osd_prev_state = osd_state;
        initInfoOverlay();
      }
      if (zxkbd.getIsEscape()) {
        osd_state = state_main;
      }
      break;
  }

  // Clear keyboard matrix in overlay mode before transmission to FPGA
  zxkbd.clear(ZX_MATRIX_SIZE);
}

/****************************************************************************/
// Screen Initialization
/****************************************************************************/

void ZXOSD::initOverlay()
{
  osd_state = state_main;
  zxkbd.setOsdPopup(false);

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  for (uint8_t i = 0; i < MAIN_MENU_ITEMS_COUNT; i++) {
    renderMenuItem(i, i == osd_main_state);
  }

  // Setup RTC / Info / About
  osd.setPos(0, 22);
  flash(PGMT(msg_s)); text(PGMT(msg_etup_rtc)); text(PGMT(msg_space));
  flash(PGMT(msg_i)); text(PGMT(msg_nfo)); flash(PGMT(msg_a)); text(PGMT(msg_bout));

  printLine(23);

  // Footer
  osd.setPos(0, 24); text(PGMT(msg_press)); hint(PGMT(msg_ctrl_alt_del)); text(PGMT(msg_to_reboot));
  osd.setPos(0, 25); text(PGMT(msg_press)); hint(PGMT(msg_menu_esc)); text(PGMT(msg_to_toggle_osd));
}

void ZXOSD::clear()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();
}

void ZXOSD::initPopup(uint8_t event_type)
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  bool is_boot = (event_type == ZXKeyboard::EVENT_OSD_POPUP);
  printLogo(0, is_boot ? 5 : 0);

  if (is_boot) return;

  int8_t item_idx = eventToMenuItem(event_type);
  if (item_idx >= 0) {
    MenuItem item;
    memcpy_P(&item, &main_menu_items[item_idx], sizeof(MenuItem));

    // Line 1: Title
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    osd.setPos(0, 5);
    osd.print(PGMT(item.title));
    printSpace();

    // Line 2: Value
    osd.setPos(0, 6);
    renderMenuItemValue((uint8_t)item_idx, false);
    printSpace();
  }
}

void ZXOSD::initRtcOverlay()
{
  zxrtc.fixInvalidTime();

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0, 5);
  text(PGMT(msg_rtc_setup));

  for (uint8_t i = 0; i < RTC_FIELDS_COUNT; i++) {
    RtcField f;
    memcpy_P(&f, &rtc_fields[i], sizeof(RtcField));
    osd.setPos(0, f.y_pos);
    param(PGMT(f.title));
    renderRtcFieldValue(i, i == osd_rtc_state);
  }

  osd.setPos(0, 17);
  text(PGMT(msg_please_use_arrows));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); osd.write(17);
  text(PGMT(msg_and));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); osd.write(16);
  osd.setPos(0, 18);
  text(PGMT(msg_to_change_values));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); osd.write(30);
  text(PGMT(msg_and));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); osd.write(31);
  osd.setPos(0, 19);
  text(PGMT(msg_to_navigate));

  popupFooter();
}

void ZXOSD::initAboutOverlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0, 5);
  text(PGMT(msg_about));

  osd.setPos(0, 7);
  osd.setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK);
  osd.print(PGMT(msg_karabas_developers_are));

  struct DevInfo { const char *name; const char *skills; };
  static const DevInfo devs[] PROGMEM = {
    { msg_dev_andykarpov, msg_dev_andykarpov_skills },
    { msg_dev_solegstar,  msg_dev_solegstar_skills },
    { msg_dev_drmax,      msg_dev_drmax_skills },
    { msg_dev_nihirash,   msg_dev_nihirash_skills }
  };

  for (uint8_t i = 0; i < 4; i++) {
    osd.setPos(0, 9 + i);
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    osd.write(250);
    const char *name = (const char *)pgm_read_ptr(&devs[i].name);
    const char *skills = (const char *)pgm_read_ptr(&devs[i].skills);
    osd.print(PGMT(name));
    hint(PGMT(skills));
  }

  osd.setPos(0, 14);
  osd.setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK);
  osd.print(PGMT(msg_special_thanks_to));

  static const char * const thanks[] PROGMEM = {
    msg_dev_kalantaj, msg_dev_tankuk, msg_dev_xdemox, msg_dev_dumpkin, msg_dev_kasper
  };

  for (uint8_t i = 0; i < 5; i++) {
    osd.setPos(0, 16 + i);
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    osd.write(250);
    const char *th = (const char *)pgm_read_ptr(&thanks[i]);
    osd.print(PGMT(th));
  }

  osd.setPos(18, 21);
  osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  osd.print(PGMT(msg_www_karabas_uk));

  popupFooter();
}

void ZXOSD::initInfoOverlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0, 5);
  text(PGMT(msg_system_info));

  uint8_t y = 14;

  osd.setPos(0, 7);
  text(PGMT(msg_fpga_build));
  osd.setPos(y, 7);
  for (uint8_t i = 0; i < 8; i++) {
    osd.write(fpga_build_num[i]);
  }

  osd.setPos(0, 8);
  text(PGMT(msg_avr_build));
  osd.setPos(y, 8);
  osd.print(avr_build_num);

  osd.setPos(0, 9);
  text(PGMT(msg_pcb_revision));
  osd.setPos(y, 9);
  printRev();

  // DAC Type
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0, 10); osd.print(PGMT(msg_dac_type));
  osd.setPos(y, 10); osd.print(PGMT(msg_tda1543));
  if (bitRead(fpga_cfg, 0) == 1) {
    osd.print(PGMT(msg_a));
  }

  // Uptime
  osd.setPos(0, 11); text(PGMT(msg_uptime));
  updateUptime();

  osd.setPos(0, 13);
  text(PGMT(msg_debug_info));

  // Scancode
  osd.setPos(0, 15); text(PGMT(msg_scancode));
  updateScancode(0);

  // Mouse
  osd.setPos(0, 16); text(PGMT(msg_mouse));
  updateMouse(0, 0, 0);

  // Joy
  osd.setPos(0, 17); text(PGMT(msg_port_1f));
  updateJoyState(0);

  popupFooter();
}

void ZXOSD::popupFooter()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  printLine(22);

  osd.setPos(0, 23);
  text(PGMT(msg_press));
  hint(PGMT(msg_esc));
  text(PGMT(msg_to_return));
}

/****************************************************************************/
// Screen Drawing Helpers
/****************************************************************************/

void ZXOSD::printLogo(uint8_t x, uint8_t y)
{
  osd.setPos(x, y);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);

  // karabas logo
  osd.write(0xb0); osd.write(0xb1); // k
  osd.write(0xb2); osd.write(0xb3); // a
  osd.write(0xb4); osd.write(0xb5); // r
  osd.write(0xb2); osd.write(0xb3); // a
  osd.write(0xb6); osd.write(0xb7); // b
  osd.write(0xb2); osd.write(0xb3); // a
  osd.write(0xb8); osd.write(0xb9); // s

  osd.setPos(x, y + 1);
  osd.write(0xc0); osd.write(0xc1); // k
  osd.write(0xc2); osd.write(0xc3); // a
  osd.write(0xc4); osd.write(0xc5); // r
  osd.write(0xc2); osd.write(0xc3); // a
  osd.write(0xc6); osd.write(0xc7); // b
  osd.write(0xc2); osd.write(0xc3); // a
  osd.write(0xc8); osd.write(0xc9); // s

  osd.setPos(x + 8, y + 2);
  osd.write(0xba); osd.write(0xbb); // p
  osd.write(0xbc); osd.write(0xbd); // r
  osd.write(0xbe); osd.write(0xbf); // o

  osd.setPos(x + 8, y + 3);
  osd.write(0xca); osd.write(0xcb); // p
  osd.write(0xcc); osd.write(0xcd); // r
  osd.write(0xce); osd.write(0xcf); // o

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  printRev();
}

void ZXOSD::printRev()
{
  uint8_t fpga_rev = ((fpga_cfg & 0b00111100) >> 2);
  switch (fpga_rev) {
    case 0x0: osd.print(PGMT(msg_rev_a));  break;
    case 0x1: osd.print(PGMT(msg_rev_ds)); break;
    case 0x9: osd.print(PGMT(msg_rev_e));  break;
    case 0xD: osd.print(PGMT(msg_rev_eu)); break;
  }
}

void ZXOSD::printLine(uint8_t y)
{
  osd.setPos(0, y);
  for (uint8_t i = 0; i < 32; i++) {
    osd.write(0x5f);
  }
}

void ZXOSD::printSpace()
{
  for (uint8_t i = 0; i < 8; i++) {
    osd.print(PGMT(msg_space));
  }
}

void ZXOSD::printHeader()
{
  printLogo(0, 0);

  osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  osd.setPos(19, 2);
  osd.print(PGMT(msg_fpga));
  for (uint8_t i = 0; i < 8; i++) {
    osd.write(fpga_build_num[i]);
  }

  osd.setPos(20, 3);
  osd.print(PGMT(msg_avr));
  osd.print(avr_build_num);

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  printLine(4);

  updateTime();
}

void ZXOSD::updateTime()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(24, 0);
  if (zxrtc.getTimeIsValid()) {
    if (zxrtc.getHour() < 10) osd.print(PGMT(msg_0));
    osd.print(zxrtc.getHour(), DEC); osd.print(PGMT(msg_colon));
    if (zxrtc.getMinute() < 10) osd.print(PGMT(msg_0));
    osd.print(zxrtc.getMinute(), DEC); osd.print(PGMT(msg_colon));
    if (zxrtc.getSecond() < 10) osd.print(PGMT(msg_0));
    osd.print(zxrtc.getSecond(), DEC);
  } else {
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_FLASH);
    osd.print(PGMT(msg_time_mask));
  }

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(22, 1);
  if (zxrtc.getDateIsValid()) {
    if (zxrtc.getDay() < 10) osd.print(PGMT(msg_0));
    osd.print(zxrtc.getDay(), DEC); osd.print(PGMT(msg_dot));
    if (zxrtc.getMonth() < 10) osd.print("0");
    osd.print(zxrtc.getMonth(), DEC); osd.print(PGMT(msg_dot));
    osd.print(zxrtc.getYear(), DEC);
  } else {
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_FLASH);
    osd.print(PGMT(msg_date_mask));
  }

  if (osd_state == state_rtc) {
    for (uint8_t i = 0; i < RTC_FIELDS_COUNT; i++) {
      renderRtcFieldValue(i, i == osd_rtc_state);
    }
  }
  if (osd_state == state_info) {
    updateUptime();
  }
}

void ZXOSD::updateUptime()
{
  unsigned long diff = (millis() - tstart) / 1000;
  unsigned long mins = diff / 60;
  unsigned long hours = mins / 60;
  unsigned long days = hours / 24;
  diff  = diff - (mins * 60);
  mins  = mins - (hours * 60);
  hours = hours - (days * 24);

  osd.setPos(14, 11);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  if (days > 0) {
    osd.print(days);
    osd.print(PGMT(days > 1 ? msg_many_days : msg_one_day));
    osd.print(PGMT(msg_and));
  }
  if (hours < 10) osd.print(PGMT(msg_0));
  osd.print(hours);
  osd.print(PGMT(msg_colon));
  if (mins < 10) osd.print(PGMT(msg_0));
  osd.print(mins);
  osd.print(PGMT(msg_colon));
  if (diff < 10) osd.print(PGMT(msg_0));
  osd.print(diff);
}

void ZXOSD::updateScancode(uint16_t c)
{
  if (osd_state != state_info) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(14, 15);
  if ((c >> 8) < 0x10) osd.print(PGMT(msg_0));
  osd.print(c >> 8, HEX);
  osd.print(PGMT(msg_space));
  if ((c & 0xFF) < 0x10) osd.print(PGMT(msg_0));
  osd.print(c & 0xFF, HEX);
}

void ZXOSD::updateMouse(uint8_t mouse_x, uint8_t mouse_y, uint8_t mouse_z)
{
  if (osd_state != state_info) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(14, 16);
  if (mouse_x < 0x10) osd.print(PGMT(msg_0));
  osd.print(mouse_x, HEX);
  osd.print(PGMT(msg_space));
  if (mouse_y < 0x10) osd.print(PGMT(msg_0));
  osd.print(mouse_y, HEX);
  osd.print(PGMT(msg_space));
  if (mouse_z < 0x10) osd.print(PGMT(msg_0));
  osd.print(mouse_z, HEX);
}

void ZXOSD::updateJoyState(uint8_t joy)
{
  if (osd_state != state_info) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(14, 17);
  if (joy < 0x10) osd.print(PGMT(msg_0));
  osd.print(joy, HEX);
}

void ZXOSD::highlight(bool val)
{
  if (val)
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);
  else
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
}

void ZXOSD::hint(const __FlashStringHelper* msg)
{
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(msg);
}

void ZXOSD::param(const __FlashStringHelper* msg)
{
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.print(msg);
  osd.print(PGMT(msg_space));
}

void ZXOSD::text(const __FlashStringHelper* msg)
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(msg);
}

void ZXOSD::flash(const __FlashStringHelper* msg)
{
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_FLASH);
  osd.print(msg);
}

void ZXOSD::setFpgaCfg(uint8_t cfg)
{
  fpga_cfg = cfg;
}

void ZXOSD::setFpgaBuildNum(uint8_t pos, uint8_t data)
{
  if (pos < 8) {
    fpga_build_num[pos] = data;
  }
}

void ZXOSD::setAvrBuildNum(const char *data)
{
  avr_build_num = data;
}
