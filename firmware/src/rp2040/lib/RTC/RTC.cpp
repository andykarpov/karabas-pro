/*
 Copyright (C) 2021-2023 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#include <SPI.h>
#include <RTClib.h>
#include <RTC.h>
#include <Arduino.h>
#include <Wire.h>

/****************************************************************************/

RTC::RTC(void)
{  
}

/****************************************************************************/

void RTC::begin(spi_cb act, osd_cb evt)
{
  delay(100);

  // init eeprom
  eeprom.setMemoryType(8);
  has_eeprom = eeprom.begin();

  // callbacks
  action = act;
  event = evt;

  rtc_clock.begin(&Wire);

  if (rtc_clock.lostPower()) {
    DateTime now = rtc_clock.now();
    if (now.isValid()) {
      rtc_clock.adjust(now); // this will flip the OSF bit also
    } else {
      rtc_clock.adjust(DateTime(F(__DATE__), F(__TIME__)));
    }
  }
  is_started = true;
}

bool RTC::started()
{
  return is_started;
}

void RTC::handle()
{
  unsigned long n = millis();

  // read time from rtc
  if (n - tr >= 500) {

    DateTime now = rtc_clock.now();
    if (now.isValid())

    rtc_year = get_year(now.year());
    rtc_month = now.month();
    rtc_day = now.day();
    rtc_week = now.dayOfTheWeek();

    rtc_hours = now.hour();
    rtc_minutes = now.minute();
    rtc_seconds = now.second();

    sendTime();

    // cb rtc
    event();

    tr = n;
  }

  /*if (n - to >= 100) {
    event();
    to = n;
  }*/
}

void RTC::save() {
  rtc_clock.adjust(DateTime(2000 + rtc_year, rtc_month, rtc_day, rtc_hours, rtc_minutes, rtc_seconds));
  // todo: set dow
}

void RTC::send(uint8_t reg, uint8_t data) {
  action(CMD_RTC, reg, data);
}

void RTC::sendTime() {
  //d_printf("Time: %02d:%02d:%02d %02d-%02d-%02d", rtc_hours, rtc_minutes, rtc_seconds, rtc_day, rtc_month, rtc_year); d_println();

  if (rtc_type == RTC_TYPE_DS1307) {
    // send ds1307 time registers
    send(0, bin2bcd(rtc_seconds));
    send(1, bin2bcd(rtc_minutes));
    send(2, bin2bcd(rtc_hours));
    send(3, bin2bcd(rtc_week));
    send(4, bin2bcd(rtc_day));
    send(5, bin2bcd(rtc_month));
    send(6, bin2bcd(rtc_year));
  } else {
    // send mc146818a time registers
    send(0, rtc_is_bcd ? bin2bcd(rtc_seconds) : rtc_seconds);
    send(2, rtc_is_bcd ? bin2bcd(rtc_minutes) : rtc_minutes);
    send(4, rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours) : rtc_hours) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours)) : time_to12h(rtc_hours)));
    send(6, rtc_is_bcd ? bin2bcd(rtc_week) : rtc_week);
    send(7, rtc_is_bcd ? bin2bcd(rtc_day) : rtc_day);
    send(8, rtc_is_bcd ? bin2bcd(rtc_month) : rtc_month);
    send(9, rtc_is_bcd ? bin2bcd(rtc_year) : rtc_year);
  }
}

void RTC::sendAll() {
  //d_println("RTC.sendAll()");

  // actualize time
  readAll();

  if (rtc_type == RTC_TYPE_DS1307) {
    // time
    sendTime();
    // control register is always 0 (sqw, prescalers, etc)
    send(7, 0);
    // eeprom registers
    for (int reg = 8; reg < 64; reg++) {
      // eeprom
      uint8_t data = getEepromReg(reg);
      //Serial.printf("<== rtc reg %02x = %02x", reg, data); Serial.println();
      send(reg, data);
    }
  } else {
    sendTime();
    // control registers and eeprom
    uint8_t data;
    for (int reg = 0; reg <= 255; reg++) {
      switch (reg) {
        // alarms
        case 1: data = rtc_is_bcd ? bin2bcd(rtc_seconds_alarm) : rtc_seconds_alarm; send(reg,data); break;
        case 3: data = rtc_is_bcd ? bin2bcd(rtc_minutes_alarm) : rtc_minutes_alarm; send(reg,data); break;
        case 5: data = rtc_is_24h ? (rtc_is_bcd ? bin2bcd(rtc_hours_alarm) : rtc_hours_alarm) : (rtc_is_bcd ? bin2bcd(time_to12h(rtc_hours_alarm)) : time_to12h(rtc_hours_alarm)); send(reg,data); break;
        // control registers
        case 0xA: data = getEepromReg(reg); bitClear(data, 7); send(reg,data); break;
        case 0xB: data = getEepromReg(reg); bitSet(data, 1); send(reg,data); break; // always 24h mode
        case 0xC: data = 0x0; send(reg,data); break;
        case 0xD: data = 0x80; send(reg,data); break; // 10000000
        // eeprom
        default: data = getEepromReg(reg); send(reg, data);
      }
      //d_printf("%02x ", data); 
      //if ((reg > 0) && ((reg+1) % 16 == 0)) d_println();
    }
  }

  
}

