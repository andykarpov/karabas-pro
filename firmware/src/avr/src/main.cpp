/**
                                                                                                                
#       #######                                                 #                                               
#                                                               #                                               
#                                                               #                                               
############### ############### ############### ############### ############### ############### ############### 
#             #               # #                             # #             #               # #               
#             # ############### #               ############### #             # ############### ############### 
#             # #             # #               #             # #             # #             #               # 
#             # ############### #               ############### ############### ############### ############### 
                                                                                                                
        ####### ####### ####### #######                         ############### ############### ############### 
                                                                #             # #               #             # 
                                                                ############### #               #             # 
                                                                #               #               #             # 
https://github.com/andykarpov/karabas-pro                       #               #               ############### 

AVR firmware for Karabas-Pro

@author Andy Karpov <andy.karpov@gmail.com>
Ukraine, 2021
*/

#include "Arduino.h"
#include "PS2KeyAdvanced.h"
#include "PS2Mouse.h"
#include "SegaController.h"
#include <EEPROM.h>
#include "SBWire.h"
#include "RTC.h"
#include "OSD.h"
#include <SPI.h>
#include "config.h"
#include "utils.h"
#include "ZXKeyboard.h"

PS2KeyAdvanced kbd;
PS2Mouse mice;
SegaController sega;
static DS1307 rtc;
OSD osd;
ZXKeyboard zxkbd;

bool joy[8]; // joystic states
bool last_joy[8];
word sega_joy_state;

bool init_done = false; // init done
uint8_t cfg = 0; // cfg byte from fpga side

bool mouse_present = false; // mouse present flag (detected by signal change on CLKM pin)
bool blink_state = false;

bool led1_state = false;
bool led2_state = false;
bool led1_overwrite = false;
bool led2_overwrite = false;

bool ms_btn1 = false;
bool ms_btn2 = false;
bool ms_btn3 = false;

unsigned long t = 0;  // current time
unsigned long tl1, tl2 = 0; // led1/2 time
unsigned long tm = 0; // mouse poll time
unsigned long tl = 0; // blink poll time
unsigned long tr = 0; // rtc poll time
unsigned long tb, tb1, tb2 = 0; // hw buttons poll time
unsigned long ts = 0; // mouse swap time

int mouse_tries; // number of triers to init mouse

uint8_t mouse_x = 0; // current mouse X
uint8_t mouse_y = 0; // current mouse Y
uint8_t mouse_z = 0; // current mousr Z
uint8_t mouse_btns = 0; // mouse buttons state
bool mouse_new_packet = false; // new packet to send (toggle flag)

int rtc_year = 0;
uint8_t rtc_month = 0;
uint8_t rtc_day = 1;
uint8_t rtc_hours = 0;
uint8_t rtc_minutes = 0;
uint8_t rtc_seconds = 0;

uint8_t rtc_seconds_alarm = 0;
uint8_t rtc_minutes_alarm = 0;
uint8_t rtc_hours_alarm = 0;
uint8_t rtc_week = 1;

uint8_t rtc_last_write_reg = 0;
uint8_t rtc_last_write_data = 0;

bool rtc_init_done = false;
bool rtc_is_bcd = false;
bool rtc_is_24h = true;


uint8_t build_num[8] = {0,0,0,0,0,0,0,0};

// osd global states
enum osd_state_e {
  state_main = 0,
  state_rtc,
  state_test
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




SPISettings settingsA(1000000, MSBFIRST, SPI_MODE0); // SPI transmission settings


uint8_t get_joy_byte();
void spi_send(uint8_t addr, uint8_t data);
void transmit_joy_data();
void transmit_mouse_data();
void rtc_save();
void rtc_fix_invalid_time();
void rtc_send(uint8_t reg, uint8_t data);
void rtc_send_time();
void rtc_send_all();
void process_in_cmd(uint8_t cmd, uint8_t data);
void init_mouse();
void update_led(uint8_t led, bool state);
void osd_print_header();
void osd_init_overlay();
void osd_init_rtc_overlay();
void osd_init_test_overlay();
void osd_popup_footer();
void osd_handle_rombank();
void osd_handle_turbofdc();
void osd_handle_covox();
void osd_handle_stereo();
void osd_handle_ssg();
void osd_handle_video();
void osd_handle_vsync();
void osd_handle_turbo();
void osd_handle_swap_ab();
void osd_handle_joy_type();
void osd_handle_keyboard_type();
void osd_handle_pause();
void osd_handle_rtc_hour();
void osd_handle_rtc_minute();
void osd_handle_rtc_second();
void osd_handle_rtc_day();
void osd_handle_rtc_month();
void osd_handle_rtc_year();
void osd_handle_rtc_dow();
void osd_update_rombank();
void osd_update_turbofdc();
void osd_update_covox();
void osd_update_stereo();
void osd_update_ssg();
void osd_update_video();
void osd_update_vsync();
void osd_update_turbo();
void osd_update_swap_ab();
void osd_update_joystick();
void osd_update_keyboard_type();
void osd_update_pause();
void osd_update_rtc_hour();
void osd_update_rtc_minute();
void osd_update_rtc_second();
void osd_update_rtc_day();
void osd_update_rtc_month();
void osd_update_rtc_year();
void osd_update_rtc_dow();
void osd_update_time();
void osd_update_scancode(uint16_t c);
void osd_update_mouse();
void osd_update_joy_state();
void setup();
void loop();







uint8_t get_joy_byte()
{
  uint8_t result = 0;
  for (uint8_t i = 0; i < 8; i++) {
    bitWrite(result, i, joy[i]);
  }
  return result;
}

void spi_send(uint8_t addr, uint8_t data)
{
  SPI.beginTransaction(settingsA);
  digitalWrite(PIN_SS, LOW);
  uint8_t cmd = SPI.transfer(addr); // command (1...6)
  uint8_t res = SPI.transfer(data); // data byte
  digitalWrite(PIN_SS, HIGH);
  SPI.endTransaction();
  if (cmd > 0) {
    process_in_cmd(cmd, res);
  }
}



void transmit_joy_data()
{
  uint8_t data = get_joy_byte();
  spi_send(CMD_JOY, data);
}

void transmit_mouse_data()
{
  spi_send(CMD_MOUSE_X, mouse_x);
  spi_send(CMD_MOUSE_Y, mouse_y);
  spi_send(CMD_MOUSE_Z, mouse_z);
}

void rtc_save() {
  rtc.setHourMode(CLOCK_H24);
  rtc.setDay(rtc_day);
  rtc.setMonth(rtc_month);
  rtc.setYear(rtc_year);
  rtc.setWeek(rtc_week);
  rtc.setHours(rtc_hours);
  rtc.setMinutes(rtc_minutes);
  rtc.setSeconds(rtc_seconds);
  if (!rtc.isRunning()) {
    rtc.startClock();
  }
}

void rtc_fix_invalid_time() {
  if (rtc_day < 1 || rtc_day > 31) rtc_day = 1;
  if (rtc_month < 1 || rtc_month > 12) rtc_month = 1;
  if (rtc_year < 2000 || rtc_year > 4095) rtc_year = 2000;
  if (rtc_hours > 23) rtc_hours = 0;
  if (rtc_minutes > 59) rtc_minutes = 0;
  if (rtc_seconds > 59) rtc_seconds = 0;
  if (rtc_week < 1 || rtc_week > 7) rtc_week = 1;
  rtc_save();
}

void rtc_send(uint8_t reg, uint8_t data) {
  spi_send(CMD_RTC_READ + reg, data);
}


void rtc_send_time() {
  //uint8_t data;
  //data = EEPROM.read(EEPROM_RTC_OFFSET + 0xA); bitClear(data, 7); rtc_send(0xA, data);
  //data = EEPROM.read(EEPROM_RTC_OFFSET + 0xB); rtc_send(0xB, data);
  rtc_send(0, rtc_is_bcd ? bin2bcd(rtc_seconds) : rtc_seconds);
  rtc_send(2, rtc_is_bcd ? bin2bcd(rtc_minutes) : rtc_minutes);
  rtc_send(4, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours) : rtc_hours) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours)) : time_to12h(rtc_hours)));
  rtc_send(6, rtc_is_bcd ? bin2bcd(rtc_week) : rtc_week);
  rtc_send(7, rtc_is_bcd ? bin2bcd(rtc_day) : rtc_day);
  rtc_send(8, rtc_is_bcd ? bin2bcd(rtc_month) : rtc_month);
  rtc_send(9, rtc_is_bcd ? bin2bcd(get_year(rtc_year)) : get_year(rtc_year));
}

