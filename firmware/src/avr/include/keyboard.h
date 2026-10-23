#ifndef __KEYBOARD_H__
#define __KEYBOARD_H__

#include <stdint.h>
#include <stdbool.h>

#define ZX_MATRIX_FULL_SIZE 80
#define ZX_MATRIX_SIZE      41

#define ZX_K_CS  0
#define ZX_K_A   1
#define ZX_K_Q   2
#define ZX_K_1   3
#define ZX_K_0   4
#define ZX_K_P   5
#define ZX_K_ENT 6
#define ZX_K_SP  7
#define ZX_K_Z   8
#define ZX_K_S   9
#define ZX_K_W   10
#define ZX_K_2   11
#define ZX_K_9   12
#define ZX_K_O   13
#define ZX_K_L   14
#define ZX_K_SS  15
#define ZX_K_X   16
#define ZX_K_D   17
#define ZX_K_E   18
#define ZX_K_3   19
#define ZX_K_8   20
#define ZX_K_I   21
#define ZX_K_K   22
#define ZX_K_M   23
#define ZX_K_C   24
#define ZX_K_F   25
#define ZX_K_R   26
#define ZX_K_4   27
#define ZX_K_7   28
#define ZX_K_U   29
#define ZX_K_J   30
#define ZX_K_N   31
#define ZX_K_V   32
#define ZX_K_G   33
#define ZX_K_T   34
#define ZX_K_5   35
#define ZX_K_6   36
#define ZX_K_Y   37
#define ZX_K_H   38
#define ZX_K_B   39

// Fn keys ext bit
#define ZX_K_BIT6  40

// special signals
#define ZX_K_RESET  41
#define ZX_K_TURBO  42
#define ZX_K_MAGICK 43
#define ZX_K_IS_UP 44

// WAIT signal
#define ZX_K_WAIT 45

// Soft Switches
#define ZX_K_SW1 46
#define ZX_K_SW2 47

#define ZX_K_SCANCODE0 48
#define ZX_K_SCANCODE1 49
#define ZX_K_SCANCODE2 50
#define ZX_K_SCANCODE3 51
#define ZX_K_SCANCODE4 52
#define ZX_K_SCANCODE5 53
#define ZX_K_SCANCODE6 54
#define ZX_K_SCANCODE7 55
#define ZX_K_SCANCODE8 56

#define ZX_K_SW3 57
#define ZX_K_SW4 58
#define ZX_K_SW5 59
#define ZX_K_KBD_MODE 60

#define ZX_K_SW6 61
#define ZX_K_SW7 62
#define ZX_K_SW8 63

#define ZX_K_SW9 64
#define ZX_K_SW10 65

#define ZX_K_JOY_TYPE 66
#define ZX_K_OSD_OVERLAY 67

#define ZX_K_TURBO2 68
#define ZX_K_SCREEN_MODE0 69
#define ZX_K_SCREEN_MODE1 70

#define ZX_K_OSD_POPUP 71

#define ZX_K_JOY_MODE0 72
#define ZX_K_JOY_MODE1 73
#define ZX_K_JOY_MODE2 74

#define ZX_K_DIVMMC 75
#define ZX_K_NEMOIDE 76

#define ZX_K_RESERVED2 77
#define ZX_K_RESERVED3 78
#define ZX_K_RESERVED4 79

#define CMD_KEYBOARD 0x01
#define CMD_KBD      0x01

#define EEPROM_TURBO_ADDRESS 0x00
#define EEPROM_MODE_ADDRESS 0x01
#define EEPROM_SW1_ADDRESS 0x02
#define EEPROM_SW2_ADDRESS 0x03
#define EEPROM_SW3_ADDRESS 0x04
#define EEPROM_SW4_ADDRESS 0x05
#define EEPROM_SW5_ADDRESS 0x06
#define EEPROM_SW6_ADDRESS 0x07
#define EEPROM_SW7_ADDRESS 0x08
#define EEPROM_SW8_ADDRESS 0x09
#define EEPROM_SW9_ADDRESS 0x0A
#define EEPROM_SW10_ADDRESS 0x0B
#define EEPROM_MOUSE_SWAP_ADDRESS 0x0C
#define EEPROM_JOY_TYPE_ADDRESS 0x0D
#define EEPROM_SCREEN_MODE_ADDRESS 0x0E
#define EEPROM_JOY_MODE_ADDRESS 0x0F
#define EEPROM_DIVMMC_ADDRESS 0x10
#define EEPROM_NEMOIDE_ADDRESS 0x11