void RTC::setData(uint8_t addr, uint8_t data) {

  if (rtc_type == RTC_TYPE_DS1307) {

    // skip multiple writes for clock registers
    //if (rtc_last_write_reg == addr && rtc_last_write_data == data && addr <= 0x08) return;

    //Serial.printf("==> rtc reg %02x = %02x", addr, data); Serial.println();

      rtc_last_write_reg = addr;
      rtc_last_write_data = data;

        // addressable only 64 registers
        addr = bitClear(addr, 7);
        addr = bitClear(addr, 6);
        switch (addr) {
          case 0: rtc_seconds = bcd2bin(data); break;
          case 1: rtc_minutes = bcd2bin(data); break;
          case 2: data = bitClear(data, 7); data = bitClear(data, 6); rtc_hours = bcd2bin(data); break;
          case 3: rtc_week = bcd2bin(data); break;
          case 4: rtc_day = bcd2bin(data); break;
          case 5: rtc_month = bcd2bin(data); break;
          case 6: rtc_year = bcd2bin(data); break;
          case 7: data = bitClear(data,6); // control register
                  data = bitClear(data, 5); 
                  data = bitClear(data, 3); 
                  data = bitClear(data, 2);
                  setEepromReg(addr, data);
                  break;
          default: setEepromReg(addr, data); // eeprom

          if (addr <= 6) {
              DateTime now = DateTime(2000 + rtc_year, rtc_month, rtc_day, rtc_hours, rtc_minutes, rtc_seconds); 
              rtc_clock.adjust(now);
          }
      }

  } else {

    // skip multiple writes for clock registers
    if (rtc_last_write_reg == addr && rtc_last_write_data == data && addr <= 0xD) return;

    if (addr != 0x0C && addr != 0x0D && addr < 0x0A) {
      //Serial.printf("RTC %02x => %02x", addr, data); Serial.println();
    }

      rtc_last_write_reg = addr;
      rtc_last_write_data = data;
      uint8_t prev;

      switch (addr) {
        case 0: rtc_seconds = rtc_is_bcd ? bcd2bin(data) : data; break;
        case 1: rtc_seconds_alarm = rtc_is_bcd ? bcd2bin(data) : data; break;
        case 2: rtc_minutes = rtc_is_bcd ? bcd2bin(data) : data; break;
        case 3: rtc_minutes_alarm = rtc_is_bcd ? bcd2bin(data) : data;  break;
        case 4: rtc_hours = rtc_is_bcd ? bcd2bin(data) : data; break;
        case 5: rtc_hours_alarm = rtc_is_bcd ? bcd2bin(data) : data; break;
        case 6: rtc_week = rtc_is_bcd ? bcd2bin(data) : data; break;
        case 7: rtc_day = rtc_is_bcd ? bcd2bin(data) : data; break;
        case 8: rtc_month = rtc_is_bcd ? bcd2bin(data) : data; break;
        case 9: rtc_year = (rtc_is_bcd ? bcd2bin(data) : data); break;
        case 0xA: bitClear(data, 7); setEepromReg(addr, data); break;
        case 0xB: rtc_is_bcd = !bitRead(data, 2); 
                  rtc_is_24h = true; //bitRead(data, 1);  
                  bitSet(data, 1); // always 24-h format
                  bitClear(data, 7);
                  // tsconf maxi-clock uses regB too much
                  /*prev = getEepromReg(addr);
                  if (prev != data) {
                    setEepromReg(addr, data); 
                  }*/
                  break;
        case 0xC: // C and D are read-only registers
        case 0xD: break;
        default: setEepromReg(addr, data);
      }

      if (addr <= 9) {
          DateTime now = DateTime(2000 + rtc_year, rtc_month, rtc_day, rtc_hours, rtc_minutes, rtc_seconds); 
          rtc_clock.adjust(now);
      }
  }
}

