#ifndef HOST_AVR_PGMSPACE_H
#define HOST_AVR_PGMSPACE_H
#include <stdint.h>
#include <string.h>
#define PROGMEM
#define PSTR(s) (s)
#define pgm_read_byte(p) (*(const uint8_t *)(p))
#define pgm_read_word(p) (*(const uint16_t *)(p))
#define pgm_read_ptr(p) (*(void * const *)(p))
#define memcpy_P memcpy
#define strlen_P strlen
#define strcpy_P strcpy
#endif
