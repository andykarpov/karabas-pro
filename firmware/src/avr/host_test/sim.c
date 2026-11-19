/*
 * Host stand of the AVR firmware (run.sh): the firmware sources of src/ (except hal.c and
 * ps2_kbd.c) run on the PC against models of the hardware, and every SPI packet to the FPGA is
 * written to a log, with a line "M" at every call of link_keys() (once per pass of the main
 * loop, after the keyboard and menu changes of the pass have gone).
 *
 * Time is virtual and moves only by the calls of millis() (MILLIS_US each) and by the delays of
 * the firmware outside the link: the time line does not depend on how many bytes a link sends,
 * so a run on link v1 and a run on link v2 reach every "M" at the same time and state.
 *
 * Models:
 *   - the FPGA: link v1 (-DLINK_V1, avr.vhd of master: the answer frame is chosen when CS goes
 *     low: a queued answer (INIT, BUILD, a CPU write into the RTC), otherwise a CMD_LED frame)
 *     or link v2 (docs/AVR_LINK_V2.md: the status byte, STATUS, INIT, the FIFO of RTC GET);
 *     the SPI must not be switched off while CS is low;
 *   - PS/2 keyboard: ps2_kbd.h returns the events of the scenario (codes of ps2_kbd.h);
 *   - PS/2 mouse: reports put into the queue of mouse.c (mouse_wrap.c);
 *   - joystick pins (Kempston and a 3-button Sega pad on the strobe PC1);
 *   - DS1307 on TWI, EEPROM (erased, LED override on; argument "b": saved settings), ADC of
 *     the two buttons. Both are written to the log at the end.
 */
#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include "hal.h"
#include "ps2_kbd.h"

#define MILLIS_US 20
#define T_END_MS 14000

volatile uint8_t DDRB, DDRC, DDRD, PORTB, PORTC, PORTD, SPCR, SPSR, SPDR, SREG;

static uint64_t s_us = 0;
static jmp_buf s_end;
static FILE *s_log;

/* ---------------- UART: lines "U <text>" of the firmware, AT lines of scenario c ---------------- */
static char s_uart[80];
static unsigned s_uartn = 0;
void hal_uart_init(void) {}
void hal_uart_putc(char c)
{
  if (c == '\r') return;
  if (c == '\n' || s_uartn == sizeof(s_uart) - 1) {
    s_uart[s_uartn] = 0;
    fprintf(s_log, "U %s\n", s_uart);
    s_uartn = 0;
  } else {
    s_uart[s_uartn++] = c;
  }
}

static char s_urx[512];
static unsigned s_urx_h, s_urx_t;
static void uart_send(const char *s)
{
  while (*s) s_urx[s_urx_h++ % sizeof(s_urx)] = *s++;
  s_urx[s_urx_h++ % sizeof(s_urx)] = '\r';
  s_urx[s_urx_h++ % sizeof(s_urx)] = '\n';
}
int16_t hal_uart_getc(void) { return s_urx_h != s_urx_t ? (uint8_t)s_urx[s_urx_t++ % sizeof(s_urx)] : -1; }
static void scenario(void);

static void tick(double us)
{
  s_us += (uint64_t)us;
  if (s_us / 1000 > T_END_MS) longjmp(s_end, 1);
}

uint32_t millis(void) { tick(MILLIS_US); scenario(); return (uint32_t)(s_us / 1000); }
void sim_delay_us(double us) { tick(us); }
void delay_ms(uint16_t ms) { tick(ms * 1000.0); }
void delay_us(uint16_t us) { (void)us; } /* only the link (CS high time): not charged */
void hal_timer_init(void) {}

/* ---------------- EEPROM ---------------- */

static uint8_t s_eeprom[1024];
uint8_t eeprom_read_byte(const uint8_t *addr) { return s_eeprom[(uintptr_t)addr & 1023]; }
void eeprom_update_byte(uint8_t *addr, uint8_t val) { s_eeprom[(uintptr_t)addr & 1023] = val; }

/* ---------------- the FPGA ---------------- */

static uint8_t s_led_bits = 0x00;
static uint8_t s_rx[2100];
static unsigned s_rxn;
static bool s_cs_low;
static const char s_build[8] = { '2', '6', '1', '1', '1', '9', '0', '0' };
static const uint8_t s_cfg = (2 << 6) | 0x24; /* max turbo 2, Rev.E */
static bool s_spe_error;

