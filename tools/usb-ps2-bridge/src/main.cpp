/*
 * USB keyboard / mouse -> PS/2 bridge for Karabas-Pro, RP2040 (README.md).
 *
 *  core 1: USB host on PIO (Pico-PIO-USB, D+ GP2 / D- GP3), HID boot protocol keyboard and mouse
 *          (a receiver with both on one dongle gives two interfaces);
 *  core 0: two PS/2 devices (keyboard GP4 / GP5, mouse GP6 / GP7, open drain through a level
 *          shifter): set 2 scancodes, the replies to the commands of the AVR; the UART of the AVR
 *          (GP1 <- AVR TX, GP0 -> AVR RX) to the USB serial port, both ways, byte for byte:
 *          the AT+KARABAS= commands of the AVR firmware go that way (docs/AT_KARABAS.md).
 */

#include <Arduino.h>
#include "pio_usb.h"
#include "Adafruit_TinyUSB.h"
#include "pico/util/queue.h"
#include "hardware/clocks.h"

#define PIN_USB_DP  2 // D- is GP3
#define PIN_KB_CLK  4
#define PIN_KB_DAT  5
#define PIN_MS_CLK  6
#define PIN_MS_DAT  7
#define PIN_UART_TX 0 // -> AVR RX (PD0)
#define PIN_UART_RX 1 // <- AVR TX (PD1)
#define PIN_LED     25

#define AVR_BAUD 115200

/* ---------------- core 1 -> core 0: HID reports ---------------- */

enum { EV_KBD = 1, EV_MOUSE, EV_KBD_ON, EV_MOUSE_ON, EV_OFF };
struct hid_ev_t {
  uint8_t kind;
  uint8_t len;
  uint8_t d[8];
};
static queue_t s_q;

Adafruit_USBH_Host USBHost;

/* ---------------- PS/2 device (open drain, bit-banged) ---------------- */

#define CLK_LO 40 // us: clock low / high (12.5 kHz)
#define CLK_HI 40

struct ps2dev_t {
  uint8_t clk, dat;
  uint8_t q[128];
  uint8_t head, tail;
  uint8_t last;    // the last byte sent (FE: resend)
  uint8_t arg_cmd; // a command waiting for its argument, 0 none
};

static ps2dev_t s_kb = { PIN_KB_CLK, PIN_KB_DAT };
static ps2dev_t s_ms = { PIN_MS_CLK, PIN_MS_DAT };

static inline void lo(uint8_t pin) { gpio_set_dir(pin, GPIO_OUT); } // the output value is 0
static inline void hi(uint8_t pin) { gpio_set_dir(pin, GPIO_IN); }  // released: the pull-ups
static inline bool rd(uint8_t pin) { return gpio_get(pin); }

static void ps2_pin_init(uint8_t pin)
{
  gpio_init(pin);
  gpio_put(pin, 0);
  gpio_set_dir(pin, GPIO_IN);
  gpio_pull_up(pin);
}

static void ps2_push(ps2dev_t *p, uint8_t b)
{
  uint8_t next = (uint8_t)((p->head + 1) % sizeof(p->q));
  if (next == p->tail) return; // full: dropped
  p->q[p->head] = b;
  p->head = next;
}

static bool ps2_empty(const ps2dev_t *p) { return p->head == p->tail; }

// one byte to the host; false when the host took the bus (inhibit or request to send)
static bool ps2_write(ps2dev_t *p, uint8_t d)
{
  if (!rd(p->clk) || !rd(p->dat)) return false;
  uint16_t frame = (uint16_t)d << 1;                 // start bit 0
  frame |= (uint16_t)(!(__builtin_popcount(d) & 1)) << 9; // odd parity
  frame |= 1u << 10;                                 // stop bit
  for (uint8_t i = 0; i < 11; i++) {
    if (frame & (1u << i)) hi(p->dat); else lo(p->dat);
    delayMicroseconds(15);
    lo(p->clk);
    delayMicroseconds(CLK_LO);
    hi(p->clk);
    delayMicroseconds(10); // the pull-ups bring the clock up
    if (!rd(p->clk) && i < 10) { // the host holds the clock: abort, send it again later
      hi(p->dat);
      return false;
    }
    delayMicroseconds(CLK_HI - 25); // + 15 us of the next bit
  }
  hi(p->dat);
  p->last = d;
  delayMicroseconds(50);
  return true;
}

