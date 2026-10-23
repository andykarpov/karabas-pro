#include "ps2_kbd.h"
#include "hal.h"
#include <avr/pgmspace.h>

#define RX_BUFF_SIZE 32
#define TX_BUFF_SIZE 16

#define MODE_BUSY          0x80
#define MODE_TX            0x40
#define MODE_BREAK         0x20
#define MODE_WAIT_RESP     0x10
#define MODE_E0            0x08
#define MODE_E1            0x04
#define MODE_LAST_VALID    0x02

#define TX_HANDSHAKE       0x80
#define TX_COMMAND         0x01

#define KC_RESEND   0xFE
#define KC_ACK      0xFA
#define KC_ECHO     0xEE
#define KC_BAT      0xAA
#define KC_OVERRUN  0xFF
#define KC_ERROR    0xFC
#define KC_KEYBREAK 0xF0
#define KC_EXTEND   0xE0
#define KC_EXTEND1  0xE1
#define KC_LOCK     0xED

#define KEY_IGNORE  0xBB

// Single-byte scan code set 2 to key ID table
static const uint8_t PROGMEM s_single_key[][2] = {
  { 0x77, PS2_KEY_NUM },
  { 0x7E, PS2_KEY_SCROLL },
  { 0x58, PS2_KEY_CAPS },
  { 0x12, PS2_KEY_L_SHIFT },
  { 0x59, PS2_KEY_R_SHIFT },
  { 0x14, PS2_KEY_L_CTRL },
  { 0x11, PS2_KEY_L_ALT },
  { 0x7C, PS2_KEY_SYSRQ },
  { 0x76, PS2_KEY_ESC },
  { 0x66, PS2_KEY_BS },
  { 0x0D, PS2_KEY_TAB },
  { 0x5A, PS2_KEY_ENTER },
  { 0x29, PS2_KEY_SPACE },
  { 0x70, PS2_KEY_KP0 },
  { 0x69, PS2_KEY_KP1 },
  { 0x72, PS2_KEY_KP2 },
  { 0x7A, PS2_KEY_KP3 },
  { 0x6B, PS2_KEY_KP4 },
  { 0x73, PS2_KEY_KP5 },
  { 0x74, PS2_KEY_KP6 },
  { 0x6C, PS2_KEY_KP7 },
  { 0x75, PS2_KEY_KP8 },
  { 0x7D, PS2_KEY_KP9 },
  { 0x71, PS2_KEY_KP_DOT },
  { 0x79, PS2_KEY_KP_PLUS },
  { 0x7B, PS2_KEY_KP_MINUS },
  { 0x7C, PS2_KEY_KP_TIMES },
  { 0x45, PS2_KEY_0 },
  { 0x16, PS2_KEY_1 },
  { 0x1E, PS2_KEY_2 },
  { 0x26, PS2_KEY_3 },
  { 0x25, PS2_KEY_4 },
  { 0x2E, PS2_KEY_5 },
  { 0x36, PS2_KEY_6 },
  { 0x3D, PS2_KEY_7 },
  { 0x3E, PS2_KEY_8 },
  { 0x46, PS2_KEY_9 },
  { 0x52, PS2_KEY_APOS },
  { 0x41, PS2_KEY_COMMA },
  { 0x4E, PS2_KEY_MINUS },
  { 0x49, PS2_KEY_DOT },
  { 0x4A, PS2_KEY_DIV },
  { 0x0E, PS2_KEY_SINGLE },
  { 0x1C, PS2_KEY_A },
  { 0x32, PS2_KEY_B },
  { 0x21, PS2_KEY_C },
  { 0x23, PS2_KEY_D },
  { 0x24, PS2_KEY_E },
  { 0x2B, PS2_KEY_F },
  { 0x34, PS2_KEY_G },
  { 0x33, PS2_KEY_H },
  { 0x43, PS2_KEY_I },
  { 0x3B, PS2_KEY_J },
  { 0x42, PS2_KEY_K },
  { 0x4B, PS2_KEY_L },
  { 0x3A, PS2_KEY_M },
  { 0x31, PS2_KEY_N },
  { 0x44, PS2_KEY_O },
  { 0x4D, PS2_KEY_P },
  { 0x15, PS2_KEY_Q },
  { 0x2D, PS2_KEY_R },
  { 0x1B, PS2_KEY_S },
  { 0x2C, PS2_KEY_T },
  { 0x3C, PS2_KEY_U },
  { 0x2A, PS2_KEY_V },
  { 0x1D, PS2_KEY_W },
  { 0x22, PS2_KEY_X },
  { 0x35, PS2_KEY_Y },
  { 0x1A, PS2_KEY_Z },
  { 0x4C, PS2_KEY_SEMI },
  { 0x5D, PS2_KEY_BACKSLASH },
  { 0x54, PS2_KEY_OPEN_SQ },
  { 0x5B, PS2_KEY_CLOSE_SQ },
  { 0x55, PS2_KEY_EQUAL },
  { 0x05, PS2_KEY_F1 },
  { 0x06, PS2_KEY_F2 },
  { 0x04, PS2_KEY_F3 },
  { 0x0C, PS2_KEY_F4 },
  { 0x03, PS2_KEY_F5 },
  { 0x0B, PS2_KEY_F6 },
  { 0x83, PS2_KEY_F7 },
  { 0x0A, PS2_KEY_F8 },
  { 0x01, PS2_KEY_F9 },
  { 0x09, PS2_KEY_F10 },
  { 0x78, PS2_KEY_F11 },
  { 0x07, PS2_KEY_F12 }
};

