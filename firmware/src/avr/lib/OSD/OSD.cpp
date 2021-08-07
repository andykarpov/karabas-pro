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
#include <SPI.h>
// Project headers
// This component's header
#include <OSD.h>
#include <Arduino.h>

/****************************************************************************/

// Commands

const uint8_t CMD_CLEAR = 0x0F;
const uint8_t CMD_SET_POS_X = 0x10;
const uint8_t CMD_SET_POS_Y = 0x11;
const uint8_t CMD_CHAR = 0x12;
const uint8_t CMD_ATTR = 0x13;
const uint8_t CMD_NOOP = 0x14;

const uint8_t SIZE_X = 32;
const uint8_t SIZE_Y = 24;

/****************************************************************************/

OSD::OSD(void)
{
}

/****************************************************************************/

void OSD::begin(m_cb act)
{
  action = act;
}

/****************************************************************************/

void OSD::setPos(uint8_t x, uint8_t y)
{
  current_x = x;
  current_y = y;

  if (x >= SIZE_X) {
    current_x = 0;
    current_y++;
  }

  if (y >= SIZE_Y) {
    current_y = 0;
    current_x = 0;
  }
}

/****************************************************************************/

void OSD::clear(void)
{
  fill(0);
}

void OSD::fill(uint8_t chr)
{
  setPos(0,0);
  for (uint8_t y=0; y<SIZE_Y; y++) {
    for (uint8_t x=0; x<SIZE_X; x++) {
      write(chr);
    }
  }
}

void OSD::fill(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t chr)
{
    setPos(x1, y1);
    for (uint8_t y=y1; y<=y2; y++) {
        setPos(x1, y);
        for (uint8_t x=x1; x<=x2; x++) {
            write(chr);
        }
    }
}

void OSD::frame(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t thickness)
{
    setPos(x1,y1);
    for(uint8_t y=y1; y<=y2; y++) {
        setPos(x1, y);
        for(uint8_t x=x1; x<=x2; x++) {
	    if (y==y1 && x==x1) {
                write(thickness ? 201 : 218); // lt
            }
            else if (y==y2 && x==x1) {
                write(thickness ? 200 : 192); // lb
            }
            else if (y==y1 && x==x2) {
                write(thickness ? 187 : 191); // rt
            }
            else if (y==y2 && x==x2) {
                write(thickness ? 188 : 217); // rb
            }
            else if (y==y1 || y == y2) {
                write(thickness ? 205 : 196); // t / b
            }
            else if ((x==x1 && y>y1 && y<y2) || (x==x2 && y>y1 && y<y2)) {
                setPos(x,y);
                write(thickness ? 186 : 179); // l / r
            }
        }
    }
}

/****************************************************************************/

size_t OSD::write(uint8_t chr)
{
  uint8_t color = fg_color << 4;  
  action(CMD_SET_POS_X, current_x);
  action(CMD_SET_POS_Y, current_y);
//  action(CMD_CHAR, chr-32);
  action(CMD_CHAR, chr);
  action(CMD_ATTR, bg_color + color);
  setPos(current_x+1, current_y);
  return 1; 
}

/****************************************************************************/

void OSD::setColor(uint8_t color, uint8_t bgcolor)
{
    fg_color = color;
    bg_color = bgcolor;
}

/****************************************************************************/

// vim:cin:ai:sts=2 sw=2 ft=cpp