// a byte from the host after its request to send (clock high, data low); false on an error
static bool ps2_read(ps2dev_t *p, uint8_t *v)
{
  uint16_t bits = 0;
  delayMicroseconds(20);
  for (uint8_t i = 0; i < 10; i++) { // d0..d7, parity, stop
    lo(p->clk);
    delayMicroseconds(CLK_LO);
    hi(p->clk);
    delayMicroseconds(CLK_HI / 2);
    if (rd(p->dat)) bits |= 1u << i;
    delayMicroseconds(CLK_HI / 2);
  }
  // acknowledge: data low for one more clock
  lo(p->dat);
  delayMicroseconds(5);
  lo(p->clk);
  delayMicroseconds(CLK_LO);
  hi(p->clk);
  delayMicroseconds(5);
  hi(p->dat);
  delayMicroseconds(50);
  uint8_t d = bits & 0xFF;
  bool parity = (bits >> 8) & 1;
  *v = d;
  return ((__builtin_popcount(d) + parity) & 1) == 1;
}

/* ---------------- keyboard ---------------- */

// HID usage 0x04..0x65 -> set 2 code; bit 7 of s_e0 marks the E0 codes
static const uint8_t s_set2[0x66] = {
  0, 0, 0, 0,
  0x1C, 0x32, 0x21, 0x23, 0x24, 0x2B, 0x34, 0x33, 0x43, 0x3B, 0x42, 0x4B, // a..l
  0x3A, 0x31, 0x44, 0x4D, 0x15, 0x2D, 0x1B, 0x2C, 0x3C, 0x2A, 0x1D, 0x22, // m..x
  0x35, 0x1A,                                                             // y z
  0x16, 0x1E, 0x26, 0x25, 0x2E, 0x36, 0x3D, 0x3E, 0x46, 0x45,             // 1..0
  0x5A, 0x76, 0x66, 0x0D, 0x29, 0x4E, 0x55, 0x54, 0x5B, 0x5D, 0x5D, 0x4C, // enter .. ;
  0x52, 0x0E, 0x41, 0x49, 0x4A, 0x58,                                     // ' ` , . / caps
  0x05, 0x06, 0x04, 0x0C, 0x03, 0x0B, 0x83, 0x0A, 0x01, 0x09, 0x78, 0x07, // f1..f12
  0x7C, 0x7E, 0x77,                                                       // prtscr scroll pause
  0x70, 0x6C, 0x7D, 0x71, 0x69, 0x7A, 0x74, 0x6B, 0x72, 0x75,             // ins .. up (E0)
  0x77, 0x4A, 0x7C, 0x7B, 0x79, 0x5A,                                     // num kp/ * - + enter
  0x69, 0x72, 0x7A, 0x6B, 0x73, 0x74, 0x6C, 0x75, 0x7D, 0x70, 0x71,       // kp1..kp9 kp0 kp.
  0x61, 0x2F,                                                             // non-US \, app (E0)
};

static bool usage_e0(uint8_t u)
{
  return (u >= 0x49 && u <= 0x52) || u == 0x54 || u == 0x58 || u == 0x65;
}

// modifiers (usage 0xE0 + bit): lctrl lshift lalt lgui rctrl rshift ralt rgui
static const uint8_t s_mod_code[8] = { 0x14, 0x12, 0x11, 0x1F, 0x14, 0x59, 0x11, 0x27 };
static const uint8_t s_mod_e0 = 0b11011000;

