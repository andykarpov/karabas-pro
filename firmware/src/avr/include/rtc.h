#ifndef __RTC_H__
#define __RTC_H__

#include <stdint.h>
#include <stdbool.h>

#define RTC_ADDRESS 0x68
#define EEPROM_RTC_OFFSET 0x20
#define CMD_RTC_INIT_REQ 0xFC
#define CMD_RTC 0xFA

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*rtc_event_cb)(void);

void rtc_init(rtc_event_cb on_time_cb);
bool rtc_started(void);
void rtc_handle(void);

void rtc_save(void);
void rtc_fix_invalid_time(void);
void rtc_send_time(void);
void rtc_send_all(void);
void rtc_set_data(uint8_t addr, uint8_t data);
void rtc_read_all(void);

uint8_t rtc_get_week(void);
uint8_t rtc_get_hour(void);
uint8_t rtc_get_minute(void);
uint8_t rtc_get_second(void);
uint8_t rtc_get_day(void);
uint8_t rtc_get_month(void);
int rtc_get_year(void);

void rtc_set_week(uint8_t val);
void rtc_set_hour(uint8_t val);
void rtc_set_minute(uint8_t val);
void rtc_set_second(uint8_t val);
void rtc_set_day(uint8_t val);
void rtc_set_month(uint8_t val);
void rtc_set_year(int val);

bool rtc_get_init_done(void);
void rtc_set_init_done(bool val);
bool rtc_get_time_is_valid(void);
bool rtc_get_date_is_valid(void);

#ifdef __cplusplus
}
#endif

#endif // __RTC_H__
