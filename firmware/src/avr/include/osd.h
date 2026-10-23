#ifndef __OSD_H__
#define __OSD_H__

#include <stdint.h>
#include <stdbool.h>
#include <avr/pgmspace.h>

#define OSD_COLOR_BLACK     0b0000
#define OSD_COLOR_FLASH     0b0001
#define OSD_COLOR_WHITE     0b1111
#define OSD_COLOR_GREY      0b1110
#define OSD_COLOR_RED       0b1000
#define OSD_COLOR_GREEN     0b0100
#define OSD_COLOR_BLUE      0b0010
#define OSD_COLOR_RED_I     0b1001
#define OSD_COLOR_GREEN_I   0b0101
#define OSD_COLOR_BLUE_I    0b0011
#define OSD_COLOR_YELLOW    0b1100
#define OSD_COLOR_YELLOW_I  0b1101
#define OSD_COLOR_MAGENTA   0b1010
#define OSD_COLOR_MAGENTA_I 0b1011
#define OSD_COLOR_CYAN      0b0110
#define OSD_COLOR_CYAN_I    0b0111

#ifdef __cplusplus
extern "C" {
#endif

void osd_init(void);
void osd_set_pos(uint8_t x, uint8_t y);
void osd_set_color(uint8_t fg, uint8_t bg);
void osd_clear(void);
void osd_fill(uint8_t chr);
void osd_fill_rect(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t chr);
void osd_frame(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t thickness);
void osd_write(uint8_t chr);
void osd_print(const char *str);
void osd_print_p(const char *pgm_str);
void osd_print_num(uint32_t num, uint8_t base);
void osd_print_int(int32_t num, uint8_t base);

#ifdef __cplusplus
}
#endif

#endif // __OSD_H__
