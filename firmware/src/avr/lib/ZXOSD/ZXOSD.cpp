/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

// STL headers
// C headers
#include <avr/pgmspace.h>
// Framework headers
// Library headers
#include <SPI.h>
// Project headers
// This component's header
#include <ZXOSD.h>
#include <Arduino.h>
#include <OSD.h>
#include <ZXKeyboard.h>
#include <ZXRTC.h>

/****************************************************************************/

ZXOSD::ZXOSD(void)
{
}

/****************************************************************************/

void ZXOSD::begin(spi_cb act, ZXKeyboard *zxkbd_, ZXRTC *zxrtc_) // todo: zxmouse, zxjoy
{
  zxkbd = zxkbd_;
  zxrtc = zxrtc_;
  action = act;
  tstart = millis();
  osd.begin(action);

  is_started = true;
}

bool ZXOSD::started() {
  return is_started;
}

void ZXOSD::handle()
{
  // switch betweeen main osd states
  if (zxkbd->getIsOsdOverlay()) {
    switch (osd_state) {
      case state_main:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          osd_main_state = state_main_rom_bank;
          osd_prev_main_state = state_main_rom_bank;
          initOverlay();
        }

        if (osd_main_state != osd_prev_main_state) {
          osd_prev_main_state = osd_main_state;
          switch(osd_main_state) {
            case state_main_rom_bank: updatePause(); updateRombank(); updateTurbofdc(); break;
            case state_main_turbofdc: updateRombank(); updateTurbofdc(); updateCovox(); break;
            case state_main_covox: updateTurbofdc(); updateCovox(); updateStereo(); break;
            case state_main_stereo: updateCovox(); updateStereo(); updateSsg(); break;
            case state_main_ssg: updateStereo(); updateSsg(); updateVideo(); break;
            case state_main_video: updateSsg(); updateVideo(); updateVsync(); break;
            case state_main_sync: updateVideo(); updateVsync(); updateTurbo(); break;
            case state_main_turbo: updateVsync(); updateTurbo(); updateSwapAB(); break;
            case state_main_swap_ab: updateTurbo(); updateSwapAB(); updateJoystick(); break;
            case state_main_joy_type: updateSwapAB(); updateJoystick(); updateKeyboardType(); break;
            case state_main_keyboard_type: updateJoystick(); updateKeyboardType(); updatePause(); break;
            case state_main_pause: updateKeyboardType(); updatePause(); updateRombank(); break;
          }
        }

      break;
      case state_rtc:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          osd_rtc_state = state_rtc_hour;
          osd_prev_rtc_state = state_rtc_hour;
          initRtcOverlay();
        }

        if (osd_rtc_state != osd_prev_rtc_state) {
          osd_prev_rtc_state = osd_rtc_state;
          switch(osd_rtc_state) {
            case state_rtc_hour: updateRtcDow(); updateRtcHour(); updateRtcMinute(); break;
            case state_rtc_minute: updateRtcHour(); updateRtcMinute(); updateRtcSecond(); break;
            case state_rtc_second: updateRtcMinute(); updateRtcSecond(); updateRtcDay(); break;
            case state_rtc_day: updateRtcSecond(); updateRtcDay(); updateRtcMonth(); break;
            case state_rtc_month: updateRtcDay(); updateRtcMonth(); updateRtcYear(); break;
            case state_rtc_year: updateRtcMonth(); updateRtcYear(); updateRtcDow(); break;
            case state_rtc_dow: updateRtcYear(); updateRtcDow(); updateRtcHour(); break;
          }
        }

      break;

      case state_test:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          initTestOverlay();
        }
      break;

      case state_about:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          initAboutOverlay();
        }
      break;

      case state_info:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          initInfoOverlay();
        }
      break;
    }
  }

  // process osd overlay keyboard actions here
  if (zxkbd->getIsOsdOverlay()) {
    switch (osd_state) {
      case state_main:

        if (zxkbd->getIsCursorDown()) {
          osd_main_state++;
          if (osd_main_state > state_main_pause) osd_main_state = state_main_rom_bank;
        }

        if (zxkbd->getIsCursorUp()) {
          osd_main_state--;
          if (osd_main_state > state_main_pause) osd_main_state = state_main_pause;
        }

        if (zxkbd->getKey(ZX_K_S) || zxkbd->getKey(ZX_K_E) || zxkbd->getKey(ZX_K_R)) {
          osd_state = state_rtc;
        }

        if (zxkbd->getKey(ZX_K_T)) {
          osd_state = state_test;
        }

        if (zxkbd->getKey(ZX_K_A)) {
          osd_state = state_about;
        }

        if (zxkbd->getKey(ZX_K_I)) {
          osd_state = state_info;
        }

        /*if (zxkbd->getIsEscape()) {
          zxkbd->toggleOsdOverlay();
        }*/

        switch (osd_main_state) {
          case state_main_rom_bank: handleRombank(); break;
          case state_main_turbofdc: handleTurbofdc(); break;
          case state_main_covox: handleCovox(); break;
          case state_main_stereo: handleStereo(); break;
          case state_main_ssg: handleSsg(); break;
          case state_main_video: handleVideo(); break;
          case state_main_sync: handleVsync(); break;
          case state_main_turbo: handleTurbo(); break;
          case state_main_swap_ab: handleSwapAB(); break;
          case state_main_joy_type: handleJoyType(); break;
          case state_main_keyboard_type: handleKeyboardType(); break;
          case state_main_pause: handlePause(); break;
        }
      break;
      case state_rtc:

        if (zxkbd->getIsCursorDown()) {
          osd_rtc_state++;
          if (osd_rtc_state > state_rtc_dow) osd_rtc_state = state_rtc_hour;
        }

        if (zxkbd->getIsCursorUp()) {
          osd_rtc_state--;
          if (osd_rtc_state > state_rtc_dow) osd_rtc_state = state_rtc_dow;
        }

        if (zxkbd->getIsEscape()) {
          osd_state = state_main;
        }

        switch (osd_rtc_state) {
          case state_rtc_hour: handleRtcHour(); break;
          case state_rtc_minute: handleRtcMinute(); break;
          case state_rtc_second: handleRtcSecond(); break;
          case state_rtc_day: handleRtcDay(); break;
          case state_rtc_month: handleRtcMonth(); break;
          case state_rtc_year: handleRtcYear(); break;
          case state_rtc_dow: handleRtcDow(); break;
        }

      break;

      case state_test:
      case state_about:
      case state_info:

        if (zxkbd->getIsEscape()) {
          osd_state = state_main;
        }

      break;
    }
  }

  // empty keyboard matrix in overlay mode before transmitting it onto FPGA side
  if (zxkbd->getIsOsdOverlay()) {
    zxkbd->clear(ZX_MATRIX_SIZE);
  }
}