void rtc_send_all() {
  uint8_t data;
  for (uint8_t reg = 0; reg < 64; reg++) {
    switch (reg) {
      case 0: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_seconds) : rtc_seconds); break;
      case 1: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_seconds_alarm) : rtc_seconds_alarm); break;
      case 2: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_minutes) : rtc_minutes); break;
      case 3: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_minutes_alarm) : rtc_minutes_alarm); break;
      case 4: rtc_send(reg, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours) : rtc_hours) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours)) : time_to12h(rtc_hours))); break;
      case 5: rtc_send(reg, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours_alarm) : rtc_hours_alarm) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours_alarm)) : time_to12h(rtc_hours_alarm))); break;
      case 6: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_week) : rtc_week); break;
      case 7: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_day) : rtc_day); break;
      case 8: rtc_send(reg, rtc_is_bcd ? bin2bcd(rtc_month) : rtc_month); break;
      case 9: rtc_send(reg, rtc_is_bcd ? bin2bcd(get_year(rtc_year)) : get_year(rtc_year)); break;
      case 0xA: data = EEPROM.read(EEPROM_RTC_OFFSET + reg); bitClear(data, 7); rtc_send(reg, data); break;
      case 0xB: data = EEPROM.read(EEPROM_RTC_OFFSET + reg); rtc_send(reg, data); break;
      case 0xC: rtc_send(reg, 0x0); break;
      case 0xD: rtc_send(reg, 0x80); break;
      default: rtc_send(reg, EEPROM.read(EEPROM_RTC_OFFSET + reg));
    }
  }
}

void process_in_cmd(uint8_t cmd, uint8_t data)
{
  uint8_t reg;

  if (cmd == CMD_INIT_REQ && !init_done) {
      init_done = true;
      zxkbd.transmit();
      rtc_send_all();
      zxkbd.doReset();
      cfg = data;
  }

  if (cmd == CMD_RTC_INIT_REQ && !rtc_init_done) {
    rtc_init_done = true;
    rtc_send_all();
  }

  if (cmd >= CMD_BUILD_REQ0 && cmd <= CMD_BUILD_REQ7) {
    switch(cmd) {
      case CMD_BUILD_REQ0: build_num[0] = data; break;
      case CMD_BUILD_REQ1: build_num[1] = data; break;
      case CMD_BUILD_REQ2: build_num[2] = data; break;
      case CMD_BUILD_REQ3: build_num[3] = data; break;
      case CMD_BUILD_REQ4: build_num[4] = data; break;
      case CMD_BUILD_REQ5: build_num[5] = data; break;
      case CMD_BUILD_REQ6: build_num[6] = data; break;
      case CMD_BUILD_REQ7: build_num[7] = data; break;
    }
  }

#if ALLOW_LED_OVERRIDE
  if (cmd == CMD_LED_WRITE) {
    led1_state = bitRead(data, 0);
    led2_state = bitRead(data, 1);
    led1_overwrite = bitRead(data, 2);
    led2_overwrite = bitRead(data, 3);
  }
#endif

  if (cmd >= CMD_RTC_WRITE && cmd < CMD_RTC_WRITE + 64) {
    // write rtc register
    reg = cmd - CMD_RTC_WRITE;

    // skip double write
    if (rtc_last_write_reg == reg && rtc_last_write_data == data) return;

    rtc_last_write_reg = reg;
    rtc_last_write_data = data;

    switch (reg) {
      case 0: rtc_seconds = rtc_is_bcd ? bcd2bin(data) : data; rtc.setSeconds(rtc_seconds); break;
      case 1: rtc_seconds_alarm = rtc_is_bcd ? bcd2bin(data) : data; break;
      case 2: rtc_minutes = rtc_is_bcd ? bcd2bin(data) : data; rtc.setMinutes(rtc_minutes); break;
      case 3: rtc_minutes_alarm = rtc_is_bcd ? bcd2bin(data) : data;  break;
      case 4: rtc_hours = rtc_is_bcd ? bcd2bin(data) : data; rtc.setHourMode(CLOCK_H24); rtc.setHours(rtc_hours); break;
      case 5: rtc_hours_alarm = rtc_is_bcd ? bcd2bin(data) : data; break;
      case 6: rtc_week = rtc_is_bcd ? bcd2bin(data) : data; rtc.setWeek(rtc_week); break;
      case 7: rtc_day = rtc_is_bcd ? bcd2bin(data) : data; rtc.setDay(rtc_day); break;
      case 8: rtc_month = rtc_is_bcd ? bcd2bin(data) : data; rtc.setMonth(rtc_month); break;
      case 9: rtc_year = 2000 + (rtc_is_bcd ? bcd2bin(data) : data); rtc.setYear(rtc_year); break;
      case 0xA: bitClear(data, 7); EEPROM.write(EEPROM_RTC_OFFSET + reg, data); break;
      case 0xB: rtc_is_bcd = !bitRead(data, 2); rtc_is_24h = bitRead(data, 1); EEPROM.write(EEPROM_RTC_OFFSET + reg, data); break;
      case 0xC: // C and D are read-only registers
      case 0xD: break;
      default: EEPROM.write(EEPROM_RTC_OFFSET + reg, data);
    }
  }
}