// Extended scancodes (preceded by E0) table
static const uint8_t PROGMEM s_extended_key[][2] = {
  { 0x7C, PS2_KEY_PRTSCR },
  { 0x14, PS2_KEY_R_CTRL },
  { 0x11, PS2_KEY_R_ALT },
  { 0x1F, PS2_KEY_L_GUI },
  { 0x27, PS2_KEY_R_GUI },
  { 0x2F, PS2_KEY_MENU },
  { 0x6C, PS2_KEY_HOME },
  { 0x69, PS2_KEY_END },
  { 0x7D, PS2_KEY_PGUP },
  { 0x7A, PS2_KEY_PGDN },
  { 0x6B, PS2_KEY_L_ARROW },
  { 0x74, PS2_KEY_R_ARROW },
  { 0x75, PS2_KEY_UP_ARROW },
  { 0x72, PS2_KEY_DN_ARROW },
  { 0x70, PS2_KEY_INSERT },
  { 0x71, PS2_KEY_DELETE },
  { 0x5A, PS2_KEY_KP_ENTER },
  { 0x4A, PS2_KEY_KP_DIV }
};

static volatile uint8_t s_ps2_mode = 0;
static volatile uint16_t s_rx_buffer[RX_BUFF_SIZE];
static volatile uint8_t s_rx_head = 0;
static uint8_t s_rx_tail = 0;
static volatile int8_t s_bytes_expected = 0;
static volatile uint8_t s_bitcount = 0;
static volatile uint8_t s_shiftdata = 0;
static volatile uint8_t s_parity = 0;

static volatile uint8_t s_tx_buff[TX_BUFF_SIZE];
static volatile uint8_t s_tx_head = 0;
static volatile uint8_t s_tx_tail = 0;
static volatile uint8_t s_last_sent = 0;
static volatile uint8_t s_now_send = 0;
static volatile uint8_t s_tx_ready = 0;

static uint8_t s_led_lock = 0;
static uint8_t s_keystatus = 0;

// IO pin control
static inline void kbd_clk_high(void) { DDRD &= ~(1 << PD2); PORTD |= (1 << PD2); }
static inline void kbd_clk_low(void)  { PORTD &= ~(1 << PD2); DDRD |= (1 << PD2); }
static inline void kbd_dat_high(void) { DDRD &= ~(1 << PD4); PORTD |= (1 << PD4); }
static inline void kbd_dat_low(void)  { PORTD &= ~(1 << PD4); DDRD |= (1 << PD4); }
static inline uint8_t kbd_dat_read(void) { return (PIND & (1 << PD4)) ? 1 : 0; }

static void send_bit(void);
static void send_next(void);
static uint8_t decode_scancode(uint8_t val);
void ps2_kbd_isr(void);

static void send_now(uint8_t data)
{
  s_now_send = data;
  s_shiftdata = data;
  s_bitcount = 0;
  s_parity = 0;
  s_ps2_mode |= (MODE_BUSY | MODE_TX);

  hal_detach_interrupt(PIN_KBD_CLK);

  // Inhibit communication: clock low for 100us
  kbd_clk_low();
  _delay_us(100);
  kbd_dat_low();
  _delay_us(10);
  kbd_clk_high();

  hal_attach_interrupt(PIN_KBD_CLK, ps2_kbd_isr, FALLING);
}

static uint8_t send_byte(uint8_t data)
{
  uint8_t next = s_tx_head + 1;
  if (next >= TX_BUFF_SIZE) next = 0;
  if (next == s_tx_tail) return 0;
  s_tx_buff[next] = data;
  s_tx_head = next;
  return 1;
}

static void send_next(void)
{
  if (s_tx_head != s_tx_tail) {
    uint8_t next = s_tx_tail + 1;
    if (next >= TX_BUFF_SIZE) next = 0;
    s_tx_tail = next;
    send_now(s_tx_buff[next]);
  }
}

