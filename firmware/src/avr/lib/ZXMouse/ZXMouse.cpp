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
#include <ZXMouse.h>

/****************************************************************************/

ZXMouse::ZXMouse(void)
{
}

/****************************************************************************/

void ZXMouse::begin(spi_cb act, osd_cb evt)
{
  action = act;
  event = evt;

  pinMode(PIN_MOUSE_CLK, INPUT_PULLUP);
  pinMode(PIN_MOUSE_DAT, INPUT_PULLUP);

  mice.begin(PIN_MOUSE_CLK, PIN_MOUSE_DAT);

  mouse_tries = MOUSE_INIT_TRIES;
  init();

  is_started = true;
}

bool ZXMouse::started()
{
  return is_started;
}

uint8_t ZXMouse::getX() {
  return mouse_x;
}

uint8_t ZXMouse::getY() {
  return mouse_y;
}

uint8_t ZXMouse::getZ() {
  return mouse_z;
}

void ZXMouse::handle(bool menu)
{
  unsigned long n = millis();

  // try to re-init mouse every 100us if not present, up to N tries
  if (mouse_tries > 0 && !mouse_present && n - tm > 100) {
    mouse_tries--;
    init();
    tm = n;
  }

  // polling for mouse data
  #if MOUSE_POLL_TYPE == 1
  if (mouse_present && n - t > MOUSE_POLL_INTERVAL) {

    MouseData m = mice.readData();

    mouse_new_packet = !mouse_new_packet;
    mouse_x = m.position.x;
    mouse_y = m.position.y;
    mouse_z = m.wheel;

    ms_btn1 = bitRead(m.status, 0);
    ms_btn2 = bitRead(m.status, 1);
    ms_btn3 = bitRead(m.status, 2);
    bitWrite(mouse_z, 4, mouse_swap ? ms_btn2 : ms_btn1); // left
    bitWrite(mouse_z, 5, mouse_swap ? ms_btn1 : ms_btn2); // right
    bitWrite(mouse_z, 6, ms_btn3); // middle
    bitWrite(mouse_z, 7, mouse_new_packet);

    transmit();
    event(EVENT_OSD_MOUSE_DATA);
    t = n;
  }
  #else
  // mouse stream report read
  if (mice.reportAvailable() > 0 ) {
    MouseData m = mice.readReport();

      mouse_new_packet = !mouse_new_packet;
      mouse_x = m.position.x;
      mouse_y = m.position.y;
      mouse_z = m.wheel;
  
      ms_btn1 = bitRead(m.status, 0);
      ms_btn2 = bitRead(m.status, 1);
      ms_btn3 = bitRead(m.status, 2);
      bitWrite(mouse_z, 4, mouse_swap ? ms_btn2 : ms_btn1); // left
      bitWrite(mouse_z, 5, mouse_swap ? ms_btn1 : ms_btn2); // right
      bitWrite(mouse_z, 6, ms_btn3); // middle
      bitWrite(mouse_z, 7, mouse_new_packet);
  
      transmit();
      event(EVENT_OSD_MOUSE_DATA);
  }

  #endif

  // swap mouse buttons
  if (mouse_present && n - ts > MOUSE_SWAP_INTERVAL) {
    if (menu && ms_btn1) {
      mouse_swap = !mouse_swap;
      event(EVENT_OSD_MOUSE_SWAPPED);
    }
    ts = n;
  }  

}

void ZXMouse::transmit()
{
  action(CMD_MOUSE_X, mouse_x);
  action(CMD_MOUSE_Y, mouse_y);
  action(CMD_MOUSE_Z, mouse_z);
}

void ZXMouse::init()
{
#if (MOUSE_POLL_TYPE == 1)
  mouse_present = mice.initialize();
#else 
  mouse_present = mice.streamInitialize();
#endif
}

bool ZXMouse::getMouseSwap()
{
  return mouse_swap;
}

void ZXMouse::setMouseSwap(bool val)
{
  mouse_swap = val;
}

/****************************************************************************/

// vim:cin:ai:sts=2 sw=2 ft=cpp
