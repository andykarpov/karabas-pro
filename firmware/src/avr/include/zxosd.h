#ifndef __ZXOSD_H__
#define __ZXOSD_H__

#include <stdint.h>
#include <stdbool.h>

#define LANG_EN 0
#define LANG_RU 1
#define LANG_UA 2

#ifndef LANG
#define LANG LANG_EN
#endif

#if (LANG == LANG_RU)
#include "lang_ru.h"
#elif (LANG == LANG_UA)
#include "lang_ua.h"
#else
#include "lang_en.h"
#endif

#define MAIN_MENU_ITEMS_COUNT 16
#define RTC_FIELDS_COUNT 7

#ifdef __cplusplus
extern "C" {
#endif

void zxosd_init(void);
bool zxosd_started(void);
void zxosd_handle(void);
void zxosd_clear(void);

void zxosd_init_overlay(void);
void zxosd_init_popup(uint8_t event_type);
void zxosd_show_popup(uint8_t event_type);
void zxosd_show_boot_popup(void);
void zxosd_on_key_event(uint8_t event_type);

void zxosd_update_item(uint8_t idx);
void zxosd_update_time(void);
void zxosd_update_scancode(uint16_t scancode);
void zxosd_update_mouse(uint8_t x, uint8_t y, uint8_t z);
void zxosd_update_joy_state(uint8_t data);

void zxosd_set_fpga_cfg(uint8_t cfg);
void zxosd_set_fpga_build_num(uint8_t pos, uint8_t data);
void zxosd_set_avr_build_num(const char *data);

int8_t zxosd_event_to_menu_item(uint8_t event_type);

#ifdef __cplusplus
}
#endif

#endif // __ZXOSD_H__
