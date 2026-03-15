/*
 Copyright (C) 2021-2023 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __RTC_H__
#define __RTC_H__

#include <Arduino.h>
#include <SparkFun_External_EEPROM.h>
#include <RTClib.h>

/****************************************************************************/

extern uint8_t core_eeprom_get(uint8_t pos);
extern void core_eeprom_set(uint8_t pos, uint8_t val);

// RTC DATA XCHANGE command
#define CMD_RTC 0xFA
#define RTC_TYPE_DS1307 1
#define RTC_TYPE_MC146818A 0

class RTC
{
  using spi_cb = void (*)(uint8_t cmd, uint8_t addr, uint8_t data); // alias function pointer
  using osd_cb = void (*)(void); // alias function pointer

private:

  RTC_DS3231 rtc_clock;
  ExternalEEPROM eeprom;
  spi_cb action;
  osd_cb event;
  bool is_started = false;
  bool has_eeprom = false;

  uint8_t rtc_year = 0;
  uint8_t rtc_month = 0;
  uint8_t rtc_day = 1;
  uint8_t rtc_hours = 0;
  uint8_t rtc_minutes = 0;
  uint8_t rtc_seconds = 0;

  uint8_t rtc_seconds_alarm = 0;
  uint8_t rtc_minutes_alarm = 0;
  uint8_t rtc_hours_alarm = 0;
  uint8_t rtc_week = 1;

  uint8_t eeprom_bank = 0;
  uint8_t rtc_type = 0;

  volatile int rtc_last_write_reg = 0;
  volatile uint8_t rtc_last_write_data = 0;

  bool rtc_is_bcd = false;
  bool rtc_is_24h = true;

  unsigned long tr = 0; // rtc poll time
  unsigned long to = 0; // redraw osd time

protected:

  uint8_t bin2bcd(uint8_t val);
  uint8_t bcd2bin(uint8_t val);
  uint8_t time_to24h(uint8_t val);
  uint8_t time_to12h(uint8_t val);
  uint8_t get_year(int year); 

public:

  RTC();

  void begin(spi_cb act, osd_cb evt);
  bool started();
  void handle();

  void save();
  void send(uint8_t reg, uint8_t data);
  void sendTime();
  void sendAll();

  void setData(uint8_t addr, uint8_t data);

  void readAll();

  uint8_t getWeek();
  uint8_t getHour();
  uint8_t getMinute();
  uint8_t getSecond();
  uint8_t getDay();
  uint8_t getMonth();
  uint8_t getYear();

  void setWeek(uint8_t val);
  void setHour(uint8_t val);
  void setMinute(uint8_t val);
  void setSecond(uint8_t val);
  void setDay(uint8_t val);
  void setMonth(uint8_t val);
  void setYear(uint8_t val);

  void setEepromBank(uint8_t val);
  void setRtcType(uint8_t val);
  uint8_t getEepromReg(uint8_t reg);
  void setEepromReg(uint8_t reg, uint8_t val);

};

extern RTC rtc;

#endif // __RTC_H__
// vim:cin:ai:sts=2 sw=2 ft=cpp
