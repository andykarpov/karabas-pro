#include "PS2Mouse.h"
#include "Arduino.h"

#define INTELLI_MOUSE 3
#define SCALING_1_TO_1 0xE6
#define RESOLUTION_8_COUNTS_PER_MM 3

enum Commands {
    SET_RESOLUTION = 0xE8,
    REQUEST_DATA = 0xEB,
    SET_REMOTE_MODE = 0xF0,
    SET_STREAM_MODE = 0xEA,
    ENABLE_REPORT = 0xF4,
    GET_DEVICE_ID = 0xF2,
    SET_SAMPLE_RATE = 0xF3,
    RESET = 0xFF,
};

#define MS_BUFFER_SIZE 16
MouseData msbuffer[ MS_BUFFER_SIZE ];
volatile uint8_t mshead, mstail;
volatile uint8_t counter = 0;
MouseData _mouse_report;
uint8_t PS2_MS_DataPin;

void receiveReport();

PS2Mouse::PS2Mouse() {
    // void constructor
}

void PS2Mouse::begin(int clockPin, int dataPin) {
    _clockPin = clockPin;
    _dataPin = dataPin;
    PS2_MS_DataPin = dataPin;
    _supportsIntelliMouseExtensions = false;
}

void PS2Mouse::high(int pin) {
    pinMode(pin, INPUT);
    digitalWrite(pin, HIGH);
}

void PS2Mouse::low(int pin) {
    pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
}

bool PS2Mouse::initialize(void) {
    high(_clockPin);
    high(_dataPin);
    if (!reset()) return false;
    checkIntelliMouseExtensions();
    setResolution(RESOLUTION_8_COUNTS_PER_MM);
    setScaling(SCALING_1_TO_1);
    setSampleRate(40);
    setRemoteMode();
    delayMicroseconds(100);
    return true;
}

bool PS2Mouse::streamInitialize(void) {
  high(_clockPin);
  high(_dataPin);
  reset();
  setResolution(RESOLUTION_8_COUNTS_PER_MM);
  setScaling(SCALING_1_TO_1);
  setSampleRate(40);
  setStreamingMode();
  delayMicroseconds(100);  
  attachInterrupt(digitalPinToInterrupt(_clockPin), receiveReport, FALLING);
  high(_clockPin);
  high(_dataPin);
  return true;
}

bool PS2Mouse::writeByte(char data) {
    int parityBit = 1;

    high(_dataPin);
    high(_clockPin);
    delayMicroseconds(300);
    low(_clockPin);
    delayMicroseconds(300);
    low(_dataPin);
    delayMicroseconds(10);

    // start bit
    high(_clockPin);

    if (!waitForClockState(LOW)) return false;

    // data
    for (int i = 0; i < 8; i++) {
        int dataBit = bitRead(data, i);
        writeBit(dataBit);
        parityBit = parityBit ^ dataBit;
    }

    // parity bit
    writeBit(parityBit);

    // stop bit
    high(_dataPin);
    delayMicroseconds(50);
    waitForClockState(LOW);

    // wait for mouse to switch modes
    while ((digitalRead(_clockPin) == LOW) || (digitalRead(_dataPin) == LOW))
        ;

    // put a hold on the incoming data
    low(_clockPin);

    return true;
}

void PS2Mouse::writeBit(int bit) {
    if (bit == HIGH) {
        high(_dataPin);
    } else {
        low(_dataPin);
    }

    waitForClockState(HIGH);
    waitForClockState(LOW);
}

char PS2Mouse::readByte() {
    char data = 0;

    high(_clockPin);
    high(_dataPin);
    delayMicroseconds(50);
    waitForClockState(LOW);
    delayMicroseconds(5);

    // consume the start bit
    waitForClockState(HIGH);

    // consume 8 bits of data
    for (int i = 0; i < 8; i++) {
        bitWrite(data, i, readBit());
    }

    // consume parity bit (ignored)
    readBit();

    // consume stop bit
    readBit();

    // put a hold on the incoming data
    low(_clockPin);

    return data;
}

int PS2Mouse::readBit() {
    waitForClockState(LOW);
    int bit = digitalRead(_dataPin);
    waitForClockState(HIGH);
    return bit;
}

void PS2Mouse::setSampleRate(int rate) {
    writeAndReadAck(SET_SAMPLE_RATE);
    writeAndReadAck(rate);
}

bool PS2Mouse::writeAndReadAck(int data) {
    if (!writeByte((char) data)) return false;
    readByte();
    return true;
}

bool PS2Mouse::reset() {
    if (!writeAndReadAck(RESET)) return false;
    readByte();  // self-test status
    readByte();  // mouse ID
    return true;
}

