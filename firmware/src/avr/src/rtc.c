#include "rtc.h"
#include "hal.h"
#include "utils.h"
#include "keyboard.h"
#include "zxosd.h"

static bool s_is_started = false;

static int s_rtc_year = 2000;
static uint8_t s_rtc_month = 1;
static uint8_t s_rtc_day = 1;
static uint8_t s_rtc_hours = 0;
static uint8_t s_rtc_minutes = 0;
static uint8_t s_rtc_seconds = 0;

static uint8_t s_rtc_seconds_alarm = 0;
static uint8_t s_rtc_minutes_alarm = 0;
static uint8_t s_rtc_hours_alarm = 0;
static uint8_t s_rtc_week = 1;

static volatile int s_rtc_last_write_reg = 0;
static volatile uint8_t s_rtc_last_write_data = 0;

static bool s_rtc_init_done = false;
static bool s_rtc_is_bcd = false;
static bool s_rtc_is_24h = true;

static uint32_t s_tr = 0;

static inline void rtc_send_reg(uint8_t reg, uint8_t data)
{
  spi_send(CMD_RTC, reg, data);
}

void rtc_init(void)
{
  hal_twi_init();

  // Check if clock is running (bit 7 of reg 0 == 0)
  uint8_t sec_reg = 0;
  if (hal_twi_read_reg(RTC_ADDRESS, 0x00, &sec_reg)) {
    if (sec_reg & 0x80) {
      // Clock is halted: clear CH bit to start clock
      sec_reg &= 0x7F;
      hal_twi_write_reg(RTC_ADDRESS, 0x00, sec_reg);
    }
  }

  rtc_read_all();
  rtc_send_time();
  if (!s_rtc_init_done) {
    rtc_send_all();
  }
  s_is_started = true;
}

bool rtc_started(void)
{
  return s_is_started;
}

void rtc_read_all(void)
{
  uint8_t buf[7];
  if (hal_twi_read_buf(RTC_ADDRESS, 0x00, buf, 7)) {
    s_rtc_seconds = bcd2bin(buf[0] & 0x7F);
    s_rtc_minutes = bcd2bin(buf[1] & 0x7F);
    s_rtc_hours   = bcd2bin(buf[2] & 0x3F);
    s_rtc_week    = bcd2bin(buf[3] & 0x07);
    s_rtc_day     = bcd2bin(buf[4] & 0x3F);
    s_rtc_month   = bcd2bin(buf[5] & 0x1F);
    s_rtc_year    = 2000 + bcd2bin(buf[6]);
  }

  uint8_t reg_b = hal_eeprom_read(EEPROM_RTC_OFFSET + 0xB);
  s_rtc_is_bcd = !bitRead(reg_b, 2);
  s_rtc_is_24h = bitRead(reg_b, 1);
}

void rtc_handle(void)
{
  uint32_t n = millis();
  if (n - s_tr >= 500) {
    uint8_t buf[7];
    if (hal_twi_read_buf(RTC_ADDRESS, 0x00, buf, 7)) {
      s_rtc_seconds = bcd2bin(buf[0] & 0x7F);
      s_rtc_minutes = bcd2bin(buf[1] & 0x7F);
      s_rtc_hours   = bcd2bin(buf[2] & 0x3F);
      s_rtc_week    = bcd2bin(buf[3] & 0x07);
      s_rtc_day     = bcd2bin(buf[4] & 0x3F);
      s_rtc_month   = bcd2bin(buf[5] & 0x1F);
      s_rtc_year    = 2000 + bcd2bin(buf[6]);
    }

    rtc_send_time();

    if (keyboard_get_is_osd_overlay()) {
      zxosd_update_time();
    }

    s_tr = n;
  }
}

void rtc_save(void)
{
  uint8_t buf[7];
  buf[0] = bin2bcd(s_rtc_seconds) & 0x7F; // CH = 0 (running)
  buf[1] = bin2bcd(s_rtc_minutes);
  buf[2] = bin2bcd(s_rtc_hours) & 0x3F;   // 24h mode (bit 6 = 0)
  buf[3] = bin2bcd(s_rtc_week);
  buf[4] = bin2bcd(s_rtc_day);
  buf[5] = bin2bcd(s_rtc_month);
  buf[6] = bin2bcd(s_rtc_year % 100);
  hal_twi_write_buf(RTC_ADDRESS, 0x00, buf, 7);
}

