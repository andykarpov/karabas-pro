/*
 Copyright (C) 2024 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __ELAPSED_TIMER_H__
#define __ELAPSED_TIMER_H__

#include <Arduino.h>

class ElapsedTimer 
{

private:
  uint32_t start_millis_;
  uint32_t now();

public:

  ElapsedTimer();
  void reset();
  uint32_t elapsed();

};

#endif // __ELAPSED_TIMER_H__
// vim:cin:ai:sts=2 sw=2 ft=cpp
