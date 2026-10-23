#include "zxosd.h"
#include "osd.h"
#include "keyboard.h"
#include "rtc.h"
#include "hal.h"
#include <string.h>
#include <avr/pgmspace.h>

typedef uint8_t (*menu_get_fn)(void);
typedef void (*menu_set_fn)(uint8_t);
typedef uint8_t (*menu_max_fn)(void);

typedef struct {
  const char *title;
  const char *hint;
  uint8_t y_pos;
  uint8_t max_val;
  const char * const *labels;
  menu_get_fn get_val;
  menu_set_fn set_val;
  menu_max_fn get_max;
} MenuItem;

// Menu Getters/Setters
static uint8_t get_rombank(void)       { return keyboard_get_rombank(); }
static void    set_rombank(uint8_t v)   { keyboard_set_rombank(v); }

static uint8_t get_turbofdc(void)      { return keyboard_get_turbofdc() ? 1 : 0; }
static void    set_turbofdc(uint8_t v)  { (void)v; keyboard_toggle_turbofdc(); }

static uint8_t get_covox(void)         { return keyboard_get_covox() ? 1 : 0; }
static void    set_covox(uint8_t v)     { (void)v; keyboard_toggle_covox(); }

static uint8_t get_stereo(void)        { return keyboard_get_stereo(); }
static void    set_stereo(uint8_t v)    { keyboard_toggle_stereo(v); }

static uint8_t get_ssg(void)           { return keyboard_get_ssg() ? 1 : 0; }
static void    set_ssg(uint8_t v)       { (void)v; keyboard_toggle_ssg(); }

static uint8_t get_video(void)         { return keyboard_get_video() ? 1 : 0; }
static void    set_video(uint8_t v)     { (void)v; keyboard_toggle_video(); }

static uint8_t get_vsync(void)         { return keyboard_get_vsync() ? 1 : 0; }
static void    set_vsync(uint8_t v)     { (void)v; keyboard_toggle_vsync(); }

static uint8_t get_turbo(void)         { return keyboard_get_turbo(); }
static void    set_turbo(uint8_t v)     { keyboard_set_turbo(v); }
static uint8_t get_turbo_max(void)     { return keyboard_get_max_turbo(); }

static uint8_t get_swap_ab(void)       { return keyboard_get_swap_ab() ? 1 : 0; }
static void    set_swap_ab(uint8_t v)   { (void)v; keyboard_toggle_swap_ab(); }

static uint8_t get_joy_type(void)      { return keyboard_get_joy_type() ? 1 : 0; }
static void    set_joy_type(uint8_t v)  { (void)v; keyboard_toggle_joy_type(); }

static uint8_t get_joy_mode(void)      { return keyboard_get_joy_mode(); }
static void    set_joy_mode(uint8_t v)  { keyboard_set_joy_mode(v); }

static uint8_t get_screen_mode(void)      { return keyboard_get_screen_mode(); }
static void    set_screen_mode(uint8_t v)  { keyboard_set_screen_mode(v); }
static uint8_t get_screen_mode_max(void)  { return keyboard_get_max_screen_mode(); }

static uint8_t get_divmmc(void)        { return keyboard_get_divmmc() ? 1 : 0; }
static void    set_divmmc(uint8_t v)    { (void)v; keyboard_toggle_divmmc(); }

static uint8_t get_nemoide(void)       { return keyboard_get_nemoide() ? 1 : 0; }
static void    set_nemoide(uint8_t v)   { (void)v; keyboard_toggle_nemoide(); }

static uint8_t get_kbd_type(void)      { return keyboard_get_keyboard_type() ? 1 : 0; }
static void    set_kbd_type(uint8_t v)  { (void)v; keyboard_toggle_keyboard_type(); }

static uint8_t get_pause(void)         { return keyboard_get_pause() ? 1 : 0; }
static void    set_pause(uint8_t v)     { (void)v; keyboard_do_pause(); }

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

