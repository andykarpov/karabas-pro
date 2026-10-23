#ifndef __UTILS_H__
#define __UTILS_H__

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

uint8_t bin2bcd(uint8_t val);
uint8_t bcd2bin(uint8_t val);
uint8_t time_to24h(uint8_t val);
uint8_t time_to12h(uint8_t val);
uint8_t get_year(int year);

#ifdef __cplusplus
}
#endif

#endif // __UTILS_H__