void init_mouse()
{
#if (MOUSE_POLL_TYPE == 1)
  mouse_present = mice.initialize();
#else 
  mouse_present = mice.streamInitialize();
#endif
}



// update led state
void update_led(uint8_t led, bool state)
{
  if (led == PIN_LED2 && zxkbd.getJoyType()) {
    digitalWrite(PIN_LED2, HIGH);
    return;
  }
  digitalWrite(led, state);
}

void osd_print_header()
{
  // OSD Header
  osd.setPos(0,0);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("Karabas Pro"));

  osd.setPos(12,0);
  // board revision
  switch (cfg) {
    case 0:
    case 1:
      osd.print(F("Rev.A"));
      break;
    case 4:
    case 5:
      osd.print(F("Rev.DS"));
      break;
  }

  // dac type
/*  switch (cfg) {
    case 0:
    case 4:
      osd.print(F("TDA1543"));
      break;
    case 1:
    case 5:
      osd.print(F("TDA1543A"));
      break;
  }
*/

  osd.setPos(0,1);
  for (uint8_t i=0; i<32; i++) {
    osd.print(F("_"));
  }

  osd.setPos(0,2);
  osd.print(F("FPGA build"));
  osd.setPos(12,2);
  osd.write(build_num[0]);
  osd.write(build_num[1]);
  osd.write(build_num[2]);
  osd.write(build_num[3]);
  osd.write(build_num[4]);
  osd.write(build_num[5]);
  osd.write(build_num[6]);
  osd.write(build_num[7]);

  osd.setPos(0,3);
  osd.print(F("AVR build"));
  osd.setPos(12,3);
  osd.print(BUILD_VER);
}

// init osd
void osd_init_overlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  osd_print_header();

  // ROM Bank
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,5); osd.print(F("ROM Bank:"));
  osd_update_rombank();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,5); osd.print(F("Menu+F1-F4"));

  // Turbo FDC
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,6); osd.print(F("TurboFDC:"));
  osd_update_turbofdc();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,6); osd.print(F("Menu+F5"));

  // Covox
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,7); osd.print(F("Covox:"));
  osd_update_covox();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,7); osd.print(F("Menu+F6"));

  // Stereo
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,8); osd.print(F("PSG mix:"));
  osd_update_stereo();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,8); osd.print(F("Menu+F7"));

  // SSG type
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,9); osd.print(F("PSG type:"));
  osd_update_ssg();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,9); osd.print(F("Menu+F8"));

  // RGB/VGA
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,10); osd.print(F("Video:"));
  osd_update_video();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,10); osd.print(F("Menu+F9"));

  // VSync
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,11); osd.print(F("VSync:"));
  osd_update_vsync();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,11); osd.print(F("Menu+F10"));

  // Turbo
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,12); osd.print(F("Turbo 2x:"));
  osd_update_turbo();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,12); osd.print(F("Menu+F11"));

  // FDC Swap
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,13); osd.print(F("Swap FDD:"));
  osd_update_swap_ab();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,13); osd.print(F("Menu+Tab"));

  // Joy type
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,14); osd.print(F("Joy type:"));
  osd_update_joystick();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,14); osd.print(F("Menu+J"));

  // Keyboard
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,15); osd.print(F("Keyboard:"));
  osd_update_keyboard_type();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,15); osd.print(F("PrtScr"));

  // Pause
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,16); osd.print(F("Pause:"));
  osd_update_pause();
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.setPos(20,16); osd.print(F("Pause"));

  // Scancode
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,18); osd.print(F("Scancode:"));
  osd_update_scancode(0);

  // Mouse
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,19); osd.print(F("Mouse:"));
  osd_update_mouse();

  // Joy
  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,20); osd.print(F("Port #1F:"));
  osd_update_joy_state();

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(20,19); osd.print(F("Press "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_FLASH);
  osd.print(F("E"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" to "));
  osd.setPos(20,20); osd.print(F("set up RTC"));

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
void osd_init_rtc_overlay()
{
  rtc_fix_invalid_time(); // try to fix invalid time

  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  osd_print_header();

  osd.setPos(0,5);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("RTC setup:"));

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,7); osd.print(F("Hours:"));
  osd_update_rtc_hour();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,8); osd.print(F("Minutes:"));
  osd_update_rtc_minute();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,9); osd.print(F("Seconds:"));
  osd_update_rtc_second();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,11); osd.print(F("Day:"));
  osd_update_rtc_day();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,12); osd.print(F("Month:"));
  osd_update_rtc_month();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,13); osd.print(F("Year:"));
  osd_update_rtc_year();

  osd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  osd.setPos(0,15); osd.print(F("DOW:"));
  osd_update_rtc_dow();

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

  osd_popup_footer();
}

