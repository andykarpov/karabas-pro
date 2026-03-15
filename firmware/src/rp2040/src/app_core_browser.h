#pragma once

#include <Arduino.h>
#include "config.h"
#include "types.h"
#include "main.h"
#include "OSD.h"

void app_core_browser_overlay();
void app_core_browser_menu(uint8_t vpos);

core_list_item_t app_core_browser_get_item();
void app_core_browser_read_list();

void app_core_browser_on_keyboard();

void app_core_browser_on_time();
