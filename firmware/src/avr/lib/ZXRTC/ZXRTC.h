/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __ZXRTC_H__
#define __ZXRTC_H__

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
#include <RTC.h>

/****************************************************************************/

#define RTC_ADDRESS 0xA0
#define EEPROM_RTC_OFFSET 0x10

// RTC RD command
#define CMD_RTC_READ 0x40 // + regnum 0e-3f (64 ... 127)
// RTC WR command 
#define CMD_RTC_WRITE 0x80 // + regnum 0e-3f (128 ... 191)
// RTC INIT command
#define CMD_RTC_INIT_REQ 0xFC // rtc init request

class ZXRTC
{
  using spi_cb = void (*)(uint8_t addr, uint8_t data); // alias function pointer
  using osd_cb = void (*)(void); // alias function pointer

private:

  static DS1307 rtc;
  spi_cb action;
  osd_cb event;
  bool is_started = false;

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

  unsigned long tr = 0; // rtc poll time

protected:

public:

  ZXRTC();

  void begin(spi_cb act, osd_cb evt);
  bool started();
  void handle();

  void save();
  void fixInvalidTime();
  void send(uint8_t reg, uint8_t data);
  void sendTime();
  void sendAll();

  void setReg(uint8_t reg, uint8_t data);

  void readAll();

  uint8_t getWeek();
  uint8_t getHour();
  uint8_t getMinute();
  uint8_t getSecond();
  uint8_t getDay();
  uint8_t getMonth();
  int getYear();

  void setWeek(uint8_t val);
  void setHour(uint8_t val);
  void setMinute(uint8_t val);
  void setSecond(uint8_t val);
  void setDay(uint8_t val);
  void setMonth(uint8_t val);
  void setYear(int val);

  bool getInitDone();
  void setInitDone(bool val);

  bool getTimeIsValid();
  bool getDateIsValid();

};

extern ZXRTC zxrtc;

#endif // __ZXRTC_H__
// vim:cin:ai:sts=2 sw=2 ft=cpp
