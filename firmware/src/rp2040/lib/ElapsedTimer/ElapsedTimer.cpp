/*
 Copyright (C) 2024 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#include <ElapsedTimer.h>
#include "pico/stdlib.h"

ElapsedTimer::ElapsedTimer()
{
  reset();
}

uint32_t ElapsedTimer::now()
{
  return to_ms_since_boot(get_absolute_time());
}

void ElapsedTimer::reset()
{
  start_millis_ = now();
}

uint32_t ElapsedTimer::elapsed()
{
  return now() - start_millis_;
}

// vim:cin:ai:sts=2 sw=2 ft=cpp