static void log_packet(void)
{
  fprintf(s_log, "%llu:", (unsigned long long)s_us);
  for (unsigned i = 0; i < s_rxn; i++) fprintf(s_log, " %02X", s_rx[i]);
  fprintf(s_log, " | C%02X\n", PORTC & 0x06);
}

void hal_spi_init(void) {}

#ifdef LINK_V1
typedef struct { uint8_t b[3]; } frame_t;
static frame_t s_q[1024];
static unsigned s_qh, s_qt;
static frame_t s_tx;
static unsigned s_init_reqs;

static void q_push(uint8_t a, uint8_t b, uint8_t c)
{
  if (s_qh - s_qt < 1024) { s_q[s_qh % 1024] = (frame_t){ { a, b, c } }; s_qh++; }
}
static void cpu_rtc_write(uint8_t reg, uint8_t val) { q_push(0xFA, reg, val); }

void hal_spi_cs_low(void)
{
  s_cs_low = true;
  s_rxn = 0;
  if (s_qh != s_qt) { s_tx = s_q[s_qt % 1024]; s_qt++; }
  else s_tx = (frame_t){ { 0x0E, 0x00, s_led_bits } };
}

void hal_spi_cs_high(void)
{
  if (!s_cs_low) return;
  s_cs_low = false;
  log_packet();
  if (s_rxn == 3) {
    if (s_rx[0] == 0xFD && ++s_init_reqs >= 3) q_push(0xFD, 0x00, s_cfg);
    if (s_rx[0] == 0xF0) q_push(0xF0, s_rx[1] & 7, (uint8_t)s_build[s_rx[1] & 7]);
  }
}

static uint8_t answer(unsigned i) { return i < 3 ? s_tx.b[i] : 0xFF; }
#else
static uint16_t s_fifo[256];
static unsigned s_fh, s_ft;
static bool s_init_req = true;

static void cpu_rtc_write(uint8_t reg, uint8_t val)
{
  if (!s_init_req && s_fh - s_ft < 256) s_fifo[s_fh++ % 256] = (uint16_t)(reg << 8 | val);
}

static uint8_t status(void)
{
  return (uint8_t)((s_init_req ? 1 : 0) | (s_fh != s_ft ? 2 : 0) | (s_led_bits << 4));
}

static uint8_t s_st; /* the status of this packet */
void hal_spi_cs_low(void) { s_cs_low = true; s_rxn = 0; s_st = status(); }

void hal_spi_cs_high(void)
{
  if (!s_cs_low) return;
  s_cs_low = false;
  log_packet();
  if (s_rxn >= 2 && s_rx[0] == 0x00 && s_rx[1] == 0x02) s_init_req = false;
  if (s_rxn >= 5 && s_rx[0] == 0x03 && s_rx[1] == 0x02 && (s_st & 2)) s_ft++; /* the value byte went */
}

static uint8_t answer(unsigned i)
{
  if (i == 0) return 0x00;
  if (i == 1) return s_st;
  unsigned m = i - 2; /* payload position */
  if (s_rx[0] == 0x00 && s_rx[1] == 0x01) {
    static const uint8_t sig[] = { 'K', 'P', 2 };
    if (m >= 1 && m <= 3) return sig[m - 1];
    if (m == 4) return s_cfg;
    if (m >= 5 && m <= 12) return (uint8_t)s_build[m - 5];
    return 0;
  }
  if (s_rx[0] == 0x03 && s_rx[1] == 0x02 && (s_st & 2)) {
    if (m == 1) return (uint8_t)(s_fifo[s_ft % 256] >> 8);
    if (m == 2) return (uint8_t)s_fifo[s_ft % 256];
  }
  return 0;
}
#endif

uint8_t hal_spi_transfer(uint8_t data)
{
  uint8_t r = 0xFF;
  if (s_cs_low) {
    r = answer(s_rxn);
    if (s_rxn < sizeof(s_rx)) s_rx[s_rxn++] = data;
  }
  return r;
}

/* every pass of the main loop calls link_keys() (keyboard_transmit) */
void link_keys_real(const uint8_t *keys);
void link_keys(const uint8_t *keys)
{
  link_keys_real(keys);
  fprintf(s_log, "M %llu\n", (unsigned long long)s_us);
}

/* ---------------- TWI: DS1307 ---------------- */

