#pragma once

#include "config.h"
#include "SdFat.h"

typedef struct {
	uint8_t cmd;
	uint8_t addr;
    uint8_t data;
} queue_spi_t;

typedef struct {
	bool flash;
	char id[32+1];
	char name[32+1];
	char filename[32+1];
	char build[8+1];
	uint8_t order;
	bool visible;
	uint8_t type;
} core_list_item_t;

typedef struct {
	char name[16+1];
} core_osd_option_t;

typedef struct {
	bool is_mounted;
	bool is_autoload;
	char ext[256];
	char dir[256];
	char filename[256];
	uint32_t offset_dir; // core file pos to write dir name
	uint32_t offset_filename; // core file pos to write file name
	File32 file;
} core_file_slot_t;

typedef struct {
	bool is_dir;
	char name[32];
	char dir[256];
	char filename[256];
} core_filebrowser_item_t;

typedef struct {
	uint8_t type;
	uint8_t def;
	char name[16+1];
	char hotkey[16+1];
	uint8_t keys[2];
	core_osd_option_t options[MAX_OSD_ITEM_OPTIONS];
	uint8_t options_len;
	uint8_t val;
	uint8_t prev_val;
	uint8_t slot_id;
} core_osd_t;

typedef struct {
	uint8_t val;
	uint8_t prev_val;
} core_eeprom_t;

typedef struct {
	char id[32+1];
	char build[8+1];
	char name[32+1];
	char filename[32+1];
	bool flash;
	uint8_t order;
	bool visible;
	uint8_t type;
	uint32_t bitstream_length;
	uint8_t eeprom_bank;
	uint8_t rtc_type;
	uint8_t spi_freq;
	bool sd_enable;
	core_osd_t osd[MAX_OSD_ITEMS];
	uint8_t osd_len;
	core_eeprom_t eeprom[MAX_EEPROM_ITEMS];
	bool osd_need_save;
	bool eeprom_need_save;
	char dir[32+1];
//	char last_file[32+1];
	uint16_t last_file_id;
	char file_extensions[32+1];
} core_item_t;

typedef struct {
	char name[32+1];
} file_list_item_t;

typedef struct {
	uint16_t file_id;
	char hash[SORT_HASH_LEN];
} file_list_sort_item_t;

typedef struct {
	bool debug_enabled;
	bool debug_hid;
	bool autoload_enabled;
	uint8_t autoload_timeout;
	char autoload_core[32+1];
} setup_t;

enum osd_state_e {
    state_main = 0,
    state_rtc,
	state_core_browser,
	state_file_loader
};
