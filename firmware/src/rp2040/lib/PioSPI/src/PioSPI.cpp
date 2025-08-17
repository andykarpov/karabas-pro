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

#include "PioSPI.h"
#include <hardware/gpio.h>
#include <hardware/pio.h>
#include "hardware/clocks.h"

#if defined(DEBUG_RP2040_PIOSPI)
#define DEBUGPIOSPI(fmt, ...) do { Serial.printf(fmt, ## __VA_ARGS__); Serial.flush();} while (0)
#else
#define DEBUGPIOSPI(...) do { } while(0)
#endif
#define ERRORPIOSPI(fmt, ...) do { Serial.printf(fmt, ## __VA_ARGS__); Serial.flush();} while (0)



PioSPI::PioSPI(pin_size_t tx, pin_size_t rx, pin_size_t sck, pin_size_t cs , uint8_t data_mode, uint32_t frequency)
:_cpha0Pgm(&spi_cpha0_program),
_cpha1Pgm(&spi_cpha1_program) {
    _rx = rx ;
    _tx = tx ;
    _sck = sck ;
    _cs = cs ;
    _BITORDER = MSBFIRST ;
    _data_mode = data_mode;
    uint32_t system_clock_frequency = clock_get_hz(clk_sys);
    _ck_freq = frequency ;
    _clkdiv = ((float) system_clock_frequency)/(_ck_freq * 4);
    if(_clkdiv < 1.5){
        _clkdiv = 1.5 ;
        _ck_freq = (((float) system_clock_frequency)/_clkdiv)/4.f ;
        ERRORPIOSPI("Set frequency too high, falling back to maximum %u Hz \n", _ck_freq);
    }
    _initted = false ;
    _running = false ;
    _beginned = false ;
}

inline bool PioSPI::cpol() {
    return (_data_mode == SPI_MODE2) || (_data_mode == SPI_MODE3);
}

inline bool PioSPI::cpha() {
    return (_data_mode == SPI_MODE1) || (_data_mode == SPI_MODE3) ;
}

inline uint8_t PioSPI::reverseByte(uint8_t b) {
    b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
    b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
    b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
    return b;
}

inline uint16_t PioSPI::reverse16Bit(uint16_t w) {
    return (reverseByte(w & 0xff) << 8) | (reverseByte(w >> 8));
}

void PioSPI::adjustBuffer(const void *s, void *d, size_t cnt, bool by16) {
    if (_BITORDER == MSBFIRST) {
        memcpy(d, s, cnt * (by16 ? 2 : 1));
    } else if (!by16) {
        const uint8_t *src = (const uint8_t *)s;
        uint8_t *dst = (uint8_t *)d;
        for (size_t i = 0; i < cnt; i++) {
            *(dst++) = reverseByte(*(src++));
        }
    } else { /* by16 */
        const uint16_t *src = (const uint16_t *)s;
        uint16_t *dst = (uint16_t *)d;
        for (size_t i = 0; i < cnt; i++) {
            *(dst++) = reverse16Bit(*(src++));
        }
    }
}

uint8_t PioSPI::transfer(uint8_t data) {
    uint8_t ret;
    if (!_initted) {
        return 0;
    }
    data = (_BITORDER == MSBFIRST) ? data : reverseByte(data);
    DEBUGPIOSPI("SPI::transfer(%02x), cpol=%d, cpha=%d\n", data, cpol(), cpha());
    pio_spi_write8_read8_blocking(&_spi, (uint8_t *) &data,(uint8_t *) &ret, 1);
    ret = (_BITORDER == MSBFIRST) ? ret : reverseByte(ret);
    DEBUGPIOSPI("SPI: read back %02x\n", ret);
    return ret;
}

uint16_t PioSPI::transfer16(uint16_t data) {
    uint16_t ret;
    if (!_initted) {
        return 0;
    }
    data = (_BITORDER == MSBFIRST) ? data : reverse16Bit(data);
    DEBUGPIOSPI("SPI::transfer16(%04x), cpol=%d, cpha=%d\n", data, cpol(), cpha());
    pio_spi_write8_read8_blocking(&_spi, (uint8_t *) &data, (uint8_t *) &ret, 2);
    ret = (_BITORDER == MSBFIRST) ? ret : reverseByte(ret);
    DEBUGPIOSPI("SPI: read back %02x\n", ret);
    return ret;
}

void PioSPI::transfer(void *buf, size_t count) {
    DEBUGPIOSPI("SPI::transfer(%p, %d)\n", buf, count);
    uint8_t *buff = reinterpret_cast<uint8_t *>(buf);
    for (size_t i = 0; i < count; i++) {
        *buff = transfer(*buff);
        *buff = (_BITORDER == MSBFIRST) ? *buff : reverseByte(*buff);
        buff++;
    }
    DEBUGPIOSPI("SPI::transfer completed\n");
}

