/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __ZXOSD_H__
#define __ZXOSD_H__

// Framework headers
#include <hal.h>

// Library & AVR headers
#include <avr/pgmspace.h>
#include <OSD.h>
#include <ZXKeyboard.h>
#include <ZXRTC.h>

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

#define PGMT( pgm_ptr ) ( reinterpret_cast< const __FlashStringHelper * >( pgm_ptr ) )

#define MAIN_MENU_ITEMS_COUNT 16
#define RTC_FIELDS_COUNT 7

class ZXOSD
{
  using spi_cb = void (*)(uint8_t cmd, uint8_t addr, uint8_t data);

private:
  spi_cb action = nullptr;
  OSD osd;
  bool is_started = false;

  uint8_t fpga_cfg = 0;
  uint8_t fpga_build_num[8] = {0};
  const char *avr_build_num = nullptr;
  unsigned long tstart = 0;

  enum osd_state_e {
    state_main = 0,
    state_rtc,
    state_about,
    state_info
  };

  uint8_t osd_state = state_main;
  uint8_t osd_prev_state = state_main;
  uint8_t osd_main_state = 0;
  uint8_t osd_prev_main_state = 0;
  uint8_t osd_rtc_state = 0;
  uint8_t osd_prev_rtc_state = 0;

protected:
  void highlight(bool val);
  void hint(const __FlashStringHelper* msg);
  void param(const __FlashStringHelper* msg);
  void text(const __FlashStringHelper* msg);
  void flash(const __FlashStringHelper* msg);

  void renderMenuItem(uint8_t idx, bool is_active);
  void changeMenuItem(uint8_t idx, int8_t dir);
  void changeRtcField(uint8_t idx, int8_t dir);

public:
  ZXOSD();

  void begin(spi_cb act);
  bool started();
  void handle();

  void printHeader();
  void printLogo(uint8_t x, uint8_t y);
  void printRev();
  void printLine(uint8_t y);
  void printSpace();
  void clear();

  void initOverlay();
  void initPopup(uint8_t event_type);
  void initRtcOverlay();
  void initAboutOverlay();
  void initInfoOverlay();

  void popupFooter();

  // Data-driven rendering
  void renderMenuItemValue(uint8_t idx, bool is_active);
  void renderRtcFieldValue(uint8_t idx, bool is_active);
  static int8_t eventToMenuItem(uint8_t event_type);

  // Unified / backward-compatible item updates
  void updateItem(uint8_t idx) { renderMenuItemValue(idx, osd_main_state == idx); }
  void updateRombank()      { updateItem(0); }
  void updateTurbofdc()     { updateItem(1); }
  void updateCovox()        { updateItem(2); }
  void updateStereo()       { updateItem(3); }
  void updateSsg()          { updateItem(4); }
  void updateVideo()        { updateItem(5); }
  void updateVsync()        { updateItem(6); }
  void updateTurbo()        { updateItem(7); }
  void updateSwapAB()       { updateItem(8); }
  void updateJoystick()     { updateItem(9); }
  void updateJoystickMode() { updateItem(10); }
  void updateScreenMode()   { updateItem(11); }
  void updateDivmmc()       { updateItem(12); }
  void updateNemoIDE()      { updateItem(13); }
  void updateKeyboardType() { updateItem(14); }
  void updatePause()        { updateItem(15); }

  void updateRtcHour()   { renderRtcFieldValue(0, osd_rtc_state == 0); }
  void updateRtcMinute() { renderRtcFieldValue(1, osd_rtc_state == 1); }
  void updateRtcSecond() { renderRtcFieldValue(2, osd_rtc_state == 2); }
  void updateRtcDay()    { renderRtcFieldValue(3, osd_rtc_state == 3); }
  void updateRtcMonth()  { renderRtcFieldValue(4, osd_rtc_state == 4); }
  void updateRtcYear()   { renderRtcFieldValue(5, osd_rtc_state == 5); }
  void updateRtcDow()    { renderRtcFieldValue(6, osd_rtc_state == 6); }

  void updateTime();
  void updateUptime();
  void updateScancode(uint16_t c);
  void updateMouse(uint8_t mouse_x, uint8_t mouse_y, uint8_t mouse_z);
  void updateJoyState(uint8_t joy);

  void setFpgaCfg(uint8_t cfg);
  void setFpgaBuildNum(uint8_t pos, uint8_t data);
  void setAvrBuildNum(const char *data);
};

#endif // __ZXOSD_H__