static void send_bit(void)
{
  s_bitcount++;
  switch (s_bitcount) {
    case 1:
      kbd_dat_low(); // Start bit
      break;
    case 2: case 3: case 4: case 5:
    case 6: case 7: case 8: case 9: {
      uint8_t bit = s_shiftdata & 1;
      if (bit) kbd_dat_high(); else kbd_dat_low();
      s_parity += bit;
      s_shiftdata >>= 1;
      break;
    }
    case 10:
      // Odd parity
      if (~s_parity & 1) kbd_dat_high(); else kbd_dat_low();
      break;
    case 11:
      kbd_dat_high(); // Stop bit
      break;
    case 12:
      // ACK received
      if (s_now_send != KC_ECHO && s_now_send != KC_RESEND) {
        s_last_sent = s_now_send;
        s_ps2_mode |= MODE_LAST_VALID;
      }
      s_ps2_mode &= ~MODE_TX;
      if (s_tx_ready & TX_HANDSHAKE) s_tx_ready &= ~TX_HANDSHAKE;
      else s_tx_ready &= ~TX_COMMAND;
      break;
    default:
      break;
  }
}

void ps2_kbd_isr(void)
{
  if (s_ps2_mode & MODE_TX) {
    send_bit();
    return;
  }

  static uint32_t prev_ms = 0;
  uint32_t now_ms = millis();
  if (now_ms - prev_ms > 250) {
    s_bitcount = 0;
    s_shiftdata = 0;
  }
  prev_ms = now_ms;

  uint8_t val = kbd_dat_read();
  s_bitcount++;

  switch (s_bitcount) {
    case 1: // Start bit
      s_parity = 0;
      s_ps2_mode |= MODE_BUSY;
      break;

    case 2: case 3: case 4: case 5:
    case 6: case 7: case 8: case 9: // Data bits
      s_parity += val;
      s_shiftdata >>= 1;
      if (val) s_shiftdata |= 0x80;
      break;

    case 10: // Parity bit
      if ((s_parity & 1) == val) s_parity = 0xFD; // parity error
      break;

    case 11: // Stop bit
      if (s_parity >= 0xFD) {
        send_now(KC_RESEND);
        s_tx_ready |= TX_HANDSHAKE;
      } else {
        uint8_t ret = decode_scancode(s_shiftdata);
        if (ret & 2) s_bytes_expected--;
        if (s_bytes_expected <= 0 || (ret & 4)) {
          uint8_t next = s_rx_head + 1;
          if (next >= RX_BUFF_SIZE) next = 0;
          if (next != s_rx_tail) {
            s_rx_buffer[next] = ((uint16_t)s_ps2_mode << 8) | s_shiftdata;
            s_rx_head = next;
          }
        }
        if (ret & 0x10) {
          send_now(s_now_send);
          s_tx_ready |= TX_HANDSHAKE;
        } else if (s_bytes_expected <= 0) {
          s_ps2_mode &= ~(MODE_E0 | MODE_E1 | MODE_WAIT_RESP | MODE_BREAK | MODE_BUSY);
          s_bytes_expected = 0;
          send_next();
        }
      }
      s_bitcount = 0;
      break;

    default:
      s_bitcount = 0;
      break;
  }
}

static uint8_t decode_scancode(uint8_t value)
{
  uint8_t state = 6;
  if (value != KC_RESEND) s_ps2_mode &= ~MODE_LAST_VALID;
  if ((s_ps2_mode & MODE_WAIT_RESP) && value < 0xF0) return state;
  if (s_ps2_mode & MODE_E1) return 2;

  switch (value) {
    case 0:
    case KC_OVERRUN:
      s_ps2_mode = 0;
      state = 0x0C;
      break;
    case KC_RESEND:
      if (s_ps2_mode & MODE_LAST_VALID) {
        s_now_send = s_last_sent;
        state = 0x10;
      } else {
        state = 0;
      }
      break;
    case KC_ERROR:
      s_bytes_expected = 0;
      s_ps2_mode = 0;
      s_tx_ready = 0;
      state = 0x0E;
      break;
    case KC_KEYBREAK:
      s_bytes_expected = 1;
      s_ps2_mode |= MODE_BREAK;
      state = 0;
      break;
    case KC_ECHO:
      state = 4;
      if ((s_ps2_mode & MODE_LAST_VALID) && s_last_sent != KC_ECHO) {
        s_now_send = KC_ECHO;
        state |= 0x10;
      }
      break;
    case KC_BAT:
      s_bytes_expected = 0;
      state = 4;
      break;
    case KC_EXTEND1:
      if (!(s_ps2_mode & MODE_E1)) {
        s_bytes_expected = 7;
        s_ps2_mode |= MODE_E1;
        s_ps2_mode &= ~MODE_BREAK;
      }
      state = 0;
      break;
    case KC_EXTEND:
      s_bytes_expected = 1;
      s_ps2_mode |= MODE_E0;
      state = 0;
      break;
  }
  return state;
}

