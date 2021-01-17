#ifndef MOUSE_H_

#define MOUSE_H_

#include "Arduino.h"

#define BUFFER_SIZE 16

typedef struct {
    int x, y;
} Position;

typedef struct {
    int status;
    Position position;
    int wheel;
} MouseData;

class PS2Mouse {
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

public:
    PS2Mouse(int clockPin, int dataPin);

    bool initialize();
    MouseData readData();

    bool streamInitialize();
    int8_t reportAvailable();
    MouseData readReport();
};

#endif // MOUSE_H_