static const MenuItem s_main_menu_items[MAIN_MENU_ITEMS_COUNT] PROGMEM = {
  { msg_rom_bank,  msg_menu_f1_f4,  5, 3, val_rom_bank, get_rombank,     set_rombank,     0 },
  { msg_turbofdc,  msg_menu_f5,     6, 1, val_on_off,   get_turbofdc,    set_turbofdc,    0 },
  { msg_covox,     msg_menu_f6,     7, 1, val_on_off,   get_covox,       set_covox,       0 },
  { msg_psg_mix,   msg_menu_f7,     8, 2, val_psg_mix,  get_stereo,      set_stereo,      0 },
  { msg_psg_type,  msg_menu_f8,     9, 1, val_psg_type, get_ssg,         set_ssg,         0 },
  { msg_video,     msg_menu_f9,    10, 1, val_video,    get_video,       set_video,       0 },
  { msg_vsync,     msg_menu_f10,   11, 1, val_vsync,    get_vsync,       set_vsync,       0 },
  { msg_turbo,     msg_menu_f11,   12, 3, val_turbo,    get_turbo,       set_turbo,       get_turbo_max },
  { msg_swap_fdd,  msg_menu_tab,   13, 1, val_on_off,   get_swap_ab,     set_swap_ab,     0 },
  { msg_joy_type,  msg_menu_j,     14, 1, val_joy_type, get_joy_type,    set_joy_type,    0 },
  { msg_joy_mode,  msg_menu_m,     15, 4, val_joy_mode, get_joy_mode,    set_joy_mode,    0 },
  { msg_screen,    msg_menu_v,     16, 1, val_screen,   get_screen_mode, set_screen_mode, get_screen_mode_max },
  { msg_divmmc,    msg_menu_d,     17, 1, val_on_off,   get_divmmc,      set_divmmc,      0 },
  { msg_nemoide,   msg_menu_n,     18, 1, val_on_off,   get_nemoide,     set_nemoide,     0 },
  { msg_keyboard,  msg_prtscr,     19, 1, val_keyboard, get_kbd_type,    set_kbd_type,    0 },
  { msg_pause,     msg_pause,      20, 1, val_on_off,   get_pause,       set_pause,       0 },
};

typedef uint16_t (*rtc_get_fn)(void);
typedef void (*rtc_set_fn)(uint16_t);

typedef struct {
  const char *title;
  uint8_t y_pos;
  uint16_t min_val;
  uint16_t max_val;
  rtc_get_fn get_val;
  rtc_set_fn set_val;
} RtcField;

static uint16_t get_rtc_hour(void)       { return rtc_get_hour(); }
static void     set_rtc_hour(uint16_t v) { rtc_set_hour((uint8_t)v); }
static uint16_t get_rtc_min(void)        { return rtc_get_minute(); }
static void     set_rtc_min(uint16_t v)  { rtc_set_minute((uint8_t)v); }
static uint16_t get_rtc_sec(void)        { return rtc_get_second(); }
static void     set_rtc_sec(uint16_t v)  { rtc_set_second((uint8_t)v); }
static uint16_t get_rtc_day(void)        { return rtc_get_day(); }
static void     set_rtc_day(uint16_t v)  { rtc_set_day((uint8_t)v); }
static uint16_t get_rtc_month(void)      { return rtc_get_month(); }
static void     set_rtc_month(uint16_t v){ rtc_set_month((uint8_t)v); }
static uint16_t get_rtc_year(void)       { return rtc_get_year(); }
static void     set_rtc_year(uint16_t v) { rtc_set_year((int)v); }
static uint16_t get_rtc_dow(void)        { return rtc_get_week(); }
static void     set_rtc_dow(uint16_t v)  { rtc_set_week((uint8_t)v); }

static const char * const val_months[] PROGMEM = {
  msg_month_jan, msg_month_feb, msg_month_mar, msg_month_apr,
  msg_month_may, msg_month_jun, msg_month_jul, msg_month_aug,
  msg_month_sep, msg_month_oct, msg_month_nov, msg_month_dec
};

static const char * const val_dows[] PROGMEM = {
  msg_dow_sun, msg_dow_mon, msg_dow_tue, msg_dow_wed, msg_dow_thu, msg_dow_fri, msg_dow_sat
};