void ZXOSD::setFpgaCfg(uint8_t cfg) {
  fpga_cfg = cfg;
}

void ZXOSD::setFpgaBuildNum(uint8_t pos, uint8_t data) {
  fpga_build_num[pos] = data;
}

void ZXOSD::setAvrBuildNum(const char *data) {
  avr_build_num = data;
}

void ZXOSD::printLogo(uint8_t x, uint8_t y)
{
  osd.setPos(x,y);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);

  // karabas logo
  osd.write(128); osd.write(129); 
  osd.write(130); osd.write(131); 
  osd.write(132); osd.write(133); 
  osd.write(130); osd.write(131); 
  osd.write(134); osd.write(135);
  osd.write(130); osd.write(131); 
  osd.write(136); osd.write(137); 

  osd.setPos(x,y+1);
  osd.write(144); osd.write(145); 
  osd.write(146); osd.write(147); 
  osd.write(148); osd.write(149); 
  osd.write(146); osd.write(147); 
  osd.write(150); osd.write(151);
  osd.write(146); osd.write(147); 
  osd.write(152); osd.write(153); 

  osd.setPos(x+8, y+2);
  osd.write(138); osd.write(139);
  osd.write(132); osd.write(133); 
  osd.write(140); osd.write(141); 

  osd.setPos(x+8, y+3);
  osd.write(154); osd.write(155);
  osd.write(148); osd.write(149); 
  osd.write(156); osd.write(157); 

  osd.setPos(x+1, y+2);
  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.write(22);
  osd.setColor(OSD::COLOR_YELLOW_I, OSD::COLOR_BLACK);
  osd.write(22);
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.write(22);
  osd.setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK);
  osd.write(22);

  osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  osd.setPos(x,y+3);
  // board revision
  switch (fpga_cfg) {
    case 0:
    case 1:
      osd.print(F("Rev.A"));
      break;
    case 4:
    case 5:
      osd.print(F("Rev.DS"));
      break;
    case 36:
    case 37:
      osd.print(F("Rev.E"));
      break;
  }
}

