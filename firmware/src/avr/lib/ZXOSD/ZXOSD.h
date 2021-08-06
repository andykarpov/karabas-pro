/*
 Copyright (C) 2021 Andy Karpov <andy.karpov@gmail.com>

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 version 2 as published by the Free Software Foundation.
 */

#ifndef __ZXOSD_H__
#define __ZXOSD_H__

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
#include <OSD.h>

/****************************************************************************/


class ZXOSD
{

private:
	OSD osd;

protected:

public:

  ZXOSD();

  void begin(OSD &osd_);

};

#endif // __ZXOSD_H__
// vim:cin:ai:sts=2 sw=2 ft=cpp