void PS2Mouse::checkIntelliMouseExtensions() {
    // IntelliMouse detection sequence
    setSampleRate(200);
    setSampleRate(100);
    setSampleRate(80);

    char deviceId = getDeviceId();
    _supportsIntelliMouseExtensions = (deviceId == INTELLI_MOUSE);
}

char PS2Mouse::getDeviceId() {
    writeAndReadAck(GET_DEVICE_ID);
    return readByte();
}

void PS2Mouse::setScaling(int scaling) {
    writeAndReadAck(scaling);
}

void PS2Mouse::setRemoteMode() {
    writeAndReadAck(SET_REMOTE_MODE);
}

void PS2Mouse::setStreamingMode() {
    writeAndReadAck(SET_STREAM_MODE);
    writeAndReadAck(ENABLE_REPORT);
}

void PS2Mouse::setResolution(int resolution) {
    writeAndReadAck(SET_RESOLUTION);
    writeAndReadAck(resolution);
}

bool PS2Mouse::waitForClockState(int expectedState) {
    long c = millis();
//    Serial.println(c);
    bool res = false;

    while (millis() - c < 100) {
      res = (digitalRead(_clockPin) == expectedState) ? true : false;
      if (res) break;
    };

//    Serial.print("waitForClockState");
//    Serial.println(res);
    
    return res;
}

MouseData PS2Mouse::readData() {
    MouseData data;

    requestData();
    data.status = readByte();
    data.position.x = readByte();
    data.position.y = readByte();

    if (_supportsIntelliMouseExtensions) {
        data.wheel = readByte();
    }

    return data;
};

void PS2Mouse::requestData() {
    writeAndReadAck(REQUEST_DATA);
}

void receiveReport(void) {

  static uint8_t bitcount = 0;      // Main state variable and bit count
  static uint8_t incoming = 0;
  static uint8_t parity = 0;
  static uint32_t prev_ms = 0;
  uint32_t now_ms;
  uint8_t val = 0;
  
  val = (digitalRead(PS2_MS_DataPin) ? 1 : 0);
  now_ms = millis();
  if( now_ms - prev_ms > 10 ) { // mouse packet timeout
    bitcount = 0;
    counter = 0;
    incoming = 0;
  }
  prev_ms = now_ms;
  bitcount++;

  switch( bitcount )
       {
       case 1:  // Start bit
                incoming = 0;
                parity = 0;
                break;
       case 2:
       case 3:
       case 4:
       case 5:
       case 6:
       case 7:
       case 8:
       case 9:  // Data bits
                parity += val;        // another one received ?
                incoming >>= 1;       // right shift one place for next bit
                incoming |= ( val ) ? 0x80 : 0;    // or in MSbit
                break;
       case 10: // Parity check
                parity &= 1;          // Get LSB if 1 = odd number of 1's so parity should be 0
                if( parity == val )   // Both same parity error
                  parity = 0xFD;      // To ensure at next bit count clear and discard
                break;
       case 11: // Stop bit
                if( parity >= 0xFD )  // had parity error
                  {
                    // Should send resend byte command here currently discard
                    counter = 0;
                    bitcount = 0;
                    incoming = 0;
                  }
                else                  // Good so save byte in buffer
                  {

                    switch(counter) {
                          case 0:
                          _mouse_report.status = incoming;
                          counter++;
                          break;
                    
                          case 1:
                          _mouse_report.position.x = incoming;
                          counter++;
                          break;
                    
                          case 2:
                          _mouse_report.position.y = incoming;
                          counter = 0;
                    
                          uint8_t i = mshead + 1;
                          if( i >= MS_BUFFER_SIZE ) i = 0;
                          if( i != mstail ) {
                            msbuffer[ i ] = _mouse_report;
                            mshead = i;
                          }
                          
                          break;
                        }
                  }
                  bitcount = 0;
                  incoming = 0;
                break;
       default: // in case of weird error and end of byte reception re-sync
                bitcount = 0;
                counter = 0;
                incoming = 0;
      }

}

int8_t PS2Mouse::reportAvailable(void) {
  int8_t  i = mshead - mstail;
  if( i < 0 ) i += MS_BUFFER_SIZE;
  return i;
}

MouseData PS2Mouse::readReport(void) {

  uint8_t  i;
  MouseData default_data;
  default_data.position.x = 0;
  default_data.position.y = 0;
  default_data.status = 0;

  if (reportAvailable()) {
    i = mstail;
    if( i == mshead )     // check for empty buffer
        return default_data;
    i++;
    if( i >= MS_BUFFER_SIZE )
        i = 0;
    mstail = i;
    return msbuffer[i];
  } else {
    return default_data;
  }
}
