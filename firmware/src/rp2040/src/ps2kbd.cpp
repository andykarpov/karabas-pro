/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2022 No0ne (https://github.com/No0ne)
 *           (c) 2023 Dustin Hoffman
 *           (c) 2024 Andy Karpov
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#include "tusb.h"
#include "main.h"

// LCTRL LSHIFT LALT LGUI RCTRL RSHIFT RALT RGUI
uint8_t const mod2ps2[] = { 0x14, 0x12, 0x11, 0x1f, 0x14, 0x59, 0x11, 0x27 };
uint8_t const hid2ps2[] = {
//   .  err  postf  err    A     B     C     D     E     F     G     H     I     J      K     L  
  0x00, 0x00, 0xfc, 0x00, 0x1c, 0x32, 0x21, 0x23, 0x24, 0x2b, 0x34, 0x33, 0x43, 0x3b, 0x42, 0x4b,
// M     N     O     P     Q      R    S     T     U     V     W     X     Y     Z     1     2
  0x3a, 0x31, 0x44, 0x4d, 0x15, 0x2d, 0x1b, 0x2c, 0x3c, 0x2a, 0x1d, 0x22, 0x35, 0x1a, 0x16, 0x1e,
// 3     4     5     6     7     8     9     0    ent    esc   bks   tab   spc   -     =      [
  0x26, 0x25, 0x2e, 0x36, 0x3d, 0x3e, 0x46, 0x45, 0x5a, 0x76, 0x66, 0x0d, 0x29, 0x4e, 0x55, 0x54,
// ]      \    \     ;     '     `     ,      .     /   caps   f1    f2    f3    f4    f5    f6     
  0x5b, 0x5d, 0x5d, 0x4c, 0x52, 0x0e, 0x41, 0x49, 0x4a, 0x58, 0x05, 0x06, 0x04, 0x0c, 0x03, 0x0b,
// f7    f8    f9    f10   f11   f12  pscr  scrl  paus  ins   home  pgup  del   end   pgdn  right        
  0x83, 0x0a, 0x01, 0x09, 0x78, 0x07, 0x7c, 0x7e, 0x7e, 0x70, 0x6c, 0x7d, 0x71, 0x69, 0x7a, 0x74,
// left down  up    numl  kp/   kp*   kp-   kp+   kpen  kp1   kp2   kp3   kp4   kp5   kp6   kp7
  0x6b, 0x72, 0x75, 0x77, 0x4a, 0x7c, 0x7b, 0x79, 0x5a, 0x69, 0x72, 0x7a, 0x6b, 0x73, 0x74, 0x6c,
// kp8  kp9   kp0   kp.   \     app   power kp=   f13   f14   f15   f16   f17   f18   f19   f20 
  0x75, 0x7d, 0x70, 0x71, 0x61, 0x2f, 0x37, 0x0f, 0x08, 0x10, 0x18, 0x20, 0x28, 0x30, 0x38, 0x40,
// f21  f22   f23   f24  
  0x48, 0x50, 0x57, 0x5f
};

// LCTRL LSHIFT LALT LGUI RCTRL RSHIFT RALT RGUI
uint8_t const mod2xt[] = { 0x1D, 0x2A, 0x38, 0x5B, 0x1D, 0x36, 0x38, 0x5C }; 
uint8_t const hid2xt[] = {
//   .  err  postf  err    A     B     C     D     E     F     G     H     I     J      K     L  
  0x00, 0x00, 0xfc, 0x00, 0x1e, 0x30, 0x2e, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26,
// M     N     O     P     Q      R    S     T     U     V     W     X     Y     Z     1     2
  0x32, 0x31, 0x18, 0x19, 0x10, 0x13, 0x1f, 0x14, 0x16, 0x2f, 0x11, 0x2d, 0x15, 0x2c, 0x02, 0x03,
// 3     4     5     6     7     8     9     0    ent    esc   bks   tab   spc   -     =      [
  0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x1c, 0x01, 0x0e, 0x0f, 0x39, 0x0c, 0x0d, 0x1a,
// ]      \    \     ;     '     `     ,      .     /   caps   f1    f2    f3    f4    f5    f6     
  0x1b, 0x2b, 0x2b, 0x27, 0x28, 0x29, 0x33, 0x34, 0x35, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40,
// f7    f8    f9    f10   f11   f12  pscr  scrl  paus  ins   home  pgup  del   end   pgdn  right        
  0x41, 0x42, 0x43, 0x44, 0x57, 0x58, 0x37, 0x46, 0x00, 0x52, 0x47, 0x51, 0x53, 0x4f, 0x51, 0x4d,
// left down  up    numl  kp/   kp*   kp-   kp+   kpen  kp1   kp2   kp3   kp4   kp5   kp6   kp7
  0x4b, 0x50, 0x48, 0x45, 0x35, 0x37, 0x4a, 0x4e, 0x1c, 0x4f, 0x50, 0x51, 0x4b, 0x4c, 0x4d, 0x47,
// kp8  kp9   kp0   kp.   \     app   power kp=   f13   f14   f15   f16   f17   f18   f19   f20 
  0x48, 0x49, 0x52, 0x53, 0x2b, 0x00, 0x00, 0x0d, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
// f21  f22   f23   f24  
  0x00, 0x00, 0x00, 0x00
};

uint32_t const repeats[] = {
  33333, 37453, 41667, 45872, 48309, 54054, 58480, 62500,
  66667, 75188, 83333, 91743, 100000, 108696, 116279, 125000,
  133333, 149254, 166667, 181818, 200000, 217391, 232558, 250000,
  270270, 303030, 333333, 370370, 400000, 434783, 476190, 500000
};
uint16_t const delays[] = { 250, 500, 750, 1000 };

uint8_t repeat = 0;
bool repeat_state = false;
uint32_t repeat_us = 33333;
uint16_t delay_ms = 250;
alarm_id_t repeater;

hid_keyboard_report_t prev_rpt = {0};

void kb_send(uint8_t byte) {
  //d_printf("PS/2 Scancode: %02x", byte); d_println();
  spi_queue(CMD_PS2_SCANCODE, 0x00, byte);
}

void kb_send_xt(uint8_t byte, bool state) {
  //d_printf("XT Scancode: %02x", byte); d_println();
  spi_queue(CMD_PS2_SCANCODE, 0x01, byte | (state ? 0x00 : 0x80) );
}

int64_t repeat_callback(alarm_id_t, void *user_data) {
  if(repeat) {
    if(repeat >= HID_KEY_CONTROL_LEFT && repeat <= HID_KEY_GUI_RIGHT) {
      kb_send_xt(mod2xt[repeat - HID_KEY_CONTROL_LEFT], repeat_state);
    } else {
      kb_send_xt(hid2xt[repeat], repeat_state);
    }
    repeat_state = !repeat_state;
    return repeat_us;
  }  
  repeater = 0;
  return 0;
}

void kb_maybe_send_e0(uint8_t key) {
  if(key == HID_KEY_PRINT_SCREEN ||
     key >= HID_KEY_INSERT && key <= HID_KEY_ARROW_UP ||
     key == HID_KEY_KEYPAD_DIVIDE ||
     key == HID_KEY_KEYPAD_ENTER ||
     key == HID_KEY_APPLICATION ||
     key == HID_KEY_POWER ||
     key >= HID_KEY_GUI_LEFT && key != HID_KEY_SHIFT_RIGHT) {
    kb_send(0xe0);
  }
}

void kb_send_key(uint8_t key, bool state, uint8_t modifiers) {
  if(key > HID_KEY_F24 &&
     key < HID_KEY_CONTROL_LEFT ||
     key > HID_KEY_GUI_RIGHT) return;
  
  if(key == HID_KEY_PAUSE) {
    
    if(state) {
      if(modifiers & KEYBOARD_MODIFIER_LEFTCTRL ||
         modifiers & KEYBOARD_MODIFIER_RIGHTCTRL) {
        kb_send(0xe0); kb_send(0x7e); kb_send(0xe0); kb_send(0xf0); kb_send(0x7e);
      } else {
        kb_send(0xe1); kb_send(0x14); kb_send(0x77); kb_send(0xe1);
        kb_send(0xf0); kb_send(0x14); kb_send(0xf0); kb_send(0x77);
      }
    }
    
    return;
  }
  
  kb_maybe_send_e0(key);
  
  if(!state) {
    kb_send(0xf0);
  }
  
  if(key >= HID_KEY_CONTROL_LEFT && key <= HID_KEY_GUI_RIGHT) {
    kb_send(mod2ps2[key - HID_KEY_CONTROL_LEFT]);
  } else {
    kb_send(hid2ps2[key]);
  }

  // xt + repeater
  if (state) {
    // send keypress
    if(key >= HID_KEY_CONTROL_LEFT && key <= HID_KEY_GUI_RIGHT) {
      kb_send_xt(mod2xt[key - HID_KEY_CONTROL_LEFT], state);
    } else {
      kb_send_xt(hid2xt[key], state);
    }
    // init repeater
    repeat = key;
    if (repeater) cancel_alarm(repeater);
    repeat_state = false;
    repeater = add_alarm_in_ms(delay_ms, repeat_callback, NULL, false);
  } else {
    if (key == repeat) repeat = 0;
    // send release
    if(key >= HID_KEY_CONTROL_LEFT && key <= HID_KEY_GUI_RIGHT) {
      kb_send_xt(mod2xt[key - HID_KEY_CONTROL_LEFT], state);
    } else {
      kb_send_xt(hid2xt[key], state);
    }
  }
}

void kb_usb_receive(hid_keyboard_report_t const *report) {
  
    if(report->modifier != prev_rpt.modifier) {
      uint8_t rbits = report->modifier;
      uint8_t pbits = prev_rpt.modifier;
      
      for(uint8_t j = 0; j < 8; j++) {
        if((rbits & 1) != (pbits & 1)) {
          kb_send_key(HID_KEY_CONTROL_LEFT + j, rbits & 1, report->modifier);
        }
        
        rbits = rbits >> 1;
        pbits = pbits >> 1;
      }
    }
    
    for(uint8_t i = 0; i < 6; i++) {
      if(prev_rpt.keycode[i]) {
        bool brk = true;
        
        for(uint8_t j = 0; j < 6; j++) {
          if(prev_rpt.keycode[i] == report->keycode[j]) {
            brk = false;
            break;
          }
        }
        
        if(brk) {
          kb_send_key(prev_rpt.keycode[i], false, report->modifier);
        }
      }
      
      if(report->keycode[i]) {
        bool make = true;
        
        for(uint8_t j = 0; j < 6; j++) {
          if(report->keycode[i] == prev_rpt.keycode[j]) {
            make = false;
            break;
          }
        }
        
        if(make) {
          kb_send_key(report->keycode[i], true, report->modifier);
        }
      }
    }
    
    prev_rpt = *report;
}