void ZXOSD::printLine(uint8_t y)
{
  osd.setPos(0,y);
  for (uint8_t i=0; i<32; i++) {
    osd.write(196);
  }
}

void ZXOSD::printHeader()
{
  printLogo(0,0);

  // dac type
/*  switch (fpga_cfg) {
    case 0:
    case 4:
    case 36:
      osd.print(F("TDA1543"));
      break;
    case 1:
    case 5:
    case 37:
      osd.print(F("TDA1543A"));
      break;
  }
*/

  osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  osd.setPos(19,2);
  osd.print(F("FPGA "));
  osd.write(fpga_build_num[0]);
  osd.write(fpga_build_num[1]);
  osd.write(fpga_build_num[2]);
  osd.write(fpga_build_num[3]);
  osd.write(fpga_build_num[4]);
  osd.write(fpga_build_num[5]);
  osd.write(fpga_build_num[6]);
  osd.write(fpga_build_num[7]);

  osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  osd.setPos(20,3);
  osd.print(F("AVR "));
  osd.print(avr_build_num);

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  printLine(4);

  updateTime();
}

// init osd
void ZXOSD::initOverlay()
{
  osd_state = state_main;

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  // ROM Bank
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,5); osd.print(F("ROM Bank:"));
  updateRombank();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,5); osd.print(F("Menu+F1-F4"));

  // Turbo FDC
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,6); osd.print(F("TurboFDC:"));
  updateTurbofdc();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,6); osd.print(F("Menu+F5"));

  // Covox
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,7); osd.print(F("Covox:"));
  updateCovox();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,7); osd.print(F("Menu+F6"));

  // Stereo
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,8); osd.print(F("PSG mix:"));
  updateStereo();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,8); osd.print(F("Menu+F7"));

  // SSG type
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,9); osd.print(F("PSG type:"));
  updateSsg();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,9); osd.print(F("Menu+F8"));

  // RGB/VGA
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,10); osd.print(F("Video:"));
  updateVideo();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,10); osd.print(F("Menu+F9"));

  // VSync
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,11); osd.print(F("VSync:"));
  updateVsync();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,11); osd.print(F("Menu+F10"));

  // Turbo
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,12); osd.print(F("Turbo:"));
  updateTurbo();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,12); osd.print(F("Menu+F11"));

  // FDC Swap
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,13); osd.print(F("Swap FDD:"));
  updateSwapAB();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,13); osd.print(F("Menu+Tab"));

  // Joy type
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,14); osd.print(F("Joy type:"));
  updateJoystick();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,14); osd.print(F("Menu+J"));

  // Keyboard
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,15); osd.print(F("Keyboard:"));
  updateKeyboardType();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,15); osd.print(F("PrtScr"));

  // Pause
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,16); osd.print(F("Pause:"));
  updatePause();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,16); osd.print(F("Pause"));

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  printLine(17);

  // Scancode
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,18); osd.print(F("Scancode:"));
  updateScancode(0);

  // Mouse
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,19); osd.print(F("Mouse:"));
  updateMouse(0,0,0);

  // Joy
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,20); osd.print(F("Port #1F:"));
  updateJoyState(0);

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(20,18); 
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_FLASH);
  osd.print(F("S"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("et up RTC"));

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(20,19); 
  osd.print(F("Color "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_FLASH);
  osd.print(F("T"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("est"));

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(20,20); 
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_FLASH);
  osd.print(F("I"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("nfo "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_FLASH);
  osd.print(F("A"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("bout"));

  printLine(21);

  // footer
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,22); osd.print(F("Press "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F("Ctrl+Alt+Del"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" to reboot"));

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,23); osd.print(F("Press "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F("Menu+ESC"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" to toggle OSD"));
}

// init rtc osd
void ZXOSD::initRtcOverlay()
{
  zxrtc->fixInvalidTime(); // try to fix invalid time

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0,5);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("RTC setup:"));

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,7); osd.print(F("Hours:"));
  updateRtcHour();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,8); osd.print(F("Minutes:"));
  updateRtcMinute();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,9); osd.print(F("Seconds:"));
  updateRtcSecond();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,11); osd.print(F("Day:"));
  updateRtcDay();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,12); osd.print(F("Month:"));
  updateRtcMonth();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,13); osd.print(F("Year:"));
  updateRtcYear();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,15); osd.print(F("DOW:"));
  updateRtcDow();

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0, 17);
  osd.print(F("Please use arrows "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.write(17);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" and "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.write(16);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0, 18);
  osd.print(F("to change values, "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.write(30);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" and "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.write(31);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0, 19);
  osd.print(F("to navigate by menu items"));

  popupFooter();
}

// init test osd
void ZXOSD::initTestOverlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0,5);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("Color test:"));

  uint8_t color = 0;
  for (uint8_t x = 0; x<32; x++) {
    for (uint8_t y = 7; y<21; y++) {
      color = x/2;
      switch (color) {
        case 0: osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_BLACK); break;
        case 1: osd.setColor(OSD::COLOR_RED, OSD::COLOR_BLACK); break;
        case 2: osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK); break;
        case 3: osd.setColor(OSD::COLOR_YELLOW, OSD::COLOR_BLACK); break;
        case 4: osd.setColor(OSD::COLOR_YELLOW_I, OSD::COLOR_BLACK); break;
        case 5: osd.setColor(OSD::COLOR_GREEN, OSD::COLOR_BLACK); break;
        case 6: osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK); break;
        case 7: osd.setColor(OSD::COLOR_CYAN, OSD::COLOR_BLACK); break;
        case 8: osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); break;
        case 9: osd.setColor(OSD::COLOR_BLUE, OSD::COLOR_BLACK); break;
        case 10: osd.setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK); break;
        case 11: osd.setColor(OSD::COLOR_MAGENTA, OSD::COLOR_BLACK); break;
        case 12: osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK); break;
        case 13: osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK); break;
        case 14: osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); break;
        case 15: osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_BLACK); break;
      }
      osd.setPos(x, y); osd.write(219);
    }
  }

  popupFooter();

}