static uint8_t s_ds[64] = { 0x56, 0x34, 0x12, 0x03, 0x19, 0x11, 0x26 };
void hal_twi_init(void) {}
bool hal_twi_write_reg(uint8_t dev, uint8_t reg, uint8_t data) { (void)dev; s_ds[reg & 63] = data; return true; }
bool hal_twi_read_reg(uint8_t dev, uint8_t reg, uint8_t *data) { (void)dev; *data = s_ds[reg & 63]; return true; }
bool hal_twi_write_buf(uint8_t dev, uint8_t reg, const uint8_t *buf, uint8_t len)
{
  (void)dev;
  for (uint8_t i = 0; i < len; i++) s_ds[(reg + i) & 63] = buf[i];
  return true;
}
bool hal_twi_read_buf(uint8_t dev, uint8_t reg, uint8_t *buf, uint8_t len)
{
  (void)dev;
  for (uint8_t i = 0; i < len; i++) buf[i] = s_ds[(reg + i) & 63];
  return true;
}

/* ---------------- ADC: board buttons ---------------- */

static bool s_btn1, s_btn2;
void hal_adc_init(void) {}
uint16_t hal_adc_read(uint8_t ch)
{
  if (ch == 6) return s_btn1 ? 10 : 1000;
  if (ch == 7) return s_btn2 ? 10 : 1000;
  return 1000;
}

void hal_attach_interrupt(uint8_t pin, void (*handler)(void), uint8_t mode) { (void)pin; (void)handler; (void)mode; }
void hal_detach_interrupt(uint8_t pin) { (void)pin; }

/* ---------------- joystick pins ---------------- */

enum { J_UP = 1, J_DOWN = 2, J_LEFT = 4, J_RIGHT = 8, J_B = 16, J_C = 32, J_A = 64, J_START = 128 };
static uint8_t s_joy;     /* pressed buttons */
static bool s_sega;       /* a Sega pad on the connector, else an Atari stick */

uint8_t sim_pin(char port)
{
  if (s_cs_low && !(SPCR & (1 << SPE)) && !s_spe_error) {
    s_spe_error = true;
    fprintf(s_log, "ERROR: the SPI is off while CS is low\n");
  }
  /* all inputs have pull-ups: 1 = released */
  bool up = s_joy & J_UP, down = s_joy & J_DOWN, left = s_joy & J_LEFT, right = s_joy & J_RIGHT;
  bool f1 = s_joy & J_B, f2 = s_joy & J_C;
  if (s_sega && !(PORTC & (1 << PC1))) {
    /* select low: left and right low (pad present), A and Start on the fire lines */
    left = true; right = true;
    f1 = s_joy & J_A; f2 = s_joy & J_START;
  }
  switch (port) {
    case 'B': return (uint8_t)(0xF8 | (down ? 0 : 1) | (left ? 0 : 2) | (right ? 0 : 4));
    case 'C': return (uint8_t)(0xF6 | (f1 ? 0 : 1) | (f2 ? 0 : 8));
    case 'D': return (uint8_t)(0xBF | (up ? 0 : 0x40));
  }
  return 0xFF;
}

/* ---------------- PS/2 keyboard ---------------- */

static uint16_t s_kq[256];
static unsigned s_kh, s_kt;
static uint8_t s_kstatus;

static void key(uint8_t code, bool brk)
{
  uint8_t m = 0;
  if (code == PS2_KEY_L_SHIFT || code == PS2_KEY_R_SHIFT) m = PS2_SHIFT >> 8;
  if (code == PS2_KEY_L_CTRL || code == PS2_KEY_R_CTRL) m = PS2_CTRL >> 8;
  if (code == PS2_KEY_L_ALT) m = PS2_ALT >> 8;
  if (brk) s_kstatus &= ~m; else s_kstatus |= m;
  s_kq[s_kh++ % 256] = (uint16_t)(code | (s_kstatus << 8) | (brk ? PS2_BREAK : 0));
}

void ps2_kbd_init(void) {}
void ps2_kbd_echo(void) {}
void ps2_kbd_set_lock(uint8_t leds) { (void)leds; }
bool ps2_kbd_available(void) { return s_kh != s_kt; }
uint16_t ps2_kbd_read(void) { return s_kh != s_kt ? s_kq[s_kt++ % 256] : 0; }
bool ps2_kbd_check_tx_timeout(void) { return false; }
bool ps2_kbd_is_tx_busy(void) { return false; }
bool ps2_kbd_inject(uint8_t key_id, bool up) { key(key_id, up); return true; }

/* ---------------- scenario ---------------- */

void sim_mouse_push(uint8_t status, int8_t x, int8_t y);