static const RtcField s_rtc_fields[RTC_FIELDS_COUNT] PROGMEM = {
  { msg_hours,    7,  0,    23,   get_rtc_hour,  set_rtc_hour },
  { msg_minutes,  8,  0,    59,   get_rtc_min,   set_rtc_min },
  { msg_seconds,  9,  0,    59,   get_rtc_sec,   set_rtc_sec },
  { msg_day,     11,  1,    31,   get_rtc_day,   set_rtc_day },
  { msg_month,   12,  1,    12,   get_rtc_month, set_rtc_month },
  { msg_year,    13,  2000, 4095, get_rtc_year,  set_rtc_year },
  { msg_dow,     15,  1,    7,    get_rtc_dow,   set_rtc_dow },
};

typedef enum {
  STATE_MAIN = 0,
  STATE_RTC,
  STATE_ABOUT,
  STATE_INFO
} OsdState;

static bool s_is_started = false;
static uint8_t s_fpga_cfg = 0;
static uint8_t s_fpga_build_num[8] = {0};
static const char *s_avr_build_num = 0;
static uint32_t s_tstart = 0;

static uint8_t s_osd_state = STATE_MAIN;
static uint8_t s_osd_prev_state = STATE_MAIN;
static uint8_t s_osd_main_state = 0;
static uint8_t s_osd_rtc_state = 0;

static void highlight(bool val)
{
  if (val) osd_set_color(OSD_COLOR_BLACK, OSD_COLOR_MAGENTA_I);
  else osd_set_color(OSD_COLOR_MAGENTA_I, OSD_COLOR_BLACK);
}

static void hint(const char *msg)
{
  osd_set_color(OSD_COLOR_CYAN_I, OSD_COLOR_BLACK);
  osd_print_p(msg);
}

static void param(const char *msg)
{
  osd_set_color(OSD_COLOR_GREEN_I, OSD_COLOR_BLACK);
  osd_print_p(msg);
  osd_print_p(msg_space);
}

static void text(const char *msg)
{
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_print_p(msg);
}

static void flash(const char *msg)
{
  osd_set_color(OSD_COLOR_CYAN_I, OSD_COLOR_FLASH);
  osd_print_p(msg);
}

static void print_space(void)
{
  for (uint8_t i = 0; i < 8; i++) {
    osd_print_p(msg_space);
  }
}

static void print_line(uint8_t y)
{
  osd_set_pos(0, y);
  for (uint8_t i = 0; i < 32; i++) {
    osd_write(0x5F);
  }
}

static void print_rev(void)
{
  uint8_t fpga_rev = ((s_fpga_cfg & 0b00111100) >> 2);
  switch (fpga_rev) {
    case 0x0: osd_print_p(msg_rev_a);  break;
    case 0x1: osd_print_p(msg_rev_ds); break;
    case 0x9: osd_print_p(msg_rev_e);  break;
    case 0xD: osd_print_p(msg_rev_eu); break;
  }
}

static void print_logo(uint8_t x, uint8_t y)
{
  osd_set_pos(x, y);
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);

  osd_write(0xb0); osd_write(0xb1);
  osd_write(0xb2); osd_write(0xb3);
  osd_write(0xb4); osd_write(0xb5);
  osd_write(0xb2); osd_write(0xb3);
  osd_write(0xb6); osd_write(0xb7);
  osd_write(0xb2); osd_write(0xb3);
  osd_write(0xb8); osd_write(0xb9);

  osd_set_pos(x, y + 1);
  osd_write(0xc0); osd_write(0xc1);
  osd_write(0xc2); osd_write(0xc3);
  osd_write(0xc4); osd_write(0xc5);
  osd_write(0xc2); osd_write(0xc3);
  osd_write(0xc6); osd_write(0xc7);
  osd_write(0xc2); osd_write(0xc3);
  osd_write(0xc8); osd_write(0xc9);

  osd_set_pos(x + 8, y + 2);
  osd_write(0xba); osd_write(0xbb);
  osd_write(0xbc); osd_write(0xbd);
  osd_write(0xbe); osd_write(0xbf);

  osd_set_pos(x + 8, y + 3);
  osd_write(0xca); osd_write(0xcb);
  osd_write(0xcc); osd_write(0xcd);
  osd_write(0xce); osd_write(0xcf);

  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  print_rev();
}