// init test osd
void ZXOSD::initAboutOverlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0,5);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("About:"));

  osd.setPos(0,7);
  osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.print(F("Karabas Pro developers are:"));

  osd.setPos(0,9);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(F(" andykarpov"));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F(" FPGA, AVR, PCB"));

  osd.setPos(0,10);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(F(" solegstar "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F(" FPGA, PCB"));

  osd.setPos(0,11);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(F(" dr_max    "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F(" FlashTool & FDImage"));

  osd.setPos(0,12);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(F(" nihirash  "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F(" Internet software"));

  osd.setPos(0,14);
  osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.print(F("Special thanks to:"));

  osd.setPos(0,16);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(F(" kalantaj"));

  osd.setPos(0,17);
  osd.write(250);
  osd.print(F(" tank-uk"));

  osd.setPos(0,18);
  osd.write(250);
  osd.print(F(" xdemox"));

  osd.setPos(0,19);
  osd.write(250);
  osd.print(F(" dumpkin"));

  osd.setPos(18,21);
  osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  osd.print(F("www.karabas.uk"));

  popupFooter();

}

// init test osd
void ZXOSD::initInfoOverlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0,5);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("System Info:"));

  // todo

  uint8_t y=14;

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,7);
  osd.print(F("FPGA build:"));
  osd.setPos(y,7);
  osd.write(fpga_build_num[0]);
  osd.write(fpga_build_num[1]);
  osd.write(fpga_build_num[2]);
  osd.write(fpga_build_num[3]);
  osd.write(fpga_build_num[4]);
  osd.write(fpga_build_num[5]);
  osd.write(fpga_build_num[6]);
  osd.write(fpga_build_num[7]);

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,8);
  osd.print(F("AVR build:"));
  osd.setPos(y,8);
  osd.print(avr_build_num);

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,9);
  osd.print(F("PCB revision:"));
  osd.setPos(y,9);
  switch (fpga_cfg) {
    case 0:
    case 1:
      osd.print(F("A/B/C/D"));
      break;
    case 4:
    case 5:
      osd.print(F("DS"));
      break;
    case 36:
    case 37:
      osd.print(F("E"));
      break;
  }

  // DAC Type
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,10); osd.print(F("DAC Type:"));
  osd.setPos(y,10); osd.print(F("TDA1543"));
  switch (fpga_cfg) {
    case 1:
    case 5:
    case 37:
      osd.print(F("A"));
      break;
  }

  // Uptime
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,11); osd.print(F("Uptime:"));

  updateUptime();
  
  popupFooter();

}

