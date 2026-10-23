#ifndef __ZXKEYBOARD_MAP_H__
#define __ZXKEYBOARD_MAP_H__

#include <stdint.h>
#include <avr/pgmspace.h>
#include <PS2KeyAdvanced.h>
#include "ZXKeyboard.h"

enum KeyType : uint8_t {
  KT_NONE = 0,
  KT_DIRECT,          // Single matrix key: matrix[zx1] = !is_up (e.g. A-Z, 0-9, Space, Enter)
  KT_COMBO,           // Two matrix keys: matrix[zx1] = !is_up, matrix[zx2] = !is_up (e.g. F1-F12, KP*, KP-, KP+)
  KT_CURSOR,          // Cursor arrow: CS + zx1, sendCS on press, processCapsedKey
  KT_SHIFT_PAIR,      // SS + (is_shift ? zx2 : zx1), clears both on release
  KT_MACRO_BRACKET,   // [ ] \ brackets: Profi -> SS + (shift?zx2:zx1); ZX -> sendMacros(code, shift?zx2:zx1)
  KT_SINGLE_QUOTE,    // ` ~ : shift -> sendMacros(code, ZX_K_A); unshift -> SS + ZX_K_X
  KT_MODIFIER_SHIFT,  // Shift: profi_mode ? SS : CS; is_shift = !is_up
  KT_MODIFIER_CTRL,   // Ctrl: profi_mode ? CS : SS; is_ctrl = !is_up
  KT_MODIFIER_ALT,    // Alt (L: zx1=ENT, R: zx1=SP): SS + (profi ? zx1 : CS)
  KT_MODIFIER_WIN,    // Win/GUI: is_win = !is_up
  KT_MODIFIER_MENU,   // Menu: is_menu = !is_up
  KT_EDIT_ESC,        // ESC: Profi -> CS + 1; ZX -> CS + SP
  KT_EDIT_BS,         // Backspace: CS + 0
  KT_EDIT_DEL,        // Delete: Profi -> P + BIT6; ZX -> SS + C
  KT_EDIT_INS,        // Insert: Profi -> O + BIT6; ZX -> SS + A
  KT_EDIT_TAB,        // Tab: CS + I
  KT_EDIT_CAPS,       // CapsLock: CS + SS
  KT_EDIT_PAGE,       // PgUp (zx1=M, zx2=3), PgDn (zx1=N, zx2=4): Profi -> zx1+BIT6; ZX -> CS+zx2
  KT_EDIT_HOME_END,   // Home (K+BIT6), End (L+BIT6): Profi only
  KT_SPECIAL_PAUSE,   // Pause -> doPause()
  KT_SPECIAL_PRTSCR,  // PrtScr -> toggleKeyboardType()
};

struct KeyDesc {
  uint8_t type;
  uint8_t zx1;
  uint8_t zx2;
};

enum HotkeyAction : uint8_t {
  HK_NONE = 0,
  HK_OSD_OVERLAY,    // ESC
  HK_SWAP_AB,        // Tab
  HK_DIVMMC,         // D
  HK_JOYSTICK,       // J
  HK_JOYSTICK_MODE,  // M
  HK_NEMOIDE,        // N
  HK_SCREEN_MODE,    // V
  HK_ROMBANK_0,      // F1
  HK_ROMBANK_1,      // F2
  HK_ROMBANK_2,      // F3
  HK_ROMBANK_3,      // F4
  HK_TURBOFDC,       // F5
  HK_COVOX,          // F6
  HK_STEREO,         // F7
  HK_SSG,            // F8
  HK_VIDEO,          // F9
  HK_VSYNC,          // F10
  HK_TURBO,          // F11
  HK_MAGIC,          // F12
};

struct HotkeyEntry {
  uint8_t code;
  uint8_t action;
};