static void print_header(void)
{
  print_logo(0, 0);

  osd_set_color(OSD_COLOR_GREY, OSD_COLOR_BLACK);
  osd_set_pos(19, 2);
  osd_print_p(msg_fpga);
  for (uint8_t i = 0; i < 8; i++) {
    osd_write(s_fpga_build_num[i]);
  }

  osd_set_pos(20, 3);
  osd_print_p(msg_avr);
  if (s_avr_build_num) osd_print(s_avr_build_num);

  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  print_line(4);

  zxosd_update_time();
}

static void popup_footer(void)
{
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  print_line(22);
  osd_set_pos(0, 23);
  text(msg_press);
  hint(msg_esc);
  text(msg_to_return);
}

static void render_menu_item_value(uint8_t idx, bool is_active)
{
  if (idx >= MAIN_MENU_ITEMS_COUNT) return;

  MenuItem item;
  memcpy_P(&item, &s_main_menu_items[idx], sizeof(MenuItem));

  if (!keyboard_get_is_osd_popup()) {
    if (s_osd_state != STATE_MAIN) return;
    highlight(is_active);
    osd_set_pos(10, item.y_pos);
  }

  uint8_t cur_v = item.get_val();
  uint8_t max_v = item.get_max ? item.get_max() : item.max_val;
  if (cur_v > max_v) cur_v = max_v;

  const char *lbl = (const char *)pgm_read_ptr(&item.labels[cur_v]);
  osd_print_p(lbl);
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);

  size_t len = strlen_P(lbl);
  for (size_t i = len; i < 9; i++) {
    osd_print_p(msg_space);
  }
}

static void render_menu_item(uint8_t idx, bool is_active)
{
  if (idx >= MAIN_MENU_ITEMS_COUNT) return;

  MenuItem item;
  memcpy_P(&item, &s_main_menu_items[idx], sizeof(MenuItem));

  osd_set_pos(0, item.y_pos);
  param(item.title);

  render_menu_item_value(idx, is_active);

  osd_set_pos(20, item.y_pos);
  hint(item.hint);
}

static void change_menu_item(uint8_t idx, int8_t dir)
{
  if (idx >= MAIN_MENU_ITEMS_COUNT) return;

  MenuItem item;
  memcpy_P(&item, &s_main_menu_items[idx], sizeof(MenuItem));

  uint8_t max_v = item.get_max ? item.get_max() : item.max_val;
  uint8_t cur_v = item.get_val();

  if (max_v == 1) {
    item.set_val(cur_v ? 0 : 1);
  } else {
    if (dir < 0) {
      cur_v = (cur_v == 0) ? max_v : cur_v - 1;
    } else {
      cur_v = (cur_v >= max_v) ? 0 : cur_v + 1;
    }
    item.set_val(cur_v);
  }
  render_menu_item_value(idx, true);
}

static void render_rtc_field_value(uint8_t idx, bool is_active)
{
  if (s_osd_state != STATE_RTC || idx >= RTC_FIELDS_COUNT) return;
  highlight(is_active);

  RtcField f;
  memcpy_P(&f, &s_rtc_fields[idx], sizeof(RtcField));
  osd_set_pos(10, f.y_pos);

  uint16_t val = f.get_val();

  if (idx == 4) { // Month
    if (val >= 1 && val <= 12) {
      const char *m = (const char *)pgm_read_ptr(&val_months[val - 1]);
      osd_print_p(m);
    } else {
      osd_print_p(msg_unknown);
    }
    osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
    print_space();
  } else if (idx == 6) { // DOW
    if (val >= 1 && val <= 7) {
      const char *d = (const char *)pgm_read_ptr(&val_dows[val - 1]);
      osd_print_p(d);
    } else {
      osd_print_p(msg_unknown);
    }
    osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
    print_space();
  } else if (idx == 5) { // Year (4 digits)
    if (val < 1000) osd_print_p(msg_0);
    if (val < 100)  osd_print_p(msg_0);
    if (val < 10)   osd_print_p(msg_0);
    osd_print_num(val, 10);
  } else { // 2 digits
    if (val < 10) osd_print_p(msg_0);
    osd_print_num(val, 10);
  }
}

