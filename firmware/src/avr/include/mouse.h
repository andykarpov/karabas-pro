#ifndef __MOUSE_H__
#define __MOUSE_H__

#include <stdint.h>
#include <stdbool.h>

#define CMD_MOUSE 0x0A
#define ADDR_MOUSE_X 0x0A
#define ADDR_MOUSE_Y 0x0B
#define ADDR_MOUSE_Z 0x0C

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

#ifdef __cplusplus
}
#endif

#endif // __MOUSE_H__