void ZXOSD::popupFooter() {

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  printLine(22);

  // footer
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,23); osd.print(F("Press "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F("ESC"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" to return"));
}

void ZXOSD::handleRombank() {
  uint8_t romset = zxkbd->getRombank();

  if (zxkbd->getIsCursorLeft()) {
    romset = romset-1;
    if (romset > 3) romset = 3;
    zxkbd->setRombank(romset);
    updateRombank();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    romset = romset+1;
    if (romset >3) romset = 0;
    zxkbd->setRombank(romset);
    updateRombank();
  }
}

void ZXOSD::handleTurbofdc() {
  if (zxkbd->getIsCursorLeft() || zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    zxkbd->toggleTurbofdc();
    updateTurbofdc();
  }
}

void ZXOSD::handleCovox() {
  if (zxkbd->getIsCursorLeft() || zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    zxkbd->toggleCovox();
    updateCovox();
  }
}

void ZXOSD::handleStereo() {

  uint8_t stereo = zxkbd->getStereo();

  if (zxkbd->getIsCursorLeft()) {
    stereo = stereo-1;
    if (stereo > 2) stereo = 2;
    zxkbd->toggleStereo(stereo);
    updateStereo();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    stereo = stereo+1;
    if (stereo >2) stereo = 0;
    zxkbd->toggleStereo(stereo);
    updateStereo();
  }
}

void ZXOSD::handleSsg() {
  if (zxkbd->getIsCursorLeft() || zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    zxkbd->toggleSsg();
    updateSsg();
  }
}

void ZXOSD::handleVideo() {
  if (zxkbd->getIsCursorLeft() || zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    zxkbd->toggleVideo();
    updateVideo();
  }
}

void ZXOSD::handleVsync() {
  if (zxkbd->getIsCursorLeft() || zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    zxkbd->toggleVsync();
    updateVsync();
  }
}

void ZXOSD::handleTurbo() {
  uint8_t turbo = zxkbd->getTurbo();
  uint8_t max_turbo = zxkbd->getMaxTurbo();

  if (zxkbd->getIsCursorLeft()) {
    turbo--;
    if (turbo > max_turbo) turbo = max_turbo;
    zxkbd->setTurbo(turbo);
    updateTurbo();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    turbo++;
    if (turbo > max_turbo) turbo = 0;
    zxkbd->setTurbo(turbo);
    updateTurbo();
  }
}

void ZXOSD::handleSwapAB() {
  if (zxkbd->getIsCursorLeft() || zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    zxkbd->toggleSwapAB();
    updateSwapAB();
  }
}

void ZXOSD::handleJoyType() {
  if (zxkbd->getIsCursorLeft() || zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    zxkbd->toggleJoyType();
    updateJoystick();
  }
}

void ZXOSD::handleKeyboardType() {
  if (zxkbd->getIsCursorLeft() || zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    zxkbd->toggleKeyboardType();
    updateKeyboardType();
  }
}

void ZXOSD::handlePause() {
  if (zxkbd->getIsCursorLeft() || zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    zxkbd->doPause();
    updatePause();
  }
}

void ZXOSD::handleRtcHour() {
  if (zxkbd->getIsCursorLeft()) {
    uint8_t rtc_hours = zxrtc->getHour()-1;
    if (rtc_hours > 23) rtc_hours = 0;
    zxrtc->setHour(rtc_hours);
    zxrtc->save();
    updateRtcHour();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    uint8_t rtc_hours = zxrtc->getHour()+1;
    if (rtc_hours >23) rtc_hours = 0;
    zxrtc->setHour(rtc_hours);
    zxrtc->save();
    updateRtcHour();
  }
}

