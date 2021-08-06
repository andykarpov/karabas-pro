/**
                                                                                                                
#       #######                                                 #                                               
#                                                               #                                               
#                                                               #                                               
############### ############### ############### ############### ############### ############### ############### 
#             #               # #                             # #             #               # #               
#             # ############### #               ############### #             # ############### ############### 
#             # #             # #               #             # #             # #             #               # 
#             # ############### #               ############### ############### ############### ############### 
                                                                                                                
        ####### ####### ####### #######                         ############### ############### ############### 
                                                                #             # #               #             # 
                                                                ############### #               #             # 
                                                                #               #               #             # 
https://github.com/andykarpov/karabas-pro                       #               #               ############### 

AVR firmware for Karabas-Pro

@author Andy Karpov <andy.karpov@gmail.com>
Ukraine, 2021
*/

#include "Arduino.h"
#include "PS2KeyAdvanced.h"
#include "PS2Mouse.h"
#include "SegaController.h"
#include "SBWire.h"
#include "OSD.h"
#include <SPI.h>
#include "config.h"
#include "ZXKeyboard.h"
#include "ZXRTC.h"
#include "ZXOSD.h"

PS2KeyAdvanced kbd;
PS2Mouse mice;
SegaController sega;
OSD osd;
ZXKeyboard zxkbd;
ZXOSD zxosd;
ZXRTC zxrtc;

bool joy[8]; // joystic states
bool last_joy[8];
word sega_joy_state;

bool init_done = false; // init done

bool mouse_present = false; // mouse present flag (detected by signal change on CLKM pin)
bool blink_state = false;

bool led1_state = false;
bool led2_state = false;
bool led1_overwrite = false;
bool led2_overwrite = false;

bool ms_btn1 = false;
bool ms_btn2 = false;
bool ms_btn3 = false;

unsigned long t = 0;  // current time
unsigned long tl1, tl2 = 0; // led1/2 time
unsigned long tm = 0; // mouse poll time
unsigned long tl = 0; // blink poll time
unsigned long tb, tb1, tb2 = 0; // hw buttons poll time
unsigned long ts = 0; // mouse swap time

int mouse_tries; // number of triers to init mouse

uint8_t mouse_x = 0; // current mouse X
uint8_t mouse_y = 0; // current mouse Y
uint8_t mouse_z = 0; // current mousr Z
uint8_t mouse_btns = 0; // mouse buttons state
bool mouse_new_packet = false; // new packet to send (toggle flag)

SPISettings settingsA(1000000, MSBFIRST, SPI_MODE0); // SPI transmission settings

uint8_t get_joy_byte();
void spi_send(uint8_t addr, uint8_t data);

void transmit_joy_data();

void transmit_mouse_data();

void process_in_cmd(uint8_t cmd, uint8_t data);

void init_mouse();

void update_led(uint8_t led, bool state);

void setup();
void loop();

uint8_t get_joy_byte()
{
  uint8_t result = 0;
  for (uint8_t i = 0; i < 8; i++) {
    bitWrite(result, i, joy[i]);
  }
  return result;
}

void spi_send(uint8_t addr, uint8_t data)
{
  SPI.beginTransaction(settingsA);
  digitalWrite(PIN_SS, LOW);
  uint8_t cmd = SPI.transfer(addr); // command (1...6)
  uint8_t res = SPI.transfer(data); // data byte
  digitalWrite(PIN_SS, HIGH);
  SPI.endTransaction();
  if (cmd > 0) {
    process_in_cmd(cmd, res);
  }
}

void transmit_joy_data()
{
  uint8_t data = get_joy_byte();
  spi_send(CMD_JOY, data);
}

void transmit_mouse_data()
{
  spi_send(CMD_MOUSE_X, mouse_x);
  spi_send(CMD_MOUSE_Y, mouse_y);
  spi_send(CMD_MOUSE_Z, mouse_z);
}



