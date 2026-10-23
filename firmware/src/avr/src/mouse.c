#include "mouse.h"
#include "hal.h"

#define PIN_MS_CLK 3 // PD3 (INT1)
#define PIN_MS_DAT 5 // PD5

#define MS_BUFFER_SIZE 16

typedef struct {
  uint8_t status;
  int8_t x;
  int8_t y;
  int8_t z;
} mouse_report_t;

static mouse_report_t s_ms_buffer[MS_BUFFER_SIZE];
static volatile uint8_t s_ms_head = 0;
static volatile uint8_t s_ms_tail = 0;
static volatile mouse_report_t s_current_report;
static volatile uint8_t s_byte_counter = 0;
static volatile uint8_t s_bit_counter = 0;
static volatile uint8_t s_incoming_byte = 0;
static volatile uint8_t s_parity_check = 0;

static mouse_event_cb s_on_mouse_cb = 0;
static bool s_is_started = false;
static bool s_mouse_present = false;
static bool s_mouse_swap = false;
static uint8_t s_mouse_x = 0;
static uint8_t s_mouse_y = 0;
static uint8_t s_mouse_z = 0;
static bool s_mouse_new_packet = false;

static uint32_t s_tm = 0;
static uint32_t s_ts = 0;
static int8_t s_mouse_tries = 3;

// GPIO line controls: open-collector style
static inline void ms_clk_high(void) { DDRD &= ~(1 << PD3); PORTD |= (1 << PD3); }
static inline void ms_clk_low(void)  { PORTD &= ~(1 << PD3); DDRD |= (1 << PD3); }
static inline void ms_dat_high(void) { DDRD &= ~(1 << PD5); PORTD |= (1 << PD5); }
static inline void ms_dat_low(void)  { PORTD &= ~(1 << PD5); DDRD |= (1 << PD5); }
static inline uint8_t ms_clk_read(void) { return (PIND & (1 << PD3)) ? 1 : 0; }
static inline uint8_t ms_dat_read(void) { return (PIND & (1 << PD5)) ? 1 : 0; }

static bool wait_for_clk(uint8_t level)
{
  uint16_t timeout = 5000;
  while (ms_clk_read() != level) {
    _delay_us(1);
    if (--timeout == 0) return false;
  }
  return true;
}

static void write_bit(uint8_t bit)
{
  if (bit) ms_dat_high(); else ms_dat_low();
  wait_for_clk(1);
  wait_for_clk(0);
}

static bool write_byte(uint8_t data)
{
  uint8_t parity = 1;

  ms_dat_high();
  ms_clk_high();
  _delay_us(300);
  ms_clk_low();
  _delay_us(300);
  ms_dat_low();
  _delay_us(10);

  // Release clock for start bit
  ms_clk_high();
  if (!wait_for_clk(0)) return false;

  for (uint8_t i = 0; i < 8; i++) {
    uint8_t bit = (data >> i) & 1;
    write_bit(bit);
    parity ^= bit;
  }

  // Parity bit
  write_bit(parity);

  // Stop bit
  write_bit(1);

  // Wait for ACK
  if (!wait_for_clk(0)) return false;
  if (!wait_for_clk(1)) return false;

  return true;
}

static int read_bit(void)
{
  wait_for_clk(0);
  int bit = ms_dat_read();
  wait_for_clk(1);
  return bit;
}

static uint8_t read_byte_raw(void)
{
  uint8_t data = 0;
  read_bit(); // start bit
  for (uint8_t i = 0; i < 8; i++) {
    if (read_bit()) data |= (1 << i);
  }
  read_bit(); // parity
  read_bit(); // stop bit
  return data;
}

static bool write_and_read_ack(uint8_t data)
{
  write_byte(data);
  return (read_byte_raw() == 0xFA);
}

static void mouse_isr(void)
{
  uint8_t val = ms_dat_read();
  s_bit_counter++;

  switch (s_bit_counter) {
    case 1: // Start bit
      s_parity_check = 0;
      s_incoming_byte = 0;
      break;

    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
    case 7:
    case 8:
    case 9: // Data bits (LSB first)
      if (val) {
        s_incoming_byte |= (1 << (s_bit_counter - 2));
        s_parity_check++;
      }
      break;

    case 10: // Parity bit
      // (val + s_parity_check) should be odd
      if ((s_parity_check & 1) == val) {
        s_parity_check = 0xFD; // parity error
      }
      break;

    case 11: // Stop bit
      if (s_parity_check < 0xFD) {
        switch (s_byte_counter) {
          case 0:
            s_current_report.status = s_incoming_byte;
            s_byte_counter++;
            break;

          case 1:
            s_current_report.x = (int8_t)s_incoming_byte;
            s_byte_counter++;
            break;

          case 2:
            s_current_report.y = (int8_t)s_incoming_byte;
            s_current_report.z = 0;
            s_byte_counter = 0;

            uint8_t next_head = s_ms_head + 1;
            if (next_head >= MS_BUFFER_SIZE) next_head = 0;
            if (next_head != s_ms_tail) {
              s_ms_buffer[next_head] = s_current_report;
              s_ms_head = next_head;
            }
            break;
        }
      } else {
        s_byte_counter = 0;
      }
      s_bit_counter = 0;
      s_incoming_byte = 0;
      break;

    default:
      s_bit_counter = 0;
      s_byte_counter = 0;
      s_incoming_byte = 0;
      break;
  }
}

