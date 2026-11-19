#ifndef __JOYSTICK_H__
#define __JOYSTICK_H__

#include <stdint.h>
#include <stdbool.h>

#define ZX_JOY_FIRE  0
#define ZX_JOY_FIRE2 1
#define ZX_JOY_UP    2
#define ZX_JOY_DOWN  3
#define ZX_JOY_LEFT  4
#define ZX_JOY_RIGHT 5
#define ZX_JOY_A     6
#define ZX_JOY_B     7

#ifdef __cplusplus
extern "C" {
#endif

void joystick_init(void);
bool joystick_started(void);
void joystick_handle(bool joy_type);
uint8_t joystick_get_state(void);
void joystick_set_at_buttons(uint16_t buttons); // AT+KARABAS=pad: LJ_* bits held on top

#ifdef __cplusplus
}
#endif

#endif // __JOYSTICK_H__
