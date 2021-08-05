#include "utils.h"
#include "Arduino.h"

uint8_t bin2bcd(uint8_t val) {
  return val + 6 * (val / 10);
}

uint8_t bcd2bin(uint8_t val) {
  return val - 6 * (val >> 4);
}

uint8_t time_to24h(uint8_t val) {
  bool pm = bitRead(val, 7);
  bitClear(val, 7);
  val = (pm) ? val + 12 : val;
  return (val < 23) ? val : 0;
}

uint8_t time_to12h(uint8_t val) {
  bool pm = false;
  if (val > 12) {
    val = 12;
    pm = true;
  }
  bitWrite(val, 7, pm);
  return val;
}

uint8_t get_year(int year) {
  int res = year % 100;
  return lowByte(res);
}
