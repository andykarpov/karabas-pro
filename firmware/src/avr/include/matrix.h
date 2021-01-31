#ifndef matrix_h
#define matrix_h

// ZX Spectrum keyboard matrix:

// 1  2  3  4  5  6  7  8  9  0
// q  w  e  r  t  y  u  i  o  p
// a  s  d  f  g  h  j  k  l  enter
// cs z  x  c  v  b  n  m  ss space

//--------------------------------------------------------------
// Scan code tables
//
//                 D0       D1      D2      D3     D4
// 
//  A8.  A0:       CS  0    Z  8    X  16   C 24   V 32
//  A9.  A1:       A   1    S  9    D  17   F 25   G 33     
//  A10. A2:       Q   2    W  10   E  18   R 26   T 34      
//  A11. A3:       1   3    2  11   3  19   4 27   5 35
//  A12. A4:       0   4    9  12   8  20   7 28   6 36
//  A13. A5:       P   5    O  13   I  21   U 29   Y 37
//  A14. A6:       Ent 6    L  14   K  22   J 30   H 38
//  A15. A7:       Sp  7    SS 15   M  23   N 31   B 39
//--------------------------------------------------------------

// Key position in output array

#define ZX_MATRIX_FULL_SIZE 64 // 40 keys + bit6 + reset + turbo + magic + keyboard is_up + 000 +  16 bit scancode
#define ZX_MATRIX_SIZE 41 // only mechanical keys state + bit6

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

// Joystick signals
#define ZX_JOY_FIRE 0
#define ZX_JOY_FIRE2 1
#define ZX_JOY_UP 2
#define ZX_JOY_DOWN 3
#define ZX_JOY_LEFT 4
#define ZX_JOY_RIGHT 5

// Outgoing commands:

// kbd commands
#define CMD_KBD_BYTE1 0x01
#define CMD_KBD_BYTE2 0x02
#define CMD_KBD_BYTE3 0x03
#define CMD_KBD_BYTE4 0x04
#define CMD_KBD_BYTE5 0x05
#define CMD_KBD_BYTE6 0x06
#define CMD_KBD_BYTE7 0x07 // scancode
#define CMD_KBD_BYTE8 0x08 // scancode

// mouse commands
#define CMD_MOUSE_X 0x0A
#define CMD_MOUSE_Y 0x0B
#define CMD_MOUSE_Z 0x0C

// joystick commands
#define CMD_JOY 0x0D

// RTC RD command
#define CMD_RTC_READ 0x40 // + regnum 0e-3f (64 ... 127)

// Incoming commands:

// LED command
#define CMD_LED_WRITE 0x0E
// RTC WR command 
#define CMD_RTC_WRITE 0x80 // + regnum 0e-3f (128 ... 191)
// RTC INIT command
#define CMD_RTC_INIT_REQ 0xFC // rtc init request
// INIT command
#define CMD_INIT_REQ 0xFD // init req
// NOP command
#define CMD_NONE 0xFF

#endif
