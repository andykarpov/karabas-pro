/*
* DS1307.cpp - Lightweight implementation using hal_twi
*/

#include "RTC.h"
#include "hal.h"

uint8_t DS1307::bin2bcd(uint8_t val)
{
  return val + 6 * (val / 10);
}

uint8_t DS1307::bcd2bin(uint8_t val)
{
  return val - 6 * (val >> 4);
}

bool DS1307::begin()
{
  hal_twi_init();
  uint8_t dummy = 0;
  return hal_twi_read_reg(DS1307_ADDR, 0x00, &dummy);
}

bool DS1307::isRunning(void)
{
  uint8_t data = 0;
  if (!hal_twi_read_reg(DS1307_ADDR, 0x00, &data)) return false;
  return !(data & 0x80); // bit 7 = CH (Clock Halt, 1 = stopped)
}

void DS1307::startClock(void)
{
  uint8_t data = 0;
  if (hal_twi_read_reg(DS1307_ADDR, 0x00, &data)) {
    data &= ~0x80;
    hal_twi_write_reg(DS1307_ADDR, 0x00, data);
  }
}

void DS1307::stopClock(void)
{
  uint8_t data = 0;
  if (hal_twi_read_reg(DS1307_ADDR, 0x00, &data)) {
    data |= 0x80;
    hal_twi_write_reg(DS1307_ADDR, 0x00, data);
  }
}

void DS1307::setHourMode(uint8_t h_mode)
{
  uint8_t data = 0;
  if (hal_twi_read_reg(DS1307_ADDR, 0x02, &data)) {
    if (h_mode) data |= (1 << 6); else data &= ~(1 << 6);
    hal_twi_write_reg(DS1307_ADDR, 0x02, data);
  }
}

uint8_t DS1307::getHourMode()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x02, &data);
  return (data >> 6) & 1;
}

void DS1307::setMeridiem(uint8_t meridiem)
{
  uint8_t data = 0;
  if (getHourMode() == CLOCK_H12) {
    if (hal_twi_read_reg(DS1307_ADDR, 0x02, &data)) {
      if (meridiem == HOUR_PM) data |= (1 << 5); else data &= ~(1 << 5);
      hal_twi_write_reg(DS1307_ADDR, 0x02, data);
    }
  }
}

uint8_t DS1307::getMeridiem()
{
  uint8_t data = 0;
  if (getHourMode() == CLOCK_H12) {
    hal_twi_read_reg(DS1307_ADDR, 0x02, &data);
    return (data >> 5) & 1;
  }
  return HOUR_24;
}

void DS1307::setSeconds(uint8_t second)
{
  uint8_t ch = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x00, &ch);
  ch &= 0x80;
  hal_twi_write_reg(DS1307_ADDR, 0x00, bin2bcd(second) | ch);
}

uint8_t DS1307::getSeconds()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x00, &data);
  return bcd2bin(data & 0x7F);
}

void DS1307::setMinutes(uint8_t minute)
{
  hal_twi_write_reg(DS1307_ADDR, 0x01, bin2bcd(minute));
}

uint8_t DS1307::getMinutes()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x01, &data);
  return bcd2bin(data & 0x7F);
}

void DS1307::setHours(uint8_t hour)
{
  hal_twi_write_reg(DS1307_ADDR, 0x02, bin2bcd(hour));
}

uint8_t DS1307::getHours()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x02, &data);
  return bcd2bin(data & 0x3F);
}

void DS1307::setWeek(uint8_t week)
{
  hal_twi_write_reg(DS1307_ADDR, 0x03, bin2bcd(week));
}

uint8_t DS1307::getWeek()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x03, &data);
  return bcd2bin(data & 0x07);
}

void DS1307::setDay(uint8_t day)
{
  hal_twi_write_reg(DS1307_ADDR, 0x04, bin2bcd(day));
}

uint8_t DS1307::getDay()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x04, &data);
  return bcd2bin(data & 0x3F);
}

void DS1307::setMonth(uint8_t month)
{
  hal_twi_write_reg(DS1307_ADDR, 0x05, bin2bcd(month));
}

uint8_t DS1307::getMonth()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x05, &data);
  return bcd2bin(data & 0x1F);
}

void DS1307::setYear(uint16_t year)
{
  uint8_t y = year % 100;
  hal_twi_write_reg(DS1307_ADDR, 0x06, bin2bcd(y));
}

uint16_t DS1307::getYear()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x06, &data);
  return 2000 + bcd2bin(data);
}

void DS1307::setDate(uint8_t day, uint8_t month, uint16_t year)
{
  setDay(day);
  setMonth(month);
  setYear(year);
}

void DS1307::setTime(uint8_t hour, uint8_t minute, uint8_t second)
{
  setHours(hour);
  setMinutes(minute);
  setSeconds(second);
}

void DS1307::setOutPin(uint8_t mode)
{
  uint8_t val = 0;
  switch (mode) {
    case HIGH:     val = (1 << 7); break;
    case LOW:      val = 0; break;
    case SQW001Hz: val = (1 << 4) | 0x00; break;
    case SQW04kHz: val = (1 << 4) | 0x01; break;
    case SQW08kHz: val = (1 << 4) | 0x02; break;
    case SQW32kHz: val = (1 << 4) | 0x03; break;
  }
  hal_twi_write_reg(DS1307_ADDR, 0x07, val);
}

bool DS1307::isOutPinEnabled()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x07, &data);
  return (data >> 7) & 1;
}

bool DS1307::isSqweEnabled()
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x07, &data);
  return (data >> 4) & 1;
}

/****************************************************************************/
// NVRAM Implementation
/****************************************************************************/

bool NVRAM::begin()
{
  return true;
}

uint8_t NVRAM::read(uint8_t address)
{
  uint8_t data = 0;
  hal_twi_read_reg(DS1307_ADDR, 0x08 + address, &data);
  return data;
}

void NVRAM::write(uint8_t address, uint8_t value)
{
  hal_twi_write_reg(DS1307_ADDR, 0x08 + address, value);
}

void NVRAM::read(uint8_t address, uint8_t *buf, uint8_t size)
{
  hal_twi_read_buf(DS1307_ADDR, 0x08 + address, buf, size);
}

void NVRAM::write(uint8_t address, uint8_t *buf, uint8_t size)
{
  hal_twi_write_buf(DS1307_ADDR, 0x08 + address, buf, size);
}