static void kb_code(uint8_t code, bool e0, bool up)
{
  if (e0) ps2_push(&s_kb, 0xE0);
  if (up) ps2_push(&s_kb, 0xF0);
  ps2_push(&s_kb, code);
}

static void kb_usage(uint8_t u, bool up)
{
  if (u == 0x46) { // print screen
    if (!up) { kb_code(0x12, true, false); kb_code(0x7C, true, false); }
    else { kb_code(0x7C, true, true); kb_code(0x12, true, true); }
    return;
  }
  if (u == 0x48) { // pause: a make sequence only
    if (!up) {
      const uint8_t seq[8] = { 0xE1, 0x14, 0x77, 0xE1, 0xF0, 0x14, 0xF0, 0x77 };
      for (uint8_t b : seq) ps2_push(&s_kb, b);
    }
    return;
  }
  if (u < sizeof(s_set2) && s_set2[u]) kb_code(s_set2[u], usage_e0(u), up);
}

static uint8_t s_kb_prev[8];

static void kb_report(const uint8_t *r)
{
  if (r[2] == 0x01) return; // rollover error
  uint8_t mods = r[0], pm = s_kb_prev[0];
  for (uint8_t i = 0; i < 8; i++) {
    uint8_t m = (uint8_t)(1u << i);
    if ((pm & m) && !(mods & m)) kb_code(s_mod_code[i], (s_mod_e0 >> i) & 1, true);
  }
  for (uint8_t i = 2; i < 8; i++) { // released keys
    uint8_t u = s_kb_prev[i];
    if (!u) continue;
    bool still = false;
    for (uint8_t j = 2; j < 8; j++) still |= (r[j] == u);
    if (!still) kb_usage(u, true);
  }
  for (uint8_t i = 0; i < 8; i++) {
    uint8_t m = (uint8_t)(1u << i);
    if (!(pm & m) && (mods & m)) kb_code(s_mod_code[i], (s_mod_e0 >> i) & 1, false);
  }
  for (uint8_t i = 2; i < 8; i++) { // new keys
    uint8_t u = r[i];
    if (!u) continue;
    bool before = false;
    for (uint8_t j = 2; j < 8; j++) before |= (s_kb_prev[j] == u);
    if (!before) kb_usage(u, false);
  }
  memcpy(s_kb_prev, r, 8);
}

static void kb_command(uint8_t c)
{
  ps2dev_t *p = &s_kb;
  if (p->arg_cmd) { // the argument of ED / F3 / F0
    uint8_t cmd = p->arg_cmd;
    p->arg_cmd = 0;
    ps2_push(p, 0xFA);
    if (cmd == 0xF0 && c == 0) ps2_push(p, 0x02); // scancode set 2
    return;
  }
  switch (c) {
    case 0xFF: p->head = p->tail = 0; ps2_push(p, 0xFA); ps2_push(p, 0xAA); break;
    case 0xFE: ps2_push(p, p->last); break;
    case 0xEE: ps2_push(p, 0xEE); break;
    case 0xF2: ps2_push(p, 0xFA); ps2_push(p, 0xAB); ps2_push(p, 0x83); break;
    case 0xED: case 0xF3: case 0xF0: p->arg_cmd = c; ps2_push(p, 0xFA); break;
    default: ps2_push(p, 0xFA); break;
  }
}

/* ---------------- mouse ---------------- */

static bool s_ms_on = false;     // reporting enabled (F4)
static uint8_t s_ms_rate = 100;  // samples per second (F3)
static uint8_t s_ms_btn = 0;
static int16_t s_ms_x = 0, s_ms_y = 0;
static bool s_ms_dirty = false;
static uint32_t s_ms_t = 0;