void PioSPI::transfer(const void *txbuf, void *rxbuf, size_t count) {
    if (!_initted) {
        return;
    }

    DEBUGPIOSPI("SPI::transfer(%p, %p, %d)\n", txbuf, rxbuf, count);
    uint8_t *txbuff = (uint8_t*)(txbuf);
    uint8_t *rxbuff = (uint8_t*)(rxbuf);

    if (_BITORDER == MSBFIRST) {
        if (rxbuf == NULL) { 
            pio_spi_write8_blocking(&_spi,  (uint8_t *) txbuff, count);
            return;
        }
        if (txbuf == NULL) {
            pio_spi_read8_blocking(&_spi,  (uint8_t *) rxbuff, count);
            return;
        }
        pio_spi_write8_read8_blocking(&_spi,  (uint8_t *) txbuff,  (uint8_t *) rxbuff, count);
        return;
    }

    for (size_t i = 0; i < count; i++) {
        *rxbuff = transfer(*txbuff);
        *rxbuff = (_BITORDER == MSBFIRST) ? *rxbuff : reverseByte(*rxbuff);
        txbuff++;
        rxbuff++;
    }
    DEBUGPIOSPI("SPI::transfer completed\n");
}

void PioSPI::beginTransaction(SPISettings settings) {
    if(!_beginned){
        begin();
    }
    if(_initted && (settings.getClockFreq() != _ck_freq || settings.getDataMode() != _data_mode)){
        pio_sm_set_enabled(_spi.pio, _spi.sm, false);
        pio_sm_unclaim(_spi.pio, _spi.sm);
        _initted = false ;
    }
    if(!_initted){
        int offset ;
        if(cpha()){
            if (!_cpha1Pgm.prepare(&_spi.pio,(int *)  &_spi.sm, &offset)) {
                return ; //Need to indicate failure somehow
            }
        }else{
            if (!_cpha0Pgm.prepare(&_spi.pio,(int *) &_spi.sm, &offset)) {
                return ; //Need to indicate failure somehow
            }
        }
        
        uint32_t system_clock_frequency = clock_get_hz(clk_sys);
        _ck_freq = settings.getClockFreq() ;
        _clkdiv = ((float) system_clock_frequency)/((float) _ck_freq * 4);
        if(_clkdiv < 1.5){
            _clkdiv = 1.5 ;
            _ck_freq = (((float) system_clock_frequency)/_clkdiv)/4.f ;
            ERRORPIOSPI("Set frequency too high, falling back to maximum %u Hz \n", _ck_freq);
        }
        _BITORDER = settings.getBitOrder();
        _data_mode = settings.getDataMode();
        //uint offset = cpha() ? pio_add_program(_spi.pio, &spi_cpha1_program) : pio_add_program(_spi.pio, &spi_cpha0_program) ;
        pio_spi_init(_spi.pio, 
                    _spi.sm,
                    offset ,
                    8,       // 8 bits per SPI frame
                    _clkdiv,
                    cpha(),
                    cpol(),
                    _sck,
                    _tx,
                    _rx);
        
        _initted = true ;
    }
    gpio_put(_cs, 0);
    _running = true ;
}

void PioSPI::endTransaction(void) {
    if(_running){
        gpio_put(_cs, 1);
        _running = false ;
    }
}

bool PioSPI::setRX(pin_size_t pin) {
    if(!_running && !_initted){
        _rx = pin;
        return true;
    }

    return false;
}

bool PioSPI::setCS(pin_size_t pin) {
    if(!_running && !_initted){
        _cs = pin;
        return true;
    }

    return false;
}

bool PioSPI::setSCK(pin_size_t pin) {
    if(!_running && !_initted){
        _sck = pin;
        return true;
    }

    return false;
}

bool PioSPI::setTX(pin_size_t pin) {
   if (!_running && !_initted ) {
        _tx= pin;
        return true;
    }
    return false;
}

void PioSPI::begin() {
    gpio_init(_cs);
    gpio_set_dir(_cs, GPIO_OUT);
    gpio_put(_cs, 1);
    _beginned = true ;
}

void PioSPI::end() {
    pio_sm_set_enabled(_spi.pio, _spi.sm, false);
    pio_sm_unclaim(_spi.pio, _spi.sm);
    _beginned = false ;
    _initted = false ;
    _running = false ;
}

void PioSPI::usingInterrupt(int interruptNumber) {

}

void PioSPI::notUsingInterrupt(int interruptNumber) {

}

void PioSPI::attachInterrupt() {

}

void PioSPI::detachInterrupt() {

}
