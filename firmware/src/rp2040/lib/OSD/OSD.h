/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __OSD_H__
#define __OSD_H__

#include <Arduino.h>

// Library headers
// Project headers

/****************************************************************************/


/**
 * Driver library for OSD overlay on FPGA sideA
 */

class OSD : public Print
{

  using m_cb = void (*)(uint8_t cmd, uint8_t addr, uint8_t data); // alias function pointer

private:
  uint8_t fg_color;
  uint8_t bg_color;
  uint8_t current_x=0;
  uint8_t current_y=0;
  m_cb action;

protected:

public:

  static const uint8_t COLOR_BLACK = 0b0000;
  static const uint8_t COLOR_FLASH = 0b0001;
  static const uint8_t COLOR_WHITE = 0b1111;
  static const uint8_t COLOR_GREY  = 0b1110;
  static const uint8_t COLOR_RED   = 0b1000;
  static const uint8_t COLOR_GREEN = 0b0100;
  static const uint8_t COLOR_BLUE  = 0b0010;
  static const uint8_t COLOR_RED_I   = 0b1001;
  static const uint8_t COLOR_GREEN_I = 0b0101;
  static const uint8_t COLOR_BLUE_I  = 0b0011;
  static const uint8_t COLOR_YELLOW = 0b1100;
  static const uint8_t COLOR_YELLOW_I = 0b1101;
  static const uint8_t COLOR_MAGENTA = 0b1010;
  static const uint8_t COLOR_MAGENTA_I = 0b1011;
  static const uint8_t COLOR_CYAN = 0b0110;
  static const uint8_t COLOR_CYAN_I = 0b0111;

  /**
   * Constructor
   */
  OSD();

  /**
   * Begin operation
   *
   * Sets pins correctly, and prepares SPI bus.
   */
  void begin(m_cb act);

  /**
   * Set character position
   *
   * @param x position x (0...31)
   * @param y position y (0...23)
   */
  void setPos(const uint8_t x, const uint8_t y);

  /**
   * Set fg / bg color
   *
   * @param color
   */
  void setColor(uint8_t color, uint8_t bgcolor);

  /**
   * Clear screen
   *
   * Set black bg to the whole screen
   */
  void clear(void);

  /**
   * Write a single characted
   *
   * @param chr character byte.
   */
  virtual size_t write(uint8_t chr);

  void fill(uint8_t chr);
  void fill(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t chr);
  void frame(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t thickness);
  void line(uint8_t y);
  void progress(uint8_t x, uint8_t y, uint8_t size, uint32_t val, uint32_t max);
  void logo(uint8_t x, uint8_t y);
  void header(char* build, char* id);
  void footer();

  void showMenu();
  void hideMenu();
  void showPopup();
  void hidePopup();

  void fontReset();
  void fontSend(uint8_t data);

};

#endif // __OSD_H__
// vim:cin:ai:sts=2 sw=2 ft=cpp