void rtc_fix_invalid_time(void)
{
  if (s_rtc_day < 1 || s_rtc_day > 31) s_rtc_day = 1;
  if (s_rtc_month < 1 || s_rtc_month > 12) s_rtc_month = 1;
  if (s_rtc_year < 2000 || s_rtc_year > 4095) s_rtc_year = 2000;
  if (s_rtc_hours > 23) s_rtc_hours = 0;
  if (s_rtc_minutes > 59) s_rtc_minutes = 0;
  if (s_rtc_seconds > 59) s_rtc_seconds = 0;
  if (s_rtc_week < 1 || s_rtc_week > 7) s_rtc_week = 1;
  rtc_save();
}

void rtc_send_time(void)
{
  rtc_send_reg(0, s_rtc_is_bcd ? bin2bcd(s_rtc_seconds) : s_rtc_seconds);
  rtc_send_reg(2, s_rtc_is_bcd ? bin2bcd(s_rtc_minutes) : s_rtc_minutes);
  rtc_send_reg(4, s_rtc_is_24h ? (s_rtc_is_bcd ? bin2bcd(s_rtc_hours) : s_rtc_hours)
                               : (s_rtc_is_bcd ? bin2bcd(time_to12h(s_rtc_hours)) : time_to12h(s_rtc_hours)));
  rtc_send_reg(6, s_rtc_is_bcd ? bin2bcd(s_rtc_week) : s_rtc_week);
  rtc_send_reg(7, s_rtc_is_bcd ? bin2bcd(s_rtc_day) : s_rtc_day);
  rtc_send_reg(8, s_rtc_is_bcd ? bin2bcd(s_rtc_month) : s_rtc_month);
  rtc_send_reg(9, s_rtc_is_bcd ? bin2bcd(get_year(s_rtc_year)) : get_year(s_rtc_year));
}

void rtc_send_all(void)
{
  uint8_t data;
  for (int reg = 0; reg <= 255; reg++) {
    switch (reg) {
      case 0: rtc_send_reg(reg, s_rtc_is_bcd ? bin2bcd(s_rtc_seconds) : s_rtc_seconds); break;
      case 1: rtc_send_reg(reg, s_rtc_is_bcd ? bin2bcd(s_rtc_seconds_alarm) : s_rtc_seconds_alarm); break;
      case 2: rtc_send_reg(reg, s_rtc_is_bcd ? bin2bcd(s_rtc_minutes) : s_rtc_minutes); break;
      case 3: rtc_send_reg(reg, s_rtc_is_bcd ? bin2bcd(s_rtc_minutes_alarm) : s_rtc_minutes_alarm); break;
      case 4: rtc_send_reg(reg, s_rtc_is_24h ? (s_rtc_is_bcd ? bin2bcd(s_rtc_hours) : s_rtc_hours)
                                            : (s_rtc_is_bcd ? bin2bcd(time_to12h(s_rtc_hours)) : time_to12h(s_rtc_hours))); break;
      case 5: rtc_send_reg(reg, s_rtc_is_24h ? (s_rtc_is_bcd ? bin2bcd(s_rtc_hours_alarm) : s_rtc_hours_alarm)
                                            : (s_rtc_is_bcd ? bin2bcd(time_to12h(s_rtc_hours_alarm)) : time_to12h(s_rtc_hours_alarm))); break;
      case 6: rtc_send_reg(reg, s_rtc_is_bcd ? bin2bcd(s_rtc_week) : s_rtc_week); break;
      case 7: rtc_send_reg(reg, s_rtc_is_bcd ? bin2bcd(s_rtc_day) : s_rtc_day); break;
      case 8: rtc_send_reg(reg, s_rtc_is_bcd ? bin2bcd(s_rtc_month) : s_rtc_month); break;
      case 9: rtc_send_reg(reg, s_rtc_is_bcd ? bin2bcd(get_year(s_rtc_year)) : get_year(s_rtc_year)); break;
      case 0xA: data = hal_eeprom_read(EEPROM_RTC_OFFSET + reg); bitClear(data, 7); rtc_send_reg(reg, data); break;
      case 0xB: data = hal_eeprom_read(EEPROM_RTC_OFFSET + reg); rtc_send_reg(reg, data); break;
      case 0xC: rtc_send_reg(reg, 0x00); break;
      case 0xD: rtc_send_reg(reg, 0x80); break;
      default:  rtc_send_reg(reg, hal_eeprom_read(EEPROM_RTC_OFFSET + reg)); break;
    }
  }
}