void process_in_cmd(uint8_t cmd, uint8_t data)
{
  if (cmd == CMD_INIT_REQ && !init_done) {
      init_done = true;
      zxkbd.transmit();
      zxrtc.sendAll();
      zxkbd.doReset();
      zxosd.setFpgaCfg(data);
  }

  if (cmd == CMD_RTC_INIT_REQ && !zxrtc.getInitDone()) {
    zxrtc.setInitDone(true);
    zxrtc.sendAll();
  }

  if (cmd >= CMD_BUILD_REQ0 && cmd <= CMD_BUILD_REQ7) {
    zxosd.setFpgaBuildNum(cmd-CMD_BUILD_REQ0, data);
  }

#if ALLOW_LED_OVERRIDE
  if (cmd == CMD_LED_WRITE) {
    led1_state = bitRead(data, 0);
    led2_state = bitRead(data, 1);
    led1_overwrite = bitRead(data, 2);
    led2_overwrite = bitRead(data, 3);
  }
#endif

  if (cmd >= CMD_RTC_WRITE && cmd < CMD_RTC_WRITE + 64) {
    // write rtc register
    zxrtc.setReg(cmd - CMD_RTC_WRITE, data);
  }
}

void init_mouse()
{
#if (MOUSE_POLL_TYPE == 1)
  mouse_present = mice.initialize();
#else 
  mouse_present = mice.streamInitialize();
#endif
}

// update led state
void update_led(uint8_t led, bool state)
{
  if (led == PIN_LED2 && zxkbd.getJoyType()) {
    digitalWrite(PIN_LED2, HIGH);
    return;
  }
  digitalWrite(led, state);
}



// update OSD by keyboard events
void on_keyboard (uint8_t event_type, uint16_t scancode)
{
  if (!zxosd.started()) return;
  switch (event_type) {
    case ZXKeyboard::EVENT_OSD_OVERLAY:  zxosd.initOverlay(); break;
    case ZXKeyboard::EVENT_OSD_SCANCODE: zxosd.updateScancode(scancode); break;
    case ZXKeyboard::EVENT_OSD_JOYSTICK: zxosd.updateJoystick(); break;
    case ZXKeyboard::EVENT_OSD_SWAP_AB:  zxosd.updateSwapAB(); break;
    case ZXKeyboard::EVENT_OSD_ROMBANK:  zxosd.updateRombank(); break;
    case ZXKeyboard::EVENT_OSD_TURBOFDC: zxosd.updateTurbofdc(); break;
    case ZXKeyboard::EVENT_OSD_COVOX:    zxosd.updateCovox(); break;
    case ZXKeyboard::EVENT_OSD_STEREO:   zxosd.updateStereo(); break;
    case ZXKeyboard::EVENT_OSD_SSG:      zxosd.updateSsg(); break;
    case ZXKeyboard::EVENT_OSD_VIDEO:    zxosd.updateVideo(); break;
    case ZXKeyboard::EVENT_OSD_VSYNC:    zxosd.updateVsync(); break;
    case ZXKeyboard::EVENT_OSD_JOY_TYPE: zxosd.updateJoystick(); break;
    case ZXKeyboard::EVENT_OSD_KEYBOARD_TYPE:  zxosd.updateKeyboardType(); break;
    case ZXKeyboard::EVENT_OSD_PAUSE:  zxosd.updatePause(); break;
    case ZXKeyboard::EVENT_OSD_TURBO:  zxosd.updateTurbo(); break;
  }
}

// update OSD by time events
void on_time()
{
  if ((!zxkbd.started()) || (!zxosd.started())) return;
  if (zxkbd.getIsOsdOverlay()) {
    zxosd.updateTime();
  }
}

