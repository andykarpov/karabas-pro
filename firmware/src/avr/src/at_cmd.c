/*
 * AT+KARABAS= commands on the UART (PD0 / PD1, 115200 8N1), after the control port of
 * Karabas Go: a test bench can type, move the mouse, press the joystick and set the menu items
 * without a keyboard. docs/AT_KARABAS.md has the list.
 *
 * Keys go into the PS/2 keyboard queue as decoded keys (ps2_kbd_inject), so the hotkeys, the
 * OSD and the ZX matrix see them as from a keyboard; the mouse reports go into the PS/2 mouse
 * queue; the pad buttons are held on top of the real joystick. A command that takes time (key,
 * type, pad, mouse, click) answers OK when it is done; the next line is read after that.
 *
 * An idle pass reads the UART only (no millis()): the host stand of link v1 / v2 gets the same
 * time line with it.
 */

#include <string.h>
#include "at_cmd.h"
#include "hal.h"
#include "ps2_kbd.h"
#include "mouse.h"
#include "joystick.h"
#include "keyboard.h"
#include "zxosd.h"
#include "link.h"
#include "utils.h"

#define STRINGIFY(s) STRINGIFY1(s)
#define STRINGIFY1(s) #s

#define LINE_SIZE 84

static char s_line[LINE_SIZE];
static uint8_t s_len = 0;
static bool s_overflow = false;
static char s_fpga[9] = "????????";

enum { J_NONE, J_KEY, J_TYPE, J_PAD, J_MOUSE, J_CLICK };
static uint8_t s_job = J_NONE;
static const char *s_p;      // the next token of the job (in s_line)
static uint8_t s_phase = 0;
static uint32_t s_t = 0;
static uint16_t s_wait = 0;

static uint8_t s_combo[4], s_ncombo = 0; // keys of the job down now
static uint8_t s_hold[4], s_nhold = 0;   // hold:
static uint16_t s_pad_hold = 0;          // padhold:
static uint8_t s_mbtn = 0;               // mouse buttons held (bit 0 left, 1 right, 2 middle)
static int16_t s_mx = 0, s_my = 0;       // mouse: the move left to send
static uint8_t s_click = 0;

void at_on_build(uint8_t pos, uint8_t c)
{
  if (pos < 8) s_fpga[pos] = (char)c;
}

/* ---------------- output ---------------- */

static void out(const char *s) { while (*s) hal_uart_putc(*s++); }
static void out_p(const char *s) { char c; while ((c = (char)pgm_read_byte(s++))) hal_uart_putc(c); }
static void out_num(uint16_t v)
{
  char b[6];
  uint8_t i = sizeof(b);
  b[--i] = 0;
  do { b[--i] = (char)('0' + v % 10); v /= 10; } while (v);
  out(&b[i]);
}
static void ok(void) { out_p(PSTR("OK\r\n")); }
static void error(void) { out_p(PSTR("ERROR\r\n")); }

/* ---------------- parsing ---------------- */

static char lower(char c) { return (c >= 'A' && c <= 'Z') ? (char)(c + 32) : c; }

// s (n chars, any case) is the PROGMEM name p
static bool is_name(const char *s, uint8_t n, const char *p)
{
  for (uint8_t i = 0; i < n; i++) {
    char c = (char)pgm_read_byte(p + i);
    if (!c || lower(s[i]) != c) return false;
  }
  return pgm_read_byte(p + n) == 0;
}

// s starts with the PROGMEM prefix p: the rest, or 0
static const char *after(const char *s, const char *p)
{
  char c;
  while ((c = (char)pgm_read_byte(p++))) {
    if (lower(*s++) != c) return 0;
  }
  return s;
}

static bool parse_num(const char **ps, int16_t *v)
{
  const char *s = *ps;
  bool neg = (*s == '-');
  if (neg || *s == '+') s++;
  if (*s < '0' || *s > '9') return false;
  int16_t n = 0;
  while (*s >= '0' && *s <= '9') {
    if (n > 3000) return false;
    n = (int16_t)(n * 10 + (*s++ - '0'));
  }
  *v = neg ? (int16_t)-n : n;
  *ps = s;
  return true;
}

// the next token apart by spaces: its length (0 at the end), *ps moves past it
static uint8_t token(const char **ps, const char **tok)
{
  const char *s = *ps;
  while (*s == ' ') s++;
  *tok = s;
  while (*s && *s != ' ') s++;
  *ps = s;
  return (uint8_t)(s - *tok);
}

