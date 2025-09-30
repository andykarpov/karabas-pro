#ifndef PS2_MOUSE_H_
#define PS2_MOUSE_H_

#include "Arduino.h"

#define BUFFER_SIZE 16

struct Position {
    int x, y;
};

struct MouseData {
    int status;
    Position position;
    int wheel;
};

class PS2Mouse {

public:
    PS2Mouse();
    void begin(int clockPin, int dataPin);
    bool initialize(void);
    MouseData readData(void);
    bool streamInitialize(void);
    int8_t reportAvailable(void);
    MouseData readReport(void);

private:
    int _clockPin;
    int _dataPin;
    bool _supportsIntelliMouseExtensions;
    void high(int pin);
    void low(int pin);
    bool writeAndReadAck(int data);
    bool reset();
    void setSampleRate(int rate);
    void checkIntelliMouseExtensions();
    void setResolution(int resolution);
    char getDeviceId();
    void setScaling(int scaling);
    void setRemoteMode();
    void setStreamingMode();
    bool waitForClockState(int expectedState);
    void requestData();
    char readByte();
    int readBit();
    bool writeByte(char data);
    void writeBit(int bit);

};

#endif // PSMOUSE_H_