void ZXOSD::handleRtcMinute() {
  if (zxkbd->getIsCursorLeft()) {
    uint8_t rtc_minutes = zxrtc->getMinute()-1;
    if (rtc_minutes > 59) rtc_minutes = 59;
    zxrtc->setMinute(rtc_minutes);
    zxrtc->save();
    updateRtcMinute();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    uint8_t rtc_minutes = zxrtc->getMinute()+1;
    if (rtc_minutes >59) rtc_minutes = 0;
    zxrtc->setMinute(rtc_minutes);
    zxrtc->save();
    updateRtcMinute();
  }
}

void ZXOSD::handleRtcSecond() {
  if (zxkbd->getIsCursorLeft()) {
    uint8_t rtc_seconds = zxrtc->getSecond()-1;
    if (rtc_seconds > 59) rtc_seconds = 59;
    zxrtc->setSecond(rtc_seconds);
    zxrtc->save();
    updateRtcSecond();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    uint8_t rtc_seconds = zxrtc->getSecond()+1;
    if (rtc_seconds >59) rtc_seconds = 0;
    zxrtc->setSecond(rtc_seconds);
    zxrtc->save();
    updateRtcSecond();
  }
}

void ZXOSD::handleRtcDay() {
  if (zxkbd->getIsCursorLeft()) {
    uint8_t rtc_day = zxrtc->getDay()-1;
    if (rtc_day < 1 || rtc_day > 31) rtc_day = 31;
    zxrtc->setDay(rtc_day);
    zxrtc->save();
    updateRtcDay();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    uint8_t rtc_day = zxrtc->getDay()+1;
    if (rtc_day > 31) rtc_day = 1;
    zxrtc->setDay(rtc_day);
    zxrtc->save();
    updateRtcDay();
  }
}

void ZXOSD::handleRtcMonth() {
  if (zxkbd->getIsCursorLeft()) {
    uint8_t rtc_month = zxrtc->getMonth()-1;
    if (rtc_month < 1 || rtc_month > 12) rtc_month = 12;
    zxrtc->setMonth(rtc_month);
    zxrtc->save();
    updateRtcMonth();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    uint8_t rtc_month = zxrtc->getMonth()+1;
    if (rtc_month > 12) rtc_month = 1;
    zxrtc->setMonth(rtc_month);
    zxrtc->save();
    updateRtcMonth();
  }
}

void ZXOSD::handleRtcYear() {
  if (zxkbd->getIsCursorLeft()) {
    int rtc_year = zxrtc->getYear()-1;
    if (rtc_year < 2000 || rtc_year > 4095) rtc_year = 2000;
    zxrtc->setYear(rtc_year);
    zxrtc->save();
    updateRtcYear();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    int rtc_year = zxrtc->getYear()+1;
    if (rtc_year < 2000 || rtc_year > 4096) rtc_year = 2000;
    zxrtc->setYear(rtc_year);
    zxrtc->save();
    updateRtcYear();
  }
}

void ZXOSD::handleRtcDow() {
  if (zxkbd->getIsCursorLeft()) {
    uint8_t rtc_week = zxrtc->getWeek()-1;
    if (rtc_week < 1 || rtc_week > 7) rtc_week = 7;
    zxrtc->setWeek(rtc_week);
    zxrtc->save();
    updateRtcDow();
  }
  if (zxkbd->getIsCursorRight() || zxkbd->getIsEnter()) {
    uint8_t rtc_week = zxrtc->getWeek()+1;
    if (rtc_week < 1 || rtc_week > 7) rtc_week = 1;
    zxrtc->setWeek(rtc_week);
    zxrtc->save();
    updateRtcDow();
  }
}

void ZXOSD::updateRombank()
{
  if (osd_state != state_main) return;

  uint8_t romset = zxkbd->getRombank();

  if (osd_main_state == state_main_rom_bank) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,5);
  switch (romset) {
    case 0: osd.print(F("Default")); break;
    case 1: osd.print(F("PQ-DOS")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 2: osd.print(F("Flasher")); break;
    case 3: osd.print(F("FDImage")); break;
  }
}