/* ---------------- keys ---------------- */

typedef struct { char name[10]; uint8_t id; } kname_t;
static const kname_t PROGMEM s_keys[] = {
  { "esc", PS2_KEY_ESC }, { "enter", PS2_KEY_ENTER }, { "space", PS2_KEY_SPACE },
  { "tab", PS2_KEY_TAB }, { "bs", PS2_KEY_BS }, { "backspace", PS2_KEY_BS },
  { "del", PS2_KEY_DELETE }, { "delete", PS2_KEY_DELETE }, { "ins", PS2_KEY_INSERT },
  { "insert", PS2_KEY_INSERT }, { "home", PS2_KEY_HOME }, { "end", PS2_KEY_END },
  { "pgup", PS2_KEY_PGUP }, { "pgdn", PS2_KEY_PGDN }, { "up", PS2_KEY_UP_ARROW },
  { "down", PS2_KEY_DN_ARROW }, { "left", PS2_KEY_L_ARROW }, { "right", PS2_KEY_R_ARROW },
  { "caps", PS2_KEY_CAPS }, { "ctrl", PS2_KEY_L_CTRL }, { "lctrl", PS2_KEY_L_CTRL },
  { "rctrl", PS2_KEY_R_CTRL }, { "shift", PS2_KEY_L_SHIFT }, { "lshift", PS2_KEY_L_SHIFT },
  { "rshift", PS2_KEY_R_SHIFT }, { "alt", PS2_KEY_L_ALT }, { "lalt", PS2_KEY_L_ALT },
  { "ralt", PS2_KEY_R_ALT }, { "altgr", PS2_KEY_R_ALT }, { "gui", PS2_KEY_L_GUI },
  { "win", PS2_KEY_L_GUI }, { "lgui", PS2_KEY_L_GUI }, { "rgui", PS2_KEY_R_GUI },
  { "menu", PS2_KEY_MENU }, { "prtscr", PS2_KEY_PRTSCR }, { "scroll", PS2_KEY_SCROLL },
  { "pause", PS2_KEY_PAUSE }, { "num", PS2_KEY_NUM }, { "minus", PS2_KEY_MINUS },
  { "equal", PS2_KEY_EQUAL }, { "lbracket", PS2_KEY_OPEN_SQ }, { "rbracket", PS2_KEY_CLOSE_SQ },
  { "backslash", PS2_KEY_BACKSLASH }, { "semicolon", PS2_KEY_SEMI }, { "quote", PS2_KEY_APOS },
  { "grave", PS2_KEY_SINGLE }, { "comma", PS2_KEY_COMMA }, { "dot", PS2_KEY_DOT },
  { "slash", PS2_KEY_DIV }, { "kpenter", PS2_KEY_KP_ENTER }, { "kpplus", PS2_KEY_KP_PLUS },
  { "kpminus", PS2_KEY_KP_MINUS }, { "kpdot", PS2_KEY_KP_DOT },
};

// a key by its name: 0 unknown
static uint8_t key_id(const char *s, uint8_t n)
{
  if (n == 1) {
    char c = lower(s[0]);
    if (c >= 'a' && c <= 'z') return (uint8_t)(PS2_KEY_A + (c - 'a'));
    if (c >= '0' && c <= '9') return (uint8_t)(PS2_KEY_0 + (c - '0'));
  }
  if ((n == 2 || n == 3) && lower(s[0]) == 'f' && s[1] >= '1' && s[1] <= '9') {
    uint8_t f = (uint8_t)(s[1] - '0');
    if (n == 3) {
      if (s[2] < '0' || s[2] > '9') return 0;
      f = (uint8_t)(f * 10 + (s[2] - '0'));
    }
    return (f >= 1 && f <= 12) ? (uint8_t)(PS2_KEY_F1 + f - 1) : 0;
  }
  if (n == 3 && lower(s[0]) == 'k' && lower(s[1]) == 'p' && s[2] >= '0' && s[2] <= '9') {
    return (uint8_t)(PS2_KEY_KP0 + (s[2] - '0'));
  }
  for (uint8_t i = 0; i < sizeof(s_keys) / sizeof(s_keys[0]); i++) {
    if (is_name(s, n, s_keys[i].name)) return pgm_read_byte(&s_keys[i].id);
  }
  return 0;
}

