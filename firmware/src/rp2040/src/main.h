#pragma once

#include <Arduino.h>
#include <SPI.h>
#include "config.h"
#include "types.h"
#include "OSD.h"
#include "RTC.h"
#include "SdFat.h"
#include "ElapsedTimer.h"
#include "file.h"
#include "LittleFS.h"
#include "Adafruit_TinyUSB.h"

#define SD2_CONFIG SdSpiConfig(PIN_CONF_DATA, SHARED_SPI, SD_SCK_MHZ(16)) // SD2 SPI Settings

extern RTC zxrtc;
extern OSD zxosd;

extern bool need_redraw;

extern File file1, file2;
extern Dir root1;

extern hid_keyboard_report_t usb_keyboard_report;
extern hid_mouse_report_t usb_mouse_report;

extern uint16_t joy;

extern uint8_t osd_state;
extern core_item_t core;
extern core_file_slot_t file_slots[MAX_FILE_SLOTS];

extern bool is_osd_hiding;
extern ElapsedTimer hide_timer; 

extern file_list_sort_item_t files[SORT_FILES_MAX];
extern uint16_t files_len;
extern uint16_t file_sel;
extern uint16_t file_page_size;
extern uint16_t file_pages;
extern uint16_t file_page;
extern file_list_item_t cached_names[MAX_CORES_PER_PAGE];
extern uint16_t cached_file_from, cached_file_to;

void spi_queue(uint8_t cmd, uint8_t addr, uint8_t data);
void spi_send(uint8_t cmd, uint8_t addr, uint8_t data);
void spi_send16(uint8_t cmd, uint16_t data);
void spi_send24(uint8_t cmd, uint32_t data);
void spi_send32(uint8_t cmd, uint32_t data);
void spi_send64(uint8_t cmd, uint64_t data);
void process_in_cmd(uint8_t cmd, uint8_t addr, uint8_t data);

void do_configure(const char* filename);
void check_update(const char* filename);
uint32_t fpga_send(const char* filename);
void halt(const char* msg);

void osd_handle(bool force);

void read_core(const char* filename);
void read_roms(const char* filename);
void core_trigger(uint8_t pos);
void core_send(uint8_t pos);

void on_time();
void on_keyboard();

bool btn_read(uint8_t num);
void led_write(uint8_t num, bool on);

static void process_kbd_report(uint8_t dev_addr, uint8_t instance, hid_keyboard_report_t const* report, uint16_t len);
static void process_mouse_report(uint8_t dev_addr, uint8_t instance, hid_mouse_report_t const* report, uint16_t len);