void ZXOSD::updateTurbofdc() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_turbofdc) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,6);
  if (zxkbd->getTurbofdc()) { 
    osd.print(F("On")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" "));
  } else { 
    osd.print(F("Off")); 
  }
}

void ZXOSD::updateCovox() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_covox) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,7);
  if (zxkbd->getCovox()) { 
    osd.print(F("On"));
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Off")); 
  }
}

void ZXOSD::updateStereo() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_stereo) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,8);
  uint8_t stereo = zxkbd->getStereo();
  switch (stereo) {
    case 1: osd.print(F("ABC")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 0: osd.print(F("ACB")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    default: osd.print(F("Mono")); 
  }
}

void ZXOSD::updateSsg() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_ssg) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,9);
  if (zxkbd->getSsg()) { osd.print(F("AY3-8912")); } else { osd.print(F("YM2149F")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); }
}

void ZXOSD::updateVideo() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_video) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,10);
  if (zxkbd->getVideo()) { osd.print(F("RGB 15kHz")); } else { osd.print(F("VGA 30kHz")); }
}

void ZXOSD::updateVsync() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_sync) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,11);
  if (zxkbd->getVsync()) { osd.print(F("60 Hz")); } else { osd.print(F("50 Hz")); }
}

void ZXOSD::updateTurbo() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_turbo) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,12);
  uint8_t turbo = zxkbd->getTurbo();
  switch (turbo) {
    case 0: osd.print(F("Off")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 1: osd.print(F("2x"));  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 2: osd.print(F("4x"));  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 3: osd.print(F("8x"));  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    default: osd.print(F("???")); 
  }
}

void ZXOSD::updateSwapAB() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_swap_ab) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,13);
  if (zxkbd->getSwapAB()) { 
    osd.print(F("On")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Off")); 
  }
}

void ZXOSD::updateJoystick() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_joy_type) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,14);
  if (zxkbd->getJoyType()) { 
    osd.print(F("SEGA")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Atari")); 
  }
}

void ZXOSD::updateKeyboardType() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_keyboard_type) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,15);
  if (zxkbd->getKeyboardType()) { osd.print(F("Profi XT")); } else { osd.print(F("Spectrum")); }
}

void ZXOSD::updatePause() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_pause) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,16);
  if (zxkbd->getPause()) { osd.print(F("On")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); } else { osd.print(F("Off")); }
}

void ZXOSD::updateRtcHour() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_hour) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,7);
  if (zxrtc->getHour() < 10) osd.print(F("0"));
  osd.print(zxrtc->getHour(), DEC);
}

void ZXOSD::updateRtcMinute() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_minute) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,8);
  if (zxrtc->getMinute() < 10) osd.print(F("0"));
  osd.print(zxrtc->getMinute(), DEC);
}

void ZXOSD::updateRtcSecond() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_second) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,9);
  if (zxrtc->getSecond() < 10) osd.print(F("0"));
  osd.print(zxrtc->getSecond(), DEC);
}

void ZXOSD::updateRtcDay() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_day) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,11);
  if (zxrtc->getDay() < 10) osd.print(F("0"));
  osd.print(zxrtc->getDay(), DEC);
}

void ZXOSD::updateRtcMonth() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_month) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,12);
  switch (zxrtc->getMonth()) {
    case 1:  osd.print(F("Jan")); break;
    case 2:  osd.print(F("Feb")); break;
    case 3:  osd.print(F("Mar")); break;
    case 4:  osd.print(F("Apr")); break;
    case 5:  osd.print(F("May")); break;
    case 6:  osd.print(F("Jun")); break;
    case 7:  osd.print(F("Jul")); break;
    case 8:  osd.print(F("Aug")); break;
    case 9:  osd.print(F("Sep")); break;
    case 10: osd.print(F("Oct")); break;
    case 11: osd.print(F("Nov")); break;
    case 12: osd.print(F("Dec")); break;
    default: osd.print(F("___")); 
  }
}

void ZXOSD::updateRtcYear() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_year) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,13);
  if (zxrtc->getYear() < 1000) osd.print(F("0"));
  if (zxrtc->getYear() < 100) osd.print(F("0"));
  if (zxrtc->getYear() < 10) osd.print(F("0"));
  osd.print(zxrtc->getYear(), DEC);
}