// a combo "ctrl+alt+del" into ids (at most 4): their number, 0 when a name is unknown
static uint8_t combo(const char *s, uint8_t n, uint8_t ids[4])
{
  uint8_t k = 0;
  while (n) {
    uint8_t m = 0;
    while (m < n && s[m] != '+') m++;
    uint8_t id = (m && k < 4) ? key_id(s, m) : 0;
    if (!id) return 0;
    ids[k++] = id;
    if (m == n) break;
    s += m + 1;
    n = (uint8_t)(n - m - 1);
  }
  return k;
}

static void keys_down(const uint8_t *ids, uint8_t n)
{
  for (uint8_t i = 0; i < n; i++) ps2_kbd_inject(ids[i], false);
}

static void keys_up(const uint8_t *ids, uint8_t n)
{
  while (n) ps2_kbd_inject(ids[--n], true);
}

static void release_hold(void)
{
  keys_up(s_hold, s_nhold);
  s_nhold = 0;
}

// ASCII (US layout) of type: the key, *shift; 0 not typeable
static const char PROGMEM s_punct[] = "-=[]\\;'`,./";
static const char PROGMEM s_punct_sh[] = "_+{}|:\"~<>?";
static const char PROGMEM s_digit_sh[] = ")!@#$%^&*(";
static const uint8_t PROGMEM s_punct_id[] = {
  PS2_KEY_MINUS, PS2_KEY_EQUAL, PS2_KEY_OPEN_SQ, PS2_KEY_CLOSE_SQ, PS2_KEY_BACKSLASH,
  PS2_KEY_SEMI, PS2_KEY_APOS, PS2_KEY_SINGLE, PS2_KEY_COMMA, PS2_KEY_DOT, PS2_KEY_DIV,
};

static uint8_t ascii_key(char c, bool *shift)
{
  *shift = false;
  if (c >= 'a' && c <= 'z') return (uint8_t)(PS2_KEY_A + (c - 'a'));
  if (c >= 'A' && c <= 'Z') { *shift = true; return (uint8_t)(PS2_KEY_A + (c - 'A')); }
  if (c >= '0' && c <= '9') return (uint8_t)(PS2_KEY_0 + (c - '0'));
  if (c == ' ') return PS2_KEY_SPACE;
  for (uint8_t i = 0; i < 10; i++) {
    if (c == (char)pgm_read_byte(&s_digit_sh[i])) { *shift = true; return (uint8_t)(PS2_KEY_0 + i); }
  }
  for (uint8_t i = 0; i < sizeof(s_punct_id); i++) {
    if (c == (char)pgm_read_byte(&s_punct[i])) return pgm_read_byte(&s_punct_id[i]);
    if (c == (char)pgm_read_byte(&s_punct_sh[i])) { *shift = true; return pgm_read_byte(&s_punct_id[i]); }
  }
  return 0;
}

/* ---------------- joystick ---------------- */

static const char PROGMEM s_pad_names[] = "up\0down\0left\0right\0start\0a\0b\0c\0x\0y\0z\0mode\0";

// "up+a": LJ_* bits, false when a name is unknown
static bool pad_bits(const char *s, uint8_t n, uint16_t *bits)
{
  uint16_t b = 0;
  while (n) {
    uint8_t m = 0;
    while (m < n && s[m] != '+') m++;
    const char *p = s_pad_names;
    uint16_t bit = LJ_UP;
    bool found = false;
    while (pgm_read_byte(p)) {
      if (is_name(s, m, p)) { b |= bit; found = true; break; }
      while (pgm_read_byte(p)) p++;
      p++;
      bit <<= 1;
    }
    if (!found) return false;
    if (m == n) break;
    s += m + 1;
    n = (uint8_t)(n - m - 1);
  }
  *bits = b;
  return true;
}

/* ---------------- menu items ---------------- */

