/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

// STL headers
// C headers
#include <avr/pgmspace.h>
// Framework headers
// Library headers
#include <Arduino.h>
// Project headers
// This component's header
#include <ZXJoystick.h>

/****************************************************************************/

ZXJoystick::ZXJoystick(void)
{
}

/****************************************************************************/

void ZXJoystick::begin(spi_cb act, osd_cb evt)
{
  action = act;
  event = evt;

  pinMode(PIN_JOY_RIGHT, OUTPUT);
  digitalWrite(PIN_JOY_RIGHT, LOW);

  // joy
  pinMode(PIN_JOY_UP, INPUT_PULLUP);
  pinMode(PIN_JOY_DOWN, INPUT_PULLUP);
  pinMode(PIN_JOY_LEFT, INPUT_PULLUP);
//  pinMode(PIN_JOY_RIGHT, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE1, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE2, INPUT_PULLUP);

  sega.begin(PIN_JOY_STROBE, PIN_JOY_UP, PIN_JOY_DOWN, PIN_JOY_LEFT, PIN_JOY_RIGHT, PIN_JOY_FIRE1, PIN_JOY_FIRE2);

  is_started = true;
}

bool ZXJoystick::started()
{
  return is_started;
}

void ZXJoystick::handle(bool joy_type)
{
  // read joystick
  // Due to conflict with the hardware SPI, we should stop the HW SPI and switch the joy_right as input before reading
  // WARNING: a 100-500 Ohm resistor is required on the PIN_JOY_RIGHT line
  //SPI.end();
  //interrupts(); // SPI.end() calls noInterrupts()
  SPCR &= ~_BV(SPE);

  // set JOY_RIGHT pin as input to read joystick signal
  pinMode(PIN_JOY_RIGHT, INPUT_PULLUP);

  if (joy_type == false) {
    // kempston joy read
    joy[ZX_JOY_UP] = digitalRead(PIN_JOY_UP) == LOW;
    joy[ZX_JOY_DOWN] = digitalRead(PIN_JOY_DOWN) == LOW;
    joy[ZX_JOY_LEFT] = digitalRead(PIN_JOY_LEFT) == LOW;
    joy[ZX_JOY_RIGHT] = digitalRead(PIN_JOY_RIGHT) == LOW;
    joy[ZX_JOY_FIRE] = digitalRead(PIN_JOY_FIRE1) == LOW;
    joy[ZX_JOY_FIRE2] = digitalRead(PIN_JOY_FIRE2) == LOW;
    joy[ZX_JOY_A] = false;
    joy[ZX_JOY_B] = false;
  } else {
    // sega joy read
    sega_joy_state = sega.getState();
    joy[ZX_JOY_UP] = sega_joy_state & SC_BTN_UP;
    joy[ZX_JOY_DOWN] = sega_joy_state & SC_BTN_DOWN;
    joy[ZX_JOY_LEFT] = sega_joy_state & SC_BTN_LEFT;
    joy[ZX_JOY_RIGHT] = sega_joy_state & SC_BTN_RIGHT;
    joy[ZX_JOY_FIRE] = sega_joy_state & SC_BTN_B;
    joy[ZX_JOY_FIRE2] = sega_joy_state & SC_BTN_C;
    joy[ZX_JOY_A] = sega_joy_state & SC_BTN_A;
    joy[ZX_JOY_B] = sega_joy_state & SC_BTN_START;
  }

  // set JOY_RIGHT as output to avoid intersection with hardware SPI SS pin
  pinMode(PIN_JOY_RIGHT, OUTPUT);
  digitalWrite(PIN_JOY_RIGHT, LOW);

  //SPI.begin();
  //interrupts(); // SPI.begin() calls noInterrupts()
  SPCR |= _BV(MSTR);
  SPCR |= _BV(SPE);

  if (joy[0] != last_joy[0] || joy[1] != last_joy[1] || joy[2] != last_joy[2] || joy[3] != last_joy[3] || joy[4] != last_joy[4] || joy[5] != last_joy[5] || joy[6] != last_joy[6] || joy[7] != last_joy[7]) {
    last_joy[0] = joy[0];
    last_joy[1] = joy[1];
    last_joy[2] = joy[2];
    last_joy[3] = joy[3];
    last_joy[4] = joy[4];
    last_joy[5] = joy[5];
    last_joy[6] = joy[6];
    last_joy[7] = joy[7];

    uint8_t joy_byte = 0;
    bitWrite(joy_byte, 7, joy[ZX_JOY_B]);
    bitWrite(joy_byte, 6, joy[ZX_JOY_A]);
    bitWrite(joy_byte, 5, joy[ZX_JOY_FIRE2]);
    bitWrite(joy_byte, 4, joy[ZX_JOY_FIRE]);
    bitWrite(joy_byte, 3, joy[ZX_JOY_UP]);
    bitWrite(joy_byte, 2, joy[ZX_JOY_DOWN]);
    bitWrite(joy_byte, 1, joy[ZX_JOY_LEFT]);
    bitWrite(joy_byte, 0, joy[ZX_JOY_RIGHT]);
    event(EVENT_OSD_JOY_DATA, joy_byte);
  }

  // transmit joy matrix
  transmit();

}

uint8_t ZXJoystick::getJoyByte()
{
  uint8_t result = 0;
  for (uint8_t i = 0; i < 8; i++) {
    bitWrite(result, i, joy[i]);
  }
  return result;
}

void ZXJoystick::transmit()
{
  uint8_t data = getJoyByte();
  action(CMD_JOY, data);
}


/****************************************************************************/

// vim:cin:ai:sts=2 sw=2 ft=cpp