// init test osd
void osd_init_test_overlay()
{
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.clear();

  osd_print_header();

  osd.setPos(0,5);
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F("Color test:"));

  uint8_t color = 0;
  for (uint8_t x = 0; x<32; x++) {
    for (uint8_t y = 7; y<22; y++) {
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

  osd_popup_footer();

}

void osd_popup_footer() {
  // footer
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.setPos(0,23); osd.print(F("Press "));
  osd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  osd.print(F("ESC"));
  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  osd.print(F(" to return"));
}

void osd_handle_rombank() {
  uint8_t romset = zxkbd.getRombank();

  if (zxkbd.getIsCursorLeft()) {
    romset = romset-1;
    if (romset > 3) romset = 3;
    zxkbd.setRombank(romset);
    osd_update_rombank();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    romset = romset+1;
    if (romset >3) romset = 0;
    zxkbd.setRombank(romset);
    osd_update_rombank();
  }
}

void osd_handle_turbofdc() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleTurbofdc();
    osd_update_turbofdc();
  }
}

void osd_handle_covox() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleCovox();
    osd_update_covox();
  }
}

void osd_handle_stereo() {

  uint8_t stereo = zxkbd.getStereo();

  if (zxkbd.getIsCursorLeft()) {
    stereo = stereo-1;
    if (stereo > 2) stereo = 2;
    zxkbd.toggleStereo(stereo);
    osd_update_stereo();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    stereo = stereo+1;
    if (stereo >2) stereo = 0;
    zxkbd.toggleStereo(stereo);
    osd_update_stereo();
  }
}

void osd_handle_ssg() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleSsg();
    osd_update_ssg();
  }
}

void osd_handle_video() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleVideo();
    osd_update_video();
  }
}

void osd_handle_vsync() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleVsync();
    osd_update_vsync();
  }
}

void osd_handle_turbo() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleTurbo();
    osd_update_turbo();
  }
}

void osd_handle_swap_ab() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleSwapAB();
    osd_update_swap_ab();
  }
}

void osd_handle_joy_type() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleJoyType();
    osd_update_joystick();
  }
}

void osd_handle_keyboard_type() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.toggleKeyboardType();
    osd_update_keyboard_type();
  }
}

void osd_handle_pause() {
  if (zxkbd.getIsCursorLeft() || zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    zxkbd.doPause();
    osd_update_pause();
  }
}

void osd_handle_rtc_hour() {
  if (zxkbd.getIsCursorLeft()) {
    rtc_hours = rtc_hours-1;
    if (rtc_hours > 23) rtc_hours = 0;
    rtc_save();
    osd_update_rtc_hour();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    rtc_hours = rtc_hours+1;
    if (rtc_hours >23) rtc_hours = 0;
    rtc_save();
    osd_update_rtc_hour();
  }
}

void osd_handle_rtc_minute() {
  if (zxkbd.getIsCursorLeft()) {
    rtc_minutes = rtc_minutes-1;
    if (rtc_minutes > 59) rtc_minutes = 59;
    rtc_save();
    osd_update_rtc_minute();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    rtc_minutes = rtc_minutes+1;
    if (rtc_minutes >59) rtc_minutes = 0;
    rtc_save();
    osd_update_rtc_minute();
  }
}

void osd_handle_rtc_second() {
  if (zxkbd.getIsCursorLeft()) {
    rtc_seconds = rtc_seconds-1;
    if (rtc_seconds > 59) rtc_seconds = 59;
    rtc_save();
    osd_update_rtc_second();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    rtc_seconds = rtc_seconds+1;
    if (rtc_seconds >59) rtc_seconds = 0;
    rtc_save();
    osd_update_rtc_second();
  }
}

void osd_handle_rtc_day() {
  if (zxkbd.getIsCursorLeft()) {
    rtc_day = rtc_day-1;
    if (rtc_day < 1 || rtc_day > 31) rtc_day = 31;
    rtc_save();
    osd_update_rtc_day();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    rtc_day = rtc_day+1;
    if (rtc_day > 31) rtc_day = 1;
    rtc_save();
    osd_update_rtc_day();
  }
}

void osd_handle_rtc_month() {
  if (zxkbd.getIsCursorLeft()) {
    rtc_month = rtc_month-1;
    if (rtc_month < 1 || rtc_month > 12) rtc_month = 12;
    rtc_save();
    osd_update_rtc_month();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    rtc_month = rtc_month+1;
    if (rtc_month > 12) rtc_month = 1;
    rtc_save();
    osd_update_rtc_month();
  }
}

void osd_handle_rtc_year() {
  if (zxkbd.getIsCursorLeft()) {
    rtc_year = rtc_year-1;
    if (rtc_year < 2000 || rtc_year > 4095) rtc_year = 2000;
    rtc_save();
    osd_update_rtc_year();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    rtc_year = rtc_year+1;
    if (rtc_year < 2000 || rtc_year > 4096) rtc_year = 2000;
    rtc_save();
    osd_update_rtc_year();
  }
}

void osd_handle_rtc_dow() {
  if (zxkbd.getIsCursorLeft()) {
    rtc_week = rtc_week-1;
    if (rtc_week < 1 || rtc_week > 7) rtc_week = 7;
    rtc_save();
    osd_update_rtc_dow();
  }
  if (zxkbd.getIsCursorRight() || zxkbd.getIsEnter()) {
    rtc_week = rtc_week+1;
    if (rtc_week < 1 || rtc_week > 7) rtc_week = 1;
    rtc_save();
    osd_update_rtc_dow();
  }
}

void osd_update_rombank()
{
  if (osd_state != state_main) return;

  uint8_t romset = zxkbd.getRombank();

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

void osd_update_turbofdc() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_turbofdc) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,6);
  if (zxkbd.getTurbofdc()) { 
    osd.print(F("On")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" "));
  } else { 
    osd.print(F("Off")); 
  }
}

void osd_update_covox() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_covox) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,7);
  if (zxkbd.getCovox()) { 
    osd.print(F("On"));
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Off")); 
  }
}

void osd_update_stereo() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_stereo) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,8);
  uint8_t stereo = zxkbd.getStereo();
  switch (stereo) {
    case 1: osd.print(F("ABC")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 0: osd.print(F("ACB")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    default: osd.print(F("Mono")); 
  }
}

void osd_update_ssg() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_ssg) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,9);
  if (zxkbd.getSsg()) { osd.print(F("AY3-8912")); } else { osd.print(F("YM2149F")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); }
}