// 20 hotkey definitions when modifier (Menu / Win / Ctrl+Alt) is held
static const HotkeyEntry s_hotkey_map[] PROGMEM = {
  { PS2_KEY_ESC,     HK_OSD_OVERLAY },
  { PS2_KEY_TAB,     HK_SWAP_AB },
  { PS2_KEY_D,       HK_DIVMMC },
  { PS2_KEY_J,       HK_JOYSTICK },
  { PS2_KEY_M,       HK_JOYSTICK_MODE },
  { PS2_KEY_N,       HK_NEMOIDE },
  { PS2_KEY_V,       HK_SCREEN_MODE },
  { PS2_KEY_F1,      HK_ROMBANK_0 },
  { PS2_KEY_F2,      HK_ROMBANK_1 },
  { PS2_KEY_F3,      HK_ROMBANK_2 },
  { PS2_KEY_F4,      HK_ROMBANK_3 },
  { PS2_KEY_F5,      HK_TURBOFDC },
  { PS2_KEY_F6,      HK_COVOX },
  { PS2_KEY_F7,      HK_STEREO },
  { PS2_KEY_F8,      HK_SSG },
  { PS2_KEY_F9,      HK_VIDEO },
  { PS2_KEY_F10,     HK_VSYNC },
  { PS2_KEY_F11,     HK_TURBO },
  { PS2_KEY_F12,     HK_MAGIC },
};

#define HOTKEY_COUNT (sizeof(s_hotkey_map) / sizeof(s_hotkey_map[0]))

