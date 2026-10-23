#include "zxosd.h"
#include "osd.h"
#include "keyboard.h"
#include "rtc.h"
#include "hal.h"
#include "config.h"
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
static const char * const val_psg_type[] PROGMEM = { msg_ym, msg_ay };
static const char * const val_joy_type[] PROGMEM = { msg_atari, msg_sega };

static const char * const val_on_off_en[] PROGMEM = { msg_en_off, msg_en_on };
static const char * const val_on_off_ru[] PROGMEM = { msg_ru_off, msg_ru_on };
static const char * const val_on_off_ua[] PROGMEM = { msg_ua_off, msg_ua_on };

static const char * const val_psg_mix_en[] PROGMEM = { msg_acb, msg_abc, msg_en_mono };
static const char * const val_psg_mix_ru[] PROGMEM = { msg_acb, msg_abc, msg_ru_mono };
static const char * const val_psg_mix_ua[] PROGMEM = { msg_acb, msg_abc, msg_ua_mono };

static const char * const val_video_en[] PROGMEM = { msg_en_vga, msg_en_rgb };
static const char * const val_video_ru[] PROGMEM = { msg_ru_vga, msg_ru_rgb };
static const char * const val_video_ua[] PROGMEM = { msg_ua_vga, msg_ua_rgb };

static const char * const val_vsync_en[] PROGMEM = { msg_en_50hz, msg_en_60hz };
static const char * const val_vsync_ru[] PROGMEM = { msg_ru_50hz, msg_ru_60hz };
static const char * const val_vsync_ua[] PROGMEM = { msg_ua_50hz, msg_ua_60hz };

static const char * const val_turbo_en[] PROGMEM = { msg_en_off, msg_2x, msg_4x, msg_8x };
static const char * const val_turbo_ru[] PROGMEM = { msg_ru_off, msg_2x, msg_4x, msg_8x };
static const char * const val_turbo_ua[] PROGMEM = { msg_ua_off, msg_2x, msg_4x, msg_8x };

static const char * const val_joy_mode_en[] PROGMEM = { msg_en_joy_kempston, msg_en_joy_sinclair1, msg_en_joy_sinclair2, msg_en_joy_cursor, msg_joy_qaop };
static const char * const val_joy_mode_ru[] PROGMEM = { msg_ru_joy_kempston, msg_ru_joy_sinclair1, msg_ru_joy_sinclair2, msg_ru_joy_cursor, msg_joy_qaop };
static const char * const val_joy_mode_ua[] PROGMEM = { msg_ua_joy_kempston, msg_ua_joy_sinclair1, msg_ua_joy_sinclair2, msg_ua_joy_cursor, msg_joy_qaop };

static const char * const val_screen_en[] PROGMEM = { msg_en_pentagon, msg_en_classic };
static const char * const val_screen_ru[] PROGMEM = { msg_ru_pentagon, msg_ru_classic };
static const char * const val_screen_ua[] PROGMEM = { msg_ua_pentagon, msg_ua_classic };

static const char * const val_keyboard_en[] PROGMEM = { msg_en_spectrum, msg_en_profi_xt };
static const char * const val_keyboard_ru[] PROGMEM = { msg_ru_spectrum, msg_ru_profi_xt };
static const char * const val_keyboard_ua[] PROGMEM = { msg_ua_spectrum, msg_ua_profi_xt };