void ZXOSD::updateRtcDow() {
if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_dow) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,15);
  switch (zxrtc->getWeek()) {
    case 2: osd.print(F("Mon")); break;
    case 3: osd.print(F("Tue")); break;
    case 4: osd.print(F("Wed")); break;
    case 5: osd.print(F("Thu")); break;
    case 6: osd.print(F("Fri")); break;
    case 7: osd.print(F("Sat")); break;
    case 1: osd.print(F("Sun")); break;
    default: osd.print(F("___")); 
  }
}

void ZXOSD::updateTime() {
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(24,0);
  if (zxrtc->getHour() < 10) osd.print("0"); 
  osd.print(zxrtc->getHour(), DEC); osd.print(F(":"));
  if (zxrtc->getMinute() < 10) osd.print("0"); 
  osd.print(zxrtc->getMinute(), DEC); osd.print(F(":"));
  if (zxrtc->getSecond() < 10) osd.print("0"); 
  osd.print(zxrtc->getSecond(), DEC);
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(22,1);
  if (zxrtc->getDay() < 10) osd.print("0"); 
  osd.print(zxrtc->getDay(), DEC); osd.print(F("."));
  if (zxrtc->getMonth() < 10) osd.print("0"); 
  osd.print(zxrtc->getMonth(), DEC); osd.print(F("."));
  osd.print(zxrtc->getYear(), DEC);
  if (osd_state == state_rtc) {
    updateRtcHour();
    updateRtcMinute();
    updateRtcSecond();
    updateRtcDay();
    updateRtcMonth();
    updateRtcYear();
    updateRtcDow();
  }
  if (osd_state == state_info) {
    updateUptime();
  }
}

void ZXOSD::updateUptime() {
  unsigned long diff = (millis() - tstart) / 1000; // seconds
  unsigned long days=0;
  unsigned long hours=0;
  unsigned long mins=0;
  mins=diff/60; //convert seconds to minutes
  hours=mins/60; //convert minutes to hours
  days=hours/24; //convert hours to days
  diff=diff-(mins*60); //subtract the coverted seconds to minutes in order to display 59 secs max 
  mins=mins-(hours*60); //subtract the coverted minutes to hours in order to display 59 minutes max
  hours=hours-(days*24); //subtract the coverted hours to days in order to display 23 hours max

  osd.setPos(14,11); 
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  if (days>0) // days will displayed only if value is greater than zero
  {
    osd.print(days);
    osd.print(F(" day"));
    if (days > 1) {
      osd.print(F("s"));
    }
    osd.print(F(" & "));
  }
  if (hours < 10) osd.print(0);
  osd.print(hours);
  osd.print(":");
  if (mins < 10) osd.print(0);
  osd.print(mins);
  osd.print(":");
  if (diff < 10) osd.print(0);
  osd.print(diff);
}

void ZXOSD::updateScancode(uint16_t c) {

  if (osd_state != state_main) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(10,18);
  if ((c >> 8) < 0x10) osd.print(F("0")); 
  osd.print(c >> 8, HEX);
  osd.print(F(" "));
  if ((c & 0xFF) < 0x10) osd.print(F("0")); 
  osd.print(c & 0xFF, HEX);
}

void ZXOSD::updateMouse(uint8_t mouse_x, uint8_t mouse_y, uint8_t mouse_z) {

  if (osd_state != state_main) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(10,19);
  if (mouse_x < 0x10) osd.print(F("0")); 
  osd.print(mouse_x, HEX);
  osd.print(F(" "));
  if (mouse_y < 0x10) osd.print(F("0")); 
  osd.print(mouse_y, HEX);
  osd.print(F(" "));
  if (mouse_z < 0x10) osd.print(F("0")); 
  osd.print(mouse_z, HEX);  
}

void ZXOSD::updateJoyState(uint8_t joy) {

  if (osd_state != state_main) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(10,20);
  if (joy < 0x10) osd.print(F("0")); 
  osd.print(joy, HEX);  
}

/****************************************************************************/

// vim:cin:ai:sts=2 sw=2 ft=cpp