typedef struct { uint32_t ms; char op; uint16_t a, b; } ev_t;
enum { MENU = PS2_KEY_MENU, CTRL = PS2_KEY_L_CTRL, ALT = PS2_KEY_L_ALT, SHIFT = PS2_KEY_L_SHIFT };
/* ops: k key down + up 40 ms later, d key down, u key up, m mouse (status, x|y<<8),
   j joystick buttons, s Sega pad on / off, l LED bits, r CPU writes RTC reg a = b, 1 / 2 button */
static const ev_t s_ev[] = {
  {   10, 'k', PS2_KEY_BAT, 0 },
  { 4000, 'k', PS2_KEY_A, 0 }, { 4100, 'k', PS2_KEY_1, 0 },
  { 4200, 'd', SHIFT, 0 }, { 4250, 'k', PS2_KEY_2, 0 }, { 4300, 'k', PS2_KEY_APOS, 0 }, { 4350, 'u', SHIFT, 0 },
  { 4400, 'k', PS2_KEY_UP_ARROW, 0 }, { 4500, 'k', PS2_KEY_L_ARROW, 0 }, { 4600, 'k', PS2_KEY_BS, 0 },
  { 4700, 'k', PS2_KEY_DELETE, 0 }, { 4800, 'k', PS2_KEY_OPEN_SQ, 0 }, { 4900, 'k', PS2_KEY_ESC, 0 },
  /* Spectrum layout: the bracket macros */
  { 5000, 'k', PS2_KEY_PRTSCR, 0 }, { 5100, 'k', PS2_KEY_OPEN_SQ, 0 }, { 5500, 'k', PS2_KEY_CLOSE_SQ, 0 },
  { 5900, 'k', PS2_KEY_PGUP, 0 }, { 6000, 'k', PS2_KEY_PRTSCR, 0 },
  /* hotkeys with Menu held */
  { 6100, 'd', MENU, 0 },
  { 6150, 'k', PS2_KEY_F2, 0 }, { 6250, 'k', PS2_KEY_F5, 0 }, { 6350, 'k', PS2_KEY_F3, 0 }, { 6450, 'k', PS2_KEY_F1, 0 },
  { 6550, 'k', PS2_KEY_F6, 0 }, { 6650, 'k', PS2_KEY_F7, 0 }, { 6750, 'k', PS2_KEY_F7, 0 }, { 6850, 'k', PS2_KEY_F8, 0 },
  { 6950, 'k', PS2_KEY_F9, 0 }, { 7050, 'k', PS2_KEY_F10, 0 }, { 7150, 'k', PS2_KEY_F11, 0 }, { 7250, 'k', PS2_KEY_F11, 0 },
  { 7350, 'k', PS2_KEY_TAB, 0 }, { 7450, 'k', PS2_KEY_D, 0 }, { 7550, 'k', PS2_KEY_N, 0 }, { 7650, 'k', PS2_KEY_V, 0 },
  { 7750, 'k', PS2_KEY_M, 0 }, { 7850, 'k', PS2_KEY_F12, 0 },
  { 8100, 'u', MENU, 0 },
  { 8200, 'k', PS2_KEY_PAUSE, 0 }, { 8400, 'k', PS2_KEY_PAUSE, 0 },
  /* joystick: Sinclair 1 mapping (Joy mode was moved to 1 by Menu+M), then a Sega pad */
  { 8500, 'j', J_UP | J_B, 0 }, { 8600, 'j', 0, 0 },
  { 8650, 'd', MENU, 0 }, { 8700, 'k', PS2_KEY_J, 0 }, { 8750, 'u', MENU, 0 },
  { 8800, 's', 1, 0 }, { 8850, 'j', J_RIGHT | J_A, 0 }, { 8900, 'j', J_START, 0 }, { 8950, 'j', J_C, 0 }, { 9050, 'j', 0, 0 },
  /* mouse, with the middle button held 1.2 s (swap) */
  { 9100, 'm', 0x09, 0x0305 }, { 9150, 'm', 0x0A, 0xFDFB }, { 9200, 'm', 0x0C, 0 }, { 10450, 'm', 0x0C, 0 },
  { 10500, 'm', 0x08, 0 },
  /* the CPU writes the RTC; LED frames of the FPGA */
  { 10550, 'r', 0x00, 0x30 }, { 10551, 'r', 0x0B, 0x02 }, { 10552, 'r', 0x20, 0x5A }, { 10553, 'l', 0x0F, 0 },
  /* OSD menu: open, move, change, the RTC page, about, info, language, close */
  { 10600, 'd', MENU, 0 }, { 10650, 'k', PS2_KEY_ESC, 0 }, { 10700, 'u', MENU, 0 },
  { 10800, 'k', PS2_KEY_DN_ARROW, 0 }, { 10900, 'k', PS2_KEY_DN_ARROW, 0 }, { 11000, 'k', PS2_KEY_R_ARROW, 0 },
  { 11100, 'k', PS2_KEY_L_ARROW, 0 }, { 11200, 'k', PS2_KEY_ENTER, 0 }, { 11300, 'k', PS2_KEY_UP_ARROW, 0 },
  { 11400, 'k', PS2_KEY_S, 0 }, { 11500, 'k', PS2_KEY_DN_ARROW, 0 }, { 11600, 'k', PS2_KEY_R_ARROW, 0 },
  { 11700, 'k', PS2_KEY_ESC, 0 }, { 11800, 'k', PS2_KEY_A, 0 }, { 11900, 'k', PS2_KEY_ESC, 0 },
  { 12000, 'k', PS2_KEY_I, 0 }, { 12100, 'm', 0x09, 0x0102 }, { 12200, 'k', PS2_KEY_ESC, 0 },
  { 12300, 'k', PS2_KEY_L, 0 },
  { 12400, 'd', MENU, 0 }, { 12450, 'k', PS2_KEY_ESC, 0 }, { 12500, 'u', MENU, 0 },
  /* board buttons, Ctrl+Alt+Del, Ctrl+Alt+Backspace */
  { 12600, '1', 1, 0 }, { 12900, '1', 0, 0 }, { 13000, '2', 1, 0 }, { 13200, '2', 0, 0 },
  { 13300, 'd', CTRL, 0 }, { 13320, 'd', ALT, 0 }, { 13340, 'd', PS2_KEY_DELETE, 0 },
  { 13400, 'u', PS2_KEY_DELETE, 0 }, { 13420, 'u', ALT, 0 }, { 13440, 'u', CTRL, 0 },
  { 13500, 'd', CTRL, 0 }, { 13520, 'd', ALT, 0 }, { 13540, 'd', PS2_KEY_BS, 0 },
  { 13600, 'u', PS2_KEY_BS, 0 }, { 13620, 'u', ALT, 0 }, { 13640, 'u', CTRL, 0 },
};

