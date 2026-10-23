#ifndef __PS2_KBD_H__
#define __PS2_KBD_H__

#include <stdint.h>
#include <stdbool.h>

#define PIN_KBD_CLK 2 // PD2 (INT0)
#define PIN_KBD_DAT 4 // PD4

// 16-bit status masks
#define PS2_BREAK    0x8000
#define PS2_SHIFT    0x4000
#define PS2_CTRL     0x2000
#define PS2_CAPS     0x1000
#define PS2_ALT      0x0800
#define PS2_ALT_GR   0x0400
#define PS2_GUI      0x0200
#define PS2_FUNCTION 0x0100

// Lock LED masks
#define PS2_LOCK_SCROLL 0x01
#define PS2_LOCK_NUM    0x02
#define PS2_LOCK_CAPS   0x04

// Key codes
#define PS2_KEY_NUM         0x01
#define PS2_KEY_SCROLL      0x02
#define PS2_KEY_CAPS        0x03
#define PS2_KEY_PRTSCR      0x04
#define PS2_KEY_PAUSE       0x05
#define PS2_KEY_L_SHIFT     0x06
#define PS2_KEY_R_SHIFT     0x07
#define PS2_KEY_L_CTRL      0x08
#define PS2_KEY_R_CTRL      0x09
#define PS2_KEY_L_ALT       0x0A
#define PS2_KEY_R_ALT       0x0B
#define PS2_KEY_L_GUI       0x0C
#define PS2_KEY_R_GUI       0x0D
#define PS2_KEY_MENU        0x0E
#define PS2_KEY_BREAK       0x0F
#define PS2_KEY_SYSRQ       0x10
#define PS2_KEY_HOME        0x11
#define PS2_KEY_END         0x12
#define PS2_KEY_PGUP        0x13
#define PS2_KEY_PGDN        0x14
#define PS2_KEY_L_ARROW     0x15
#define PS2_KEY_R_ARROW     0x16
#define PS2_KEY_UP_ARROW    0x17
#define PS2_KEY_DN_ARROW    0x18
#define PS2_KEY_INSERT      0x19
#define PS2_KEY_DELETE      0x1A
#define PS2_KEY_ESC         0x1B
#define PS2_KEY_BS          0x1C
#define PS2_KEY_TAB         0x1D
#define PS2_KEY_ENTER       0x1E
#define PS2_KEY_SPACE       0x1F
#define PS2_KEY_KP0         0x20
#define PS2_KEY_KP1         0x21
#define PS2_KEY_KP2         0x22
#define PS2_KEY_KP3         0x23
#define PS2_KEY_KP4         0x24
#define PS2_KEY_KP5         0x25
#define PS2_KEY_KP6         0x26
#define PS2_KEY_KP7         0x27
#define PS2_KEY_KP8         0x28
#define PS2_KEY_KP9         0x29
#define PS2_KEY_KP_DOT      0x2A
#define PS2_KEY_KP_ENTER    0x2B
#define PS2_KEY_KP_PLUS     0x2C
#define PS2_KEY_KP_MINUS    0x2D
#define PS2_KEY_KP_TIMES    0x2E
#define PS2_KEY_KP_DIV      0x2F
#define PS2_KEY_0           0x30
#define PS2_KEY_1           0x31
#define PS2_KEY_2           0x32
#define PS2_KEY_3           0x33
#define PS2_KEY_4           0x34
#define PS2_KEY_5           0x35
#define PS2_KEY_6           0x36
#define PS2_KEY_7           0x37
#define PS2_KEY_8           0x38
#define PS2_KEY_9           0x39
#define PS2_KEY_APOS        0x3A
#define PS2_KEY_COMMA       0x3B
#define PS2_KEY_MINUS       0x3C
#define PS2_KEY_DOT         0x3D
#define PS2_KEY_DIV         0x3E
#define PS2_KEY_KP_EQUAL    0x3F
#define PS2_KEY_SINGLE      0x40
#define PS2_KEY_A           0x41
#define PS2_KEY_B           0x42
#define PS2_KEY_C           0x43
#define PS2_KEY_D           0x44
#define PS2_KEY_E           0x45
#define PS2_KEY_F           0x46
#define PS2_KEY_G           0x47
#define PS2_KEY_H           0x48
#define PS2_KEY_I           0x49
#define PS2_KEY_J           0x4A
#define PS2_KEY_K           0x4B
#define PS2_KEY_L           0x4C
#define PS2_KEY_M           0x4D
#define PS2_KEY_N           0x4E
#define PS2_KEY_O           0x4F
#define PS2_KEY_P           0x50
#define PS2_KEY_Q           0x51
#define PS2_KEY_R           0x52
#define PS2_KEY_S           0x53
#define PS2_KEY_T           0x54
#define PS2_KEY_U           0x55
#define PS2_KEY_V           0x56
#define PS2_KEY_W           0x57
#define PS2_KEY_X           0x58
#define PS2_KEY_Y           0x59
#define PS2_KEY_Z           0x5A
#define PS2_KEY_SEMI        0x5B
#define PS2_KEY_BACKSLASH   0x5C
#define PS2_KEY_EQUAL       0x5D
#define PS2_KEY_OPEN_SQ     0x5E
#define PS2_KEY_CLOSE_SQ    0x5F
#define PS2_KEY_F1          0x61
#define PS2_KEY_F2          0x62
#define PS2_KEY_F3          0x63
#define PS2_KEY_F4          0x64
#define PS2_KEY_F5          0x65
#define PS2_KEY_F6          0x66
#define PS2_KEY_F7          0x67
#define PS2_KEY_F8          0x68
#define PS2_KEY_F9          0x69
#define PS2_KEY_F10         0x6A
#define PS2_KEY_F11         0x6B
#define PS2_KEY_F12         0x6C
#define PS2_KEY_ECHO        0xEE
#define PS2_KEY_BAT         0xAA

#ifdef __cplusplus
extern "C" {
#endif

void ps2_kbd_init(void);
void ps2_kbd_echo(void);
void ps2_kbd_set_lock(uint8_t leds);
bool ps2_kbd_available(void);
uint16_t ps2_kbd_read(void);
bool ps2_kbd_check_tx_timeout(void);
bool ps2_kbd_is_tx_busy(void);

#ifdef __cplusplus
}
#endif

#endif // __PS2_KBD_H__