typedef struct { char name[11]; uint8_t event; } item_t;
#define NO_EVENT 0xFF
static const item_t PROGMEM s_items[] = {
  { "rombank", EVENT_OSD_ROMBANK }, { "turbofdc", EVENT_OSD_TURBOFDC },
  { "covox", EVENT_OSD_COVOX }, { "psg_mix", EVENT_OSD_STEREO },
  { "psg_type", EVENT_OSD_SSG }, { "video", EVENT_OSD_VIDEO },
  { "vsync", EVENT_OSD_VSYNC }, { "turbo", EVENT_OSD_TURBO },
  { "swap_fdd", EVENT_OSD_SWAP_AB }, { "joy_type", EVENT_OSD_JOYSTICK },
  { "joy_mode", EVENT_OSD_JOYSTICK_MODE }, { "screen", EVENT_OSD_SCREEN_MODE },
  { "divmmc", EVENT_OSD_DIVMMC }, { "nemoide", EVENT_OSD_NEMOIDE },
  { "keyboard", EVENT_OSD_KEYBOARD_TYPE }, { "pause", NO_EVENT },
  { "mouse_swap", NO_EVENT }, { "lang", NO_EVENT }, { "menu", NO_EVENT },
};
#define ITEMS (sizeof(s_items) / sizeof(s_items[0]))

static uint8_t item_get(uint8_t i)
{
  switch (i) {
    case 0: return keyboard_get_rombank();
    case 1: return keyboard_get_turbofdc();
    case 2: return keyboard_get_covox();
    case 3: return keyboard_get_stereo();
    case 4: return keyboard_get_ssg();
    case 5: return keyboard_get_video();
    case 6: return keyboard_get_vsync();
    case 7: return keyboard_get_turbo();
    case 8: return keyboard_get_swap_ab();
    case 9: return keyboard_get_joy_type();
    case 10: return keyboard_get_joy_mode();
    case 11: return keyboard_get_screen_mode();
    case 12: return keyboard_get_divmmc();
    case 13: return keyboard_get_nemoide();
    case 14: return keyboard_get_keyboard_type();
    case 15: return keyboard_get_pause();
    case 16: return keyboard_get_mouse_swap();
    case 17: return keyboard_get_lang();
    default: return keyboard_get_is_osd_overlay();
  }
}

static uint8_t item_max(uint8_t i)
{
  switch (i) {
    case 0: return 4;
    case 3: return 2;
    case 7: return keyboard_get_max_turbo();
    case 10: return 4;
    case 11: return keyboard_get_max_screen_mode();
    case 17: return LANG_COUNT - 1;
    default: return 1;
  }
}

static void item_set(uint8_t i, uint8_t v)
{
  bool change = item_get(i) != v;
  switch (i) {
    case 0: keyboard_set_rombank(v); break;
    case 1: if (change) keyboard_toggle_turbofdc(); break;
    case 2: if (change) keyboard_toggle_covox(); break;
    case 3: keyboard_toggle_stereo(v); break;
    case 4: if (change) keyboard_toggle_ssg(); break;
    case 5: if (change) keyboard_toggle_video(); break;
    case 6: if (change) keyboard_toggle_vsync(); break;
    case 7: keyboard_set_turbo(v); break;
    case 8: if (change) keyboard_toggle_swap_ab(); break;
    case 9: if (change) keyboard_toggle_joy_type(); break;
    case 10: keyboard_set_joy_mode(v); break;
    case 11: keyboard_set_screen_mode(v); break;
    case 12: keyboard_set_divmmc(v); break;
    case 13: keyboard_set_nemoide(v); break;
    case 14: if (change) keyboard_toggle_keyboard_type(); break;
    case 15: if (change) keyboard_do_pause(); break;
    case 16: keyboard_set_mouse_swap(v); mouse_set_swap(v); break;
    case 17:
      keyboard_set_lang(v);
      if (keyboard_get_is_osd_overlay()) zxosd_init_overlay();
      break;
    default: if (change) keyboard_toggle_osd_overlay(); break;
  }
  uint8_t ev = pgm_read_byte(&s_items[i].event);
  if (ev != NO_EVENT) zxosd_on_key_event(ev);
}

static void item_print(uint8_t i)
{
  out_p(PSTR("+KARABAS:item;"));
  out_num(i);
  hal_uart_putc(';');
  out_p(s_items[i].name);
  hal_uart_putc(';');
  out_num(item_get(i));
  hal_uart_putc(';');
  out_num(item_max(i));
  out_p(PSTR("\r\n"));
}