static void ms_packet(void)
{
  int16_t x = constrain(s_ms_x, -255, 255), y = constrain(s_ms_y, -255, 255);
  uint8_t b0 = (uint8_t)(0x08 | (s_ms_btn & 7) | (x < 0 ? 0x10 : 0) | (y < 0 ? 0x20 : 0));
  ps2_push(&s_ms, b0);
  ps2_push(&s_ms, (uint8_t)x);
  ps2_push(&s_ms, (uint8_t)y);
  s_ms_x = (int16_t)(s_ms_x - x);
  s_ms_y = (int16_t)(s_ms_y - y);
  s_ms_dirty = s_ms_x || s_ms_y;
}

static void ms_report(const uint8_t *r, uint8_t len)
{
  if (len < 3) return;
  uint8_t btn = r[0] & 7;
  if (btn != s_ms_btn) s_ms_dirty = true;
  s_ms_btn = btn;
  s_ms_x = (int16_t)(s_ms_x + (int8_t)r[1]);
  s_ms_y = (int16_t)(s_ms_y - (int8_t)r[2]); // PS/2: up is positive
  if (r[1] || r[2]) s_ms_dirty = true;
}

static void ms_command(uint8_t c)
{
  ps2dev_t *p = &s_ms;
  if (p->arg_cmd) { // the argument of F3 / E8
    if (p->arg_cmd == 0xF3 && c) s_ms_rate = c;
    p->arg_cmd = 0;
    ps2_push(p, 0xFA);
    return;
  }
  switch (c) {
    case 0xFF:
      p->head = p->tail = 0;
      s_ms_on = false;
      s_ms_rate = 100;
      ps2_push(p, 0xFA); ps2_push(p, 0xAA); ps2_push(p, 0x00);
      break;
    case 0xFE: ps2_push(p, p->last); break;
    case 0xF2: ps2_push(p, 0xFA); ps2_push(p, 0x00); break;
    case 0xF3: case 0xE8: p->arg_cmd = c; ps2_push(p, 0xFA); break;
    case 0xF4: s_ms_on = true; ps2_push(p, 0xFA); break;
    case 0xF5: s_ms_on = false; ps2_push(p, 0xFA); break;
    case 0xF6: s_ms_rate = 100; ps2_push(p, 0xFA); break;
    case 0xE9:
      ps2_push(p, 0xFA);
      ps2_push(p, (uint8_t)((s_ms_on ? 0x20 : 0) | (s_ms_btn & 7)));
      ps2_push(p, 0x02);
      ps2_push(p, s_ms_rate);
      break;
    case 0xEB: ps2_push(p, 0xFA); ms_packet(); break;
    default: ps2_push(p, 0xFA); break;
  }
}

/* ---------------- PS/2 service ---------------- */

static void ps2_service(ps2dev_t *p, void (*command)(uint8_t))
{
  if (rd(p->clk) && !rd(p->dat)) { // the host asks to send
    uint8_t c;
    if (ps2_read(p, &c)) command(c);
    else ps2_push(p, 0xFE);
    return;
  }
  if (!ps2_empty(p) && ps2_write(p, p->q[p->tail])) {
    p->tail = (uint8_t)((p->tail + 1) % sizeof(p->q));
  }
}

/* ---------------- core 0 ---------------- */

static bool s_kb_usb = false, s_ms_usb = false;

void setup()
{
  queue_init(&s_q, sizeof(hid_ev_t), 64);
  pinMode(PIN_LED, OUTPUT);
  ps2_pin_init(PIN_KB_CLK);
  ps2_pin_init(PIN_KB_DAT);
  ps2_pin_init(PIN_MS_CLK);
  ps2_pin_init(PIN_MS_DAT);
  Serial.begin(115200);
  Serial1.setTX(PIN_UART_TX);
  Serial1.setRX(PIN_UART_RX);
  Serial1.setFIFOSize(1024);
  Serial1.begin(AVR_BAUD);
  // power-on self test passed, as a keyboard and a mouse say it
  ps2_push(&s_kb, 0xAA);
  ps2_push(&s_ms, 0xAA);
  ps2_push(&s_ms, 0x00);
}

