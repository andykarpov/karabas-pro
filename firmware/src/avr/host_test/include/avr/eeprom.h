#ifndef HOST_AVR_EEPROM_H
#define HOST_AVR_EEPROM_H
#include <stdint.h>
uint8_t eeprom_read_byte(const uint8_t *addr);
void eeprom_update_byte(uint8_t *addr, uint8_t val);
#endif