// "osd", "osd:<item>", "osd:<item>=<value>"; the item by name or #<pos>
static void cmd_osd(const char *a)
{
  if (!a) {
    for (uint8_t i = 0; i < ITEMS; i++) item_print(i);
    ok();
    return;
  }
  uint8_t n = 0;
  while (a[n] && a[n] != '=') n++;
  uint8_t idx = 0xFF;
  if (a[0] == '#') {
    const char *s = a + 1;
    int16_t v;
    if (parse_num(&s, &v) && s == a + n && v >= 0 && v < (int16_t)ITEMS) idx = (uint8_t)v;
  } else {
    for (uint8_t i = 0; i < ITEMS; i++) {
      if (is_name(a, n, s_items[i].name)) idx = i;
    }
  }
  if (idx == 0xFF) { error(); return; }
  if (a[n] == '=') {
    const char *s = a + n + 1;
    int16_t v;
    if (!parse_num(&s, &v) || *s || v < 0 || v > item_max(idx)) { error(); return; }
    item_set(idx, (uint8_t)v);
  }
  item_print(idx);
  ok();
}

/* ---------------- jobs ---------------- */

static void start(uint8_t job, const char *arg)
{
  s_job = job;
  s_p = arg;
  s_phase = 0;
  s_wait = 0;
  s_t = millis();
}

static void done(bool good)
{
  s_job = J_NONE;
  if (good) ok(); else error();
}

static void mouse_report(uint8_t btn, int16_t dx, int16_t dy)
{
  // PS/2: bit 3 always 1; y up is positive (a USB mouse: down)
  mouse_inject((uint8_t)(0x08 | (btn & 7)), (int8_t)dx, (int8_t)-dy);
}

static void run_job(void)
{
  uint32_t n = millis();
  if ((uint32_t)(n - s_t) < s_wait) return;
  s_t = n;
  s_wait = 0;
  const char *tok;
  uint8_t len;
  switch (s_job) {
    case J_KEY:
      if (s_phase) {
        keys_up(s_combo, s_ncombo);
        s_ncombo = 0;
        s_phase = 0;
        s_wait = 40;
        return;
      }
      len = token(&s_p, &tok);
      if (!len) { done(true); return; }
      s_ncombo = combo(tok, len, s_combo);
      if (!s_ncombo) { done(false); return; }
      keys_down(s_combo, s_ncombo);
      s_phase = 1;
      s_wait = 100;
      return;

    case J_TYPE: {
      bool shift;
      if (s_phase) {
        keys_up(s_combo, s_ncombo);
        s_ncombo = 0;
        s_phase = 0;
        s_wait = 40;
        return;
      }
      char c = *s_p;
      if (!c) { done(true); return; }
      s_p++;
      uint8_t id = ascii_key(c, &shift);
      if (!id) { done(false); return; }
      s_ncombo = 0;
      if (shift) s_combo[s_ncombo++] = PS2_KEY_L_SHIFT;
      s_combo[s_ncombo++] = id;
      keys_down(s_combo, s_ncombo);
      s_phase = 1;
      s_wait = 60;
      return;
    }

    case J_PAD: {
      if (s_phase) {
        joystick_set_at_buttons(s_pad_hold);
        s_phase = 0;
        s_wait = 40;
        return;
      }
      len = token(&s_p, &tok);
      if (!len) { done(true); return; }
      uint16_t bits;
      if (!pad_bits(tok, len, &bits)) { done(false); return; }
      joystick_set_at_buttons(s_pad_hold | bits);
      s_phase = 1;
      s_wait = 100;
      return;
    }

    case J_MOUSE: {
      if (!s_mx && !s_my && s_phase) { done(true); return; }
      int16_t dx = s_mx > 127 ? 127 : (s_mx < -127 ? -127 : s_mx);
      int16_t dy = s_my > 127 ? 127 : (s_my < -127 ? -127 : s_my);
      mouse_report(s_mbtn, dx, dy);
      s_mx = (int16_t)(s_mx - dx);
      s_my = (int16_t)(s_my - dy);
      s_phase = 1;
      s_wait = 10;
      return;
    }

    case J_CLICK:
      if (s_phase) {
        mouse_report(s_mbtn, 0, 0);
        done(true);
        return;
      }
      mouse_report(s_mbtn | s_click, 0, 0);
      s_phase = 1;
      s_wait = 60;
      return;
  }
}

/* ---------------- commands ---------------- */

