/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __OSD_H__
#define __OSD_H__

#include <stdint.h>
#include <stddef.h>
#include <avr/pgmspace.h>

#ifndef DEC
#define DEC 10
#endif
#ifndef HEX
#define HEX 16
#endif

// Forward declaration for compatibility with PGMT / __FlashStringHelper
class __FlashStringHelper;

/**
 * Driver library for OSD overlay on FPGA side
 */
class OSD
{
  using m_cb = void (*)(uint8_t cmd, uint8_t addr, uint8_t data);

private:
  uint8_t fg_color = 0;
  uint8_t bg_color = 0;
  uint8_t current_x = 0;
  uint8_t current_y = 0;
  m_cb action = nullptr;

public:
  static const uint8_t COLOR_BLACK     = 0b0000;
  static const uint8_t COLOR_FLASH     = 0b0001;
  static const uint8_t COLOR_WHITE     = 0b1111;
  static const uint8_t COLOR_GREY      = 0b1110;
  static const uint8_t COLOR_RED       = 0b1000;
  static const uint8_t COLOR_GREEN     = 0b0100;
  static const uint8_t COLOR_BLUE      = 0b0010;
  static const uint8_t COLOR_RED_I     = 0b1001;
  static const uint8_t COLOR_GREEN_I   = 0b0101;
  static const uint8_t COLOR_BLUE_I    = 0b0011;
  static const uint8_t COLOR_YELLOW    = 0b1100;
  static const uint8_t COLOR_YELLOW_I  = 0b1101;
  static const uint8_t COLOR_MAGENTA   = 0b1010;
  static const uint8_t COLOR_MAGENTA_I = 0b1011;
  static const uint8_t COLOR_CYAN      = 0b0110;
  static const uint8_t COLOR_CYAN_I    = 0b0111;

  OSD();

  void begin(m_cb act);
  void setPos(const uint8_t x, const uint8_t y);
  void setColor(uint8_t color, uint8_t bgcolor);
  void clear(void);

  size_t write(uint8_t chr);
  void print(const char *str);
  void print_P(const char *pgm_str);
  void print(const __FlashStringHelper *f) { print_P(reinterpret_cast<const char *>(f)); }

  void print(uint32_t num, uint8_t base = 10);
  void print(int32_t num, uint8_t base = 10);
  void print(uint16_t num, uint8_t base = 10) { print((uint32_t)num, base); }
  void print(int16_t num, uint8_t base = 10)  { print((int32_t)num, base); }
  void print(uint8_t num, uint8_t base = 10)  { print((uint32_t)num, base); }
  void print(int8_t num, uint8_t base = 10)   { print((int32_t)num, base); }

  void fill(uint8_t chr);
  void fill(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t chr);
  void frame(uint8_t x1, uint8_t y1, uint8_t x2, uint8_t y2, uint8_t thickness);
};

#endif // __OSD_H__