// Direct indexed table for PS/2 key codes 0x00 .. 0x6C (109 entries)
static const KeyDesc s_key_map[109] PROGMEM = {
  /* 0x00 None         */ { KT_NONE, 0, 0 },
  /* 0x01 NUM          */ { KT_NONE, 0, 0 },
  /* 0x02 SCROLL       */ { KT_NONE, 0, 0 },
  /* 0x03 CAPS         */ { KT_EDIT_CAPS, ZX_K_CS, ZX_K_SS },
  /* 0x04 PRTSCR       */ { KT_SPECIAL_PRTSCR, 0, 0 },
  /* 0x05 PAUSE        */ { KT_SPECIAL_PAUSE, 0, 0 },
  /* 0x06 L_SHIFT      */ { KT_MODIFIER_SHIFT, 0, 0 },
  /* 0x07 R_SHIFT      */ { KT_MODIFIER_SHIFT, 0, 0 },
  /* 0x08 L_CTRL       */ { KT_MODIFIER_CTRL, 0, 0 },
  /* 0x09 R_CTRL       */ { KT_MODIFIER_CTRL, 0, 0 },
  /* 0x0A L_ALT        */ { KT_MODIFIER_ALT, ZX_K_ENT, 0 },
  /* 0x0B R_ALT        */ { KT_MODIFIER_ALT, ZX_K_SP, 0 },
  /* 0x0C L_GUI        */ { KT_MODIFIER_WIN, 0, 0 },
  /* 0x0D R_GUI        */ { KT_MODIFIER_WIN, 0, 0 },
  /* 0x0E MENU         */ { KT_MODIFIER_MENU, 0, 0 },
  /* 0x0F BREAK        */ { KT_NONE, 0, 0 },
  /* 0x10 SYSRQ        */ { KT_NONE, 0, 0 },
  /* 0x11 HOME         */ { KT_EDIT_HOME_END, ZX_K_K, ZX_K_BIT6 },
  /* 0x12 END          */ { KT_EDIT_HOME_END, ZX_K_L, ZX_K_BIT6 },
  /* 0x13 PGUP         */ { KT_EDIT_PAGE, ZX_K_M, ZX_K_3 },
  /* 0x14 PGDN         */ { KT_EDIT_PAGE, ZX_K_N, ZX_K_4 },
  /* 0x15 L_ARROW      */ { KT_CURSOR, ZX_K_5, 0 },
  /* 0x16 R_ARROW      */ { KT_CURSOR, ZX_K_8, 0 },
  /* 0x17 UP_ARROW     */ { KT_CURSOR, ZX_K_7, 0 },
  /* 0x18 DN_ARROW     */ { KT_CURSOR, ZX_K_6, 0 },
  /* 0x19 INSERT       */ { KT_EDIT_INS, ZX_K_O, ZX_K_A },
  /* 0x1A DELETE       */ { KT_EDIT_DEL, ZX_K_P, ZX_K_C },
  /* 0x1B ESC          */ { KT_EDIT_ESC, 0, 0 },
  /* 0x1C BS           */ { KT_EDIT_BS, 0, 0 },
  /* 0x1D TAB          */ { KT_EDIT_TAB, 0, 0 },
  /* 0x1E ENTER        */ { KT_DIRECT, ZX_K_ENT, 0 },
  /* 0x1F SPACE        */ { KT_DIRECT, ZX_K_SP, 0 },
  /* 0x20 KP0          */ { KT_DIRECT, ZX_K_0, 0 },
  /* 0x21 KP1          */ { KT_DIRECT, ZX_K_1, 0 },
  /* 0x22 KP2          */ { KT_DIRECT, ZX_K_2, 0 },
  /* 0x23 KP3          */ { KT_DIRECT, ZX_K_3, 0 },
  /* 0x24 KP4          */ { KT_DIRECT, ZX_K_4, 0 },
  /* 0x25 KP5          */ { KT_DIRECT, ZX_K_5, 0 },
  /* 0x26 KP6          */ { KT_DIRECT, ZX_K_6, 0 },
  /* 0x27 KP7          */ { KT_DIRECT, ZX_K_7, 0 },
  /* 0x28 KP8          */ { KT_DIRECT, ZX_K_8, 0 },
  /* 0x29 KP9          */ { KT_DIRECT, ZX_K_9, 0 },
  /* 0x2A KP_DOT       */ { KT_SHIFT_PAIR, ZX_K_M, ZX_K_T },
  /* 0x2B KP_ENTER     */ { KT_DIRECT, ZX_K_ENT, 0 },
  /* 0x2C KP_PLUS      */ { KT_COMBO, ZX_K_SS, ZX_K_K },
  /* 0x2D KP_MINUS     */ { KT_COMBO, ZX_K_SS, ZX_K_J },
  /* 0x2E KP_TIMES     */ { KT_COMBO, ZX_K_SS, ZX_K_B },
  /* 0x2F KP_DIV       */ { KT_SHIFT_PAIR, ZX_K_V, ZX_K_C },
  /* 0x30 '0'          */ { KT_DIRECT, ZX_K_0, 0 },
  /* 0x31 '1'          */ { KT_DIRECT, ZX_K_1, 0 },
  /* 0x32 '2'          */ { KT_DIRECT, ZX_K_2, 0 },
  /* 0x33 '3'          */ { KT_DIRECT, ZX_K_3, 0 },
  /* 0x34 '4'          */ { KT_DIRECT, ZX_K_4, 0 },
  /* 0x35 '5'          */ { KT_DIRECT, ZX_K_5, 0 },
  /* 0x36 '6'          */ { KT_DIRECT, ZX_K_6, 0 },
  /* 0x37 '7'          */ { KT_DIRECT, ZX_K_7, 0 },
  /* 0x38 '8'          */ { KT_DIRECT, ZX_K_8, 0 },
  /* 0x39 '9'          */ { KT_DIRECT, ZX_K_9, 0 },
  /* 0x3A APOS         */ { KT_SHIFT_PAIR, ZX_K_7, ZX_K_P },
  /* 0x3B COMMA        */ { KT_SHIFT_PAIR, ZX_K_N, ZX_K_R },
  /* 0x3C MINUS        */ { KT_SHIFT_PAIR, ZX_K_J, ZX_K_0 },
  /* 0x3D DOT          */ { KT_SHIFT_PAIR, ZX_K_M, ZX_K_T },
  /* 0x3E DIV          */ { KT_SHIFT_PAIR, ZX_K_V, ZX_K_C },
  /* 0x3F KP_EQUAL     */ { KT_NONE, 0, 0 },
  /* 0x40 SINGLE       */ { KT_SINGLE_QUOTE, 0, 0 },
  /* 0x41 'A'          */ { KT_DIRECT, ZX_K_A, 0 },
  /* 0x42 'B'          */ { KT_DIRECT, ZX_K_B, 0 },
  /* 0x43 'C'          */ { KT_DIRECT, ZX_K_C, 0 },
  /* 0x44 'D'          */ { KT_DIRECT, ZX_K_D, 0 },
  /* 0x45 'E'          */ { KT_DIRECT, ZX_K_E, 0 },
  /* 0x46 'F'          */ { KT_DIRECT, ZX_K_F, 0 },
  /* 0x47 'G'          */ { KT_DIRECT, ZX_K_G, 0 },
  /* 0x48 'H'          */ { KT_DIRECT, ZX_K_H, 0 },
  /* 0x49 'I'          */ { KT_DIRECT, ZX_K_I, 0 },
  /* 0x4A 'J'          */ { KT_DIRECT, ZX_K_J, 0 },
  /* 0x4B 'K'          */ { KT_DIRECT, ZX_K_K, 0 },
  /* 0x4C 'L'          */ { KT_DIRECT, ZX_K_L, 0 },
  /* 0x4D 'M'          */ { KT_DIRECT, ZX_K_M, 0 },
  /* 0x4E 'N'          */ { KT_DIRECT, ZX_K_N, 0 },
  /* 0x4F 'O'          */ { KT_DIRECT, ZX_K_O, 0 },
  /* 0x50 'P'          */ { KT_DIRECT, ZX_K_P, 0 },
  /* 0x51 'Q'          */ { KT_DIRECT, ZX_K_Q, 0 },
  /* 0x52 'R'          */ { KT_DIRECT, ZX_K_R, 0 },
  /* 0x53 'S'          */ { KT_DIRECT, ZX_K_S, 0 },
  /* 0x54 'T'          */ { KT_DIRECT, ZX_K_T, 0 },
  /* 0x55 'U'          */ { KT_DIRECT, ZX_K_U, 0 },
  /* 0x56 'V'          */ { KT_DIRECT, ZX_K_V, 0 },
  /* 0x57 'W'          */ { KT_DIRECT, ZX_K_W, 0 },
  /* 0x58 'X'          */ { KT_DIRECT, ZX_K_X, 0 },
  /* 0x59 'Y'          */ { KT_DIRECT, ZX_K_Y, 0 },
  /* 0x5A 'Z'          */ { KT_DIRECT, ZX_K_Z, 0 },
  /* 0x5B SEMI         */ { KT_SHIFT_PAIR, ZX_K_O, ZX_K_Z },
  /* 0x5C BACK         */ { KT_MACRO_BRACKET, ZX_K_D, ZX_K_S },
  /* 0x5D OPEN_SQ      */ { KT_MACRO_BRACKET, ZX_K_Y, ZX_K_F },
  /* 0x5E CLOSE_SQ     */ { KT_MACRO_BRACKET, ZX_K_U, ZX_K_G },
  /* 0x5F EQUAL        */ { KT_SHIFT_PAIR, ZX_K_L, ZX_K_K },
  /* 0x60 KP_COMMA     */ { KT_NONE, 0, 0 },
  /* 0x61 F1           */ { KT_COMBO, ZX_K_A, ZX_K_BIT6 },
  /* 0x62 F2           */ { KT_COMBO, ZX_K_B, ZX_K_BIT6 },
  /* 0x63 F3           */ { KT_COMBO, ZX_K_C, ZX_K_BIT6 },
  /* 0x64 F4           */ { KT_COMBO, ZX_K_D, ZX_K_BIT6 },
  /* 0x65 F5           */ { KT_COMBO, ZX_K_E, ZX_K_BIT6 },
  /* 0x66 F6           */ { KT_COMBO, ZX_K_F, ZX_K_BIT6 },
  /* 0x67 F7           */ { KT_COMBO, ZX_K_G, ZX_K_BIT6 },
  /* 0x68 F8           */ { KT_COMBO, ZX_K_H, ZX_K_BIT6 },
  /* 0x69 F9           */ { KT_COMBO, ZX_K_I, ZX_K_BIT6 },
  /* 0x6A F10          */ { KT_COMBO, ZX_K_J, ZX_K_BIT6 },
  /* 0x6B F11          */ { KT_COMBO, ZX_K_Q, ZX_K_SS },
  /* 0x6C F12          */ { KT_COMBO, ZX_K_W, ZX_K_SS },
};

#endif // __ZXKEYBOARD_MAP_H__
