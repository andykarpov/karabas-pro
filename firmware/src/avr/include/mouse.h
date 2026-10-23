#ifndef __MOUSE_H__
#define __MOUSE_H__

#include <stdint.h>
#include <stdbool.h>

#define CMD_MOUSE 0x0A
#define ADDR_MOUSE_X 0x0A
#define ADDR_MOUSE_Y 0x0B
#define ADDR_MOUSE_Z 0x0C

#define EVENT_OSD_MOUSE_SWAPPED 0
#define EVENT_OSD_MOUSE_DATA    1

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*mouse_event_cb)(uint8_t evt);

void mouse_init(mouse_event_cb on_mouse_cb);
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