#define EEPROM_VALUE_TRUE 10
#define EEPROM_VALUE_FALSE 20

// Event types
#define EVENT_OSD_OVERLAY       0
#define EVENT_OSD_SCANCODE      1
#define EVENT_OSD_JOYSTICK      2
#define EVENT_OSD_SWAP_AB       3
#define EVENT_OSD_ROMBANK       4
#define EVENT_OSD_TURBOFDC      5
#define EVENT_OSD_COVOX         6
#define EVENT_OSD_STEREO        7
#define EVENT_OSD_SSG           8
#define EVENT_OSD_VIDEO         9
#define EVENT_OSD_VSYNC         10
#define EVENT_OSD_KEYBOARD_TYPE 12
#define EVENT_OSD_PAUSE         13
#define EVENT_OSD_TURBO         14
#define EVENT_OSD_SCREEN_MODE   15
#define EVENT_OSD_POPUP         16
#define EVENT_OSD_JOYSTICK_MODE 17
#define EVENT_OSD_DIVMMC        18
#define EVENT_OSD_NEMOIDE       19

#ifdef __cplusplus
extern "C" {
#endif

void keyboard_init(bool send_echo);
bool keyboard_started(void);
bool keyboard_handle(void);
void keyboard_apply_joy(uint8_t data);

void keyboard_set_key(uint8_t key, bool pressed);
bool keyboard_get_key(uint8_t key);
void keyboard_clear(int clear_size);
void keyboard_transmit(void);

void keyboard_do_special(uint8_t key1, uint8_t key2);
void keyboard_do_reset(void);
void keyboard_do_full_reset(void);
void keyboard_do_magic(void);
void keyboard_do_caps(void);
void keyboard_do_pause(void);

void keyboard_toggle_osd_overlay(void);
void keyboard_set_osd_popup(bool val);
void keyboard_set_rombank(uint8_t bank);
void keyboard_toggle_turbofdc(void);
void keyboard_toggle_covox(void);
void keyboard_toggle_stereo(uint8_t stereo);
void keyboard_toggle_ssg(void);
void keyboard_toggle_video(void);
void keyboard_toggle_vsync(void);
void keyboard_set_turbo(uint8_t val);
void keyboard_set_max_turbo(uint8_t val);
void keyboard_toggle_swap_ab(void);
void keyboard_toggle_joy_type(void);
void keyboard_toggle_keyboard_type(void);
void keyboard_set_mouse_swap(bool val);
bool keyboard_get_mouse_swap(void);
void keyboard_set_screen_mode(uint8_t val);
void keyboard_set_joy_mode(uint8_t val);
void keyboard_set_divmmc(bool val);
void keyboard_toggle_divmmc(void);
bool keyboard_get_divmmc(void);
void keyboard_set_nemoide(bool val);
void keyboard_toggle_nemoide(void);
bool keyboard_get_nemoide(void);

bool keyboard_get_is_osd_overlay(void);
bool keyboard_get_is_osd_popup(void);
uint8_t keyboard_get_rombank(void);
bool keyboard_get_turbofdc(void);
bool keyboard_get_covox(void);
uint8_t keyboard_get_stereo(void);
bool keyboard_get_ssg(void);
bool keyboard_get_video(void);
bool keyboard_get_vsync(void);
uint8_t keyboard_get_turbo(void);
uint8_t keyboard_get_max_turbo(void);
bool keyboard_get_swap_ab(void);
bool keyboard_get_joy_type(void);
bool keyboard_get_keyboard_type(void);
bool keyboard_get_pause(void);
uint8_t keyboard_get_screen_mode(void);
uint8_t keyboard_get_max_screen_mode(void);
uint8_t keyboard_get_joy_mode(void);

bool keyboard_get_is_cursor_up(void);
bool keyboard_get_is_cursor_down(void);
bool keyboard_get_is_cursor_left(void);
bool keyboard_get_is_cursor_right(void);
bool keyboard_get_is_enter(void);
bool keyboard_get_is_escape(void);
bool keyboard_get_is_menu(void);
void keyboard_reset_osd_controls(void);

#ifdef __cplusplus
}
#endif

#endif // __KEYBOARD_H__