static void command(const char *c)
{
  const char *a;
  if ((a = after(c, PSTR("key:")))) {
    release_hold();
    start(J_KEY, a);
  } else if ((a = after(c, PSTR("type:")))) {
    release_hold();
    start(J_TYPE, a);
  } else if ((a = after(c, PSTR("hold:")))) {
    release_hold();
    const char *tok;
    uint8_t len = token(&a, &tok);
    s_nhold = len ? combo(tok, len, s_hold) : 0;
    if (!s_nhold) { error(); return; }
    keys_down(s_hold, s_nhold);
    ok();
  } else if (after(c, PSTR("release")) && !c[7]) {
    release_hold();
    s_pad_hold = 0;
    joystick_set_at_buttons(0);
    if (s_mbtn) { s_mbtn = 0; mouse_report(0, 0, 0); }
    ok();
  } else if (after(c, PSTR("sync")) && !c[4]) {
    ok(); // the commands answer when they are done: nothing is queued here
  } else if ((a = after(c, PSTR("mouse:")))) {
    int16_t dx, dy, b;
    if (!parse_num(&a, &dx) || *a++ != ',' || !parse_num(&a, &dy)) { error(); return; }
    if (*a == ',') {
      a++;
      if (*a) {
        if (!parse_num(&a, &b) || b < 0 || b > 7) { error(); return; }
        s_mbtn = (uint8_t)b;
      }
    }
    if (*a) { error(); return; }
    s_mx = dx;
    s_my = dy;
    start(J_MOUSE, a);
  } else if ((a = after(c, PSTR("click")))) {
    s_click = 1;
    if (*a == ':') {
      a++;
      if (is_name(a, (uint8_t)strlen(a), PSTR("right"))) s_click = 2;
      else if (is_name(a, (uint8_t)strlen(a), PSTR("middle"))) s_click = 4;
      else if (!is_name(a, (uint8_t)strlen(a), PSTR("left"))) { error(); return; }
    } else if (*a) { error(); return; }
    start(J_CLICK, a);
  } else if ((a = after(c, PSTR("pad:"))) || (a = after(c, PSTR("padhold:")))) {
    bool hold = (c[3] != ':');
    if (a[0] == '0' && a[1] == ':') a += 2; // the only port (as pad:0: of Karabas Go)
    if (hold) {
      const char *tok;
      uint8_t len = token(&a, &tok);
      uint16_t bits;
      if (!len || !pad_bits(tok, len, &bits)) { error(); return; }
      s_pad_hold = bits;
      joystick_set_at_buttons(bits);
      ok();
    } else {
      start(J_PAD, a);
    }
  } else if ((a = after(c, PSTR("osd")))) {
    if (*a == ':') cmd_osd(a + 1);
    else if (!*a) cmd_osd(0);
    else error();
  } else if (after(c, PSTR("version")) && !c[7]) {
    out_p(PSTR("+KARABAS:"));
    out(STRINGIFY(BUILD_VER));
    out_p(PSTR(";pro;"));
    out(s_fpga);
    out_p(PSTR("\r\n"));
    ok();
  } else if (after(c, PSTR("state")) && !c[5]) {
    out_p(PSTR("+KARABAS:osd;"));
    out_num(keyboard_get_is_osd_overlay());
    hal_uart_putc(';');
    out_num(keyboard_get_is_osd_popup());
    out_p(PSTR("\r\n"));
    ok();
  } else if (after(c, PSTR("reset")) && !c[5]) {
    keyboard_do_reset();
    ok();
  } else if (after(c, PSTR("magic")) && !c[5]) {
    keyboard_do_magic();
    ok();
  } else {
    error();
  }
}

void at_handle(void)
{
  if (s_job) {
    run_job();
    return;
  }
  int16_t c;
  while ((c = hal_uart_getc()) >= 0) {
    if (c == '\r' || c == '\n') {
      if (!s_len) continue;
      s_line[s_len] = 0;
      bool bad = s_overflow;
      s_len = 0;
      s_overflow = false;
      const char *cmd = after(s_line, PSTR("at+karabas="));
      if (!cmd) continue; // not ours (an echo, noise)
      if (bad) error(); else command(cmd);
      if (s_job) return; // the rest waits until the job is done (s_line holds its argument)
    } else if (s_len < LINE_SIZE - 1) {
      s_line[s_len++] = (char)c;
    } else {
      s_overflow = true;
    }
  }
}
