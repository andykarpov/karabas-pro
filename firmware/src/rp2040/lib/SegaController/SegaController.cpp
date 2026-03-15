//
// SegaController.cpp
//
// Author:
//       Jon Thysell <thysell@gmail.com>
//
// Copyright (c) 2017 Jon Thysell <http://jonthysell.com>
//
// Modified by Andy Karpov <andy.karpov@gmail.com>
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#include "Arduino.h"
#include "SegaController.h"

SegaController::SegaController()
{
    // nothing here
}

void SegaController::begin(uint8_t joy_sck, uint8_t joy_load, uint8_t joy_data, uint8_t joy_p7)
{
    // Set pins
    _sckPin = joy_sck;
    _loadPin = joy_load;
    _dataPin = joy_data;
    _selectPin = joy_p7;

    // Setup pins
    pinMode(_selectPin, OUTPUT); digitalWrite(_selectPin, HIGH);
    pinMode(_sckPin, OUTPUT); digitalWrite(_sckPin, LOW);
    pinMode(_loadPin, OUTPUT); digitalWrite(_loadPin, LOW);
    pinMode(_dataPin, INPUT_PULLUP);

    _currentState = 0;
    _sixButtonMode = false;
    _lastReadTime = 0;
}

word SegaController::getState()
{
    if (max(millis() - _lastReadTime, 0) < SC_READ_DELAY_MS)
    {
        // Not enough time has elapsed, return previously read state
        return _currentState;
    }
    
    // Clear current state
    _currentState = 0;

    for (uint8_t cycle = 0; cycle < SC_CYCLES; cycle++)
    {
        readCycle(cycle);
    }

    // When a controller disconnects, revert to three-button polling
    if (!(_currentState & SC_CTL_ON))
    {
        _sixButtonMode = false;
    }

    _lastReadTime = millis();

    return _currentState;
}

bool SegaController::getIsOn()
{
    return _currentState & SC_CTL_ON;
}

bool SegaController::getSixButtonMode()
{
    return _sixButtonMode;
}

uint16_t SegaController::readPins()
{
    uint16_t result = 0;
    
    // latch
    gpio_put(_loadPin, HIGH);
    delayMicroseconds(2);
    gpio_put(_loadPin, LOW);
    delayMicroseconds(2);
    
    // latch
    gpio_put(_loadPin, HIGH);
    delayMicroseconds(2);

    // reading 8 bits of 1 shift register
    for (uint8_t i=8; i>0; i--) {

        if (gpio_get(_dataPin) == HIGH) {
            result |= (1 << i-1);
        }
        gpio_put(_sckPin, HIGH);
        delayMicroseconds(2);
        gpio_put(_sckPin, LOW);
        delayMicroseconds(2);
    }
    gpio_put(_loadPin, LOW);
    delayMicroseconds(2);

    return result;
}

void SegaController::readCycle(byte cycle)
{
    // Set the select pin low/high
    gpio_put(_selectPin, cycle % 2);

    // a small delay before reading
    delayMicroseconds(50);

    uint16_t reading = readPins();

    // Read flags
    switch (cycle)
    {
        case 0:
        case 1:
        case 6:
        case 7:
            // read pins, nothing to do with data
        break;
        case 2:
            // Check that a controller is connected
            _currentState |= (bitRead(reading, 2) == LOW && bitRead(reading, 3) == LOW) * SC_CTL_ON;
            
            // Check controller is connected before reading A/Start to prevent bad reads when inserting/removing cable
            if (_currentState & SC_CTL_ON) {
                // Read input pins for A, Start
                if (bitRead(reading, 4) == LOW) { _currentState |= SC_BTN_A; }
                if (bitRead(reading, 5) == LOW) { _currentState |= SC_BTN_START; }
            }
            break;
        case 3:
            // Read input pins for Up, Down, Left, Right, B, C
            if (bitRead(reading, 0) == LOW) { _currentState |= SC_BTN_UP; }
            if (bitRead(reading, 1) == LOW) { _currentState |= SC_BTN_DOWN; }
            if (bitRead(reading, 2) == LOW) { _currentState |= SC_BTN_LEFT; }
            if (bitRead(reading, 3) == LOW) { _currentState |= SC_BTN_RIGHT; }
            if (bitRead(reading, 4) == LOW) { _currentState |= SC_BTN_B; }
            if (bitRead(reading, 5) == LOW) { _currentState |= SC_BTN_C; }
            break;
        case 4:
            _sixButtonMode = (bitRead(reading, 0) == LOW && bitRead(reading, 1) == LOW);
            break;
        case 5:
            if (_sixButtonMode)
            {
                // Read input pins for X, Y, Z, Mode
                if (bitRead(reading, 0) == LOW) { _currentState |= SC_BTN_Z; }
                if (bitRead(reading, 1) == LOW) { _currentState |= SC_BTN_Y; }
                if (bitRead(reading, 2) == LOW) { _currentState |= SC_BTN_X; }
                if (bitRead(reading, 3) == LOW) { _currentState |= SC_BTN_MODE; }
            }
            break;
    }
}