/* scenario c: AT+KARABAS= lines (op a: s_at[a]); scenario d: the same keys, pad and mouse by the
   models, at the times the AT jobs make them (key 100 ms down + 40 up, type 60 + 40, pad 100 +
   40, mouse 127 counts per 10 ms, click 60 ms); run.sh compares their HID packets */
static const char *const s_at[] = {
  "AT+KARABAS=version", "AT+KARABAS=osd:turbo=2", "AT+KARABAS=osd:rombank=4", "AT+KARABAS=key:a",
  "AT+KARABAS=type:Ab1", "AT+KARABAS=pad:0:up+b", "AT+KARABAS=mouse:200,-5,1",
  "AT+KARABAS=click:right", "AT+KARABAS=bogus", "AT+KARABAS=osd:turbo=9", "AT+KARABAS=osd",
  "AT+KARABAS=hold:shift", "AT+KARABAS=key:x", "AT+KARABAS=release", "AT+KARABAS=osd:menu=1",
  "AT+KARABAS=osd:menu=0", "noise without the prefix",
};
static const ev_t s_ev_c[] = {
  { 10, 'k', PS2_KEY_BAT, 0 },
  { 3000, 'a', 0, 0 }, { 3100, 'a', 1, 0 }, { 3200, 'a', 2, 0 }, { 3300, 'a', 3, 0 },
  { 3600, 'a', 4, 0 }, { 4200, 'a', 5, 0 }, { 4600, 'a', 6, 0 }, { 4800, 'a', 7, 0 },
  { 5000, 'a', 8, 0 }, { 5050, 'a', 16, 0 }, { 5100, 'a', 9, 0 }, { 5200, 'a', 10, 0 },
  { 5300, 'a', 11, 0 }, { 5400, 'a', 12, 0 }, { 5700, 'a', 13, 0 }, { 5800, 'a', 14, 0 },
  { 6000, 'a', 15, 0 },
};
static const ev_t s_ev_d[] = {
  { 10, 'k', PS2_KEY_BAT, 0 },
  { 3300, 'd', PS2_KEY_A, 0 }, { 3400, 'u', PS2_KEY_A, 0 },
  { 3600, 'd', SHIFT, 0 }, { 3600, 'd', PS2_KEY_A, 0 }, { 3660, 'u', PS2_KEY_A, 0 }, { 3660, 'u', SHIFT, 0 },
  { 3700, 'd', PS2_KEY_B, 0 }, { 3760, 'u', PS2_KEY_B, 0 },
  { 3800, 'd', PS2_KEY_1, 0 }, { 3860, 'u', PS2_KEY_1, 0 },
  { 4200, 'j', J_UP | J_B, 0 }, { 4300, 'j', 0, 0 },
  { 4600, 'm', 0x09, 0x057F }, { 4610, 'm', 0x09, 0x0049 },
  { 4800, 'm', 0x0B, 0 }, { 4860, 'm', 0x09, 0 },
  { 5300, 'd', SHIFT, 0 }, { 5400, 'u', SHIFT, 0 }, { 5400, 'd', PS2_KEY_X, 0 }, { 5500, 'u', PS2_KEY_X, 0 },
  { 5700, 'm', 0x08, 0 },
};
static const ev_t *s_evp = s_ev;
static unsigned s_evn = sizeof(s_ev) / sizeof(s_ev[0]);

