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
#include <SPI.h>
#include "config.h"
#include "ZXKeyboard.h"
#include "ZXMouse.h"
#include "ZXJoystick.h"
#include "ZXRTC.h"
#include "ZXOSD.h"

#define STRINGIFY(s) STRINGIFY1(s)
#define STRINGIFY1(s) #s

//ZXKeyboard zxkbd;
ZXMouse zxmouse;
ZXJoystick zxjoy;
//ZXRTC zxrtc;
ZXOSD zxosd;

bool init_done = false; // init done
bool blink_state = false;
bool led1_state = false;
bool led2_state = false;
bool led1_overwrite = false;
bool led2_overwrite = false;
bool boot_popup = true;

unsigned long tl, tl1, tl2, tb, tb1, tb2, tpopup = 0; // last time

SPISettings settingsA(1000000, MSBFIRST, SPI_MODE0); // SPI transmission settings

void spi_send(uint8_t addr, uint8_t data);
void process_in_cmd(uint8_t cmd, uint8_t data);
void update_led(uint8_t led, bool state);
void setup();
void loop();

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

void process_in_cmd(uint8_t cmd, uint8_t data)
{
  if (cmd == CMD_INIT_REQ && !init_done) {
      init_done = true;
      uint8_t max_turbo = data >> 6;
      uint8_t cfg = data & 0b00111111;
      zxkbd.setMaxTurbo(max_turbo);
      zxkbd.transmit();
      zxrtc.sendAll();
      zxkbd.doReset();
      zxosd.setFpgaCfg(cfg);
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
  tl = millis();
  if (!led1_overwrite) {
    update_led(PIN_LED1, HIGH);
  }

  if (!zxosd.started()) return;

  // overlay has more priority than popup
  if (zxkbd.getIsOsdOverlay()) {
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
      case ZXKeyboard::EVENT_OSD_KEYBOARD_TYPE:  zxosd.updateKeyboardType(); break;
      case ZXKeyboard::EVENT_OSD_PAUSE:  zxosd.updatePause(); break;
      case ZXKeyboard::EVENT_OSD_TURBO:  zxosd.updateTurbo(); break;
      case ZXKeyboard::EVENT_OSD_SCREEN_MODE: zxosd.updateScreenMode(); break;
    }
  } else {
    switch (event_type) {
      case ZXKeyboard::EVENT_OSD_SWAP_AB:
      case ZXKeyboard::EVENT_OSD_ROMBANK:
      case ZXKeyboard::EVENT_OSD_TURBOFDC:
      case ZXKeyboard::EVENT_OSD_COVOX:
      case ZXKeyboard::EVENT_OSD_STEREO:
      case ZXKeyboard::EVENT_OSD_SSG:
      case ZXKeyboard::EVENT_OSD_VIDEO:
      case ZXKeyboard::EVENT_OSD_VSYNC:
      case ZXKeyboard::EVENT_OSD_JOYSTICK:
      case ZXKeyboard::EVENT_OSD_KEYBOARD_TYPE:
      case ZXKeyboard::EVENT_OSD_PAUSE:
      case ZXKeyboard::EVENT_OSD_TURBO:
      case ZXKeyboard::EVENT_OSD_SCREEN_MODE: 
        tpopup = millis();
        if (!zxkbd.getIsOsdPopup()) {
          zxosd.clear();
        }
        zxkbd.setOsdPopup(true);
        zxosd.initPopup(event_type);
      break;
    }
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

// update OSD by mouse events
void on_mouse(uint8_t event_type)
{
  if ((!zxkbd.started()) || (!zxosd.started())) return;
   switch (event_type) {
    case ZXMouse::EVENT_OSD_MOUSE_SWAPPED:  
      zxkbd.setMouseSwap(zxmouse.getMouseSwap());
      update_led(PIN_LED1, HIGH);
      delay(100);
      update_led(PIN_LED1, LOW);
      delay(100);
      update_led(PIN_LED1, HIGH);
      delay(100);
      update_led(PIN_LED1, LOW);
    break;
    case ZXMouse::EVENT_OSD_MOUSE_DATA: 
      if (zxkbd.getIsOsdOverlay()) { 
        zxosd.updateMouse(zxmouse.getX(), zxmouse.getY(), zxmouse.getZ()); 
      }
    break;
   }
}

// update OSD by joy events
void on_joystick(uint8_t evt, uint8_t data)
{
  if ((!zxkbd.started()) || (!zxosd.started())) return;
  if (zxkbd.getIsOsdOverlay()) {
    zxosd.updateJoyState(data);
  }
}

// initial setup
void setup()
{
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

  zxkbd.begin(spi_send, on_keyboard, SEND_ECHO_ON_START);
  zxrtc.begin(spi_send, on_time);
  zxmouse.begin(spi_send, on_mouse);
  zxmouse.setMouseSwap(zxkbd.getMouseSwap());
  zxjoy.begin(spi_send, on_joystick);
  zxosd.begin(spi_send);
  const char* ver = STRINGIFY(BUILD_VER);
  zxosd.setAvrBuildNum(ver);

  // waiting for init
  while (!init_done) {
    spi_send(CMD_NONE, 0x00);
    spi_send(CMD_INIT_REQ, 0x00);
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

  tpopup = millis();
  zxosd.clear();
  zxkbd.setOsdPopup(true);
  zxosd.initPopup(ZXKeyboard::EVENT_OSD_POPUP);
  boot_popup = true;

  digitalWrite(PIN_LED1, LOW);
}


// main loop
void loop()
{
  unsigned long n = millis();

  zxkbd.handle();
  zxosd.handle();
  zxkbd.transmit();
  zxrtc.handle();
  zxmouse.handle(zxkbd.getIsMenu());
  zxjoy.handle(zxkbd.getJoyType());

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

  // hide osd popup after 1 second
  if (zxkbd.getIsOsdPopup() && (millis() - tpopup > ((boot_popup) ? BOOT_POPUP_TIMEOUT : POPUP_TIMEOUT))) {
    zxkbd.setOsdPopup(false);
    boot_popup = false;
  }

  // reset pressed keys for OSD
  zxkbd.resetOsdControls();

  delayMicroseconds(1);

}