void rtc_set_data(uint8_t addr, uint8_t data)
{
  if (s_rtc_last_write_reg == addr && s_rtc_last_write_data == data && addr <= 0xD) return;

  s_rtc_last_write_reg = addr;
  s_rtc_last_write_data = data;

  switch (addr) {
    case 0:
      s_rtc_seconds = s_rtc_is_bcd ? bcd2bin(data) : data;
      hal_twi_write_reg(RTC_ADDRESS, 0x00, bin2bcd(s_rtc_seconds) & 0x7F);
      break;
    case 1:
      s_rtc_seconds_alarm = s_rtc_is_bcd ? bcd2bin(data) : data;
      break;
    case 2:
      s_rtc_minutes = s_rtc_is_bcd ? bcd2bin(data) : data;
      hal_twi_write_reg(RTC_ADDRESS, 0x01, bin2bcd(s_rtc_minutes));
      break;
    case 3:
      s_rtc_minutes_alarm = s_rtc_is_bcd ? bcd2bin(data) : data;
      break;
    case 4:
      s_rtc_hours = s_rtc_is_bcd ? bcd2bin(data) : data;
      hal_twi_write_reg(RTC_ADDRESS, 0x02, bin2bcd(s_rtc_hours) & 0x3F);
      break;
    case 5:
      s_rtc_hours_alarm = s_rtc_is_bcd ? bcd2bin(data) : data;
      break;
    case 6:
      s_rtc_week = s_rtc_is_bcd ? bcd2bin(data) : data;
      hal_twi_write_reg(RTC_ADDRESS, 0x03, bin2bcd(s_rtc_week));
      break;
    case 7:
      s_rtc_day = s_rtc_is_bcd ? bcd2bin(data) : data;
      hal_twi_write_reg(RTC_ADDRESS, 0x04, bin2bcd(s_rtc_day));
      break;
    case 8:
      s_rtc_month = s_rtc_is_bcd ? bcd2bin(data) : data;
      hal_twi_write_reg(RTC_ADDRESS, 0x05, bin2bcd(s_rtc_month));
      break;
    case 9:
      s_rtc_year = 2000 + (s_rtc_is_bcd ? bcd2bin(data) : data);
      hal_twi_write_reg(RTC_ADDRESS, 0x06, bin2bcd(s_rtc_year % 100));
      break;
    case 0xA:
      bitClear(data, 7);
      hal_eeprom_update(EEPROM_RTC_OFFSET + addr, data);
      break;
    case 0xB:
      s_rtc_is_bcd = !bitRead(data, 2);
      s_rtc_is_24h = bitRead(data, 1);
      hal_eeprom_update(EEPROM_RTC_OFFSET + addr, data);
      break;
    case 0xC:
    case 0xD:
      break;
    default:
      hal_eeprom_update(EEPROM_RTC_OFFSET + addr, data);
      break;
  }
}

uint8_t rtc_get_week(void)   { return s_rtc_week; }
uint8_t rtc_get_hour(void)   { return s_rtc_hours; }
uint8_t rtc_get_minute(void) { return s_rtc_minutes; }
uint8_t rtc_get_second(void) { return s_rtc_seconds; }
uint8_t rtc_get_day(void)    { return s_rtc_day; }
uint8_t rtc_get_month(void)  { return s_rtc_month; }
int     rtc_get_year(void)   { return s_rtc_year; }

void rtc_set_week(uint8_t val)   { s_rtc_week = val; }
void rtc_set_hour(uint8_t val)   { s_rtc_hours = val; }
void rtc_set_minute(uint8_t val) { s_rtc_minutes = val; }
void rtc_set_second(uint8_t val) { s_rtc_seconds = val; }
void rtc_set_day(uint8_t val)    { s_rtc_day = val; }
void rtc_set_month(uint8_t val)  { s_rtc_month = val; }
void rtc_set_year(int val)       { s_rtc_year = val; }

bool rtc_get_init_done(void)     { return s_rtc_init_done; }
void rtc_set_init_done(bool val) { s_rtc_init_done = val; }

bool rtc_get_time_is_valid(void)
{
  return (s_rtc_hours <= 23 && s_rtc_minutes <= 59 && s_rtc_seconds <= 59);
}

bool rtc_get_date_is_valid(void)
{
  return (s_rtc_year < 9999 && s_rtc_month <= 12 && s_rtc_day <= 31 && s_rtc_week <= 7);
}