static void change_rtc_field(uint8_t idx, int8_t dir)
{
  if (idx >= RTC_FIELDS_COUNT) return;

  RtcField f;
  memcpy_P(&f, &s_rtc_fields[idx], sizeof(RtcField));
  int32_t val = (int32_t)f.get_val();

  if (dir < 0) {
    val = (val <= f.min_val) ? f.max_val : val - 1;
  } else {
    val = (val >= f.max_val) ? f.min_val : val + 1;
  }
  f.set_val((uint16_t)val);
  rtc_save();
  render_rtc_field_value(idx, true);
}

static void init_rtc_overlay(void)
{
  rtc_fix_invalid_time();

  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_clear();

  print_header();

  osd_set_pos(0, 5);
  text(msg_rtc_setup);

  for (uint8_t i = 0; i < RTC_FIELDS_COUNT; i++) {
    RtcField f;
    memcpy_P(&f, &s_rtc_fields[i], sizeof(RtcField));
    osd_set_pos(0, f.y_pos);
    param(f.title);
    render_rtc_field_value(i, i == s_osd_rtc_state);
  }

  osd_set_pos(0, 17);
  text(msg_please_use_arrows);
  osd_set_color(OSD_COLOR_CYAN_I, OSD_COLOR_BLACK); osd_write(17);
  text(msg_and);
  osd_set_color(OSD_COLOR_CYAN_I, OSD_COLOR_BLACK); osd_write(16);
  osd_set_pos(0, 18);
  text(msg_to_change_values);
  osd_set_color(OSD_COLOR_CYAN_I, OSD_COLOR_BLACK); osd_write(30);
  text(msg_and);
  osd_set_color(OSD_COLOR_CYAN_I, OSD_COLOR_BLACK); osd_write(31);
  osd_set_pos(0, 19);
  text(msg_to_navigate);

  popup_footer();
}

static void init_about_overlay(void)
{
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_clear();

  print_header();

  osd_set_pos(0, 5);
  text(msg_about);

  osd_set_pos(0, 7);
  osd_set_color(OSD_COLOR_BLUE_I, OSD_COLOR_BLACK);
  osd_print_p(msg_karabas_developers_are);

  typedef struct { const char *name; const char *skills; } DevInfo;
  static const DevInfo devs[] PROGMEM = {
    { msg_dev_andykarpov, msg_dev_andykarpov_skills },
    { msg_dev_solegstar,  msg_dev_solegstar_skills },
    { msg_dev_drmax,      msg_dev_drmax_skills },
    { msg_dev_nihirash,   msg_dev_nihirash_skills }
  };

  for (uint8_t i = 0; i < 4; i++) {
    osd_set_pos(0, 9 + i);
    osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
    osd_write(250);
    const char *name = (const char *)pgm_read_ptr(&devs[i].name);
    const char *skills = (const char *)pgm_read_ptr(&devs[i].skills);
    osd_print_p(name);
    hint(skills);
  }

  osd_set_pos(0, 14);
  osd_set_color(OSD_COLOR_BLUE_I, OSD_COLOR_BLACK);
  osd_print_p(msg_special_thanks_to);

  static const char * const thanks[] PROGMEM = {
    msg_dev_kalantaj, msg_dev_tankuk, msg_dev_xdemox, msg_dev_dumpkin, msg_dev_kasper
  };

  for (uint8_t i = 0; i < 5; i++) {
    osd_set_pos(0, 16 + i);
    osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
    osd_write(250);
    const char *th = (const char *)pgm_read_ptr(&thanks[i]);
    osd_print_p(th);
  }

  osd_set_pos(18, 21);
  osd_set_color(OSD_COLOR_GREY, OSD_COLOR_BLACK);
  osd_print_p(msg_www_karabas_uk);

  popup_footer();
}

