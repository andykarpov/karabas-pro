/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __ZXJOY_H__
#define __ZXJOY_H__

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
#include <ZXJoystick.h>
#include <SegaController.h>

// joystick
#define PIN_JOY_UP 6
#define PIN_JOY_DOWN 8
#define PIN_JOY_LEFT 9
#define PIN_JOY_RIGHT 10
#define PIN_JOY_FIRE1 A0
#define PIN_JOY_FIRE2 A3
#define PIN_JOY_STROBE A1 // Busy LED

// Joystick signals
#define ZX_JOY_FIRE 0
#define ZX_JOY_FIRE2 1
#define ZX_JOY_UP 2
#define ZX_JOY_DOWN 3
#define ZX_JOY_LEFT 4
#define ZX_JOY_RIGHT 5
#define ZX_JOY_A 6
#define ZX_JOY_B 7

// joystick commands
#define CMD_JOY 0x0D

/****************************************************************************/

class ZXJoystick
{
  using spi_cb = void (*)(uint8_t addr, uint8_t data); // alias function pointer
  using osd_cb = void (*)(uint8_t evt, uint8_t data); // alias function pointer

private:

  SegaController sega;
  spi_cb action;
  osd_cb event;
  bool is_started = false;

  bool joy[8]; // joystic states
  bool last_joy[8];
  word sega_joy_state;

  uint8_t getJoyByte();
  void transmit();

protected:

public:

  static const uint8_t EVENT_OSD_JOY_DATA = 1;

  ZXJoystick();

  void begin(spi_cb act, osd_cb evt);
  bool started();
  void handle(bool joy_type);
};

#endif // __ZXJOY_H__
// vim:cin:ai:sts=2 sw=2 ft=cpp
