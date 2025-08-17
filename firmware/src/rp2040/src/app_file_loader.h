#pragma once

#include <Arduino.h>

void app_file_loader_read_list(bool forceIndex);
void app_file_loader_menu(uint8_t vpos);
void app_file_loader_overlay(bool initSD, bool recreateIndex);
void app_file_loader_save();
void app_file_loader_send_file(uint16_t file_id);
void app_file_loader_send_byte(uint32_t addr, uint8_t data);
void app_file_loader_on_keyboard();
