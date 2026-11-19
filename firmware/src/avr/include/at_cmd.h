#ifndef __AT_CMD_H__
#define __AT_CMD_H__

#include <stdint.h>
#include <stdbool.h>

// AT+KARABAS= commands on the UART (docs/AT_KARABAS.md): keys, text, mouse, joystick, menu items
void at_handle(void);                    // once per pass of the main loop
void at_on_build(uint8_t pos, uint8_t c); // the build number of the FPGA (link_on_build)

#endif // __AT_CMD_H__
