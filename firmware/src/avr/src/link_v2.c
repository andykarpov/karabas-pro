/*
 * Link v2 (docs/AVR_LINK_V2.md): one packet per chip select, T (target), C (command), then the
 * payload; the answer to C is the status byte of the FPGA. There is no INT line: the status of
 * every packet tells what the FPGA has, and a pass of the main loop that sent nothing ends with
 * SYS POLL (link_service()).
 *
 * The values (menu items, controls, key matrix, joystick) go only when they change; the OSD
 * cells and the RTC registers go as runs in one packet while their addresses follow each other.
 * A run stays open (CS low) until another packet, link_flush() or link_service().
 */

#include "link.h"
#include "hal.h"

#define T_SYS 0x00
#define T_HID 0x01
#define T_OSD 0x02
#define T_RTC 0x03

#define SYS_POLL   0x00
#define SYS_STATUS 0x01
#define SYS_INIT   0x02
#define SYS_SETVAL 0x03

#define HID_MATRIX 0x01
#define HID_MOUSE  0x02
#define HID_JOY    0x03

#define OSD_WRITE  0x01

#define RTC_SET    0x01
#define RTC_GET    0x02

#define ST_INIT_REQ 0x01
#define ST_RTC_PEND 0x02
#define ST_ZERO     0x0C // always 0: FF is "no FPGA"

#define LV_COUNT 0x13

static bool s_up = false;       // the FPGA answered and was initialized by us
static bool s_sent = false;     // a packet went in this pass of the main loop
static uint8_t s_status = 0;
static uint8_t s_open = 0;      // the target of the open run (OSD, RTC), 0 none
static uint16_t s_next = 0;     // the next address of the open run
static uint8_t s_vals[LV_COUNT];
static uint8_t s_keys[LINK_KEYS_SIZE];
static bool s_keys_sent = false;
static uint16_t s_joy = 0;
static bool s_joy_sent = false;

static inline uint8_t xfer(uint8_t b) { return hal_spi_transfer(b); }

#ifdef LINK_DEBUG
// Link check of the debug build: a pass that sends nothing reads SYS STATUS (instead of SYS POLL)
// and compares it with the answer of link_start(); every 1024 checks the counts go to the UART
// (no millis() here: the host stand charges time per call).
static uint8_t s_st[12];
static uint32_t s_chk = 0, s_err = 0;

static void uart_str(const char *s) { while (*s) hal_uart_putc(*s++); }

static void uart_num(uint32_t v)
{
  char b[11];
  uint8_t i = sizeof(b);
  b[--i] = 0;
  do { b[--i] = '0' + v % 10; v /= 10; } while (v);
  uart_str(&b[i]);
}
#endif

static void cs_end(void)
{
  hal_spi_cs_high();
  delay_us(1); // the FPGA ends a packet after CS has been high for ~0.33 us
}

void link_flush(void)
{
  if (s_open) {
    cs_end();
    s_open = 0;
  }
}

// CS low, T and C; the status byte comes with C. The packet stays open for its payload.
static void begin(uint8_t t, uint8_t c)
{
  link_flush();
  hal_spi_cs_low();
  xfer(t);
  s_status = xfer(c);
  s_sent = true;
  if ((s_status & ST_ZERO) == 0) {
    link_on_leds(s_status >> 4);
  }
}

static void forget(void)
{
  for (uint8_t i = 0; i < LV_COUNT; i++) s_vals[i] = 0xFF;
  s_keys_sent = false;
  s_joy_sent = false;
}

void link_start(void)
{
  uint8_t st[12];
  s_up = false;
  s_open = 0;
  for (;;) {
    begin(T_SYS, SYS_STATUS);
    xfer(0); // turnaround
    for (uint8_t i = 0; i < sizeof(st); i++) st[i] = xfer(0);
    cs_end();
    if (st[0] == 'K' && st[1] == 'P' && st[2] == 2 && (s_status & ST_ZERO) == 0) break;
    delay_ms(10);
  }
  for (uint8_t i = 0; i < 8; i++) {
    link_on_build(i, st[4 + i]);
  }
#ifdef LINK_DEBUG
  for (uint8_t i = 0; i < sizeof(st); i++) s_st[i] = st[i];
  uart_str("link up, SCK ");
  uart_num(LINK_SPI_MHZ);
  uart_str(" MHz\r\n");
#endif
  forget();
  s_up = true;
  link_on_init(st[3] & 0b00111111, st[3] >> 6);
  begin(T_SYS, SYS_INIT);
  cs_end();
}