static const MenuItem s_main_menu_items[LANG_COUNT][MAIN_MENU_ITEMS_COUNT] PROGMEM = {
  // LANG_EN
  {
    { msg_en_rom_bank,  msg_en_menu_f1_f4,  5, 3, val_rom_bank,    get_rombank,     set_rombank,     0 },
    { msg_en_turbofdc,  msg_en_menu_f5,     6, 1, val_on_off_en,   get_turbofdc,    set_turbofdc,    0 },
    { msg_en_covox,     msg_en_menu_f6,     7, 1, val_on_off_en,   get_covox,       set_covox,       0 },
    { msg_en_psg_mix,   msg_en_menu_f7,     8, 2, val_psg_mix_en,  get_stereo,      set_stereo,      0 },
    { msg_en_psg_type,  msg_en_menu_f8,     9, 1, val_psg_type,    get_ssg,         set_ssg,         0 },
    { msg_en_video,     msg_en_menu_f9,    10, 1, val_video_en,    get_video,       set_video,       0 },
    { msg_en_vsync,     msg_en_menu_f10,   11, 1, val_vsync_en,    get_vsync,       set_vsync,       0 },
    { msg_en_turbo,     msg_en_menu_f11,   12, 3, val_turbo_en,    get_turbo,       set_turbo,       get_turbo_max },
    { msg_en_swap_fdd,  msg_en_menu_tab,   13, 1, val_on_off_en,   get_swap_ab,     set_swap_ab,     0 },
    { msg_en_joy_type,  msg_en_menu_j,     14, 1, val_joy_type,    get_joy_type,    set_joy_type,    0 },
    { msg_en_joy_mode,  msg_en_menu_m,     15, 4, val_joy_mode_en, get_joy_mode,    set_joy_mode,    0 },
    { msg_en_screen,    msg_en_menu_v,     16, 1, val_screen_en,   get_screen_mode, set_screen_mode, get_screen_mode_max },
    { msg_divmmc,       msg_en_menu_d,     17, 1, val_on_off_en,   get_divmmc,      set_divmmc,      0 },
    { msg_nemoide,      msg_en_menu_n,     18, 1, val_on_off_en,   get_nemoide,     set_nemoide,     0 },
    { msg_en_keyboard,  msg_prtscr,        19, 1, val_keyboard_en, get_kbd_type,    set_kbd_type,    0 },
    { msg_en_pause,     msg_en_pause,      20, 1, val_on_off_en,   get_pause,       set_pause,       0 },
  },
  // LANG_RU
  {
    { msg_ru_rom_bank,  msg_ru_menu_f1_f4,  5, 3, val_rom_bank,    get_rombank,     set_rombank,     0 },
    { msg_ru_turbofdc,  msg_ru_menu_f5,     6, 1, val_on_off_ru,   get_turbofdc,    set_turbofdc,    0 },
    { msg_ru_covox,     msg_ru_menu_f6,     7, 1, val_on_off_ru,   get_covox,       set_covox,       0 },
    { msg_ru_psg_mix,   msg_ru_menu_f7,     8, 2, val_psg_mix_ru,  get_stereo,      set_stereo,      0 },
    { msg_ru_psg_type,  msg_ru_menu_f8,     9, 1, val_psg_type,    get_ssg,         set_ssg,         0 },
    { msg_ru_video,     msg_ru_menu_f9,    10, 1, val_video_ru,    get_video,       set_video,       0 },
    { msg_ru_vsync,     msg_ru_menu_f10,   11, 1, val_vsync_ru,    get_vsync,       set_vsync,       0 },
    { msg_ru_turbo,     msg_ru_menu_f11,   12, 3, val_turbo_ru,    get_turbo,       set_turbo,       get_turbo_max },
    { msg_ru_swap_fdd,  msg_ru_menu_tab,   13, 1, val_on_off_ru,   get_swap_ab,     set_swap_ab,     0 },
    { msg_ru_joy_type,  msg_ru_menu_j,     14, 1, val_joy_type,    get_joy_type,    set_joy_type,    0 },
    { msg_ru_joy_mode,  msg_ru_menu_m,     15, 4, val_joy_mode_ru, get_joy_mode,    set_joy_mode,    0 },
    { msg_ru_screen,    msg_ru_menu_v,     16, 1, val_screen_ru,   get_screen_mode, set_screen_mode, get_screen_mode_max },
    { msg_divmmc,       msg_ru_menu_d,     17, 1, val_on_off_ru,   get_divmmc,      set_divmmc,      0 },
    { msg_nemoide,      msg_ru_menu_n,     18, 1, val_on_off_ru,   get_nemoide,     set_nemoide,     0 },
    { msg_ru_keyboard,  msg_prtscr,        19, 1, val_keyboard_ru, get_kbd_type,    set_kbd_type,    0 },
    { msg_ru_pause,     msg_ru_pause,      20, 1, val_on_off_ru,   get_pause,       set_pause,       0 },
  },
  // LANG_UA
  {
    { msg_ua_rom_bank,  msg_ua_menu_f1_f4,  5, 3, val_rom_bank,    get_rombank,     set_rombank,     0 },
    { msg_ua_turbofdc,  msg_ua_menu_f5,     6, 1, val_on_off_ua,   get_turbofdc,    set_turbofdc,    0 },
    { msg_ua_covox,     msg_ua_menu_f6,     7, 1, val_on_off_ua,   get_covox,       set_covox,       0 },
    { msg_ua_psg_mix,   msg_ua_menu_f7,     8, 2, val_psg_mix_ua,  get_stereo,      set_stereo,      0 },
    { msg_ua_psg_type,  msg_ua_menu_f8,     9, 1, val_psg_type,    get_ssg,         set_ssg,         0 },
    { msg_ua_video,     msg_ua_menu_f9,    10, 1, val_video_ua,    get_video,       set_video,       0 },
    { msg_ua_vsync,     msg_ua_menu_f10,   11, 1, val_vsync_ua,    get_vsync,       set_vsync,       0 },
    { msg_ua_turbo,     msg_ua_menu_f11,   12, 3, val_turbo_ua,    get_turbo,       set_turbo,       get_turbo_max },
    { msg_ua_swap_fdd,  msg_ua_menu_tab,   13, 1, val_on_off_ua,   get_swap_ab,     set_swap_ab,     0 },
    { msg_ua_joy_type,  msg_ua_menu_j,     14, 1, val_joy_type,    get_joy_type,    set_joy_type,    0 },
    { msg_ua_joy_mode,  msg_ua_menu_m,     15, 4, val_joy_mode_ua, get_joy_mode,    set_joy_mode,    0 },
    { msg_ua_screen,    msg_ua_menu_v,     16, 1, val_screen_ua,   get_screen_mode, set_screen_mode, get_screen_mode_max },
    { msg_divmmc,       msg_ua_menu_d,     17, 1, val_on_off_ua,   get_divmmc,      set_divmmc,      0 },
    { msg_nemoide,      msg_ua_menu_n,     18, 1, val_on_off_ua,   get_nemoide,     set_nemoide,     0 },
    { msg_ua_keyboard,  msg_prtscr,        19, 1, val_keyboard_ua, get_kbd_type,    set_kbd_type,    0 },
    { msg_ua_pause,     msg_ua_pause,      20, 1, val_on_off_ua,   get_pause,       set_pause,       0 },
  }
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

static const char * const val_months[LANG_COUNT][12] PROGMEM = {
  { msg_en_month_jan, msg_en_month_feb, msg_en_month_mar, msg_en_month_apr,
    msg_en_month_may, msg_en_month_jun, msg_en_month_jul, msg_en_month_aug,
    msg_en_month_sep, msg_en_month_oct, msg_en_month_nov, msg_en_month_dec },
  { msg_ru_month_jan, msg_ru_month_feb, msg_ru_month_mar, msg_ru_month_apr,
    msg_ru_month_may, msg_ru_month_jun, msg_ru_month_jul, msg_ru_month_aug,
    msg_ru_month_sep, msg_ru_month_oct, msg_ru_month_nov, msg_ru_month_dec },
  { msg_ua_month_jan, msg_ua_month_feb, msg_ua_month_mar, msg_ua_month_apr,
    msg_ua_month_may, msg_ua_month_jun, msg_ua_month_jul, msg_ua_month_aug,
    msg_ua_month_sep, msg_ua_month_oct, msg_ua_month_nov, msg_ua_month_dec }
};

static const char * const val_dows[LANG_COUNT][7] PROGMEM = {
  { msg_en_dow_sun, msg_en_dow_mon, msg_en_dow_tue, msg_en_dow_wed, msg_en_dow_thu, msg_en_dow_fri, msg_en_dow_sat },
  { msg_ru_dow_sun, msg_ru_dow_mon, msg_ru_dow_tue, msg_ru_dow_wed, msg_ru_dow_thu, msg_ru_dow_fri, msg_ru_dow_sat },
  { msg_ua_dow_sun, msg_ua_dow_mon, msg_ua_dow_tue, msg_ua_dow_wed, msg_ua_dow_thu, msg_ua_dow_fri, msg_ua_dow_sat }
};

static const RtcField s_rtc_fields[LANG_COUNT][RTC_FIELDS_COUNT] PROGMEM = {
  // LANG_EN
  {
    { msg_en_hours,    7,  0,    23,   get_rtc_hour,  set_rtc_hour },
    { msg_en_minutes,  8,  0,    59,   get_rtc_min,   set_rtc_min },
    { msg_en_seconds,  9,  0,    59,   get_rtc_sec,   set_rtc_sec },
    { msg_en_day,     11,  1,    31,   get_rtc_day,   set_rtc_day },
    { msg_en_month,   12,  1,    12,   get_rtc_month, set_rtc_month },
    { msg_en_year,    13,  2000, 4095, get_rtc_year,  set_rtc_year },
    { msg_en_dow,     15,  1,    7,    get_rtc_dow,   set_rtc_dow },
  },
  // LANG_RU
  {
    { msg_ru_hours,    7,  0,    23,   get_rtc_hour,  set_rtc_hour },
    { msg_ru_minutes,  8,  0,    59,   get_rtc_min,   set_rtc_min },
    { msg_ru_seconds,  9,  0,    59,   get_rtc_sec,   set_rtc_sec },
    { msg_ru_day,     11,  1,    31,   get_rtc_day,   set_rtc_day },
    { msg_ru_month,   12,  1,    12,   get_rtc_month, set_rtc_month },
    { msg_ru_year,    13,  2000, 4095, get_rtc_year,  set_rtc_year },
    { msg_ru_dow,     15,  1,    7,    get_rtc_dow,   set_rtc_dow },
  },
  // LANG_UA
  {
    { msg_ua_hours,    7,  0,    23,   get_rtc_hour,  set_rtc_hour },
    { msg_ua_minutes,  8,  0,    59,   get_rtc_min,   set_rtc_min },
    { msg_ua_seconds,  9,  0,    59,   get_rtc_sec,   set_rtc_sec },
    { msg_ua_day,     11,  1,    31,   get_rtc_day,   set_rtc_day },
    { msg_ua_month,   12,  1,    12,   get_rtc_month, set_rtc_month },
    { msg_ua_year,    13,  2000, 4095, get_rtc_year,  set_rtc_year },
    { msg_ua_dow,     15,  1,    7,    get_rtc_dow,   set_rtc_dow },
  }
};

typedef enum {
  MSG_FPGA,
  MSG_AVR,
  MSG_ETUP_RTC,
  MSG_NFO,
  MSG_BOUT,
  MSG_ANG,
  MSG_PRESS,
  MSG_TO_RETURN,
  MSG_TO_REBOOT,
  MSG_MENU_ESC,
  MSG_TO_TOGGLE_OSD,
  MSG_RTC_SETUP,
  MSG_PLEASE_USE_ARROWS,
  MSG_AND,
  MSG_ABOUT,
  MSG_KARABAS_DEVELOPERS_ARE,
  MSG_SPECIAL_THANKS_TO,
  MSG_SYSTEM_INFO,
  MSG_FPGA_BUILD,
  MSG_AVR_BUILD,
  MSG_PCB_REVISION,
  MSG_DAC_TYPE,
  MSG_UPTIME,
  MSG_DEBUG_INFO,
  MSG_SCANCODE,
  MSG_MOUSE,
  MSG_PORT_1F,
  MSG_ONE_DAY,
  MSG_MANY_DAYS,
  MSG_COUNT
} MsgId;

static const char * const s_messages[LANG_COUNT][MSG_COUNT] PROGMEM = {
  // LANG_EN
  {
    msg_en_fpga,
    msg_en_avr,
    msg_en_etup_rtc,
    msg_en_nfo,
    msg_en_bout,
    msg_en_ang,
    msg_en_press,
    msg_en_to_return,
    msg_en_to_reboot,
    msg_en_menu_esc,
    msg_en_to_toggle_osd,
    msg_en_rtc_setup,
    msg_en_please_use_arrows,
    msg_en_and,
    msg_en_about,
    msg_en_karabas_developers_are,
    msg_en_special_thanks_to,
    msg_en_system_info,
    msg_en_fpga_build,
    msg_en_avr_build,
    msg_en_pcb_revision,
    msg_en_dac_type,
    msg_en_uptime,
    msg_en_debug_info,
    msg_en_scancode,
    msg_en_mouse,
    msg_en_port_1f,
    msg_en_one_day,
    msg_en_many_days,
  },
  // LANG_RU
  {
    msg_ru_fpga,
    msg_ru_avr,
    msg_ru_etup_rtc,
    msg_ru_nfo,
    msg_ru_bout,
    msg_ru_ang,
    msg_ru_press,
    msg_ru_to_return,
    msg_ru_to_reboot,
    msg_ru_menu_esc,
    msg_ru_to_toggle_osd,
    msg_ru_rtc_setup,
    msg_ru_please_use_arrows,
    msg_ru_and,
    msg_ru_about,
    msg_ru_karabas_developers_are,
    msg_ru_special_thanks_to,
    msg_ru_system_info,
    msg_ru_fpga_build,
    msg_ru_avr_build,
    msg_ru_pcb_revision,
    msg_ru_dac_type,
    msg_ru_uptime,
    msg_ru_debug_info,
    msg_ru_scancode,
    msg_ru_mouse,
    msg_ru_port_1f,
    msg_ru_one_day,
    msg_ru_many_days,
  },
  // LANG_UA
  {
    msg_ua_fpga,
    msg_ua_avr,
    msg_ua_etup_rtc,
    msg_ua_nfo,
    msg_ua_bout,
    msg_ua_ang,
    msg_ua_press,
    msg_ua_to_return,
    msg_ua_to_reboot,
    msg_ua_menu_esc,
    msg_ua_to_toggle_osd,
    msg_ua_rtc_setup,
    msg_ua_please_use_arrows,
    msg_ua_and,
    msg_ua_about,
    msg_ua_karabas_developers_are,
    msg_ua_special_thanks_to,
    msg_ua_system_info,
    msg_ua_fpga_build,
    msg_ua_avr_build,
    msg_ua_pcb_revision,
    msg_ua_dac_type,
    msg_ua_uptime,
    msg_ua_debug_info,
    msg_ua_scancode,
    msg_ua_mouse,
    msg_ua_port_1f,
    msg_ua_one_day,
    msg_ua_many_days,
  }
};

static uint8_t s_lang = LANG_EN;

static inline const char * msg(MsgId id) {
  return (const char *)pgm_read_ptr(&s_messages[s_lang][id]);
}

typedef enum {
  STATE_MAIN = 0,
  STATE_RTC,
  STATE_ABOUT,
  STATE_INFO
} OsdState;

static bool s_is_started = false;
static uint32_t s_tpopup = 0;
static bool s_boot_popup = false;
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
  osd_write(0xba); osd_write(0xbb); // P
  osd_write(0xb4); osd_write(0xb5); // R
  osd_write(0xbc); osd_write(0xbd); // O

  osd_set_pos(x + 8, y + 3);
  osd_write(0xca); osd_write(0xcb); // P
  osd_write(0xc4); osd_write(0xc5); // R
  osd_write(0xcc); osd_write(0xcd); // O

  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  print_rev();
}