static unsigned s_evi;
static ev_t s_ups[16];
static unsigned s_nups;

static void scenario(void)
{
  uint32_t now = (uint32_t)(s_us / 1000);
  for (unsigned i = 0; i < s_nups; i++) {
    if (s_ups[i].ms <= now) { key((uint8_t)s_ups[i].a, true); s_ups[i] = s_ups[--s_nups]; i--; }
  }
  while (s_evi < s_evn && s_evp[s_evi].ms <= now) {
    const ev_t *e = &s_evp[s_evi++];
    switch (e->op) {
      case 'k': key((uint8_t)e->a, false); s_ups[s_nups++] = (ev_t){ now + 40, 'u', e->a, 0 }; break;
      case 'd': key((uint8_t)e->a, false); break;
      case 'u': key((uint8_t)e->a, true); break;
      case 'm': sim_mouse_push((uint8_t)e->a, (int8_t)(e->b & 0xFF), (int8_t)(e->b >> 8)); break;
      case 'j': s_joy = (uint8_t)e->a; break;
      case 's': s_sega = e->a != 0; break;
      case 'l': s_led_bits = (uint8_t)e->a; break;
      case 'r': cpu_rtc_write((uint8_t)e->a, (uint8_t)e->b); break;
      case '1': s_btn1 = e->a != 0; break;
      case '2': s_btn2 = e->a != 0; break;
      case 'a': uart_send(s_at[e->a]); break;
    }
  }
}

int avr_main(void);

int main(int argc, char **argv)
{
  s_log = fopen(argc > 1 ? argv[1] : "spi.log", "w");
  if (!s_log) { perror("log"); return 1; }
  memset(s_eeprom, 0xFF, sizeof(s_eeprom));
  s_eeprom[0x12] = 10; /* EEPROM_LED_OVERRIDE_ADDRESS = true */
  if (argc > 2 && argv[2][0] == 'b') {
    /* saved settings (10 true, 20 false): ROM bank +3e over bank 1, turbo 2, Spectrum layout,
       ABC, RGB, Sega, Cursor, Classic, DivMMC, Russian */
    s_eeprom[0x15] = 10; s_eeprom[0x04] = 10; s_eeprom[0x00] = 2; s_eeprom[0x01] = 20;
    s_eeprom[0x08] = 10; s_eeprom[0x02] = 10; s_eeprom[0x0D] = 10; s_eeprom[0x0F] = 3;
    s_eeprom[0x0E] = 1; s_eeprom[0x10] = 10; s_eeprom[0x14] = 1;
    s_sega = true;
  }
  if (argc > 2 && argv[2][0] == 'c') { s_evp = s_ev_c; s_evn = sizeof(s_ev_c) / sizeof(s_ev_c[0]); }
  if (argc > 2 && argv[2][0] == 'd') { s_evp = s_ev_d; s_evn = sizeof(s_ev_d) / sizeof(s_ev_d[0]); }
  PORTD = 0x80;
  if (!setjmp(s_end)) avr_main();
  fprintf(s_log, "end at %llu us\nEEPROM", (unsigned long long)s_us);
  for (unsigned i = 0; i < 512; i++) fprintf(s_log, "%s%02X", i % 32 ? " " : "\n", s_eeprom[i]);
  fprintf(s_log, "\nDS1307");
  for (unsigned i = 0; i < 64; i++) fprintf(s_log, " %02X", s_ds[i]);
  fprintf(s_log, "\n");
  fclose(s_log);
  return 0;
}
