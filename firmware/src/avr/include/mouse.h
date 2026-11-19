#ifndef __MOUSE_H__
#define __MOUSE_H__

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void mouse_init(void);
bool mouse_started(void);
void mouse_handle(bool menu);

uint8_t mouse_get_x(void);
uint8_t mouse_get_y(void);
uint8_t mouse_get_z(void);

bool mouse_get_swap(void);
void mouse_set_swap(bool val);
bool mouse_inject(uint8_t status, int8_t x, int8_t y); // AT+KARABAS= (at_cmd.c)

#ifdef __cplusplus
}
#endif

#endif // __MOUSE_H__