static void update_uptime(void)
{
  uint32_t diff = (millis() - s_tstart) / 1000;
  uint32_t mins = diff / 60;
  uint32_t hours = mins / 60;
  uint32_t days = hours / 24;
  diff  = diff - (mins * 60);
  mins  = mins - (hours * 60);
  hours = hours - (days * 24);

  osd_set_pos(14, 11);
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  if (days > 0) {
    osd_print_num(days, 10);
    osd_print_p(days > 1 ? msg_many_days : msg_one_day);
    osd_print_p(msg_and);
  }
  if (hours < 10) osd_print_p(msg_0);
  osd_print_num(hours, 10);
  osd_print_p(msg_colon);
  if (mins < 10) osd_print_p(msg_0);
  osd_print_num(mins, 10);
  osd_print_p(msg_colon);
  if (diff < 10) osd_print_p(msg_0);
  osd_print_num(diff, 10);
}

static void init_info_overlay(void)
{
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_clear();

  print_header();

  osd_set_pos(0, 5);
  text(msg_system_info);

  uint8_t y = 14;

  osd_set_pos(0, 7);
  text(msg_fpga_build);
  osd_set_pos(y, 7);
  for (uint8_t i = 0; i < 8; i++) {
    osd_write(s_fpga_build_num[i]);
  }

  osd_set_pos(0, 8);
  text(msg_avr_build);
  osd_set_pos(y, 8);
  if (s_avr_build_num) osd_print(s_avr_build_num);

  osd_set_pos(0, 9);
  text(msg_pcb_revision);
  osd_set_pos(y, 9);
  print_rev();

  // DAC Type
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_set_pos(0, 10); osd_print_p(msg_dac_type);
  osd_set_pos(y, 10); osd_print_p(msg_tda1543);
  if (bitRead(s_fpga_cfg, 0) == 1) {
    osd_print_p(msg_a);
  }

  // Uptime
  osd_set_pos(0, 11); text(msg_uptime);
  update_uptime();

  osd_set_pos(0, 13);
  text(msg_debug_info);

  osd_set_pos(0, 15); text(msg_scancode);
  zxosd_update_scancode(0);

  osd_set_pos(0, 16); text(msg_mouse);
  zxosd_update_mouse(0, 0, 0);

  osd_set_pos(0, 17); text(msg_port_1f);
  zxosd_update_joy_state(0);

  popup_footer();
}

void zxosd_init(void)
{
  osd_init();
  s_tstart = millis();
  s_is_started = true;
}

bool zxosd_started(void)
{
  return s_is_started;
}

void zxosd_clear(void)
{
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_clear();
}

void zxosd_init_overlay(void)
{
  s_osd_state = STATE_MAIN;
  keyboard_set_osd_popup(false);

  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_clear();

  print_header();

  for (uint8_t i = 0; i < MAIN_MENU_ITEMS_COUNT; i++) {
    render_menu_item(i, i == s_osd_main_state);
  }

  osd_set_pos(0, 22);
  flash(msg_s); text(msg_etup_rtc); text(msg_space);
  flash(msg_i); text(msg_nfo); flash(msg_a); text(msg_bout);

  print_line(23);

  osd_set_pos(0, 24); text(msg_press); hint(msg_ctrl_alt_del); text(msg_to_reboot);
  osd_set_pos(0, 25); text(msg_press); hint(msg_menu_esc); text(msg_to_toggle_osd);
}

void zxosd_init_popup(uint8_t event_type)
{
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_clear();

  bool is_boot = (event_type == EVENT_OSD_POPUP);
  print_logo(0, is_boot ? 5 : 0);

  if (is_boot) return;

  int8_t item_idx = zxosd_event_to_menu_item(event_type);
  if (item_idx >= 0) {
    MenuItem item;
    memcpy_P(&item, &s_main_menu_items[item_idx], sizeof(MenuItem));

    osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
    osd_set_pos(0, 5);
    osd_print_p(item.title);
    print_space();

    osd_set_pos(0, 6);
    render_menu_item_value((uint8_t)item_idx, false);
    print_space();
  }
}