void osd_update_video() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_video) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,10);
  if (zxkbd.getVideo()) { osd.print(F("RGB 15kHz")); } else { osd.print(F("VGA 30kHz")); }
}

void osd_update_vsync() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_sync) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,11);
  if (zxkbd.getVsync()) { osd.print(F("60 Hz")); } else { osd.print(F("50 Hz")); }
}

void osd_update_turbo() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_turbo) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,12);
  if (zxkbd.getTurbo()) { 
    osd.print(F("On")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Off")); 
  }
}

void osd_update_swap_ab() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_swap_ab) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,13);
  if (zxkbd.getSwapAB()) { 
    osd.print(F("On")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Off")); 
  }
}

void osd_update_joystick() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_joy_type) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,14);
  if (zxkbd.getJoyType()) { 
    osd.print(F("SEGA")); 
    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); 
  } else { 
    osd.print(F("Atari")); 
  }
}

void osd_update_keyboard_type() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_keyboard_type) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,15);
  if (zxkbd.getKeyboardType()) { osd.print(F("Profi XT")); } else { osd.print(F("Spectrum")); }
}

void osd_update_pause() {

  if (osd_state != state_main) return;

  if (osd_main_state == state_main_pause) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);

  osd.setPos(10,16);
  if (zxkbd.getPause()) { osd.print(F("On")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); } else { osd.print(F("Off")); }
}

void osd_update_rtc_hour() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_hour) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,7);
  if (rtc_hours < 10) osd.print(F("0"));
  osd.print(rtc_hours, DEC);
}

void osd_update_rtc_minute() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_minute) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,8);
  if (rtc_minutes < 10) osd.print(F("0"));
  osd.print(rtc_minutes, DEC);
}

void osd_update_rtc_second() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_second) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,9);
  if (rtc_seconds < 10) osd.print(F("0"));
  osd.print(rtc_seconds, DEC);
}

void osd_update_rtc_day() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_day) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,11);
  if (rtc_day < 10) osd.print(F("0"));
  osd.print(rtc_day, DEC);
}

void osd_update_rtc_month() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_month) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,12);
  switch (rtc_month) {
    case 1:  osd.print(F("January"));  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("  ")); break;
    case 2:  osd.print(F("February")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 3:  osd.print(F("March"));    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("    ")); break;
    case 4:  osd.print(F("April"));    osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("    ")); break;
    case 5:  osd.print(F("May"));      osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("      ")); break;
    case 6:  osd.print(F("June"));     osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("     ")); break;
    case 7:  osd.print(F("July"));     osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("     ")); break;
    case 8:  osd.print(F("August"));   osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("   ")); break;
    case 9:  osd.print(F("September")); break;
    case 10: osd.print(F("October"));  osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F("  ")); break;
    case 11: osd.print(F("November")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    case 12: osd.print(F("December")); osd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK); osd.print(F(" ")); break;
    default: osd.print(F("___")); 
  }
}

void osd_update_rtc_year() {
  if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_year) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,13);
  if (rtc_year < 1000) osd.print(F("0"));
  if (rtc_year < 100) osd.print(F("0"));
  if (rtc_year < 10) osd.print(F("0"));
  osd.print(rtc_year, DEC);
}

