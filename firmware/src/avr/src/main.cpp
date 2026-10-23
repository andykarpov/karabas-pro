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
Ukraine, 2021 - 2023
*/

#include "hal.h"
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

void spi_send(uint8_t cmd, uint8_t addr, uint8_t data);
void process_in_cmd(uint8_t cmd, uint8_t addr, uint8_t data);
void update_led(uint8_t led, bool state);
void setup();
void loop();

void spi_send(uint8_t cmd, uint8_t addr, uint8_t data)
{
  hal_spi_cs_low();
  uint8_t rx_cmd = hal_spi_transfer(cmd);
  uint8_t rx_addr = hal_spi_transfer(addr);
  uint8_t rx_data = hal_spi_transfer(data);
  hal_spi_cs_high();
  if (rx_cmd > 0) {
    process_in_cmd(rx_cmd, rx_addr, rx_data);
  }
}

void process_in_cmd(uint8_t cmd, uint8_t addr, uint8_t data)
{
  if (cmd == CMD_INIT_REQ && !init_done) {
      init_done = true;
      uint8_t max_turbo = data >> 6;
      uint8_t cfg = data & 0b00111111;
      zxkbd.setMaxTurbo(max_turbo);
      zxkbd.transmit();
      zxrtc.sendAll();
      zxrtc.sendAll();
      zxkbd.doReset();
      zxosd.setFpgaCfg(cfg);
  }

  if (cmd == CMD_RTC_INIT_REQ && !zxrtc.getInitDone()) {
    zxrtc.setInitDone(true);
    zxrtc.sendAll();
  }

  if (cmd == CMD_BUILD_REQ) {
    zxosd.setFpgaBuildNum(addr, data);
  }

#if ALLOW_LED_OVERRIDE
  if (cmd == CMD_LED_WRITE) {
    led1_state = bitRead(data, 0);
    led2_state = bitRead(data, 1);
    led1_overwrite = bitRead(data, 2);
    led2_overwrite = bitRead(data, 3);
  }
#endif

  if (cmd == CMD_RTC) {
    zxrtc.setData(addr, data);
  }
}

// update led state
void update_led(uint8_t led, bool state)
{
  if (led == PIN_LED2) {
    if (zxkbd.getJoyType()) {
      hal_led2_set(true);
    } else {
      hal_led2_set(state);
    }
  } else if (led == PIN_LED1) {
    hal_led1_set(state);
  }
}