void zxosd_handle(void)
{
  if (!keyboard_get_is_osd_overlay()) return;

  switch (s_osd_state) {
    case STATE_MAIN:
      if (s_osd_prev_state != s_osd_state) {
        s_osd_prev_state = s_osd_state;
        s_osd_main_state = 0;
        zxosd_init_overlay();
      }

      if (keyboard_get_is_cursor_down()) {
        uint8_t prev = s_osd_main_state;
        s_osd_main_state = (s_osd_main_state + 1) % MAIN_MENU_ITEMS_COUNT;
        render_menu_item_value(prev, false);
        render_menu_item_value(s_osd_main_state, true);
      }
      if (keyboard_get_is_cursor_up()) {
        uint8_t prev = s_osd_main_state;
        s_osd_main_state = (s_osd_main_state == 0) ? (MAIN_MENU_ITEMS_COUNT - 1) : s_osd_main_state - 1;
        render_menu_item_value(prev, false);
        render_menu_item_value(s_osd_main_state, true);
      }

      if (keyboard_get_key(ZX_K_S)) s_osd_state = STATE_RTC;
      if (keyboard_get_key(ZX_K_A)) s_osd_state = STATE_ABOUT;
      if (keyboard_get_key(ZX_K_I)) s_osd_state = STATE_INFO;

      if (keyboard_get_is_cursor_left()) {
        change_menu_item(s_osd_main_state, -1);
      }
      if (keyboard_get_is_cursor_right() || keyboard_get_is_enter()) {
        change_menu_item(s_osd_main_state, 1);
      }
      break;

    case STATE_RTC:
      if (s_osd_prev_state != s_osd_state) {
        s_osd_prev_state = s_osd_state;
        s_osd_rtc_state = 0;
        init_rtc_overlay();
      }

      if (keyboard_get_is_cursor_down()) {
        uint8_t prev = s_osd_rtc_state;
        s_osd_rtc_state = (s_osd_rtc_state + 1) % RTC_FIELDS_COUNT;
        render_rtc_field_value(prev, false);
        render_rtc_field_value(s_osd_rtc_state, true);
      }
      if (keyboard_get_is_cursor_up()) {
        uint8_t prev = s_osd_rtc_state;
        s_osd_rtc_state = (s_osd_rtc_state == 0) ? (RTC_FIELDS_COUNT - 1) : s_osd_rtc_state - 1;
        render_rtc_field_value(prev, false);
        render_rtc_field_value(s_osd_rtc_state, true);
      }

      if (keyboard_get_is_escape()) {
        s_osd_state = STATE_MAIN;
      }

      if (keyboard_get_is_cursor_left()) {
        change_rtc_field(s_osd_rtc_state, -1);
      }
      if (keyboard_get_is_cursor_right() || keyboard_get_is_enter()) {
        change_rtc_field(s_osd_rtc_state, 1);
      }
      break;

    case STATE_ABOUT:
      if (s_osd_prev_state != s_osd_state) {
        s_osd_prev_state = s_osd_state;
        init_about_overlay();
      }
      if (keyboard_get_is_escape()) {
        s_osd_state = STATE_MAIN;
      }
      break;

    case STATE_INFO:
      if (s_osd_prev_state != s_osd_state) {
        s_osd_prev_state = s_osd_state;
        init_info_overlay();
      }
      if (keyboard_get_is_escape()) {
        s_osd_state = STATE_MAIN;
      }
      break;
  }

  keyboard_clear(ZX_MATRIX_SIZE);
}

void zxosd_update_item(uint8_t idx)
{
  render_menu_item_value(idx, s_osd_main_state == idx);
}

