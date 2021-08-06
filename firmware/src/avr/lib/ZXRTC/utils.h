#ifndef utils_h
#define utils_h

#include "Arduino.h"

uint8_t bin2bcd(uint8_t val);
uint8_t bcd2bin(uint8_t val);
uint8_t time_to24h(uint8_t val);
uint8_t time_to12h(uint8_t val);
uint8_t get_year(int year);

#endif