void RTC::readAll() {

  DateTime now = rtc_clock.now();

  rtc_year = get_year(now.year());
  rtc_month = now.month();
  rtc_day = now.day();
  rtc_week = now.dayOfTheWeek();

  rtc_hours = now.hour();
  rtc_minutes = now.minute();
  rtc_seconds = now.second();

  // read is_bcd, is_24h
  uint8_t reg_b = getEepromReg(0xB);
  if (rtc_type == RTC_TYPE_DS1307) {
    rtc_is_bcd = true;
  } else {
    rtc_is_bcd = !bitRead(reg_b, 2);
  }
  rtc_is_24h = true; //bitRead(reg_b, 1);
}

uint8_t RTC::getWeek() {
  return rtc_week;
}

uint8_t RTC::getHour() {
  return rtc_hours;
}

uint8_t RTC::getMinute() {
  return rtc_minutes;
}

uint8_t RTC::getSecond() {
  return rtc_seconds;
}

uint8_t RTC::getDay() {
  return rtc_day;
}

uint8_t RTC::getMonth() {
  return rtc_month;
}

uint8_t RTC::getYear() {
  return rtc_year;
}

void RTC::setWeek(uint8_t val) {
  rtc_week = val;
}

void RTC::setHour(uint8_t val) {
  rtc_hours = val;
}

void RTC::setMinute(uint8_t val) {
  rtc_minutes = val;
}

void RTC::setSecond(uint8_t val) {
  rtc_seconds = val;
}

void RTC::setDay(uint8_t val) {
  rtc_day = val;
}

void RTC::setMonth(uint8_t val) {
  rtc_month = val;
}

void RTC::setYear(uint8_t val) {
  rtc_year = val;
}

void RTC::setEepromBank(uint8_t val) {
  eeprom_bank = val;
}

void RTC::setRtcType(uint8_t val) {
  rtc_type = val;
}

uint8_t RTC::getEepromReg(uint8_t reg) {
  if (has_eeprom && eeprom_bank < 4) {
    uint32_t addr = (uint32_t)eeprom_bank*256 + reg;
    uint8_t data = eeprom.read(addr);
    //Serial.printf("<== eeprom %08x = %02x", addr, data); Serial.println();
    return data;
  } else if (eeprom_bank >=4 && eeprom_bank < 255) {
    return core_eeprom_get(reg);
  } else {
    return 0xFF;
  }
}

void RTC::setEepromReg(uint8_t reg, uint8_t val) {
  //d_printf("Set eeprom reg %02x = %02x", reg, val); d_println();
  if (has_eeprom && eeprom_bank < 4) {
    uint32_t addr = (uint32_t)eeprom_bank*256 + reg;
    //Serial.printf("==> eeprom %08x = %02x", addr, val); Serial.println();
    eeprom.write(addr, val);
  } else if (eeprom_bank >= 4 && eeprom_bank < 255) {
    core_eeprom_set(reg, val);
  } else {
    // noting here, 255 means no eeprom allowed
  }
}

uint8_t RTC::bin2bcd(uint8_t val) {
  return val + 6 * (val / 10);
}

uint8_t RTC::bcd2bin(uint8_t val) {
  return val - 6 * (val >> 4);
}

uint8_t RTC::time_to24h(uint8_t val) {
  bool pm = bitRead(val, 7);
  bitClear(val, 7);
  val = (pm) ? val + 12 : val;
  return (val < 23) ? val : 0;
}

uint8_t RTC::time_to12h(uint8_t val) {
  bool pm = false;
  if (val > 12) {
    val = val - 12;
    pm = true;
  }
  //bitWrite(val, 7, pm);
  return val;
}

uint8_t RTC::get_year(int year) {
  int res = year % 100;
  return lowByte(res);
}



/****************************************************************************/

RTC rtc = RTC();

// vim:cin:ai:sts=2 sw=2 ft=cpp