// update OSD by keyboard events
void on_keyboard (uint8_t event_type, uint16_t scancode)
{
  tl = millis();
  if (!led1_overwrite) {
    update_led(PIN_LED1, HIGH);
  }

  if (!zxosd.started()) return;

  int8_t item_idx = ZXOSD::eventToMenuItem(event_type);

  // overlay has more priority than popup
  if (zxkbd.getIsOsdOverlay()) {
    if (event_type == ZXKeyboard::EVENT_OSD_OVERLAY) {
      zxosd.initOverlay();
    } else if (event_type == ZXKeyboard::EVENT_OSD_SCANCODE) {
      zxosd.updateScancode(scancode);
    } else if (item_idx >= 0) {
      zxosd.updateItem((uint8_t)item_idx);
    }
  } else {
    if (item_idx >= 0) {
      tpopup = millis();
      if (!zxkbd.getIsOsdPopup()) {
        zxosd.clear();
      }
      zxkbd.setOsdPopup(true);
      zxosd.initPopup(event_type);
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

  // update keyboard keys with joystick state
  switch (zxkbd.getJoyMode()) {
    case 1: // sinclair 1
      zxkbd.setKey(ZX_K_1, bitRead(data, 1)); // L
      zxkbd.setKey(ZX_K_2, bitRead(data, 0)); // R
      zxkbd.setKey(ZX_K_3, bitRead(data, 2)); // D
      zxkbd.setKey(ZX_K_4, bitRead(data, 3)); // U
      zxkbd.setKey(ZX_K_5, bitRead(data, 4)); // F
    break; 
    case 2: // sinclair 2
      zxkbd.setKey(ZX_K_6, bitRead(data, 1)); // L
      zxkbd.setKey(ZX_K_7, bitRead(data, 0)); // R
      zxkbd.setKey(ZX_K_8, bitRead(data, 2)); // D
      zxkbd.setKey(ZX_K_9, bitRead(data, 3)); // U
      zxkbd.setKey(ZX_K_0, bitRead(data, 4)); // F
    break;
    case 3: // cursor
      zxkbd.setKey(ZX_K_5, bitRead(data, 1)); // L
      zxkbd.setKey(ZX_K_6, bitRead(data, 2)); // D
      zxkbd.setKey(ZX_K_7, bitRead(data, 3)); // U
      zxkbd.setKey(ZX_K_8, bitRead(data, 0)); // R
      zxkbd.setKey(ZX_K_0, bitRead(data, 4)); // F
    break;
    case 4: // qaop
      zxkbd.setKey(ZX_K_Q, bitRead(data, 3)); // U
      zxkbd.setKey(ZX_K_A, bitRead(data, 2)); // D
      zxkbd.setKey(ZX_K_O, bitRead(data, 1)); // L
      zxkbd.setKey(ZX_K_P, bitRead(data, 0)); // R
      zxkbd.setKey(ZX_K_M, bitRead(data, 4)); // F
    break;
  }

}

// initial setup
void setup()
{
  // Joy right / SS as output low initially
  DDRB |= (1 << PB2);
  PORTB &= ~(1 << PB2);

  // Setup hardware SPI and ADC
  hal_spi_init();
  hal_adc_init();

  // LEDs as outputs, initially HIGH (off)
  DDRC |= (1 << PC2) | (1 << PC1);
  hal_led1_set(true);
  hal_led2_set(true);

  // Keyboard and mouse pins as input with pullup
  DDRD &= ~((1 << PD2) | (1 << PD4) | (1 << PD3) | (1 << PD5));
  PORTD |=  (1 << PD2) | (1 << PD4) | (1 << PD3) | (1 << PD5);

  zxkbd.begin(spi_send, on_keyboard, SEND_ECHO_ON_START);
  zxmouse.begin(spi_send, on_mouse);
  zxmouse.setMouseSwap(zxkbd.getMouseSwap());
  zxrtc.begin(spi_send, on_time);
  zxjoy.begin(spi_send, on_joystick);
  zxosd.begin(spi_send);
  const char* ver = STRINGIFY(BUILD_VER);
  zxosd.setAvrBuildNum(ver);

  // waiting for init
  while (!init_done) {
    spi_send(CMD_NONE, 0, 0x00);
    spi_send(CMD_INIT_REQ, 0, 0x00);
  }

  // request build num from the fpga
  spi_send(CMD_BUILD_REQ, 0, 0x00);
  spi_send(CMD_BUILD_REQ, 1, 0x00);
  spi_send(CMD_BUILD_REQ, 2, 0x00);
  spi_send(CMD_BUILD_REQ, 3, 0x00);
  spi_send(CMD_BUILD_REQ, 4, 0x00);
  spi_send(CMD_BUILD_REQ, 5, 0x00);
  spi_send(CMD_BUILD_REQ, 6, 0x00);
  spi_send(CMD_BUILD_REQ, 7, 0x00);

  tpopup = millis();
  zxosd.clear();
  zxkbd.setOsdPopup(true);
  zxosd.initPopup(ZXKeyboard::EVENT_OSD_POPUP);
  boot_popup = true;

  hal_led1_set(false);
}


// main loop
void loop()
{
  unsigned long n = millis();

  zxkbd.handle();
  zxosd.handle();
  zxkbd.transmit();
  zxmouse.handle(zxkbd.getIsMenu());
  zxrtc.handle();
  zxjoy.handle(zxkbd.getJoyType());

// react on hardware buttons every 100ms
#if USE_HW_BUTTONS
  if (n - tb >= 100) {

    bool btn1 = (hal_adc_read(6) < 100);
    bool btn2 = (hal_adc_read(7) < 100);

    //if (btn2) zxkbd.doReset();
    //if (btn1) zxkbd.doMagic();
    
    zxkbd.setKey(ZX_K_RESET, btn2);
    zxkbd.setKey(ZX_K_MAGICK, btn1);

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

#if !defined(ARDUINO)
int main(void)
{
  hal_timer_init();
  setup();
  for (;;) {
    loop();
  }
  return 0;
}
#endif