// initial setup
void setup()
{
  Serial.begin(115200);
  Serial.flush();
  pinMode(PIN_JOY_RIGHT, OUTPUT);
  digitalWrite(PIN_JOY_RIGHT, LOW);
  SPI.begin();

  // set up fast ADC
  // Bit 7 - ADEN: ADC Enable
  // Bit 6 - ADSC: ADC Start Conversion
  // Bit 5 - ADATE: ADC Auto Trigger Enable
  // Bit 4 - ADIF: ADC Interrupt Flag
  // Bit 3 - ADIE: ADC Interrupt Enable
  // Bits 2:0 - ADPS[2:0]: ADC Prescaler Select Bits
  ADCSRA = (ADCSRA & B11111000) | 4;

  pinMode(PIN_SS, OUTPUT);
  digitalWrite(PIN_SS, HIGH);

  pinMode(PIN_LED1, OUTPUT);
  digitalWrite(PIN_LED1, HIGH);

  pinMode(PIN_LED2, OUTPUT);
  digitalWrite(PIN_LED2, HIGH);

  pinMode(PIN_BTN1, INPUT_PULLUP);
  pinMode(PIN_BTN2, INPUT_PULLUP);

  // ps/2

  pinMode(PIN_KBD_CLK, INPUT_PULLUP);
  pinMode(PIN_KBD_DAT, INPUT_PULLUP);

  pinMode(PIN_MOUSE_CLK, INPUT_PULLUP);
  pinMode(PIN_MOUSE_DAT, INPUT_PULLUP);

  // joy
  pinMode(PIN_JOY_UP, INPUT_PULLUP);
  pinMode(PIN_JOY_DOWN, INPUT_PULLUP);
  pinMode(PIN_JOY_LEFT, INPUT_PULLUP);
//  pinMode(PIN_JOY_RIGHT, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE1, INPUT_PULLUP);
  pinMode(PIN_JOY_FIRE2, INPUT_PULLUP);

  kbd.begin(PIN_KBD_DAT, PIN_KBD_CLK);
  zxkbd.begin(&kbd, spi_send, on_keyboard);

  zxrtc.begin(spi_send, on_time);

  // setup osd library with callback to send spi command
  osd.begin(spi_send);
  zxosd.begin(&osd, &zxkbd, &zxrtc);

  // setup sega controller
  sega.begin(PIN_LED2, PIN_JOY_UP, PIN_JOY_DOWN, PIN_JOY_LEFT, PIN_JOY_RIGHT, PIN_JOY_FIRE1, PIN_JOY_FIRE2);

  mouse_tries = MOUSE_INIT_TRIES;
  mice.begin(PIN_MOUSE_CLK, PIN_MOUSE_DAT);
  init_mouse();

  // waiting for init
  while (!init_done) {
    spi_send(CMD_NONE, 0x00);
  }

  // request build num from the fpga
  spi_send(CMD_BUILD_REQ0, 0x00);
  spi_send(CMD_BUILD_REQ1, 0x00);
  spi_send(CMD_BUILD_REQ2, 0x00);
  spi_send(CMD_BUILD_REQ3, 0x00);
  spi_send(CMD_BUILD_REQ4, 0x00);
  spi_send(CMD_BUILD_REQ5, 0x00);
  spi_send(CMD_BUILD_REQ6, 0x00);
  spi_send(CMD_BUILD_REQ7, 0x00);

  digitalWrite(PIN_LED1, LOW);
}


