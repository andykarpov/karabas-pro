/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

// STL headers
// C headers
// Framework headers
// Library headers
#include <SPI.h>
// Project headers
// This component's header
#include <OSD.h>
#include <Arduino.h>

/****************************************************************************/

// Commands

const uint8_t CMD_OSD = 0x20;

const uint8_t ADDR_SHOW = 0x01;
const uint8_t ADDR_POPUP = 0x02;

const uint8_t ADDR_CLEAR = 0x0F;
const uint8_t ADDR_SET_POS_X = 0x10;
const uint8_t ADDR_SET_POS_Y = 0x11;
const uint8_t ADDR_CHAR = 0x12;
const uint8_t ADDR_ATTR = 0x13;
const uint8_t ADDR_NOOP = 0x14;

const uint8_t ADDR_FONT_RST = 0x20;
const uint8_t ADDR_FONT_DATA = 0x21;
const uint8_t ADDR_FONT_DATA_WR = 0x22;

const uint8_t SIZE_X = 32;
const uint8_t SIZE_Y = 26;

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
  setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
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
                write(210); // lt
            }
            else if (y==y2 && x==x1) {
                write(212); // lb
            }
            else if (y==y1 && x==x2) {
                write(211); // rt
            }
            else if (y==y2 && x==x2) {
                write(213); // rb
            }
            else if (y==y1 || y == y2) {
                write(209); // t / b
            }
            else if ((x==x1 && y>y1 && y<y2) || (x==x2 && y>y1 && y<y2)) {
                setPos(x,y);
                write(208); // l / r
            }
        }
    }
}

void OSD::progress(uint8_t x, uint8_t y, uint8_t size, uint32_t val, uint32_t max)
{
  setPos(x,y);
  // fill with 0xfe (small square)
  uint8_t v = map(val, 0, max, 0, size);
  for (uint8_t i=0; i<v; i++) {
    write(0xfe);
  }
  // fill empty space
  for (uint8_t i=v; i<size; i++) {
    write(0x00);
  }
}


/****************************************************************************/

size_t OSD::write(uint8_t chr)
{
  uint8_t color = fg_color << 4;  
  action(CMD_OSD, ADDR_SET_POS_X, current_x);
  action(CMD_OSD, ADDR_SET_POS_Y, current_y);
//  action(CMD_CHAR, chr-32);
  action(CMD_OSD, ADDR_CHAR, chr);
  action(CMD_OSD, ADDR_ATTR, bg_color + color);
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

void OSD::showMenu() {
  action(CMD_OSD, ADDR_SHOW, 1);
}

void OSD::hideMenu() {
  action(CMD_OSD, ADDR_SHOW, 0);
}

void OSD::showPopup() {
  action(CMD_OSD, ADDR_POPUP, 1);
}

void OSD::hidePopup() {
  action(CMD_OSD, ADDR_POPUP, 0);
}

void OSD::fontReset() {
  action(CMD_OSD, ADDR_FONT_RST, 1);
  action(CMD_OSD, ADDR_FONT_RST, 0);
}

void OSD::fontSend(uint8_t data) {
  action (CMD_OSD, ADDR_FONT_DATA, data);
  action (CMD_OSD, ADDR_FONT_DATA_WR, 1);
}

void OSD::line(uint8_t y) {
  setPos(0,y);
  for (uint8_t i=0; i<32; i++) {
    write(0xd1); 
  }
}

void OSD::logo(uint8_t x, uint8_t y) {
  setPos(x,y);
  setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);

  // karabas pro logo
  write(0xb0); write(0xb1); // k
  write(0xb2); write(0xb3); // a
  write(0xb4); write(0xb5); // r
  write(0xb2); write(0xb3); // a
  write(0xb6); write(0xb7); // b
  write(0xb2); write(0xb3); // a
  write(0xb8); write(0xb9); // s

  setPos(x,y+1);
  write(0xc0); write(0xc1); // k
  write(0xc2); write(0xc3); // a
  write(0xc4); write(0xc5); // r
  write(0xc2); write(0xc3); // a
  write(0xc6); write(0xc7); // b
  write(0xc2); write(0xc3); // a
  write(0xc8); write(0xc9); // s

  setPos(x+8, y+2);
  write(0xba); write(0xbb); // p
  write(0xb4); write(0xb5); // r
  write(0xbc); write(0xbd); // o

  setPos(x+8, y+3);
  write(0xca); write(0xcb); // p
  write(0xc4); write(0xc5); // r
  write(0xcc); write(0xcd); // o

  setPos(x+1, y+2);
  setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
  write(0x16); // -
  setColor(OSD::COLOR_YELLOW_I, OSD::COLOR_BLACK);
  write(0x16); // -
  setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  write(0x16); // -
  setColor(OSD::COLOR_BLUE_I, OSD::COLOR_BLACK);
  write(0x16); // -

  setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  setPos(x,y+3);
}

void OSD::header(char* build, char* id)
{
  logo(0,0);

  setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  setPos(19,2);
  print("FPGA "); print(build);

  setColor(OSD::COLOR_GREY, OSD::COLOR_BLACK);
  setPos(19,3);
  print("CORE "); print(id);

  setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  line(4);
}

void OSD::footer() {

  setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  line(22);

  // footer
  setPos(0,23); 
  print("Press ESC to return");
}


// vim:cin:ai:sts=2 sw=2 ft=cpp
