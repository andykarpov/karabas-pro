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

void ZXOSD::begin(spi_cb act) // todo: zxmouse, zxjoy
{
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
  if (zxkbd.getIsOsdOverlay()) {
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
            case state_main_joy_type: updateSwapAB(); updateJoystick(); updateJoystickMode(); break;
            case state_main_joy_mode: updateJoystick(); updateJoystickMode(); updateScreenMode(); break;
            case state_main_screen_mode: updateJoystickMode(); updateScreenMode(); updateDivmmc(); break;
            case state_main_divmmc: updateScreenMode(); updateDivmmc(); updateNemoIDE(); break;
            case state_main_nemoide: updateDivmmc(); updateNemoIDE(); updateKeyboardType(); break;
            case state_main_keyboard_type: updateNemoIDE(); updateKeyboardType(); updatePause(); break;
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
  if (zxkbd.getIsOsdOverlay()) {
    switch (osd_state) {
      case state_main:

        if (zxkbd.getIsCursorDown()) {
          osd_main_state++;
          if (osd_main_state > state_main_pause) osd_main_state = state_main_rom_bank;
        }

        if (zxkbd.getIsCursorUp()) {
          osd_main_state--;
          if (osd_main_state > state_main_pause) osd_main_state = state_main_pause;
        }

        if (zxkbd.getKey(ZX_K_S)) {
          osd_state = state_rtc;
        }

        if (zxkbd.getKey(ZX_K_A)) {
          osd_state = state_about;
        }

        if (zxkbd.getKey(ZX_K_I)) {
          osd_state = state_info;
        }

        /*if (zxkbd.getIsEscape()) {
          zxkbd.toggleOsdOverlay();
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
          case state_main_joy_mode: handleJoyMode(); break;
          case state_main_screen_mode: handleScreenMode(); break;
          case state_main_divmmc: handleDivmmc(); break;
          case state_main_nemoide: handleNemoIDE(); break;
          case state_main_keyboard_type: handleKeyboardType(); break;
          case state_main_pause: handlePause(); break;
        }
      break;
      case state_rtc:

        if (zxkbd.getIsCursorDown()) {
          osd_rtc_state++;
          if (osd_rtc_state > state_rtc_dow) osd_rtc_state = state_rtc_hour;
        }

        if (zxkbd.getIsCursorUp()) {
          osd_rtc_state--;
          if (osd_rtc_state > state_rtc_dow) osd_rtc_state = state_rtc_dow;
        }

        if (zxkbd.getIsEscape()) {
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

      case state_about:
      case state_info:

        if (zxkbd.getIsEscape()) {
          osd_state = state_main;
        }

      break;
    }
  }

  // empty keyboard matrix in overlay mode before transmitting it onto FPGA side
  if (zxkbd.getIsOsdOverlay()) {
    zxkbd.clear(ZX_MATRIX_SIZE);
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
  osd.write(0xb0); osd.write(0xb1); // k
  osd.write(0xb2); osd.write(0xb3); // a
  osd.write(0xb4); osd.write(0xb5); // r
  osd.write(0xb2); osd.write(0xb3); // a
  osd.write(0xb6); osd.write(0xb7); // b
  osd.write(0xb2); osd.write(0xb3); // a
  osd.write(0xb8); osd.write(0xb9); // s

  osd.setPos(x,y+1);
  osd.write(0xc0); osd.write(0xc1); // k
  osd.write(0xc2); osd.write(0xc3); // a
  osd.write(0xc4); osd.write(0xc5); // r
  osd.write(0xc2); osd.write(0xc3); // a
  osd.write(0xc6); osd.write(0xc7); // b
  osd.write(0xc2); osd.write(0xc3); // a
  osd.write(0xc8); osd.write(0xc9); // s

  osd.setPos(x+8, y+2);
  osd.write(0xba); osd.write(0xbb); // p
  osd.write(0xb4); osd.write(0xb5); // r
  osd.write(0xbc); osd.write(0xbd); // o

  osd.setPos(x+8, y+3);
  osd.write(0xca); osd.write(0xcb); // p
  osd.write(0xc4); osd.write(0xc5); // r
  osd.write(0xcc); osd.write(0xcd); // o

  osd.setPos(x+1, y+2);
  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.write(0x16); // -
  osd.setColor(OSD::COLOR_YELLOW_I, OSD::COLOR_BLACK);
  osd.write(0x16); // -
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.write(0x16); // -
  osd.setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK);
  osd.write(0x16); // -

  osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  osd.setPos(x,y+3);
  // board revision
  osd.print(PGMT(msg_rev));
  printRev();
}

void ZXOSD::printRev()
{
  uint8_t fpga_rev = ((fpga_cfg & 0b00111100) >> 2);
  switch (fpga_rev) {
    case 0x0:
      osd.print(PGMT(msg_rev_a));
      break;
    case 0x1:
      osd.print(PGMT(msg_rev_ds));
      break;
    case 0x9:
      osd.print(PGMT(msg_rev_e));
      break;
    case 0xD:
      osd.print(PGMT(msg_rev_eu));
      break;
  }
}

void ZXOSD::printLine(uint8_t y)
{
  osd.setPos(0,y);
  for (uint8_t i=0; i<32; i++) {
    osd.write(0x5f);
  }
}

void ZXOSD::printSpace() {
  uint8_t i = 0;
  for (i=0; i<8; i++) {
    osd.print(PGMT(msg_space));
  }
}


void ZXOSD::printHeader()
{
  printLogo(0,0);

  osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  osd.setPos(19,2);
  osd.print(PGMT(msg_fpga));
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
  osd.print(PGMT(msg_avr));
  osd.print(avr_build_num);

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  printLine(4);

  updateTime();
}

// init osd
void ZXOSD::initOverlay()
{
  osd_state = state_main;

  // disable popup in overlay mode
  zxkbd.setOsdPopup(false);

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  // ROM Bank
  osd.setPos(0,5); param(PGMT(msg_rom_bank));
  updateRombank();
  osd.setPos(20,5); hint(PGMT(msg_menu_f1_f4));

  // Turbo FDC
  osd.setPos(0,6); param(PGMT(msg_turbofdc));
  updateTurbofdc();
  osd.setPos(20,6); hint(PGMT(msg_menu_f5));

  // Covox
  osd.setPos(0,7); param(PGMT(msg_covox));
  updateCovox();
  osd.setPos(20,7); hint(PGMT(msg_menu_f6));

  // Stereo
  osd.setPos(0,8); param(PGMT(msg_psg_mix));
  updateStereo();
  osd.setPos(20,8); hint(PGMT(msg_menu_f7));

  // SSG type
  osd.setPos(0,9); param(PGMT(msg_psg_type));
  updateSsg();
  osd.setPos(20,9); hint(PGMT(msg_menu_f8));

  // RGB/VGA
  osd.setPos(0,10); param(PGMT(msg_video));
  updateVideo();
  osd.setPos(20,10); hint(PGMT(msg_menu_f9));

  // VSync
  osd.setPos(0,11); param(PGMT(msg_vsync));
  updateVsync();
  osd.setPos(20,11); hint(PGMT(msg_menu_f10));

  // Turbo
  osd.setPos(0,12); param(PGMT(msg_turbo));
  updateTurbo();
  osd.setPos(20,12); hint(PGMT(msg_menu_f11));

  // FDC Swap
  osd.setPos(0,13); param(PGMT(msg_swap_fdd));
  updateSwapAB();
  osd.setPos(20,13); hint(PGMT(msg_menu_tab));

  // Joy type
  osd.setPos(0,14); param(PGMT(msg_joy_type));
  updateJoystick();
  osd.setPos(20,14); hint(PGMT(msg_menu_j));

  // Joy mode
  osd.setPos(0,15); param(PGMT(msg_joy_mode));
  updateJoystickMode();
  osd.setPos(20,15); hint(PGMT(msg_menu_m));

  // Screen Mode
  osd.setPos(0,16); param(PGMT(msg_screen));
  updateScreenMode();
  osd.setPos(20,16); hint(PGMT(msg_menu_v));

  // DivMMC
  osd.setPos(0, 17); param(PGMT(msg_divmmc));
  updateDivmmc();
  osd.setPos(20,17); hint(PGMT(msg_menu_d));

  // NemoIDE
  osd.setPos(0, 18); param(PGMT(msg_nemoide));
  updateNemoIDE();
  osd.setPos(20,18); hint(PGMT(msg_menu_n));

  // Keyboard
  osd.setPos(0,19); param(PGMT(msg_keyboard));
  updateKeyboardType();
  osd.setPos(20,19); hint(PGMT(msg_prtscr));

  // Pause
  osd.setPos(0,20); param(PGMT(msg_pause));
  updatePause();
  osd.setPos(20,20); hint(PGMT(msg_pause));

  //printLine(21);

  // Setup RTC / Info / About
  osd.setPos(0,22); flash(PGMT(msg_s)); text(PGMT(msg_etup_rtc)); text(PGMT(msg_space));
                    flash(PGMT(msg_i)); text(PGMT(msg_nfo)); flash(PGMT(msg_a)); text(PGMT(msg_bout));

  printLine(23);

  // footer
  osd.setPos(0,24); text(PGMT(msg_press)); hint(PGMT(msg_ctrl_alt_del)); text(PGMT(msg_to_reboot));
  osd.setPos(0,25); text(PGMT(msg_press)); hint(PGMT(msg_menu_esc)); text(PGMT(msg_to_toggle_osd));
}

void ZXOSD::clear()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();
}

void ZXOSD::initPopup(uint8_t event_type)
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();  
  bool is_boot = (event_type == ZXKeyboard::EVENT_OSD_POPUP);
  printLogo(0,is_boot ? 5 : 0);

  // print only logo on boot screen
  if (is_boot) return;

  // line1
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,5);
  switch(event_type) {
    case ZXKeyboard::EVENT_OSD_ROMBANK:       osd.print(PGMT(msg_rom_bank)); break;
    case ZXKeyboard::EVENT_OSD_TURBOFDC:      osd.print(PGMT(msg_turbofdc)); break;
    case ZXKeyboard::EVENT_OSD_COVOX:         osd.print(PGMT(msg_covox)); break;
    case ZXKeyboard::EVENT_OSD_STEREO:        osd.print(PGMT(msg_psg_mix)); break;
    case ZXKeyboard::EVENT_OSD_SSG:           osd.print(PGMT(msg_psg_type)); break;
    case ZXKeyboard::EVENT_OSD_VIDEO:         osd.print(PGMT(msg_video)); break;
    case ZXKeyboard::EVENT_OSD_VSYNC:         osd.print(PGMT(msg_vsync)); break;
    case ZXKeyboard::EVENT_OSD_TURBO:         osd.print(PGMT(msg_turbo)); break;
    case ZXKeyboard::EVENT_OSD_SWAP_AB:       osd.print(PGMT(msg_swap_fdd)); break;
    case ZXKeyboard::EVENT_OSD_JOYSTICK:      osd.print(PGMT(msg_joy_type)); break; 
    case ZXKeyboard::EVENT_OSD_JOYSTICK_MODE: osd.print(PGMT(msg_joy_mode)); break;
    case ZXKeyboard::EVENT_OSD_SCREEN_MODE:   osd.print(PGMT(msg_screen)); break; 
    case ZXKeyboard::EVENT_OSD_DIVMMC:        osd.print(PGMT(msg_divmmc)); break; 
    case ZXKeyboard::EVENT_OSD_NEMOIDE:       osd.print(PGMT(msg_nemoide)); break; 
    case ZXKeyboard::EVENT_OSD_KEYBOARD_TYPE: osd.print(PGMT(msg_keyboard)); break;
    case ZXKeyboard::EVENT_OSD_PAUSE:         osd.print(PGMT(msg_pause)); break; 
  }
  printSpace();

  // line2
  osd.setPos(0,6);
  switch(event_type) {
    case ZXKeyboard::EVENT_OSD_ROMBANK: updateRombank(); break;
    case ZXKeyboard::EVENT_OSD_TURBOFDC:updateTurbofdc(); break;
    case ZXKeyboard::EVENT_OSD_COVOX: updateCovox(); break;
    case ZXKeyboard::EVENT_OSD_STEREO: updateStereo(); break;
    case ZXKeyboard::EVENT_OSD_SSG: updateSsg(); break;
    case ZXKeyboard::EVENT_OSD_VIDEO: updateVideo(); break;
    case ZXKeyboard::EVENT_OSD_VSYNC: updateVsync(); break;
    case ZXKeyboard::EVENT_OSD_TURBO: updateTurbo(); break;
    case ZXKeyboard::EVENT_OSD_SWAP_AB: updateSwapAB(); break;
    case ZXKeyboard::EVENT_OSD_JOYSTICK: updateJoystick(); break;
    case ZXKeyboard::EVENT_OSD_JOYSTICK_MODE: updateJoystickMode(); break; 
    case ZXKeyboard::EVENT_OSD_SCREEN_MODE: updateScreenMode(); break; 
    case ZXKeyboard::EVENT_OSD_DIVMMC: updateDivmmc(); break; 
    case ZXKeyboard::EVENT_OSD_NEMOIDE: updateNemoIDE(); break; 
    case ZXKeyboard::EVENT_OSD_KEYBOARD_TYPE: updateKeyboardType(); break;
    case ZXKeyboard::EVENT_OSD_PAUSE: updatePause(); break; 
  }
  printSpace();
}

// init rtc osd
void ZXOSD::initRtcOverlay()
{
  zxrtc.fixInvalidTime(); // try to fix invalid time

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0,5);
  text(PGMT(msg_rtc_setup));

  osd.setPos(0,7); param(PGMT(msg_hours));
  updateRtcHour();

  osd.setPos(0,8); param(PGMT(msg_minutes));
  updateRtcMinute();

  osd.setPos(0,9); param(PGMT(msg_seconds));
  updateRtcSecond();

  osd.setPos(0,11); param(PGMT(msg_day));
  updateRtcDay();

  osd.setPos(0,12); param(PGMT(msg_month));
  updateRtcMonth();

  osd.setPos(0,13); param(PGMT(msg_year));
  updateRtcYear();

  osd.setPos(0,15); param(PGMT(msg_dow));
  updateRtcDow();

  osd.setPos(0, 17);
  text(PGMT(msg_please_use_arrows));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); osd.write(17);
  text(PGMT(msg_and));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); osd.write(16);
  osd.setPos(0, 18);
  text(PGMT(msg_to_change_values));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); osd.write(30);
  text(PGMT(msg_and));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK); osd.write(31);
  osd.setPos(0, 19);
  text(PGMT(msg_to_navigate));

  popupFooter();
}

// init about osd
void ZXOSD::initAboutOverlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0,5);
  text(PGMT(msg_about));

  osd.setPos(0,7);
  osd.setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK);
  osd.print(PGMT(msg_karabas_developers_are));

  osd.setPos(0,9);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(PGMT(msg_dev_andykarpov));
  hint(PGMT(msg_dev_andykarpov_skills));

  osd.setPos(0,10);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(PGMT(msg_dev_solegstar));
  hint(PGMT(msg_dev_solegstar_skills));

  osd.setPos(0,11);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(PGMT(msg_dev_drmax));
  hint(PGMT(msg_dev_drmax_skills));

  osd.setPos(0,12);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(PGMT(msg_dev_nihirash));
  hint(PGMT(msg_dev_nihirash_skills));

  osd.setPos(0,14);
  osd.setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK);
  osd.print(PGMT(msg_special_thanks_to));

  osd.setPos(0,16);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.write(250);
  osd.print(PGMT(msg_dev_kalantaj));

  osd.setPos(0,17);
  osd.write(250);
  osd.print(PGMT(msg_dev_tankuk));

  osd.setPos(0,18);
  osd.write(250);
  osd.print(PGMT(msg_dev_xdemox));

  osd.setPos(0,19);
  osd.write(250);
  osd.print(PGMT(msg_dev_dumpkin));

  osd.setPos(0,20);
  osd.write(250);
  osd.print(PGMT(msg_dev_kasper));

  osd.setPos(18,21);
  osd.setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  osd.print(PGMT(msg_www_karabas_uk));

  popupFooter();

}

// init info osd
void ZXOSD::initInfoOverlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  printHeader();

  osd.setPos(0,5);
  text(PGMT(msg_system_info));

  // todo

  uint8_t y=14;

  osd.setPos(0,7);
  text(PGMT(msg_fpga_build));
  osd.setPos(y,7);
  osd.write(fpga_build_num[0]);
  osd.write(fpga_build_num[1]);
  osd.write(fpga_build_num[2]);
  osd.write(fpga_build_num[3]);
  osd.write(fpga_build_num[4]);
  osd.write(fpga_build_num[5]);
  osd.write(fpga_build_num[6]);
  osd.write(fpga_build_num[7]);

  osd.setPos(0,8);
  text(PGMT(msg_avr_build));
  osd.setPos(y,8);
  osd.print(avr_build_num);

  osd.setPos(0,9);
  text(PGMT(msg_pcb_revision));
  osd.setPos(y,9);
  printRev();

  // DAC Type
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,10); osd.print(PGMT(msg_dac_type));
  osd.setPos(y,10); osd.print(PGMT(msg_tda1543));
  uint8_t dac_type = bitRead(fpga_cfg, 0);
  if (dac_type == 1) {
      osd.print(PGMT(msg_a));
  }

  // Uptime
  osd.setPos(0,11); text(PGMT(msg_uptime));
  updateUptime();

  osd.setPos(0,13);
  text(PGMT(msg_debug_info));


    // Scancode
  osd.setPos(0,15); text(PGMT(msg_scancode));
  updateScancode(0);

  // Mouse
  osd.setPos(0,16); text(PGMT(msg_mouse));
  updateMouse(0,0,0);

  // Joy
  osd.setPos(0,17); text(PGMT(msg_port_1f));
  updateJoyState(0);

  
  popupFooter();

}

void ZXOSD::popupFooter() {

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  printLine(22);

  // footer
  osd.setPos(0,23); 
  text(PGMT(msg_press));  
  hint(PGMT(msg_esc));
  text(PGMT(msg_to_return));
}

void ZXOSD::handleRombank() {
  uint8_t romset = zxkbd.getRombank();

  if (zxkbd.getIsCursorLeft()) {
    romset = romset-1;
    if (romset > 3) romset = 3;
    zxkbd.setRombank(romset);
    updateRombank();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    romset = romset+1;
    if (romset >3) romset = 0;
    zxkbd.setRombank(romset);
    updateRombank();
  }
}

void ZXOSD::handleTurbofdc() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleTurbofdc();
    updateTurbofdc();
  }
}

void ZXOSD::handleCovox() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleCovox();
    updateCovox();
  }
}

void ZXOSD::handleStereo() {

  uint8_t stereo = zxkbd.getStereo();

  if (zxkbd.getIsCursorLeft()) {
    stereo = stereo-1;
    if (stereo > 2) stereo = 2;
    zxkbd.toggleStereo(stereo);
    updateStereo();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    stereo = stereo+1;
    if (stereo >2) stereo = 0;
    zxkbd.toggleStereo(stereo);
    updateStereo();
  }
}

void ZXOSD::handleSsg() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleSsg();
    updateSsg();
  }
}

void ZXOSD::handleVideo() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleVideo();
    updateVideo();
  }
}

void ZXOSD::handleVsync() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleVsync();
    updateVsync();
  }
}

void ZXOSD::handleTurbo() {
  uint8_t turbo = zxkbd.getTurbo();
  uint8_t max_turbo = zxkbd.getMaxTurbo();

  if (zxkbd.getIsCursorLeft()) {
    turbo--;
    if (turbo > max_turbo) turbo = max_turbo;
    zxkbd.setTurbo(turbo);
    updateTurbo();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    turbo++;
    if (turbo > max_turbo) turbo = 0;
    zxkbd.setTurbo(turbo);
    updateTurbo();
  }
}

void ZXOSD::handleSwapAB() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleSwapAB();
    updateSwapAB();
  }
}

void ZXOSD::handleJoyType() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleJoyType();
    updateJoystick();
  }
}

void ZXOSD::handleJoyMode() {
  uint8_t joymode = zxkbd.getJoyMode();

  if (zxkbd.getIsCursorLeft()) {
    joymode = joymode-1;
    if (joymode > 4) joymode = 4;
    zxkbd.setJoyMode(joymode);
    updateJoystickMode();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    joymode = joymode+1;
    if (joymode > 4) joymode = 0;
    zxkbd.setJoyMode(joymode);
    updateJoystickMode();
  }

}

void ZXOSD::handleScreenMode() {
  uint8_t screen_mode = zxkbd.getScreenMode();

  if (zxkbd.getIsCursorLeft()) {
    screen_mode--;
    if (screen_mode > zxkbd.getMaxScreenMode()) screen_mode = zxkbd.getMaxScreenMode();
    zxkbd.setScreenMode(screen_mode);
    updateScreenMode();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    screen_mode++;
    if (screen_mode > zxkbd.getMaxScreenMode()) screen_mode = 0;
    zxkbd.setScreenMode(screen_mode);
    updateScreenMode();
  }
}

void ZXOSD::handleDivmmc() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleDivmmc();
    updateDivmmc();
  }
}

void ZXOSD::handleNemoIDE() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleNemoIDE();
    updateNemoIDE();
  }
}

void ZXOSD::handleKeyboardType() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleKeyboardType();
    updateKeyboardType();
  }
}

void ZXOSD::handlePause() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.doPause();
    updatePause();
  }
}

void ZXOSD::handleRtcHour() {
  if (zxkbd.getIsCursorLeft()) {
    uint8_t rtc_hours = zxrtc.getHour()-1;
    if (rtc_hours > 23) rtc_hours = 0;
    zxrtc.setHour(rtc_hours);
    zxrtc.save();
    updateRtcHour();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    uint8_t rtc_hours = zxrtc.getHour()+1;
    if (rtc_hours >23) rtc_hours = 0;
    zxrtc.setHour(rtc_hours);
    zxrtc.save();
    updateRtcHour();
  }
}

void ZXOSD::handleRtcMinute() {
  if (zxkbd.getIsCursorLeft()) {
    uint8_t rtc_minutes = zxrtc.getMinute()-1;
    if (rtc_minutes > 59) rtc_minutes = 59;
    zxrtc.setMinute(rtc_minutes);
    zxrtc.save();
    updateRtcMinute();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    uint8_t rtc_minutes = zxrtc.getMinute()+1;
    if (rtc_minutes >59) rtc_minutes = 0;
    zxrtc.setMinute(rtc_minutes);
    zxrtc.save();
    updateRtcMinute();
  }
}

void ZXOSD::handleRtcSecond() {
  if (zxkbd.getIsCursorLeft()) {
    uint8_t rtc_seconds = zxrtc.getSecond()-1;
    if (rtc_seconds > 59) rtc_seconds = 59;
    zxrtc.setSecond(rtc_seconds);
    zxrtc.save();
    updateRtcSecond();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    uint8_t rtc_seconds = zxrtc.getSecond()+1;
    if (rtc_seconds >59) rtc_seconds = 0;
    zxrtc.setSecond(rtc_seconds);
    zxrtc.save();
    updateRtcSecond();
  }
}

void ZXOSD::handleRtcDay() {
  if (zxkbd.getIsCursorLeft()) {
    uint8_t rtc_day = zxrtc.getDay()-1;
    if (rtc_day < 1 || rtc_day > 31) rtc_day = 31;
    zxrtc.setDay(rtc_day);
    zxrtc.save();
    updateRtcDay();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    uint8_t rtc_day = zxrtc.getDay()+1;
    if (rtc_day > 31) rtc_day = 1;
    zxrtc.setDay(rtc_day);
    zxrtc.save();
    updateRtcDay();
  }
}

void ZXOSD::handleRtcMonth() {
  if (zxkbd.getIsCursorLeft()) {
    uint8_t rtc_month = zxrtc.getMonth()-1;
    if (rtc_month < 1 || rtc_month > 12) rtc_month = 12;
    zxrtc.setMonth(rtc_month);
    zxrtc.save();
    updateRtcMonth();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    uint8_t rtc_month = zxrtc.getMonth()+1;
    if (rtc_month > 12) rtc_month = 1;
    zxrtc.setMonth(rtc_month);
    zxrtc.save();
    updateRtcMonth();
  }
}

void ZXOSD::handleRtcYear() {
  if (zxkbd.getIsCursorLeft()) {
    int rtc_year = zxrtc.getYear()-1;
    if (rtc_year < 2000 || rtc_year > 4095) rtc_year = 2000;
    zxrtc.setYear(rtc_year);
    zxrtc.save();
    updateRtcYear();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    int rtc_year = zxrtc.getYear()+1;
    if (rtc_year < 2000 || rtc_year > 4096) rtc_year = 2000;
    zxrtc.setYear(rtc_year);
    zxrtc.save();
    updateRtcYear();
  }
}

void ZXOSD::handleRtcDow() {
  if (zxkbd.getIsCursorLeft()) {
    uint8_t rtc_week = zxrtc.getWeek()-1;
    if (rtc_week < 1 || rtc_week > 7) rtc_week = 7;
    zxrtc.setWeek(rtc_week);
    zxrtc.save();
    updateRtcDow();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    uint8_t rtc_week = zxrtc.getWeek()+1;
    if (rtc_week < 1 || rtc_week > 7) rtc_week = 1;
    zxrtc.setWeek(rtc_week);
    zxrtc.save();
    updateRtcDow();
  }
}

void ZXOSD::updateRombank()
{
  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_rom_bank);
    osd.setPos(10,5);
  }
  
  uint8_t romset = zxkbd.getRombank();
  switch (romset) {
    case 0: osd.print(PGMT(msg_default)); break;
    case 1: osd.print(PGMT(msg_pqdos)); break;
    case 2: osd.print(PGMT(msg_flasher)); break;
    case 3: osd.print(PGMT(msg_fdimage)); break;
  }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space));
}

void ZXOSD::updateTurbofdc() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_turbofdc);
    osd.setPos(10,6);
  }
  if (zxkbd.getTurbofdc()) { 
    osd.print(PGMT(msg_on)); 
  } else { 
    osd.print(PGMT(msg_off)); 
  }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space));
}

void ZXOSD::updateCovox() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_covox);
    osd.setPos(10,7);
  }

  if (zxkbd.getCovox()) { 
    osd.print(PGMT(msg_on));
  } else { 
    osd.print(PGMT(msg_off)); 
  }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space));
}

void ZXOSD::updateStereo() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_stereo);
    osd.setPos(10,8);
  }
  uint8_t stereo = zxkbd.getStereo();
  switch (stereo) {
    case 1: osd.print(PGMT(msg_abc)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space)); break;
    case 0: osd.print(PGMT(msg_acb)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space)); break;
    default: osd.print(PGMT(msg_mono)); 
  }
}

void ZXOSD::updateSsg() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_ssg);
    osd.setPos(10,9);
  }
  if (zxkbd.getSsg()) { osd.print(PGMT(msg_ay)); } else { osd.print(PGMT(msg_ym)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space)); }
}

void ZXOSD::updateVideo() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_video);
    osd.setPos(10,10);
  }
  if (zxkbd.getVideo()) { osd.print(PGMT(msg_rgb)); } else { osd.print(PGMT(msg_vga)); }
}

void ZXOSD::updateVsync() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_sync);
    osd.setPos(10,11);
  }
  if (zxkbd.getVsync()) { osd.print(PGMT(msg_60hz)); } else { osd.print(PGMT(msg_50hz)); }
}

void ZXOSD::updateTurbo() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_turbo);
    osd.setPos(10,12);
  }
  uint8_t turbo = zxkbd.getTurbo();
  switch (turbo) {
    case 0: osd.print(PGMT(msg_off)); break;
    case 1: osd.print(PGMT(msg_2x));  break;
    case 2: osd.print(PGMT(msg_4x));  break;
    case 3: osd.print(PGMT(msg_8x));  break;
    default: osd.print(PGMT(msg_unknown)); 
  }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space));osd.print(PGMT(msg_space));
}

void ZXOSD::updateSwapAB() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_swap_ab);
    osd.setPos(10,13);
  }
  if (zxkbd.getSwapAB()) { 
    osd.print(PGMT(msg_on)); 
  } else { 
    osd.print(PGMT(msg_off)); 
  }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space));
}

void ZXOSD::updateJoystick() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_joy_type);
    osd.setPos(10,14);
  }

  if (zxkbd.getJoyType()) { 
    osd.print(PGMT(msg_sega)); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space)); 
  } else { 
    osd.print(PGMT(msg_atari)); 
  }
}

void ZXOSD::updateJoystickMode() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_joy_mode);
    osd.setPos(10,15);
  }

  switch (zxkbd.getJoyMode()) { 
    case 0: osd.print(PGMT(msg_joy_kempston)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space)); break;
    case 1: osd.print(PGMT(msg_joy_sinclair1)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); break;
    case 2: osd.print(PGMT(msg_joy_sinclair2)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); break;
    case 3: osd.print(PGMT(msg_joy_cursor)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);  osd.print(PGMT(msg_space));  osd.print(PGMT(msg_space)); osd.print(PGMT(msg_space)); break;
    case 4: osd.print(PGMT(msg_joy_qaop)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);  break;
  }
}

void ZXOSD::updateScreenMode() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_screen_mode);
    osd.setPos(10,16);
  }

  switch (zxkbd.getScreenMode()) { 
    case 0: osd.print(PGMT(msg_pentagon)); break;
    case 1: osd.print(PGMT(msg_classic)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space)); break;
    case 2: osd.print(PGMT(msg_128)); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space)); osd.print(PGMT(msg_space)); osd.print(PGMT(msg_space)); osd.print(PGMT(msg_space)); osd.print(PGMT(msg_space)); break;
  }
}

void ZXOSD::updateDivmmc() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_divmmc);
    osd.setPos(10,17);
  }
  if (zxkbd.getDivmmc()) { 
    osd.print(PGMT(msg_on)); 
  } else { 
    osd.print(PGMT(msg_off)); 
  }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space));
}

void ZXOSD::updateNemoIDE() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_nemoide);
    osd.setPos(10,18);
  }
  if (zxkbd.getNemoIDE()) { 
    osd.print(PGMT(msg_on)); 
  } else { 
    osd.print(PGMT(msg_off)); 
  }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space));
}

void ZXOSD::updateKeyboardType() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_keyboard_type);
    osd.setPos(10,19);
  }
  if (zxkbd.getKeyboardType()) { osd.print(PGMT(msg_profi_xt)); } else { osd.print(PGMT(msg_spectrum)); }
}

void ZXOSD::updatePause() {

  if (!zxkbd.getIsOsdPopup()) {
    if (osd_state != state_main) return;
    highlight(osd_main_state == state_main_pause);
    osd.setPos(10,20);
  }

  if (zxkbd.getPause()) { osd.print(PGMT(msg_on)); } else { osd.print(PGMT(msg_off)); }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(PGMT(msg_space));
}

void ZXOSD::updateRtcHour() {
  if (osd_state != state_rtc) return;
  highlight(osd_rtc_state == state_rtc_hour);
  osd.setPos(10,7);
  if (zxrtc.getHour() < 10) osd.print(PGMT(msg_0));
  osd.print(zxrtc.getHour(), DEC);
}

void ZXOSD::updateRtcMinute() {
  if (osd_state != state_rtc) return;
  highlight(osd_rtc_state == state_rtc_minute);
  osd.setPos(10,8);
  if (zxrtc.getMinute() < 10) osd.print(PGMT(msg_0));
  osd.print(zxrtc.getMinute(), DEC);
}

void ZXOSD::updateRtcSecond() {
  if (osd_state != state_rtc) return;
  highlight(osd_rtc_state == state_rtc_second);
  osd.setPos(10,9);
  if (zxrtc.getSecond() < 10) osd.print(PGMT(msg_0));
  osd.print(zxrtc.getSecond(), DEC);
}

void ZXOSD::updateRtcDay() {
  if (osd_state != state_rtc) return;
  highlight(osd_rtc_state == state_rtc_day);
  osd.setPos(10,11);
  if (zxrtc.getDay() < 10) osd.print(PGMT(msg_0));
  osd.print(zxrtc.getDay(), DEC);
}

void ZXOSD::updateRtcMonth() {
  if (osd_state != state_rtc) return;
  highlight(osd_rtc_state == state_rtc_month);
  osd.setPos(10,12);
  switch (zxrtc.getMonth()) {
    case 1:  osd.print(PGMT(msg_month_jan)); break;
    case 2:  osd.print(PGMT(msg_month_feb)); break;
    case 3:  osd.print(PGMT(msg_month_mar)); break;
    case 4:  osd.print(PGMT(msg_month_apr)); break;
    case 5:  osd.print(PGMT(msg_month_may)); break;
    case 6:  osd.print(PGMT(msg_month_jun)); break;
    case 7:  osd.print(PGMT(msg_month_jul)); break;
    case 8:  osd.print(PGMT(msg_month_aug)); break;
    case 9:  osd.print(PGMT(msg_month_sep)); break;
    case 10: osd.print(PGMT(msg_month_oct)); break;
    case 11: osd.print(PGMT(msg_month_nov)); break;
    case 12: osd.print(PGMT(msg_month_dec)); break;
    default: osd.print(PGMT(msg_unknown)); 
  }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); printSpace();
}

void ZXOSD::updateRtcYear() {
  if (osd_state != state_rtc) return;
  highlight(osd_rtc_state == state_rtc_year);
  osd.setPos(10,13);
  if (zxrtc.getYear() < 1000) osd.print(PGMT(msg_0));
  if (zxrtc.getYear() < 100) osd.print(PGMT(msg_0));
  if (zxrtc.getYear() < 10) osd.print(PGMT(msg_0));
  osd.print(zxrtc.getYear(), DEC);
}

void ZXOSD::updateRtcDow() {
  if (osd_state != state_rtc) return;
  highlight(osd_rtc_state == state_rtc_dow);
  osd.setPos(10,15);
  switch (zxrtc.getWeek()) {
    case 2: osd.print(PGMT(msg_dow_mon)); break;
    case 3: osd.print(PGMT(msg_dow_tue)); break;
    case 4: osd.print(PGMT(msg_dow_wed)); break;
    case 5: osd.print(PGMT(msg_dow_thu)); break;
    case 6: osd.print(PGMT(msg_dow_fri)); break;
    case 7: osd.print(PGMT(msg_dow_sat)); break;
    case 1: osd.print(PGMT(msg_dow_sun)); break;
    default: osd.print(PGMT(msg_unknown)); 
  }
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); printSpace();
}

void ZXOSD::updateTime() {
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(24,0);
  if (zxrtc.getTimeIsValid()) {
    if (zxrtc.getHour() < 10) osd.print(PGMT(msg_0)); 
    osd.print(zxrtc.getHour(), DEC); osd.print(PGMT(msg_colon));
    if (zxrtc.getMinute() < 10) osd.print(PGMT(msg_0)); 
    osd.print(zxrtc.getMinute(), DEC); osd.print(PGMT(msg_colon));
    if (zxrtc.getSecond() < 10) osd.print(PGMT(msg_0)); 
    osd.print(zxrtc.getSecond(), DEC);
  } else {
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_FLASH);
    osd.print(PGMT(msg_time_mask));
  }

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(22,1);
  if (zxrtc.getDateIsValid()) {
    if (zxrtc.getDay() < 10) osd.print(PGMT(msg_0)); 
    osd.print(zxrtc.getDay(), DEC); osd.print(PGMT(msg_dot));
    if (zxrtc.getMonth() < 10) osd.print("0"); 
    osd.print(zxrtc.getMonth(), DEC); osd.print(PGMT(msg_dot));
    osd.print(zxrtc.getYear(), DEC);
  } else {
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_FLASH);
    osd.print(PGMT(msg_date_mask));
  }

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
    if (days > 1) {
      osd.print(PGMT(msg_many_days));
    } else {
      osd.print(PGMT(msg_one_day));
    }
    osd.print(PGMT(msg_and));
  }
  if (hours < 10) osd.print(PGMT(msg_0));
  osd.print(hours);
  osd.print(PGMT(msg_colon));
  if (mins < 10) osd.print(PGMT(msg_0));
  osd.print(mins);
  osd.print(PGMT(msg_colon));
  if (diff < 10) osd.print(PGMT(msg_0));
  osd.print(diff);
}

void ZXOSD::updateScancode(uint16_t c) {

  if (osd_state != state_info) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(14,15);
  if ((c >> 8) < 0x10) osd.print(PGMT(msg_0)); 
  osd.print(c >> 8, HEX);
  osd.print(PGMT(msg_space));
  if ((c & 0xFF) < 0x10) osd.print(PGMT(msg_0)); 
  osd.print(c & 0xFF, HEX);
}

void ZXOSD::updateMouse(uint8_t mouse_x, uint8_t mouse_y, uint8_t mouse_z) {

  if (osd_state != state_info) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(14,16);
  if (mouse_x < 0x10) osd.print(PGMT(msg_0)); 
  osd.print(mouse_x, HEX);
  osd.print(PGMT(msg_space));
  if (mouse_y < 0x10) osd.print(PGMT(msg_0)); 
  osd.print(mouse_y, HEX);
  osd.print(PGMT(msg_space));
  if (mouse_z < 0x10) osd.print(PGMT(msg_0)); 
  osd.print(mouse_z, HEX);  
}

void ZXOSD::updateJoyState(uint8_t joy) {

  if (osd_state != state_info) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(14,17);
  if (joy < 0x10) osd.print(PGMT(msg_0)); 
  osd.print(joy, HEX);  
}

void ZXOSD::highlight(bool val) {
  if (val) 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLUE);
  else 
    osd.setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK);
}

void ZXOSD::hint(const __FlashStringHelper* msg) {
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(msg);
}

void ZXOSD::param(const __FlashStringHelper* msg) {
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(msg);
  osd.print(PGMT(msg_space));
}

void ZXOSD::text(const __FlashStringHelper* msg) {
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(msg);
}

void ZXOSD::flash(const __FlashStringHelper* msg) {
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_FLASH);
  osd.print(msg);
}

/****************************************************************************/

// vim:cin:ai:sts=2 sw=2 ft=cpp