// main loop
void loop()
{
  unsigned long n = millis();

  zxkbd.handle();

  zxosd.handle();

  // empty keyboard matrix in overlay mode before transmitting it onto FPGA side
  if (zxkbd.getIsOsdOverlay()) {
    zxkbd.clear(ZX_MATRIX_SIZE);
  }

  // transmit kbd always
  zxkbd.transmit();

  // read joystick
  // Due to conflict with the hardware SPI, we should stop the HW SPI and switch the joy_right as input before reading
  // WARNING: a 100-500 Ohm resistor is required on the PIN_JOY_RIGHT line
  //SPI.end();
  //interrupts(); // SPI.end() calls noInterrupts()
  SPCR &= ~_BV(SPE);

  // set JOY_RIGHT pin as input to read joystick signal
  pinMode(PIN_JOY_RIGHT, INPUT_PULLUP);

  if (zxkbd.getJoyType() == false) {
    // kempston joy read
    joy[ZX_JOY_UP] = digitalRead(PIN_JOY_UP) == LOW;
    joy[ZX_JOY_DOWN] = digitalRead(PIN_JOY_DOWN) == LOW;
    joy[ZX_JOY_LEFT] = digitalRead(PIN_JOY_LEFT) == LOW;
    joy[ZX_JOY_RIGHT] = digitalRead(PIN_JOY_RIGHT) == LOW;
    joy[ZX_JOY_FIRE] = digitalRead(PIN_JOY_FIRE1) == LOW;
    joy[ZX_JOY_FIRE2] = digitalRead(PIN_JOY_FIRE2) == LOW;
    joy[ZX_JOY_A] = false;
    joy[ZX_JOY_B] = false;
  } else {
    // sega joy read
    sega_joy_state = sega.getState();
    joy[ZX_JOY_UP] = sega_joy_state & SC_BTN_UP;
    joy[ZX_JOY_DOWN] = sega_joy_state & SC_BTN_DOWN;
    joy[ZX_JOY_LEFT] = sega_joy_state & SC_BTN_LEFT;
    joy[ZX_JOY_RIGHT] = sega_joy_state & SC_BTN_RIGHT;
    joy[ZX_JOY_FIRE] = sega_joy_state & SC_BTN_B;
    joy[ZX_JOY_FIRE2] = sega_joy_state & SC_BTN_C;
    joy[ZX_JOY_A] = sega_joy_state & SC_BTN_A;
    joy[ZX_JOY_B] = sega_joy_state & SC_BTN_START;
  }

  // set JOY_RIGHT as output to avoid intersection with hardware SPI SS pin
  pinMode(PIN_JOY_RIGHT, OUTPUT);
  digitalWrite(PIN_JOY_RIGHT, LOW);

  //SPI.begin();
  //interrupts(); // SPI.begin() calls noInterrupts()
  SPCR |= _BV(MSTR);
  SPCR |= _BV(SPE);

  if (joy[0] != last_joy[0] || joy[1] != last_joy[1] || joy[2] != last_joy[2] || joy[3] != last_joy[3] || joy[4] != last_joy[4] || joy[5] != last_joy[5] || joy[6] != last_joy[6] || joy[7] != last_joy[7]) {
    last_joy[0] = joy[0];
    last_joy[1] = joy[1];
    last_joy[2] = joy[2];
    last_joy[3] = joy[3];
    last_joy[4] = joy[4];
    last_joy[5] = joy[5];
    last_joy[6] = joy[6];
    last_joy[7] = joy[7];

    if (zxkbd.getIsOsdOverlay()) {
      uint8_t joy_byte = 0;
      bitWrite(joy_byte, 7, joy[ZX_JOY_B]);
      bitWrite(joy_byte, 6, joy[ZX_JOY_A]);
      bitWrite(joy_byte, 5, joy[ZX_JOY_FIRE2]);
      bitWrite(joy_byte, 4, joy[ZX_JOY_FIRE]);
      bitWrite(joy_byte, 3, joy[ZX_JOY_UP]);
      bitWrite(joy_byte, 2, joy[ZX_JOY_DOWN]);
      bitWrite(joy_byte, 1, joy[ZX_JOY_LEFT]);
      bitWrite(joy_byte, 0, joy[ZX_JOY_RIGHT]);

      zxosd.updateJoyState(joy_byte);
    }

  }

  // transmit joy matrix
  transmit_joy_data();

  // react on hardware buttons every 100ms
#if USE_HW_BUTTONS
  if (n - tb >= 100) {
    if (analogRead(PIN_BTN1) < 3 && (n - tb1 >= 500) ) {
      tb1 = n;
      update_led(PIN_LED2, HIGH);
      zxkbd.doMagic();
       update_led(PIN_LED2, LOW);
    }

    if (analogRead(PIN_BTN2) < 3 && (n - tb2 >= 500) ) {
      tb2 = n;
      update_led(PIN_LED1, HIGH);
      zxkbd.doReset();
      update_led(PIN_LED1, LOW);
    }
    tb = n;
  }
#endif

  zxrtc.handle();

  // try to re-init mouse every 100us if not present, up to N tries
  if (mouse_tries > 0 && !mouse_present && n - tm > 100) {
    mouse_tries--;
    init_mouse();
    tm = n;
  }

  // polling for mouse data
  #if MOUSE_POLL_TYPE == 1
  if (mouse_present && n - t > MOUSE_POLL_INTERVAL) {

    MouseData m = mice.readData();

    mouse_new_packet = !mouse_new_packet;
    mouse_x = m.position.x;
    mouse_y = m.position.y;
    mouse_z = m.wheel;

    ms_btn1 = bitRead(m.status, 0);
    ms_btn2 = bitRead(m.status, 1);
    ms_btn3 = bitRead(m.status, 2);
    bitWrite(mouse_z, 4, zxkbd.getMouseSwap() ? ms_btn2 : ms_btn1); // left
    bitWrite(mouse_z, 5, zxkbd.getMouseSwap() ? ms_btn1 : ms_btn2); // right
    bitWrite(mouse_z, 6, ms_btn3); // middle
    bitWrite(mouse_z, 7, mouse_new_packet);

    transmit_mouse_data();

    if (zxkbd.getIsOsdOverlay()) {
      zxosd.updateMouse(mouse_x, mouse_y, mouse_z);
    }

    t = n;
  }
  #else
  // mouse stream report read
  if (mice.reportAvailable() > 0 ) {
    MouseData m = mice.readReport();

    //if ((bitRead(m.status, 3) == 1) and (bitRead(m.status, 6) == 0) and (bitRead(m.status,7)== 0)) {
      mouse_new_packet = !mouse_new_packet;
      mouse_x = m.position.x;
      mouse_y = m.position.y;
      mouse_z = m.wheel;
  
      ms_btn1 = bitRead(m.status, 0);
      ms_btn2 = bitRead(m.status, 1);
      ms_btn3 = bitRead(m.status, 2);
      bitWrite(mouse_z, 4, zxkbd.getMouseSwap() ? ms_btn2 : ms_btn1); // left
      bitWrite(mouse_z, 5, zxkbd.getMouseSwap() ? ms_btn1 : ms_btn2); // right
      bitWrite(mouse_z, 6, ms_btn3); // middle
      bitWrite(mouse_z, 7, mouse_new_packet);
  
      transmit_mouse_data();    

      if (zxkbd.getIsOsdOverlay()) {
        zxosd.updateMouse(mouse_x, mouse_y, mouse_z);
      }
    //}
  }

  #endif

  // swap mouse buttons
  if (mouse_present && n - ts > MOUSE_SWAP_INTERVAL) {
    if (zxkbd.getIsMenu() && ms_btn1) {
      zxkbd.setMouseSwap(!zxkbd.getMouseSwap());
      update_led(PIN_LED1, HIGH);
      delay(100);
      update_led(PIN_LED1, LOW);
      delay(100);
      update_led(PIN_LED1, HIGH);
      delay(100);
      update_led(PIN_LED1, LOW);
    }
    ts = n;
  }

  // control led1
#if ALLOW_LED_OVERRIDE
  if (led1_overwrite) {
    if (led1_state == 1) {
      update_led(PIN_LED1, HIGH);
    }
    if (n - tl1 >= 100) {
      tl1 = n;
      if (led1_state == false) {
        update_led(PIN_LED1, LOW);
      }
    }
  }

  // control led2
  if (led2_overwrite) {
      if (led2_state == 1) {
        update_led(PIN_LED2, HIGH);
      }
      if (n - tl2 >= 100) {
        tl2 = n;
        if (led2_state == false) {
          update_led(PIN_LED2, LOW);
        }
    }
  }
#else 
  if (zxkbd.getPause()) {
    if (n - tl2 >= 500) {
      tl2 = n;
      blink_state = !blink_state;
      update_led(PIN_LED2, blink_state);
    }
  } else {
    update_led(PIN_LED2, HIGH);
  }

  if (n - tl >= 100) {
    update_led(PIN_LED1, LOW);
  }
#endif

// reset pressed keys for OSD
zxkbd.resetOsdControls();

delayMicroseconds(1);

}
