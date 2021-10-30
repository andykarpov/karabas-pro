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
#include <ZXRTC.h>
#include <Arduino.h>
#include <utils.h>
#include <EEPROM.h>

/****************************************************************************/

ZXRTC::ZXRTC(void)
{
}

/****************************************************************************/

void ZXRTC::begin(spi_cb act, osd_cb evt)
{
  rtc.begin();
  action = act;
  event = evt;

  if (!rtc.isRunning()) {
     rtc.startClock();
  }

  readAll();
  sendTime();
  if (!getInitDone()) {
    sendAll();
  }
  is_started = true;
}

bool ZXRTC::started()
{
  return is_started;
}

void ZXRTC::handle()
{
  unsigned long n = millis();

  // read time from rtc
  if (n - tr >= 500) {

    rtc_year = rtc.getYear();
    rtc_month = rtc.getMonth();
    rtc_day = rtc.getDay();
    rtc_week = rtc.getWeek();

    rtc_hours = rtc.getHours();
    rtc_minutes = rtc.getMinutes();
    rtc_seconds = rtc.getSeconds();

    sendTime();

    // cb rtc
    event();

    tr = n;
  }
}

void ZXRTC::save() {
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

void ZXRTC::fixInvalidTime() {
  if (rtc_day < 1 || rtc_day > 31) rtc_day = 1;
  if (rtc_month < 1 || rtc_month > 12) rtc_month = 1;
  if (rtc_year < 2000 || rtc_year > 4095) rtc_year = 2000;
  if (rtc_hours > 23) rtc_hours = 0;
  if (rtc_minutes > 59) rtc_minutes = 0;
  if (rtc_seconds > 59) rtc_seconds = 0;
  if (rtc_week < 1 || rtc_week > 7) rtc_week = 1;
  save();
}

void ZXRTC::send(uint8_t reg, uint8_t data) {
  action(CMD_RTC_READ + reg, data);
}


void ZXRTC::sendTime() {
  send(0, rtc_is_bcd ? bin2bcd(rtc_seconds) : rtc_seconds);
  send(2, rtc_is_bcd ? bin2bcd(rtc_minutes) : rtc_minutes);
  send(4, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours) : rtc_hours) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours)) : time_to12h(rtc_hours)));
  send(6, rtc_is_bcd ? bin2bcd(rtc_week) : rtc_week);
  send(7, rtc_is_bcd ? bin2bcd(rtc_day) : rtc_day);
  send(8, rtc_is_bcd ? bin2bcd(rtc_month) : rtc_month);
  send(9, rtc_is_bcd ? bin2bcd(get_year(rtc_year)) : get_year(rtc_year));
}

void ZXRTC::sendAll() {
  uint8_t data;
  for (uint8_t reg = 0; reg < 64; reg++) {
    switch (reg) {
      case 0: send(reg, rtc_is_bcd ? bin2bcd(rtc_seconds) : rtc_seconds); break;
      case 1: send(reg, rtc_is_bcd ? bin2bcd(rtc_seconds_alarm) : rtc_seconds_alarm); break;
      case 2: send(reg, rtc_is_bcd ? bin2bcd(rtc_minutes) : rtc_minutes); break;
      case 3: send(reg, rtc_is_bcd ? bin2bcd(rtc_minutes_alarm) : rtc_minutes_alarm); break;
      case 4: send(reg, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours) : rtc_hours) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours)) : time_to12h(rtc_hours))); break;
      case 5: send(reg, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours_alarm) : rtc_hours_alarm) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours_alarm)) : time_to12h(rtc_hours_alarm))); break;
      case 6: send(reg, rtc_is_bcd ? bin2bcd(rtc_week) : rtc_week); break;
      case 7: send(reg, rtc_is_bcd ? bin2bcd(rtc_day) : rtc_day); break;
      case 8: send(reg, rtc_is_bcd ? bin2bcd(rtc_month) : rtc_month); break;
      case 9: send(reg, rtc_is_bcd ? bin2bcd(get_year(rtc_year)) : get_year(rtc_year)); break;
      case 0xA: data = EEPROM.read(EEPROM_RTC_OFFSET + reg); bitClear(data, 7); send(reg, data); break;
      case 0xB: data = EEPROM.read(EEPROM_RTC_OFFSET + reg); send(reg, data); break;
      case 0xC: send(reg, 0x0); break;
      case 0xD: send(reg, 0x80); break;
      default: send(reg, EEPROM.read(EEPROM_RTC_OFFSET + reg));
    }
  }
}

void ZXRTC::setReg(uint8_t reg, uint8_t data) {
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

void ZXRTC::readAll() {
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
}

uint8_t ZXRTC::getWeek() {
  return rtc_week;
}

uint8_t ZXRTC::getHour() {
  return rtc_hours;
}

uint8_t ZXRTC::getMinute() {
  return rtc_minutes;
}

uint8_t ZXRTC::getSecond() {
  return rtc_seconds;
}

uint8_t ZXRTC::getDay() {
  return rtc_day;
}

uint8_t ZXRTC::getMonth() {
  return rtc_month;
}

int ZXRTC::getYear() {
  return rtc_year;
}

void ZXRTC::setWeek(uint8_t val) {
  rtc_week = val;
}

void ZXRTC::setHour(uint8_t val) {
  rtc_hours = val;
}

void ZXRTC::setMinute(uint8_t val) {
  rtc_minutes = val;
}

void ZXRTC::setSecond(uint8_t val) {
  rtc_seconds = val;
}

void ZXRTC::setDay(uint8_t val) {
  rtc_day = val;
}

void ZXRTC::setMonth(uint8_t val) {
  rtc_month = val;
}

void ZXRTC::setYear(int val) {
  rtc_year = val;
}

  bool ZXRTC::getInitDone() {
    return rtc_init_done;
  }

  void ZXRTC::setInitDone(bool val) {
    rtc_init_done = val;
  }

bool ZXRTC::getTimeIsValid() {
  return (rtc_hours <= 23 && rtc_minutes <= 59 && rtc_seconds <= 59);
}

bool ZXRTC::getDateIsValid() {
  return (rtc_year < 9999 && rtc_month <= 12 && rtc_day <= 31 && rtc_week <= 7);
}

/****************************************************************************/

ZXRTC zxrtc = ZXRTC();

// vim:cin:ai:sts=2 sw=2 ft=cpp
