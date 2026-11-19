/*
 * Link v1 (avr.vhd of master 8fbc791): a 3-byte frame (cmd, addr, data) per chip select, the
 * answer of the FPGA in the same bytes. The menu values and the controls go as bits 41..79 of
 * the keyboard frames, next to the key matrix.
 */

#include "link.h"
#include "hal.h"

#define CMD_KEYBOARD  0x01
#define CMD_MOUSE     0x0A
#define CMD_JOY       0x0D
#define CMD_LED_WRITE 0x0E
#define CMD_OSD       0x20
#define CMD_BUILD_REQ 0xF0
#define CMD_RTC       0xFA
#define CMD_INIT_REQ  0xFD
#define CMD_NONE      0xFF

#define ADDR_MOUSE_X 0x0A
#define ADDR_MOUSE_Y 0x0B
#define ADDR_MOUSE_Z 0x0C

#define ADDR_SET_POS_X 0x10
#define ADDR_SET_POS_Y 0x11
#define ADDR_CHAR      0x12
#define ADDR_ATTR      0x13

// bits of the keyboard frames above the 41 keys
#define B_RESET    41
#define B_TURBO    42
#define B_MAGICK   43
#define B_IS_UP    44
#define B_WAIT     45
#define B_SW1      46
#define B_SW2      47
#define B_SCANCODE 48 // 48..55
#define B_SW3      57
#define B_SW4      58
#define B_SW5      59
#define B_KBD_MODE 60
#define B_SW6      61
#define B_SW7      62
#define B_SW8      63
#define B_SW9      64
#define B_SW10     65
#define B_JOY_TYPE 66
#define B_OSD_OVERLAY 67
#define B_TURBO2   68
#define B_SCREEN   69 // 69..70
#define B_OSD_POPUP 71
#define B_JOY_MODE 72 // 72..74
#define B_DIVMMC   75
#define B_NEMOIDE  76
#define B_PLUS3E   77

#define FRAMES_KBD 10

static uint8_t s_kbd[FRAMES_KBD];
static bool s_init_done = false;
static bool s_mouse_toggle = false;

static void bit_set(uint8_t b, bool v)
{
  if (v) s_kbd[b >> 3] |= (uint8_t)(1 << (b & 7));
  else s_kbd[b >> 3] &= (uint8_t)~(1 << (b & 7));
}

static void frame(uint8_t cmd, uint8_t addr, uint8_t data);

static void process_in_cmd(uint8_t cmd, uint8_t addr, uint8_t data)
{
  if (cmd == CMD_INIT_REQ && !s_init_done) {
    s_init_done = true;
    link_on_init(data & 0b00111111, data >> 6);
  }
  if (cmd == CMD_BUILD_REQ) {
    link_on_build(addr, data);
  }
  if (cmd == CMD_LED_WRITE) {
    link_on_leds(data);
  }
  if (cmd == CMD_RTC) {
    link_on_rtc_write(addr, data);
  }
}

static void frame(uint8_t cmd, uint8_t addr, uint8_t data)
{
  hal_spi_cs_low();
  uint8_t rx_cmd  = hal_spi_transfer(cmd);
  uint8_t rx_addr = hal_spi_transfer(addr);
  uint8_t rx_data = hal_spi_transfer(data);
  hal_spi_cs_high();
  if (rx_cmd > 0) {
    process_in_cmd(rx_cmd, rx_addr, rx_data);
  }
}

void link_start(void)
{
  while (!s_init_done) {
    frame(CMD_NONE, 0, 0x00);
    frame(CMD_INIT_REQ, 0, 0x00);
  }
  for (uint8_t i = 0; i < 8; i++) {
    frame(CMD_BUILD_REQ, i, 0x00);
  }
}