static bool mouse_stream_init(void)
{
  ms_clk_high();
  ms_dat_high();

  // Reset command 0xFF
  if (!write_and_read_ack(0xFF)) return false;
  if (read_byte_raw() != 0xAA) return false;
  read_byte_raw(); // device ID (0x00)

  // Resolution: 8 counts/mm
  write_and_read_ack(0xE8);
  write_and_read_ack(0x03);

  // Scaling 1:1
  write_and_read_ack(0xE6);

  // Sample rate 40
  write_and_read_ack(0xF3);
  write_and_read_ack(40);

  // Stream mode
  write_and_read_ack(0xEA);

  // Enable reporting
  write_and_read_ack(0xF4);
  _delay_us(100);

  hal_attach_interrupt(PIN_MS_CLK, mouse_isr, FALLING);
  ms_clk_high();
  ms_dat_high();

  return true;
}

static void mouse_try_init(void)
{
  s_mouse_present = mouse_stream_init();
}

void mouse_init(mouse_event_cb on_mouse_cb)
{
  s_on_mouse_cb = on_mouse_cb;
  ms_clk_high();
  ms_dat_high();
  s_mouse_tries = 3;
  mouse_try_init();
  s_is_started = true;
}

bool mouse_started(void)
{
  return s_is_started;
}

void mouse_handle(bool menu)
{
  (void)menu;
  uint32_t n = millis();

  // Try re-init if not present
  if (s_mouse_tries > 0 && !s_mouse_present && (n - s_tm > 500)) {
    s_mouse_tries--;
    mouse_try_init();
    s_tm = n;
  }

  // Check if reports available
  if (s_ms_head != s_ms_tail) {
    uint8_t next_tail = s_ms_tail + 1;
    if (next_tail >= MS_BUFFER_SIZE) next_tail = 0;
    mouse_report_t r = s_ms_buffer[next_tail];
    s_ms_tail = next_tail;

    s_mouse_new_packet = !s_mouse_new_packet;
    s_mouse_x = (uint8_t)r.x;
    s_mouse_y = (uint8_t)r.y;
    s_mouse_z = (uint8_t)r.z;

    bool btn1 = bitRead(r.status, 0); // Left
    bool btn2 = bitRead(r.status, 1); // Right
    bool btn3 = bitRead(r.status, 2); // Middle

    bitWrite(s_mouse_z, 4, s_mouse_swap ? btn2 : btn1);
    bitWrite(s_mouse_z, 5, s_mouse_swap ? btn1 : btn2);
    bitWrite(s_mouse_z, 6, btn3);
    bitWrite(s_mouse_z, 7, s_mouse_new_packet);

    spi_send(CMD_MOUSE, ADDR_MOUSE_X, s_mouse_x);
    spi_send(CMD_MOUSE, ADDR_MOUSE_Y, s_mouse_y);
    spi_send(CMD_MOUSE, ADDR_MOUSE_Z, s_mouse_z);

    if (s_on_mouse_cb) {
      s_on_mouse_cb(EVENT_OSD_MOUSE_DATA);
    }

    // Middle button hold for 1000ms toggles mouse swap
    if (btn3) {
      if (n - s_ts >= 1000) {
        s_mouse_swap = !s_mouse_swap;
        if (s_on_mouse_cb) {
          s_on_mouse_cb(EVENT_OSD_MOUSE_SWAPPED);
        }
        s_ts = n;
      }
    } else {
      s_ts = n;
    }
  }
}

uint8_t mouse_get_x(void) { return s_mouse_x; }
uint8_t mouse_get_y(void) { return s_mouse_y; }
uint8_t mouse_get_z(void) { return s_mouse_z; }

bool mouse_get_swap(void) { return s_mouse_swap; }
void mouse_set_swap(bool val) { s_mouse_swap = val; }
