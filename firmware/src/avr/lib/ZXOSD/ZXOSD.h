/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __ZXOSD_H__
#define __ZXOSD_H__

// STL headers
// C headers
// Framework headers
#if ARDUINO < 100
#include <WProgram.h>
#else
#include <Arduino.h>
#endif

// Library headers
// Project headers
#include <avr/pgmspace.h>
#include <OSD.h>
#include <ZXKeyboard.h>
#include <ZXRTC.h>

/****************************************************************************/


class ZXOSD
{

  using spi_cb = void (*)(uint8_t addr, uint8_t data); // alias function pointer

private:
  spi_cb action;
	OSD osd;
  bool is_started = false;

  uint8_t fpga_cfg;
  uint8_t fpga_build_num[8];
  const char *avr_build_num;
  unsigned long tstart = 0;

  // osd global states
  enum osd_state_e {
    state_main = 0,
    state_rtc,
    state_test,
    state_about,
    state_info
  };

  // osd main states
  enum osd_main_state_e {
    state_main_rom_bank = 0,
    state_main_turbofdc,
    state_main_covox,
    state_main_stereo,
    state_main_ssg,
    state_main_video,
    state_main_sync,
    state_main_turbo,
    state_main_swap_ab,
    state_main_joy_type,
    state_main_screen_mode,
    state_main_keyboard_type,
    state_main_pause
  };

  // osd rtc states
  enum osd_rtc_state_e {
    state_rtc_hour = 0,
    state_rtc_minute,
    state_rtc_second,
    state_rtc_day,
    state_rtc_month,
    state_rtc_year,
    state_rtc_dow
  };

  uint8_t osd_state = state_main;
  uint8_t osd_prev_state = state_main;
  uint8_t osd_main_state = state_main_rom_bank;
  uint8_t osd_prev_main_state = state_main_rom_bank;
  uint8_t osd_rtc_state = state_rtc_dow;
  uint8_t osd_prev_rtc_state = state_rtc_dow;

protected:

  void highlight(bool val);
  void hint(const __FlashStringHelper* msg);
  void param(const __FlashStringHelper* msg);
  void text(const __FlashStringHelper* msg);
  void flash(const __FlashStringHelper* msg);

public:

  ZXOSD();

  void begin(spi_cb act); // TODO: zxmouse, zxjoy
  bool started();
  void handle();

  void printHeader();
  void printLogo(uint8_t x, uint8_t y);
  void printLine(uint8_t y);
  void printSpace();
  void clear();

  void initOverlay();
  void initPopup(uint8_t event_type);
  void initRtcOverlay();
  void initTestOverlay();
  void initAboutOverlay();
  void initInfoOverlay();

  void popupFooter();
  
  void handleRombank();
  void handleTurbofdc();
  void handleCovox();
  void handleStereo();
  void handleSsg();
  void handleVideo();
  void handleVsync();
  void handleTurbo();
  void handleSwapAB();
  void handleJoyType();
  void handleScreenMode();
  void handleKeyboardType();
  void handlePause();

  void handleRtcHour();
  void handleRtcMinute();
  void handleRtcSecond();
  void handleRtcDay();
  void handleRtcMonth();
  void handleRtcYear();
  void handleRtcDow();

  void updateRombank();
  void updateTurbofdc();
  void updateCovox();
  void updateStereo();
  void updateSsg();
  void updateVideo();
  void updateVsync();
  void updateTurbo();
  void updateSwapAB();
  void updateJoystick();
  void updateScreenMode();
  void updateKeyboardType();
  void updatePause();

  void updateRtcHour();
  void updateRtcMinute();
  void updateRtcSecond();
  void updateRtcDay();
  void updateRtcMonth();
  void updateRtcYear();
  void updateRtcDow();
  
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
// vim:cin:ai:sts=2 sw=2 ft=cpp
