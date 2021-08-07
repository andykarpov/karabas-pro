/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __ZXMOUSE_H__
#define __ZXMOUSE_H__

// STL headers
// C headers
// Framework headers
#if ARDUINO < 100
#include <WProgram.h>
#else
#include <Arduino.h>
#endif

// Library headers
// Project headers
#include <avr/pgmspace.h>
#include <PS2Mouse.h>

#define PIN_MOUSE_CLK 3 // pin 26 (CLKM)
#define PIN_MOUSE_DAT 5 // pin 25 (DATM)

#define MOUSE_POLL_INTERVAL 10 // ms
#define MOUSE_SWAP_INTERVAL 1000 // ms
#define MOUSE_INIT_TRIES 2

#ifndef MOUSE_POLL_TYPE
#define MOUSE_POLL_TYPE 0 // 1 = poll, 0 = stream
#endif

// mouse commands
#define CMD_MOUSE_X 0x0A
#define CMD_MOUSE_Y 0x0B
#define CMD_MOUSE_Z 0x0C

/****************************************************************************/

class ZXMouse
{
  using spi_cb = void (*)(uint8_t addr, uint8_t data); // alias function pointer
  using osd_cb = void (*)(uint8_t evt); // alias function pointer

private:

  spi_cb action;
  osd_cb event;
  PS2Mouse mice;
  bool is_started = false;

  bool mouse_present = false; // mouse present flag (detected by signal change on CLKM pin)
  bool mouse_swap = false;
  bool ms_btn1 = false;
  bool ms_btn2 = false;
  bool ms_btn3 = false;
  unsigned long t = 0;  // current time
  unsigned long tm = 0; // mouse poll time
  unsigned long ts = 0; // mouse swap time
  int mouse_tries; // number of triers to init mouse

  uint8_t mouse_x = 0; // current mouse X
  uint8_t mouse_y = 0; // current mouse Y
  uint8_t mouse_z = 0; // current mousr Z
  uint8_t mouse_btns = 0; // mouse buttons state
  bool mouse_new_packet = false; // new packet to send (toggle flag)

  void transmit();
  void init();

protected:

public:

  static const uint8_t EVENT_OSD_MOUSE_SWAPPED = 0;
  static const uint8_t EVENT_OSD_MOUSE_DATA = 1;

  ZXMouse();

  void begin(spi_cb act, osd_cb evt);
  bool started();
  void handle(bool menu);

  uint8_t getX();
  uint8_t getY();
  uint8_t getZ();

  bool getMouseSwap();
  void setMouseSwap(bool val);

};

#endif // __ZXMouse_H__
// vim:cin:ai:sts=2 sw=2 ft=cpp
