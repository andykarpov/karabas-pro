/*
    PioSPI Master library for the Raspberry Pi Pico RP2040

    Copyright (c) 2021 Jonathan Piat <piat.jonathan@gmail.com>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#pragma once

#include <Arduino.h>
#include <hardware/pio.h>
#include <api/HardwareSPI.h>
#include <hardware/spi.h>
extern "C" {
#include "pio_spi.h"
}

class PioSPI : public arduino::HardwareSPI {
public:
    PioSPI(pin_size_t tx, pin_size_t rx, pin_size_t sck, pin_size_t cs ,uint8_t data_mode, uint32_t frequency);

    uint8_t transfer(uint8_t data) override;
    uint16_t transfer16(uint16_t data) override;
    void transfer(void *buf, size_t count) override;

    // EFP3 - Additional block-based versions we implement
    void transfer(const void *txbuf, void *rxbuf, size_t count) override;

    // Transaction Functions
    void usingInterrupt(int interruptNumber) override;
    void notUsingInterrupt(int interruptNumber) override;
    void beginTransaction(SPISettings settings) override;
    void endTransaction(void) override;

    // SPI Configuration methods
    void attachInterrupt() override;
    void detachInterrupt() override;

    void begin() override;
    void end() override;

    // Assign pins, call before begin()
    bool setRX(pin_size_t pin);
    bool setCS(pin_size_t pin);
    bool setSCK(pin_size_t pin);
    bool setTX(pin_size_t pin);

private:
    bool cpol();
    bool cpha();
    uint8_t reverseByte(uint8_t b);
    uint16_t reverse16Bit(uint16_t w);
    void adjustBuffer(const void *s, void *d, size_t cnt, bool by16);

    pio_spi_inst_t _spi;
    pin_size_t _rx, _tx, _sck, _cs;
    bool _running; // SPI port active
    bool _beginned ;
    bool _initted; // Transaction begun
    BitOrder _BITORDER ;
    uint8_t _data_mode ;
    uint32_t _ck_freq ;
    float _clkdiv ;
    PIOProgram _cpha0Pgm ;
    PIOProgram _cpha1Pgm ;
    
};