void ps2_kbd_init(void)
{
  kbd_clk_high();
  kbd_dat_high();
  s_ps2_mode = 0;
  s_bitcount = 0;
  s_rx_head = 0;
  s_rx_tail = 0;
  s_tx_head = 0;
  s_tx_tail = 0;
  s_keystatus = 0;
  s_led_lock = 0;
  hal_attach_interrupt(PIN_KBD_CLK, ps2_kbd_isr, FALLING);
}

void ps2_kbd_echo(void)
{
  send_byte(KC_ECHO);
  send_byte(KEY_IGNORE);
  send_next();
}

void ps2_kbd_set_lock(uint8_t leds)
{
  s_led_lock = leds & 0x07;
  s_keystatus &= ~(PS2_CAPS >> 8);
  if (leds & PS2_LOCK_CAPS) s_keystatus |= (PS2_CAPS >> 8);

  send_byte(KC_LOCK);
  send_byte(KEY_IGNORE);
  send_byte(s_led_lock);
  send_byte(KEY_IGNORE);
  send_next();
}

bool ps2_kbd_available(void)
{
  return (s_rx_head != s_rx_tail);
}

uint16_t ps2_kbd_read(void)
{
  if (s_rx_head == s_rx_tail) return 0;

  uint8_t next = s_rx_tail + 1;
  if (next >= RX_BUFF_SIZE) next = 0;
  s_rx_tail = next;

  uint16_t raw = s_rx_buffer[next];
  uint8_t scancode = raw & 0xFF;
  uint8_t mode = (raw >> 8) & 0xFF;

  if (scancode == KC_BAT) return PS2_KEY_BAT;
  if (scancode == KC_ECHO) return PS2_KEY_ECHO;

  uint8_t key_id = 0;

  if (mode & MODE_E0) {
    uint8_t count = sizeof(s_extended_key) / sizeof(s_extended_key[0]);
    for (uint8_t i = 0; i < count; i++) {
      if (scancode == pgm_read_byte(&s_extended_key[i][0])) {
        key_id = pgm_read_byte(&s_extended_key[i][1]);
        break;
      }
    }
  } else if (mode & MODE_E1) {
    key_id = PS2_KEY_PAUSE;
  } else {
    uint8_t count = sizeof(s_single_key) / sizeof(s_single_key[0]);
    for (uint8_t i = 0; i < count; i++) {
      if (scancode == pgm_read_byte(&s_single_key[i][0])) {
        key_id = pgm_read_byte(&s_single_key[i][1]);
        break;
      }
    }
  }

  if (key_id == 0) return 0;

  bool is_break = (mode & MODE_BREAK) != 0;

  // Update modifiers
  switch (key_id) {
    case PS2_KEY_L_SHIFT:
    case PS2_KEY_R_SHIFT:
      if (is_break) s_keystatus &= ~(PS2_SHIFT >> 8);
      else s_keystatus |= (PS2_SHIFT >> 8);
      break;

    case PS2_KEY_L_CTRL:
    case PS2_KEY_R_CTRL:
      if (is_break) s_keystatus &= ~(PS2_CTRL >> 8);
      else s_keystatus |= (PS2_CTRL >> 8);
      break;

    case PS2_KEY_L_ALT:
      if (is_break) s_keystatus &= ~(PS2_ALT >> 8);
      else s_keystatus |= (PS2_ALT >> 8);
      break;

    case PS2_KEY_R_ALT:
      if (is_break) s_keystatus &= ~(PS2_ALT_GR >> 8);
      else s_keystatus |= (PS2_ALT_GR >> 8);
      break;

    case PS2_KEY_L_GUI:
    case PS2_KEY_R_GUI:
      if (is_break) s_keystatus &= ~(PS2_GUI >> 8);
      else s_keystatus |= (PS2_GUI >> 8);
      break;

    case PS2_KEY_CAPS:
      if (!is_break) {
        s_keystatus ^= (PS2_CAPS >> 8);
        ps2_kbd_set_lock((s_keystatus & (PS2_CAPS >> 8)) ? PS2_LOCK_CAPS : 0);
      }
      break;

    default:
      break;
  }

  uint16_t result = ((uint16_t)s_keystatus << 8) | key_id;
  if (is_break) result |= PS2_BREAK;
  return result;
}