void osd_update_rtc_dow() {
if (osd_state != state_rtc) return;
  if (osd_rtc_state == state_rtc_dow) 
    osd.setColor(OSD::COLOR_BLACK, OSD::COLOR_MAGENTA_I);  
  else 
    osd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  osd.setPos(10,15);
  switch (rtc_week) {
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

void osd_update_time() {
  osd.setColor(OSD::COLOR_YELLOW_I, OSD::COLOR_BLACK);
  osd.setPos(24,0);
  if (rtc_hours < 10) osd.print("0"); 
  osd.print(rtc_hours, DEC); osd.print(F(":"));
  if (rtc_minutes < 10) osd.print("0"); 
  osd.print(rtc_minutes, DEC); osd.print(F(":"));
  if (rtc_seconds < 10) osd.print("0"); 
  osd.print(rtc_seconds, DEC);
  osd.setPos(22,2);
  if (rtc_day < 10) osd.print("0"); 
  osd.print(rtc_day, DEC); osd.print(F("."));
  if (rtc_month < 10) osd.print("0"); 
  osd.print(rtc_month, DEC); osd.print(F("."));
  osd.print(rtc_year, DEC);
  if (osd_state == state_rtc) {
    osd_update_rtc_hour();
    osd_update_rtc_minute();
    osd_update_rtc_second();
    osd_update_rtc_day();
    osd_update_rtc_month();
    osd_update_rtc_year();
    osd_update_rtc_dow();
  }
}

void osd_update_scancode(uint16_t c) {

  if (osd_state != state_main) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(10,18);
  if ((c >> 8) < 0x10) osd.print(F("0")); 
  osd.print(c >> 8, HEX);
  osd.print(F(" "));
  if ((c & 0xFF) < 0x10) osd.print(F("0")); 
  osd.print(c & 0xFF, HEX);
}

void osd_update_mouse() {

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

void osd_update_joy_state() {

  if (osd_state != state_main) return;

  osd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  osd.setPos(10,20);
  osd.print(joy[ZX_JOY_B], DEC);
  osd.print(joy[ZX_JOY_A], DEC);
  osd.print(joy[ZX_JOY_FIRE2], DEC);
  osd.print(joy[ZX_JOY_FIRE], DEC);
  osd.print(joy[ZX_JOY_UP], DEC);
  osd.print(joy[ZX_JOY_DOWN], DEC);
  osd.print(joy[ZX_JOY_LEFT], DEC);
  osd.print(joy[ZX_JOY_RIGHT], DEC);
}

// update OSD by keyboard events
void on_keyboard (uint8_t event_type, uint16_t scancode)
{
  switch (event_type) {
    case ZXKeyboard::EVENT_OSD_OVERLAY:  osd_state = state_main; osd_init_overlay(); break;
    case ZXKeyboard::EVENT_OSD_SCANCODE: osd_update_scancode(scancode); break;
    case ZXKeyboard::EVENT_OSD_JOYSTICK: osd_update_joystick(); break;
    case ZXKeyboard::EVENT_OSD_SWAP_AB:  osd_update_swap_ab(); break;
    case ZXKeyboard::EVENT_OSD_ROMBANK:  osd_update_rombank(); break;
    case ZXKeyboard::EVENT_OSD_TURBOFDC:  osd_update_turbofdc(); break;
    case ZXKeyboard::EVENT_OSD_COVOX:  osd_update_covox(); break;
    case ZXKeyboard::EVENT_OSD_STEREO:  osd_update_stereo(); break;
    case ZXKeyboard::EVENT_OSD_SSG:  osd_update_ssg(); break;
    case ZXKeyboard::EVENT_OSD_VIDEO:  osd_update_video(); break;
    case ZXKeyboard::EVENT_OSD_VSYNC:  osd_update_vsync(); break;
    case ZXKeyboard::EVENT_OSD_JOY_TYPE:  osd_update_joystick(); break;
    case ZXKeyboard::EVENT_OSD_KEYBOARD_TYPE:  osd_update_keyboard_type(); break;
    case ZXKeyboard::EVENT_OSD_PAUSE:  osd_update_pause(); break;
    case ZXKeyboard::EVENT_OSD_TURBO:  osd_update_turbo(); break;
  }
}

// initial setup
void setup()
{
  Serial.begin(115200);
  Serial.flush();
  pinMode(PIN_JOY_RIGHT, OUTPUT);
  digitalWrite(PIN_JOY_RIGHT, LOW);
  SPI.begin();

  // set up fast ADC
  // Bit 7 - ADEN: ADC Enable
  // Bit 6 - ADSC: ADC Start Conversion
  // Bit 5 - ADATE: ADC Auto Trigger Enable
  // Bit 4 - ADIF: ADC Interrupt Flag
  // Bit 3 - ADIE: ADC Interrupt Enable
  // Bits 2:0 - ADPS[2:0]: ADC Prescaler Select Bits
  ADCSRA = (ADCSRA & B11111000) | 4;

  pinMode(PIN_SS, OUTPUT);
  digitalWrite(PIN_SS, HIGH);

  pinMode(PIN_LED1, OUTPUT);
  digitalWrite(PIN_LED1, HIGH);

  pinMode(PIN_LED2, OUTPUT);
  digitalWrite(PIN_LED2, HIGH);

  pinMode(PIN_BTN1, INPUT_PULLUP);
  pinMode(PIN_BTN2, INPUT_PULLUP);

  // ps/2

  pinMode(PIN_KBD_CLK, INPUT_PULLUP);
  pinMode(PIN_KBD_DAT, INPUT_PULLUP);

  pinMode(PIN_MOUSE_CLK, INPUT_PULLUP);
  pinMode(PIN_MOUSE_DAT, INPUT_PULLUP);

  // joy
  pinMode(PIN_JOY_UP, INPUT_PULLUP);
  pinMode(PIN_JOY_DOWN, INPUT_PULLUP);
  pinMode(PIN_JOY_LEFT, INPUT_PULLUP);
//  pinMode(PIN_JOY_RIGHT, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE1, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE2, INPUT_PULLUP);

  kbd.begin(PIN_KBD_DAT, PIN_KBD_CLK);
  kbd.echo(); // ping keyboard to see if there
  delay(6);
  uint16_t c = kbd.read();
  if( (c & 0xFF) == PS2_KEY_ECHO || (c & 0xFF) == PS2_KEY_BAT ) {
    kbd.setLock(PS2_LOCK_SCROLL);
  }

  zxkbd.begin(&kbd, spi_send, on_keyboard);

  // waiting for init
  while (!init_done) {
    spi_send(CMD_NONE, 0x00);
  }

  // request build num from the fpga
  spi_send(CMD_BUILD_REQ0, 0x00);
  spi_send(CMD_BUILD_REQ1, 0x00);
  spi_send(CMD_BUILD_REQ2, 0x00);
  spi_send(CMD_BUILD_REQ3, 0x00);
  spi_send(CMD_BUILD_REQ4, 0x00);
  spi_send(CMD_BUILD_REQ5, 0x00);
  spi_send(CMD_BUILD_REQ6, 0x00);
  spi_send(CMD_BUILD_REQ7, 0x00);

  // setup osd library with callback to send spi command
  osd.begin(spi_send);

  // setup sega controller
  sega.begin(PIN_LED2, PIN_JOY_UP, PIN_JOY_DOWN, PIN_JOY_LEFT, PIN_JOY_RIGHT, PIN_JOY_FIRE1, PIN_JOY_FIRE2);

  mouse_tries = MOUSE_INIT_TRIES;

  mice.begin(PIN_MOUSE_CLK, PIN_MOUSE_DAT);
  init_mouse();

  rtc.begin();

  if (!rtc.isRunning()) {
     rtc.startClock();
  }

  rtc_year = rtc.getYear();
  rtc_month = rtc.getMonth();
  rtc_day = rtc.getDay();
  rtc_week = rtc.getWeek();

  rtc_hours = rtc.getHours();
  rtc_minutes = rtc.getMinutes();
  rtc_seconds = rtc.getSeconds();

  // read is_bcd, is_24h
  uint8_t reg_b = EEPROM.read(EEPROM_RTC_OFFSET + 0xB);
  rtc_is_bcd = !bitRead(reg_b, 2);
  rtc_is_24h = bitRead(reg_b, 1);

  rtc_send_time();

  if (!rtc_init_done) {
    rtc_send_all();
  }

  digitalWrite(PIN_LED1, LOW);
}


// main loop
void loop()
{
  unsigned long n = millis();

  zxkbd.handle();

  // switch betweeen main osd states
  if (zxkbd.getIsOsdOverlay()) {
    switch (osd_state) {
      case state_main:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          osd_main_state = state_main_rom_bank;
          osd_prev_main_state = state_main_rom_bank;
          osd_init_overlay();
        }

        if (osd_main_state != osd_prev_main_state) {
          osd_prev_main_state = osd_main_state;
          switch(osd_main_state) {
            case state_main_rom_bank: osd_update_pause(); osd_update_rombank(); osd_update_turbofdc(); break;
            case state_main_turbofdc: osd_update_rombank(); osd_update_turbofdc(); osd_update_covox(); break;
            case state_main_covox: osd_update_turbofdc(); osd_update_covox(); osd_update_stereo(); break;
            case state_main_stereo: osd_update_covox(); osd_update_stereo(); osd_update_ssg(); break;
            case state_main_ssg: osd_update_stereo(); osd_update_ssg(); osd_update_video(); break;
            case state_main_video: osd_update_ssg(); osd_update_video(); osd_update_vsync(); break;
            case state_main_sync: osd_update_video(); osd_update_vsync(); osd_update_turbo(); break;
            case state_main_turbo: osd_update_vsync(); osd_update_turbo(); osd_update_swap_ab(); break;
            case state_main_swap_ab: osd_update_turbo(); osd_update_swap_ab(); osd_update_joystick(); break;
            case state_main_joy_type: osd_update_swap_ab(); osd_update_joystick(); osd_update_keyboard_type(); break;
            case state_main_keyboard_type: osd_update_joystick(); osd_update_keyboard_type(); osd_update_pause(); break;
            case state_main_pause: osd_update_keyboard_type(); osd_update_pause(); osd_update_rombank(); break;
          }
        }

      break;
      case state_rtc:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          osd_rtc_state = state_rtc_hour;
          osd_prev_rtc_state = state_rtc_hour;
          osd_init_rtc_overlay();
        }

        if (osd_rtc_state != osd_prev_rtc_state) {
          osd_prev_rtc_state = osd_rtc_state;
          switch(osd_rtc_state) {
            case state_rtc_hour: osd_update_rtc_dow(); osd_update_rtc_hour(); osd_update_rtc_minute(); break;
            case state_rtc_minute: osd_update_rtc_hour(); osd_update_rtc_minute(); osd_update_rtc_second(); break;
            case state_rtc_second: osd_update_rtc_minute(); osd_update_rtc_second(); osd_update_rtc_day(); break;
            case state_rtc_day: osd_update_rtc_second(); osd_update_rtc_day(); osd_update_rtc_month(); break;
            case state_rtc_month: osd_update_rtc_day(); osd_update_rtc_month(); osd_update_rtc_year(); break;
            case state_rtc_year: osd_update_rtc_month(); osd_update_rtc_year(); osd_update_rtc_dow(); break;
            case state_rtc_dow: osd_update_rtc_year(); osd_update_rtc_dow(); osd_update_rtc_hour(); break;
          }
        }

      break;

      case state_test:
        if (osd_prev_state != osd_state) {
          osd_prev_state = osd_state;
          osd_init_test_overlay();
        }
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

        if (zxkbd.getKey(ZX_K_E)) {
          osd_state = state_rtc;
        }

        if (zxkbd.getKey(ZX_K_T)) {
          osd_state = state_test;
        }

        switch (osd_main_state) {
          case state_main_rom_bank: osd_handle_rombank(); break;
          case state_main_turbofdc: osd_handle_turbofdc(); break;
          case state_main_covox: osd_handle_covox(); break;
          case state_main_stereo: osd_handle_stereo(); break;
          case state_main_ssg: osd_handle_ssg(); break;
          case state_main_video: osd_handle_video(); break;
          case state_main_sync: osd_handle_vsync(); break;
          case state_main_turbo: osd_handle_turbo(); break;
          case state_main_swap_ab: osd_handle_swap_ab(); break;
          case state_main_joy_type: osd_handle_joy_type(); break;
          case state_main_keyboard_type: osd_handle_keyboard_type(); break;
          case state_main_pause: osd_handle_pause(); break;
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
          case state_rtc_hour: osd_handle_rtc_hour(); break;
          case state_rtc_minute: osd_handle_rtc_minute(); break;
          case state_rtc_second: osd_handle_rtc_second(); break;
          case state_rtc_day: osd_handle_rtc_day(); break;
          case state_rtc_month: osd_handle_rtc_month(); break;
          case state_rtc_year: osd_handle_rtc_year(); break;
          case state_rtc_dow: osd_handle_rtc_dow(); break;
        }

      break;

      case state_test:

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

  // transmit kbd always
  zxkbd.transmit();

  // read joystick
  // Due to conflict with the hardware SPI, we should stop the HW SPI and switch the joy_right as input before reading
  // WARNING: a 100-500 Ohm resistor is required on the PIN_JOY_RIGHT line
  //SPI.end();
  //interrupts(); // SPI.end() calls noInterrupts()
  SPCR &= ~_BV(SPE);

  // set JOY_RIGHT pin as input to read joystick signal
  pinMode(PIN_JOY_RIGHT, INPUT_PULLUP);

  if (zxkbd.getJoyType() == false) {
    // kempston joy read
    joy[ZX_JOY_UP] = digitalRead(PIN_JOY_UP) == LOW;
    joy[ZX_JOY_DOWN] = digitalRead(PIN_JOY_DOWN) == LOW;
    joy[ZX_JOY_LEFT] = digitalRead(PIN_JOY_LEFT) == LOW;
    joy[ZX_JOY_RIGHT] = digitalRead(PIN_JOY_RIGHT) == LOW;
    joy[ZX_JOY_FIRE] = digitalRead(PIN_JOY_FIRE1) == LOW;
    joy[ZX_JOY_FIRE2] = digitalRead(PIN_JOY_FIRE2) == LOW;
    joy[ZX_JOY_A] = false;
    joy[ZX_JOY_B] = false;
  } else {
    // sega joy read
    sega_joy_state = sega.getState();
    joy[ZX_JOY_UP] = sega_joy_state & SC_BTN_UP;
    joy[ZX_JOY_DOWN] = sega_joy_state & SC_BTN_DOWN;
    joy[ZX_JOY_LEFT] = sega_joy_state & SC_BTN_LEFT;
    joy[ZX_JOY_RIGHT] = sega_joy_state & SC_BTN_RIGHT;
    joy[ZX_JOY_FIRE] = sega_joy_state & SC_BTN_B;
    joy[ZX_JOY_FIRE2] = sega_joy_state & SC_BTN_C;
    joy[ZX_JOY_A] = sega_joy_state & SC_BTN_A;
    joy[ZX_JOY_B] = sega_joy_state & SC_BTN_START;
  }

  // set JOY_RIGHT as output to avoid intersection with hardware SPI SS pin
  pinMode(PIN_JOY_RIGHT, OUTPUT);
  digitalWrite(PIN_JOY_RIGHT, LOW);

  //SPI.begin();
  //interrupts(); // SPI.begin() calls noInterrupts()
  SPCR |= _BV(MSTR);
  SPCR |= _BV(SPE);

  if (joy[0] != last_joy[0] || joy[1] != last_joy[1] || joy[2] != last_joy[2] || joy[3] != last_joy[3] || joy[4] != last_joy[4] || joy[5] != last_joy[5] || joy[6] != last_joy[6] || joy[7] != last_joy[7]) {
    last_joy[0] = joy[0];
    last_joy[1] = joy[1];
    last_joy[2] = joy[2];
    last_joy[3] = joy[3];
    last_joy[4] = joy[4];
    last_joy[5] = joy[5];
    last_joy[6] = joy[6];
    last_joy[7] = joy[7];

    if (zxkbd.getIsOsdOverlay()) {
      osd_update_joy_state();
    }

  }

  // transmit joy matrix
  transmit_joy_data();

  // react on hardware buttons every 100ms
#if USE_HW_BUTTONS
  if (n - tb >= 100) {
    if (analogRead(PIN_BTN1) < 3 && (n - tb1 >= 500) ) {
      tb1 = n;
      update_led(PIN_LED2, HIGH);
      zxkbd.doMagic();
       update_led(PIN_LED2, LOW);
    }

    if (analogRead(PIN_BTN2) < 3 && (n - tb2 >= 500) ) {
      tb2 = n;
      update_led(PIN_LED1, HIGH);
      zxkbd.doReset();
      update_led(PIN_LED1, LOW);
    }
    tb = n;
  }
#endif

  // read time from rtc
  if (n - tr >= 500) {

    rtc_year = rtc.getYear();
    rtc_month = rtc.getMonth();
    rtc_day = rtc.getDay();
    rtc_week = rtc.getWeek();

    rtc_hours = rtc.getHours();
    rtc_minutes = rtc.getMinutes();
    rtc_seconds = rtc.getSeconds();

    rtc_send_time();

    // show time in the overlay
    if (zxkbd.getIsOsdOverlay()) {
      osd_update_time();
    }

    tr = n;
  }

  // try to re-init mouse every 100us if not present, up to N tries
  if (mouse_tries > 0 && !mouse_present && n - tm > 100) {
    mouse_tries--;
    init_mouse();
    tm = n;
  }

  // polling for mouse data
  #if MOUSE_POLL_TYPE == 1
  if (mouse_present && n - t > MOUSE_POLL_INTERVAL) {

    MouseData m = mice.readData();

    mouse_new_packet = !mouse_new_packet;
    mouse_x = m.position.x;
    mouse_y = m.position.y;
    mouse_z = m.wheel;

    ms_btn1 = bitRead(m.status, 0);
    ms_btn2 = bitRead(m.status, 1);
    ms_btn3 = bitRead(m.status, 2);
    bitWrite(mouse_z, 4, zxkbd.getMouseSwap() ? ms_btn2 : ms_btn1); // left
    bitWrite(mouse_z, 5, zxkbd.getMouseSwap() ? ms_btn1 : ms_btn2); // right
    bitWrite(mouse_z, 6, ms_btn3); // middle
    bitWrite(mouse_z, 7, mouse_new_packet);

    transmit_mouse_data();

    if (zxkbd.getIsOsdOverlay()) {
      osd_update_mouse();
    }

    t = n;
  }
  #else
  // mouse stream report read
  if (mice.reportAvailable() > 0 ) {
    MouseData m = mice.readReport();

    //if ((bitRead(m.status, 3) == 1) and (bitRead(m.status, 6) == 0) and (bitRead(m.status,7)== 0)) {
      mouse_new_packet = !mouse_new_packet;
      mouse_x = m.position.x;
      mouse_y = m.position.y;
      mouse_z = m.wheel;
  
      ms_btn1 = bitRead(m.status, 0);
      ms_btn2 = bitRead(m.status, 1);
      ms_btn3 = bitRead(m.status, 2);
      bitWrite(mouse_z, 4, zxkbd.getMouseSwap() ? ms_btn2 : ms_btn1); // left
      bitWrite(mouse_z, 5, zxkbd.getMouseSwap() ? ms_btn1 : ms_btn2); // right
      bitWrite(mouse_z, 6, ms_btn3); // middle
      bitWrite(mouse_z, 7, mouse_new_packet);
  
      transmit_mouse_data();    

      if (zxkbd.getIsOsdOverlay()) {
        osd_update_mouse();
      }
    //}
  }

  #endif

  // swap mouse buttons
  if (mouse_present && n - ts > MOUSE_SWAP_INTERVAL) {
    if (zxkbd.getIsMenu() && ms_btn1) {
      zxkbd.setMouseSwap(!zxkbd.getMouseSwap());
      update_led(PIN_LED1, HIGH);
      delay(100);
      update_led(PIN_LED1, LOW);
      delay(100);
      update_led(PIN_LED1, HIGH);
      delay(100);
      update_led(PIN_LED1, LOW);
    }
    ts = n;
  }

  // control led1
#if ALLOW_LED_OVERRIDE
  if (led1_overwrite) {
    if (led1_state == 1) {
      update_led(PIN_LED1, HIGH);
    }
    if (n - tl1 >= 100) {
      tl1 = n;
      if (led1_state == false) {
        update_led(PIN_LED1, LOW);
      }
    }
  }

  // control led2
  if (led2_overwrite) {
      if (led2_state == 1) {
        update_led(PIN_LED2, HIGH);
      }
      if (n - tl2 >= 100) {
        tl2 = n;
        if (led2_state == false) {
          update_led(PIN_LED2, LOW);
        }
    }
  }
#else 
  if (zxkbd.getPause()) {
    if (n - tl2 >= 500) {
      tl2 = n;
      blink_state = !blink_state;
      update_led(PIN_LED2, blink_state);
    }
  } else {
    update_led(PIN_LED2, HIGH);
  }

  if (n - tl >= 100) {
    update_led(PIN_LED1, LOW);
  }
#endif

// reset pressed keys for OSD
zxkbd.resetOsdControls();

delayMicroseconds(1);

}
