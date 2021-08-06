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
#include <ZXOSD.h>
#include <Arduino.h>
#include <OSD.h>

/****************************************************************************/

ZXOSD::ZXOSD(void)
{
}

/****************************************************************************/

void ZXOSD::begin(OSD &osd_)
{
  osd = osd_;
}

/****************************************************************************/

// vim:cin:ai:sts=2 sw=2 ft=cpp