void loop()
{
  // the UART of the AVR <-> the USB serial port
  while (Serial1.available()) Serial.write((uint8_t)Serial1.read());
  while (Serial.available()) Serial1.write((uint8_t)Serial.read());

  hid_ev_t ev;
  while (queue_try_remove(&s_q, &ev)) {
    switch (ev.kind) {
      case EV_KBD: kb_report(ev.d); break;
      case EV_MOUSE: ms_report(ev.d, ev.len); break;
      case EV_KBD_ON: s_kb_usb = true; break;
      case EV_MOUSE_ON: s_ms_usb = true; break;
      case EV_OFF: // a device left: keys up
        if (ev.d[0] == HID_ITF_PROTOCOL_KEYBOARD) {
          uint8_t none[8] = { 0 };
          kb_report(none);
          s_kb_usb = false;
        } else {
          s_ms_usb = false;
        }
        break;
    }
  }
  digitalWrite(PIN_LED, s_kb_usb || s_ms_usb);

  // mouse packets at the sample rate, while reporting is on
  uint32_t now = millis();
  if (s_ms_on && s_ms_dirty && ps2_empty(&s_ms) && now - s_ms_t >= 1000u / s_ms_rate) {
    s_ms_t = now;
    ms_packet();
  }

  ps2_service(&s_kb, kb_command);
  ps2_service(&s_ms, ms_command);
}

/* ---------------- core 1: USB host ---------------- */

void setup1()
{
  if (clock_get_hz(clk_sys) % 12000000u) {
    for (;;) delay(1); // PIO USB needs 120 or 240 MHz
  }
  pio_usb_configuration_t cfg = PIO_USB_DEFAULT_CONFIG;
  cfg.pin_dp = PIN_USB_DP;
  USBHost.configure_pio_usb(1, &cfg);
  USBHost.begin(1);
}

void loop1()
{
  USBHost.task();
}

static void post(uint8_t kind, const uint8_t *d, uint8_t len)
{
  hid_ev_t ev = { kind, len, { 0 } };
  if (len > sizeof(ev.d)) len = sizeof(ev.d);
  if (d) memcpy(ev.d, d, len);
  queue_try_add(&s_q, &ev);
}

extern "C" {

void tuh_hid_mount_cb(uint8_t dev_addr, uint8_t instance, uint8_t const *desc, uint16_t len)
{
  (void)desc;
  (void)len;
  uint8_t proto = tuh_hid_interface_protocol(dev_addr, instance);
  if (proto == HID_ITF_PROTOCOL_KEYBOARD || proto == HID_ITF_PROTOCOL_MOUSE) {
    tuh_hid_set_protocol(dev_addr, instance, HID_PROTOCOL_BOOT);
    post(proto == HID_ITF_PROTOCOL_KEYBOARD ? EV_KBD_ON : EV_MOUSE_ON, nullptr, 0);
    tuh_hid_receive_report(dev_addr, instance);
  }
}

void tuh_hid_umount_cb(uint8_t dev_addr, uint8_t instance)
{
  uint8_t proto = tuh_hid_interface_protocol(dev_addr, instance);
  post(EV_OFF, &proto, 1);
}

void tuh_hid_report_received_cb(uint8_t dev_addr, uint8_t instance, uint8_t const *report, uint16_t len)
{
  uint8_t proto = tuh_hid_interface_protocol(dev_addr, instance);
  if (proto == HID_ITF_PROTOCOL_KEYBOARD && len >= 8) post(EV_KBD, report, 8);
  else if (proto == HID_ITF_PROTOCOL_MOUSE) post(EV_MOUSE, report, (uint8_t)(len > 8 ? 8 : len));
  tuh_hid_receive_report(dev_addr, instance);
}

} // extern "C"
