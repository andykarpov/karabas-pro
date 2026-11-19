#ifndef __LINK_H__
#define __LINK_H__

/*
 * The link to the FPGA (docs/AVR_LINK_V2.md). The services say what they send (the key matrix,
 * a menu value, a mouse report, ...), the link turns it into frames on the SPI. Only the link
 * knows the frames.
 */

#include <stdint.h>
#include <stdbool.h>

// SYS SETVAL indices: 00..0F are the items of the main OSD menu in their order, the value is
// what the getter of the item returns; 10.. are controls
#define LV_ROMBANK   0x00 // 0..3 bank, 4 +3e (sw3 / sw4 keep the last bank 0..3)
#define LV_TURBOFDC  0x01
#define LV_COVOX     0x02
#define LV_PSG_MIX   0x03 // 0 ACB, 1 ABC, 2 mono
#define LV_PSG_TYPE  0x04
#define LV_VIDEO     0x05
#define LV_VSYNC     0x06
#define LV_TURBO     0x07 // 0..3
#define LV_SWAP_FDD  0x08
#define LV_JOY_TYPE  0x09
#define LV_JOY_MODE  0x0A // 0..4
#define LV_SCREEN    0x0B // 0 Pentagon, 1 Classic
#define LV_DIVMMC    0x0C
#define LV_NEMOIDE   0x0D
#define LV_KEYBOARD  0x0E // 0 Spectrum, 1 Profi XT
#define LV_PAUSE     0x0F
#define LV_RESET     0x10 // 1 held, 0 released
#define LV_MAGIC     0x11
#define LV_OSD       0x12 // bit 0 menu, bit 1 popup

#define LV_OSD_MENU  0x01
#define LV_OSD_POPUP 0x02

// HID JOY buttons (the layout of Karabas Go)
#define LJ_CTL_ON 0x0001 // a Sega pad answers
#define LJ_UP     0x0002
#define LJ_DOWN   0x0004
#define LJ_LEFT   0x0008
#define LJ_RIGHT  0x0010
#define LJ_START  0x0020
#define LJ_A      0x0040
#define LJ_B      0x0080 // Atari fire 1
#define LJ_C      0x0100 // Atari fire 2
#define LJ_X      0x0200
#define LJ_Y      0x0400
#define LJ_Z      0x0800
#define LJ_MODE   0x1000

#define LINK_KEYS_SIZE 6 // bits 0..39 the ZX matrix, bit 40 the 5th bit of Profi

#ifdef __cplusplus
extern "C" {
#endif

// waits for the FPGA, reads its build id; calls link_on_init() / link_on_build()
void link_start(void);

void link_setval(uint8_t idx, uint8_t val);
void link_keys(const uint8_t keys[LINK_KEYS_SIZE]);
void link_keys_cs(const uint8_t keys[LINK_KEYS_SIZE]); // CS ahead of a cursor key
void link_scancode(uint8_t code, bool up); // link v1 only (bits of the matrix frames)
void link_mouse(uint8_t dx, uint8_t dy, uint8_t z); // z: bits 3..0 wheel, 4..6 buttons
void link_joy(uint16_t buttons);
void link_osd_char(uint8_t x, uint8_t y, uint8_t chr, uint8_t attr);
void link_rtc(uint8_t reg, uint8_t val);

// called by the link
void link_on_init(uint8_t cfg, uint8_t max_turbo);
void link_on_build(uint8_t pos, uint8_t c);
void link_on_leds(uint8_t bits); // bit 0 LED1, 1 LED2, 2 LED1 by the FPGA, 3 LED2 by the FPGA
void link_on_rtc_write(uint8_t reg, uint8_t val);

#ifdef __cplusplus
}
#endif

#endif // __LINK_H__
