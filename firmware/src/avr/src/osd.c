#include "osd.h"
#include "hal.h"

#define CMD_OSD         0x20
#define ADDR_CLEAR      0x0F
#define ADDR_SET_POS_X  0x10
#define ADDR_SET_POS_Y  0x11
#define ADDR_CHAR       0x12
#define ADDR_ATTR       0x13
#define ADDR_NOOP       0x14

#define SIZE_X 32
#define SIZE_Y 26

static uint8_t s_fg_color = 0;
static uint8_t s_bg_color = 0;
static uint8_t s_current_x = 0;
static uint8_t s_current_y = 0;

void osd_init(void)
{
  s_fg_color = 0;
  s_bg_color = 0;
  s_current_x = 0;
  s_current_y = 0;
}

void osd_set_pos(uint8_t x, uint8_t y)
{
  s_current_x = x;
  s_current_y = y;

  if (x >= SIZE_X) {
    s_current_x = 0;
    s_current_y++;
  }

  if (y >= SIZE_Y) {
    s_current_y = 0;
    s_current_x = 0;
  }
}

void osd_set_color(uint8_t fg, uint8_t bg)
{
  s_fg_color = fg;
  s_bg_color = bg;
}

void osd_clear(void)
{
  osd_fill(0);
}

void osd_write(uint8_t chr)
{
  uint8_t color = s_fg_color << 4;
  spi_send(CMD_OSD, ADDR_SET_POS_X, s_current_x);
  spi_send(CMD_OSD, ADDR_SET_POS_Y, s_current_y);
  spi_send(CMD_OSD, ADDR_CHAR, chr);
  spi_send(CMD_OSD, ADDR_ATTR, s_bg_color + color);
  osd_set_pos(s_current_x + 1, s_current_y);
}

void osd_fill(uint8_t chr)
{
  osd_set_pos(0, 0);
  for (uint8_t y = 0; y < SIZE_Y; y++) {
    for (uint8_t x = 0; x < SIZE_X; x++) {
      osd_write(chr);
    }
  }
}

void osd_fill_rect(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t chr)
{
  for (uint8_t y = y1; y <= y2; y++) {
    osd_set_pos(x1, y);
    for (uint8_t x = x1; x <= x2; x++) {
      osd_write(chr);
    }
  }
}

void osd_frame(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t thickness)
{
  for (uint8_t y = y1; y <= y2; y++) {
    osd_set_pos(x1, y);
    for (uint8_t x = x1; x <= x2; x++) {
      if (y == y1 && x == x1) {
        osd_write(thickness ? 201 : 218); // lt
      } else if (y == y2 && x == x1) {
        osd_write(thickness ? 200 : 192); // lb
      } else if (y == y1 && x == x2) {
        osd_write(thickness ? 187 : 191); // rt
      } else if (y == y2 && x == x2) {
        osd_write(thickness ? 188 : 217); // rb
      } else if (y == y1 || y == y2) {
        osd_write(thickness ? 205 : 196); // t / b
      } else if ((x == x1 && y > y1 && y < y2) || (x == x2 && y > y1 && y < y2)) {
        osd_set_pos(x, y);
        osd_write(thickness ? 186 : 179); // l / r
      }
    }
  }
}

void osd_print(const char *str)
{
  if (!str) return;
  while (*str) {
    osd_write((uint8_t)*str++);
  }
}

void osd_print_p(const char *pgm_str)
{
  if (!pgm_str) return;
  char c;
  while ((c = pgm_read_byte(pgm_str++))) {
    osd_write((uint8_t)c);
  }
}

void osd_print_num(uint32_t n, uint8_t base)
{
  if (base < 2 || base > 16) base = 10;
  char buf[12];
  char *str = &buf[sizeof(buf) - 1];
  *str = '\0';

  if (n == 0) {
    osd_write('0');
    return;
  }

  while (n > 0) {
    uint8_t m = n % base;
    n /= base;
    *(--str) = (m < 10) ? ('0' + m) : ('A' + m - 10);
  }
  osd_print(str);
}

void osd_print_int(int32_t n, uint8_t base)
{
  if (base == 10 && n < 0) {
    osd_write('-');
    osd_print_num((uint32_t)(-n), 10);
  } else {
    osd_print_num((uint32_t)n, base);
  }
}