void zxosd_update_time(void)
{
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_set_pos(24, 0);

  if (rtc_get_time_is_valid()) {
    if (rtc_get_hour() < 10) osd_print_p(msg_0);
    osd_print_num(rtc_get_hour(), 10);
    osd_print_p(msg_colon);
    if (rtc_get_minute() < 10) osd_print_p(msg_0);
    osd_print_num(rtc_get_minute(), 10);
    osd_print_p(msg_colon);
    if (rtc_get_second() < 10) osd_print_p(msg_0);
    osd_print_num(rtc_get_second(), 10);
  } else {
    osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_FLASH);
    osd_print_p(msg_time_mask);
  }

  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_set_pos(22, 1);

  if (rtc_get_date_is_valid()) {
    if (rtc_get_day() < 10) osd_print_p(msg_0);
    osd_print_num(rtc_get_day(), 10);
    osd_print_p(msg_dot);
    if (rtc_get_month() < 10) osd_print_p(msg_0);
    osd_print_num(rtc_get_month(), 10);
    osd_print_p(msg_dot);
    osd_print_num(rtc_get_year(), 10);
  } else {
    osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_FLASH);
    osd_print_p(msg_date_mask);
  }

  if (s_osd_state == STATE_RTC) {
    for (uint8_t i = 0; i < RTC_FIELDS_COUNT; i++) {
      render_rtc_field_value(i, i == s_osd_rtc_state);
    }
  }
  if (s_osd_state == STATE_INFO) {
    update_uptime();
  }
}

void zxosd_update_scancode(uint16_t scancode)
{
  if (s_osd_state != STATE_INFO) return;
  osd_set_color(OSD_COLOR_RED_I, OSD_COLOR_BLACK);
  osd_set_pos(14, 15);
  if ((scancode >> 8) < 0x10) osd_print_p(msg_0);
  osd_print_num(scancode >> 8, 16);
  osd_print_p(msg_space);
  if ((scancode & 0xFF) < 0x10) osd_print_p(msg_0);
  osd_print_num(scancode & 0xFF, 16);
}

void zxosd_update_mouse(uint8_t x, uint8_t y, uint8_t z)
{
  if (s_osd_state != STATE_INFO) return;
  osd_set_color(OSD_COLOR_RED_I, OSD_COLOR_BLACK);
  osd_set_pos(14, 16);
  if (x < 0x10) osd_print_p(msg_0);
  osd_print_num(x, 16);
  osd_print_p(msg_space);
  if (y < 0x10) osd_print_p(msg_0);
  osd_print_num(y, 16);
  osd_print_p(msg_space);
  if (z < 0x10) osd_print_p(msg_0);
  osd_print_num(z, 16);
}

void zxosd_update_joy_state(uint8_t data)
{
  if (s_osd_state != STATE_INFO) return;
  osd_set_color(OSD_COLOR_RED_I, OSD_COLOR_BLACK);
  osd_set_pos(14, 17);
  if (data < 0x10) osd_print_p(msg_0);
  osd_print_num(data, 16);
}

void zxosd_set_fpga_cfg(uint8_t cfg)
{
  s_fpga_cfg = cfg;
}

void zxosd_set_fpga_build_num(uint8_t pos, uint8_t data)
{
  if (pos < 8) s_fpga_build_num[pos] = data;
}

void zxosd_set_avr_build_num(const char *data)
{
  s_avr_build_num = data;
}

int8_t zxosd_event_to_menu_item(uint8_t event_type)
{
  switch (event_type) {
    case EVENT_OSD_ROMBANK:       return 0;
    case EVENT_OSD_TURBOFDC:      return 1;
    case EVENT_OSD_COVOX:         return 2;
    case EVENT_OSD_STEREO:        return 3;
    case EVENT_OSD_SSG:           return 4;
    case EVENT_OSD_VIDEO:         return 5;
    case EVENT_OSD_VSYNC:         return 6;
    case EVENT_OSD_TURBO:         return 7;
    case EVENT_OSD_SWAP_AB:       return 8;
    case EVENT_OSD_JOYSTICK:      return 9;
    case EVENT_OSD_JOYSTICK_MODE: return 10;
    case EVENT_OSD_SCREEN_MODE:   return 11;
    case EVENT_OSD_DIVMMC:        return 12;
    case EVENT_OSD_NEMOIDE:       return 13;
    case EVENT_OSD_KEYBOARD_TYPE: return 14;
    case EVENT_OSD_PAUSE:         return 15;
    default: return -1;
  }
}