void link_setval(uint8_t idx, uint8_t val)
{
  switch (idx) {
    case LV_ROMBANK:
      bit_set(B_PLUS3E, val == 4);
      if (val != 4) {
        bit_set(B_SW3, val & 1);
        bit_set(B_SW4, val & 2);
      }
      break;
    case LV_TURBOFDC: bit_set(B_SW5, val); break;
    case LV_COVOX:    bit_set(B_SW6, val); break;
    case LV_PSG_MIX:  bit_set(B_SW7, val & 1); bit_set(B_SW9, val & 2); break;
    case LV_PSG_TYPE: bit_set(B_SW8, val); break;
    case LV_VIDEO:    bit_set(B_SW1, val); break;
    case LV_VSYNC:    bit_set(B_SW2, val); break;
    case LV_TURBO:    bit_set(B_TURBO, val & 1); bit_set(B_TURBO2, val & 2); break;
    case LV_SWAP_FDD: bit_set(B_SW10, val); break;
    case LV_JOY_TYPE: bit_set(B_JOY_TYPE, val); break;
    case LV_JOY_MODE:
      bit_set(B_JOY_MODE, val & 1); bit_set(B_JOY_MODE + 1, val & 2); bit_set(B_JOY_MODE + 2, val & 4);
      break;
    case LV_SCREEN:   bit_set(B_SCREEN, val & 1); bit_set(B_SCREEN + 1, val & 2); break;
    case LV_DIVMMC:   bit_set(B_DIVMMC, val); break;
    case LV_NEMOIDE:  bit_set(B_NEMOIDE, val); break;
    case LV_KEYBOARD: bit_set(B_KBD_MODE, val); break;
    case LV_PAUSE:    bit_set(B_WAIT, val); break;
    case LV_RESET:    bit_set(B_RESET, val); break;
    case LV_MAGIC:    bit_set(B_MAGICK, val); break;
    case LV_OSD:
      bit_set(B_OSD_OVERLAY, val & LV_OSD_MENU);
      bit_set(B_OSD_POPUP, val & LV_OSD_POPUP);
      break;
    default: break;
  }
}

static void put_keys(const uint8_t keys[LINK_KEYS_SIZE])
{
  for (uint8_t i = 0; i < 5; i++) s_kbd[i] = keys[i];
  s_kbd[5] = (uint8_t)((s_kbd[5] & 0xFE) | (keys[5] & 1));
}

void link_keys(const uint8_t keys[LINK_KEYS_SIZE])
{
  put_keys(keys);
  for (uint8_t i = 0; i < FRAMES_KBD; i++) {
    frame(CMD_KEYBOARD, i + 1, s_kbd[i]);
  }
}

void link_keys_cs(const uint8_t keys[LINK_KEYS_SIZE])
{
  put_keys(keys);
  frame(CMD_KEYBOARD, 1, s_kbd[0]);
  frame(CMD_KEYBOARD, 6, s_kbd[5]);
}

void link_scancode(uint8_t code, bool up)
{
  bit_set(B_IS_UP, up);
  for (uint8_t i = 0; i < 8; i++) bit_set(B_SCANCODE + i, (code >> i) & 1);
}

void link_mouse(uint8_t dx, uint8_t dy, uint8_t z)
{
  s_mouse_toggle = !s_mouse_toggle;
  frame(CMD_MOUSE, ADDR_MOUSE_X, dx);
  frame(CMD_MOUSE, ADDR_MOUSE_Y, dy);
  frame(CMD_MOUSE, ADDR_MOUSE_Z, (uint8_t)((z & 0x7F) | (s_mouse_toggle ? 0x80 : 0)));
}

void link_joy(uint16_t buttons)
{
  // the byte of CMD_JOY: 0 fire, 1 fire2, 2 up, 3 down, 4 left, 5 right, 6 A, 7 B (Start)
  uint8_t flags = 0;
  if (buttons & LJ_B)     flags |= 0x01;
  if (buttons & LJ_C)     flags |= 0x02;
  if (buttons & LJ_UP)    flags |= 0x04;
  if (buttons & LJ_DOWN)  flags |= 0x08;
  if (buttons & LJ_LEFT)  flags |= 0x10;
  if (buttons & LJ_RIGHT) flags |= 0x20;
  if (buttons & LJ_A)     flags |= 0x40;
  if (buttons & LJ_START) flags |= 0x80;
  frame(CMD_JOY, 0, flags);
}

void link_osd_char(uint8_t x, uint8_t y, uint8_t chr, uint8_t attr)
{
  frame(CMD_OSD, ADDR_SET_POS_X, x);
  frame(CMD_OSD, ADDR_SET_POS_Y, y);
  frame(CMD_OSD, ADDR_CHAR, chr);
  frame(CMD_OSD, ADDR_ATTR, attr);
}

void link_rtc(uint8_t reg, uint8_t val)
{
  frame(CMD_RTC, reg, val);
}