static void print_header(void)
{
  print_logo(0, 0);

  osd_set_color(OSD_COLOR_GREY, OSD_COLOR_BLACK);
  osd_set_pos(19, 2);
  osd_print_p(msg(MSG_FPGA));
  for (uint8_t i = 0; i < 8; i++) {
    osd_write(s_fpga_build_num[i]);
  }

  osd_set_pos(20, 3);
  osd_print_p(msg(MSG_AVR));
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
  text(msg(MSG_PRESS));
  hint(msg_esc);
  text(msg(MSG_TO_RETURN));
}

static void render_menu_item_value(uint8_t idx, bool is_active)
{
  if (idx >= MAIN_MENU_ITEMS_COUNT) return;

  MenuItem item;
  memcpy_P(&item, &s_main_menu_items[s_lang][idx], sizeof(MenuItem));

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
  memcpy_P(&item, &s_main_menu_items[s_lang][idx], sizeof(MenuItem));

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
  memcpy_P(&item, &s_main_menu_items[s_lang][idx], sizeof(MenuItem));

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
  memcpy_P(&f, &s_rtc_fields[s_lang][idx], sizeof(RtcField));
  osd_set_pos(10, f.y_pos);

  uint16_t val = f.get_val();

  if (idx == 4) { // Month
    if (val >= 1 && val <= 12) {
      const char *m = (const char *)pgm_read_ptr(&val_months[s_lang][val - 1]);
      osd_print_p(m);
    } else {
      osd_print_p(msg_unknown);
    }
    osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
    print_space();
  } else if (idx == 6) { // DOW
    if (val >= 1 && val <= 7) {
      const char *d = (const char *)pgm_read_ptr(&val_dows[s_lang][val - 1]);
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
  memcpy_P(&f, &s_rtc_fields[s_lang][idx], sizeof(RtcField));
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
  text(msg(MSG_RTC_SETUP));

  for (uint8_t i = 0; i < RTC_FIELDS_COUNT; i++) {
    RtcField f;
    memcpy_P(&f, &s_rtc_fields[s_lang][i], sizeof(RtcField));
    osd_set_pos(0, f.y_pos);
    param(f.title);
    render_rtc_field_value(i, i == s_osd_rtc_state);
  }

  osd_set_pos(0, 17);
  text(msg(MSG_PLEASE_USE_ARROWS));
  osd_set_color(OSD_COLOR_CYAN_I, OSD_COLOR_BLACK); osd_write(17);
  text(msg(MSG_AND));
  osd_set_color(OSD_COLOR_CYAN_I, OSD_COLOR_BLACK); osd_write(16);
  osd_set_pos(0, 18);
  text(msg_to_change_values);
  osd_set_color(OSD_COLOR_CYAN_I, OSD_COLOR_BLACK); osd_write(30);
  text(msg(MSG_AND));
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
  text(msg(MSG_ABOUT));

  osd_set_pos(0, 7);
  osd_set_color(OSD_COLOR_BLUE_I, OSD_COLOR_BLACK);
  osd_print_p(msg(MSG_KARABAS_DEVELOPERS_ARE));

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
  osd_print_p(msg(MSG_SPECIAL_THANKS_TO));

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
    osd_print_p(days > 1 ? msg(MSG_MANY_DAYS) : msg(MSG_ONE_DAY));
    osd_print_p(msg(MSG_AND));
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
  text(msg(MSG_SYSTEM_INFO));

  uint8_t y = 14;

  osd_set_pos(0, 7);
  text(msg(MSG_FPGA_BUILD));
  osd_set_pos(y, 7);
  for (uint8_t i = 0; i < 8; i++) {
    osd_write(s_fpga_build_num[i]);
  }

  osd_set_pos(0, 8);
  text(msg(MSG_AVR_BUILD));
  osd_set_pos(y, 8);
  if (s_avr_build_num) osd_print(s_avr_build_num);

  osd_set_pos(0, 9);
  text(msg(MSG_PCB_REVISION));
  osd_set_pos(y, 9);
  print_rev();

  // DAC Type
  osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
  osd_set_pos(0, 10); osd_print_p(msg(MSG_DAC_TYPE));
  osd_set_pos(y, 10); osd_print_p(msg_tda1543);
  if (bitRead(s_fpga_cfg, 0) == 1) {
    osd_print_p(msg_a);
  }

  // Uptime
  osd_set_pos(0, 11); text(msg(MSG_UPTIME));
  update_uptime();

  osd_set_pos(0, 13);
  text(msg(MSG_DEBUG_INFO));

  osd_set_pos(0, 15); text(msg(MSG_SCANCODE));
  zxosd_update_scancode(0);

  osd_set_pos(0, 16); text(msg(MSG_MOUSE));
  zxosd_update_mouse(0, 0, 0);

  osd_set_pos(0, 17); text(msg(MSG_PORT_1F));
  zxosd_update_joy_state(0);

  popup_footer();
}

void zxosd_init(void)
{
  osd_init();
  s_lang = keyboard_get_lang();
  if (s_lang >= LANG_COUNT) s_lang = LANG_EN;
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
  flash(msg_s); text(msg(MSG_ETUP_RTC)); text(msg_space);
  flash(msg_i); text(msg(MSG_NFO)); flash(msg_a); text(msg(MSG_BOUT));
  text(msg_space); flash(msg_l); text(msg(MSG_ANG));

  print_line(23);

  osd_set_pos(0, 24); text(msg(MSG_PRESS)); hint(msg_ctrl_alt_del); text(msg(MSG_TO_REBOOT));
  osd_set_pos(0, 25); text(msg(MSG_PRESS)); hint(msg(MSG_MENU_ESC)); text(msg(MSG_TO_TOGGLE_OSD));
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
    memcpy_P(&item, &s_main_menu_items[s_lang][item_idx], sizeof(MenuItem));

    osd_set_color(OSD_COLOR_WHITE, OSD_COLOR_BLACK);
    osd_set_pos(0, 5);
    osd_print_p(item.title);
    print_space();

    osd_set_pos(0, 6);
    render_menu_item_value((uint8_t)item_idx, false);
    print_space();
  }
}

void zxosd_show_popup(uint8_t event_type)
{
  s_tpopup = millis();
  if (!keyboard_get_is_osd_popup()) {
    zxosd_clear();
  }
  keyboard_set_osd_popup(true);
  zxosd_init_popup(event_type);
}

void zxosd_show_boot_popup(void)
{
  s_boot_popup = true;
  zxosd_show_popup(EVENT_OSD_POPUP);
}

void zxosd_on_key_event(uint8_t event_type)
{
  if (!s_is_started) return;

  int8_t item_idx = zxosd_event_to_menu_item(event_type);
  if (keyboard_get_is_osd_overlay()) {
    if (event_type == EVENT_OSD_OVERLAY) {
      zxosd_init_overlay();
    } else if (item_idx >= 0) {
      zxosd_update_item((uint8_t)item_idx);
    }
  } else {
    if (item_idx >= 0) {
      s_boot_popup = false;
      zxosd_show_popup(event_type);
    }
  }
}

void zxosd_handle(void)
{
  if (keyboard_get_is_osd_popup()) {
    uint32_t timeout = s_boot_popup ? BOOT_POPUP_TIMEOUT : POPUP_TIMEOUT;
    if (millis() - s_tpopup > timeout) {
      keyboard_set_osd_popup(false);
      s_boot_popup = false;
    }
  }

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
      if (keyboard_get_key(ZX_K_L)) {
        s_lang = (s_lang + 1) % LANG_COUNT;
        keyboard_set_lang(s_lang);
        zxosd_init_overlay();
      }

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