void link_service(void)
{
  link_flush();
  if (!s_sent) {
#ifdef LINK_DEBUG
    if (s_up) {
      begin(T_SYS, SYS_STATUS);
      xfer(0);
      bool bad = false;
      for (uint8_t i = 0; i < sizeof(s_st); i++) {
        uint8_t b = xfer(0);
        if (i != 3 && b != s_st[i]) bad = true; // byte 3: the config, may change
      }
      cs_end();
      s_chk++;
      if (bad) s_err++;
      if ((s_chk & 1023) == 0) {
        uart_str("link checks ");
        uart_num(s_chk);
        uart_str(" errors ");
        uart_num(s_err);
        uart_str("\r\n");
      }
    } else
#endif
    {
      begin(T_SYS, SYS_POLL);
      cs_end();
    }
  }
  s_sent = false;
  if (s_status & ST_ZERO) return; // no FPGA on the bus now
  if (s_status & ST_INIT_REQ) {
    // the FPGA was configured or reset again: start over
    link_start();
    return;
  }
  if (s_status & ST_RTC_PEND) {
    // one CPU write per pass; this packet's status says whether it holds an entry
    begin(T_RTC, RTC_GET);
    xfer(0);
    uint8_t reg = xfer(0);
    uint8_t val = xfer(0);
    cs_end();
    if (s_status & ST_RTC_PEND) {
      link_on_rtc_write(reg, val);
    }
  }
}

void link_setval(uint8_t idx, uint8_t val)
{
  if (!s_up) return;
  if (idx < LV_COUNT) {
    if (s_vals[idx] == val) return;
    s_vals[idx] = val;
  }
  begin(T_SYS, SYS_SETVAL);
  xfer(idx);
  xfer(val);
  cs_end();
}

void link_keys(const uint8_t keys[LINK_KEYS_SIZE])
{
  if (!s_up) return;
  bool same = s_keys_sent;
  for (uint8_t i = 0; i < LINK_KEYS_SIZE; i++) {
    if (s_keys[i] != keys[i]) same = false;
  }
  if (same) return;
  begin(T_HID, HID_MATRIX);
  for (uint8_t i = 0; i < LINK_KEYS_SIZE; i++) {
    s_keys[i] = keys[i];
    xfer(keys[i]);
  }
  cs_end();
  s_keys_sent = true;
}

void link_keys_cs(const uint8_t keys[LINK_KEYS_SIZE])
{
  link_keys(keys);
}

void link_scancode(uint8_t code, bool up)
{
  // HID PS2 (raw bytes) is reserved: nothing yet
  (void)code;
  (void)up;
}

void link_mouse(uint8_t dx, uint8_t dy, uint8_t z)
{
  if (!s_up) return;
  begin(T_HID, HID_MOUSE);
  xfer(dx);
  xfer(dy);
  xfer(z & 0x7F);
  cs_end();
}

void link_joy(uint16_t buttons)
{
  if (!s_up) return;
  if (s_joy_sent && s_joy == buttons) return;
  s_joy = buttons;
  s_joy_sent = true;
  begin(T_HID, HID_JOY);
  xfer(0);
  xfer(buttons & 0xFF);
  xfer(buttons >> 8);
  cs_end();
}

void link_osd_char(uint8_t x, uint8_t y, uint8_t chr, uint8_t attr)
{
  if (!s_up) return;
  uint16_t addr = (uint16_t)y * 32 + x;
  if (!(s_open == T_OSD && s_next == addr)) {
    begin(T_OSD, OSD_WRITE);
    xfer(addr & 0xFF);
    xfer(addr >> 8);
    s_open = T_OSD;
  }
  xfer(chr);
  xfer(attr);
  s_next = (addr + 1) & 1023;
}

void link_rtc(uint8_t reg, uint8_t val)
{
  if (!s_up) return;
  if (!(s_open == T_RTC && s_next == reg)) {
    begin(T_RTC, RTC_SET);
    xfer(reg);
    s_open = T_RTC;
  }
  xfer(val);
  s_next = (uint8_t)(reg + 1);
}
