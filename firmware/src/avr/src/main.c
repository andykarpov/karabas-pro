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
Pure C implementation

@author Andy Karpov <andy.karpov@gmail.com>
Ukraine, 2021 - 2026
*/

#include "hal.h"
#include "config.h"
#include "keyboard.h"
#include "mouse.h"
#include "joystick.h"
#include "rtc.h"
#include "zxosd.h"
#include "utils.h"

#define STRINGIFY(s) STRINGIFY1(s)
#define STRINGIFY1(s) #s

static bool init_done = false;
static bool boot_popup = true;

#if ALLOW_LED_OVERRIDE
static bool led1_state = false;
static bool led2_state = false;
static bool led1_overwrite = false;
static bool led2_overwrite = false;
static uint32_t tl1 = 0;
#else
static bool blink_state = false;
#endif

#if USE_HW_BUTTONS
static uint32_t tb = 0;
#endif

static uint32_t tl = 0, tl2 = 0, tpopup = 0;

static void process_in_cmd(uint8_t cmd, uint8_t addr, uint8_t data);
static void update_led(uint8_t led, bool state);

void spi_send(uint8_t cmd, uint8_t addr, uint8_t data)
{
  hal_spi_cs_low();
  uint8_t rx_cmd  = hal_spi_transfer(cmd);
  uint8_t rx_addr = hal_spi_transfer(addr);
  uint8_t rx_data = hal_spi_transfer(data);
  hal_spi_cs_high();
  if (rx_cmd > 0) {
    process_in_cmd(rx_cmd, rx_addr, rx_data);
  }
}

static void process_in_cmd(uint8_t cmd, uint8_t addr, uint8_t data)
{
  if (cmd == CMD_INIT_REQ && !init_done) {
    init_done = true;
    uint8_t max_turbo = data >> 6;
    uint8_t cfg = data & 0b00111111;
    keyboard_set_max_turbo(max_turbo);
    keyboard_transmit();
    rtc_send_all();
    rtc_send_all();
    keyboard_do_reset();
    zxosd_set_fpga_cfg(cfg);
  }

  if (cmd == CMD_RTC_INIT_REQ && !rtc_get_init_done()) {
    rtc_set_init_done(true);
    rtc_send_all();
  }

  if (cmd == CMD_BUILD_REQ) {
    zxosd_set_fpga_build_num(addr, data);
  }

#if ALLOW_LED_OVERRIDE
  if (cmd == CMD_LED_WRITE) {
    led1_state     = bitRead(data, 0);
    led2_state     = bitRead(data, 1);
    led1_overwrite = bitRead(data, 2);
    led2_overwrite = bitRead(data, 3);
  }
#endif

  if (cmd == CMD_RTC) {
    rtc_set_data(addr, data);
  }
}

static void update_led(uint8_t led, bool state)
{
  if (led == PIN_LED2) {
    if (keyboard_get_joy_type()) {
      hal_led2_set(true);
    } else {
      hal_led2_set(state);
    }
  } else if (led == PIN_LED1) {
    hal_led1_set(state);
  }
}

static void on_keyboard(uint8_t event_type, uint16_t scancode)
{
  tl = millis();
#if ALLOW_LED_OVERRIDE
  if (!led1_overwrite) {
    update_led(PIN_LED1, HIGH);
  }
#else
  update_led(PIN_LED1, HIGH);
#endif

  if (!zxosd_started()) return;

  int8_t item_idx = zxosd_event_to_menu_item(event_type);

  if (keyboard_get_is_osd_overlay()) {
    if (event_type == EVENT_OSD_OVERLAY) {
      zxosd_init_overlay();
    } else if (event_type == EVENT_OSD_SCANCODE) {
      zxosd_update_scancode(scancode);
    } else if (item_idx >= 0) {
      zxosd_update_item((uint8_t)item_idx);
    }
  } else {
    if (item_idx >= 0) {
      tpopup = millis();
      if (!keyboard_get_is_osd_popup()) {
        zxosd_clear();
      }
      keyboard_set_osd_popup(true);
      zxosd_init_popup(event_type);
    }
  }
}

static void on_time(void)
{
  if (!keyboard_started() || !zxosd_started()) return;
  if (keyboard_get_is_osd_overlay()) {
    zxosd_update_time();
  }
}

static void on_mouse(uint8_t event_type)
{
  if (!keyboard_started() || !zxosd_started()) return;
  switch (event_type) {
    case EVENT_OSD_MOUSE_SWAPPED:
      keyboard_set_mouse_swap(mouse_get_swap());
      update_led(PIN_LED1, HIGH);
      delay_ms(100);
      update_led(PIN_LED1, LOW);
      delay_ms(100);
      update_led(PIN_LED1, HIGH);
      delay_ms(100);
      update_led(PIN_LED1, LOW);
      break;

    case EVENT_OSD_MOUSE_DATA:
      if (keyboard_get_is_osd_overlay()) {
        zxosd_update_mouse(mouse_get_x(), mouse_get_y(), mouse_get_z());
      }
      break;
  }
}

static void on_joystick(uint8_t evt, uint8_t data)
{
  (void)evt;
  if (!keyboard_started() || !zxosd_started()) return;
  if (keyboard_get_is_osd_overlay()) {
    zxosd_update_joy_state(data);
  }

  switch (keyboard_get_joy_mode()) {
    case 1: // sinclair 1
      keyboard_set_key(ZX_K_1, bitRead(data, 1)); // L
      keyboard_set_key(ZX_K_2, bitRead(data, 0)); // R
      keyboard_set_key(ZX_K_3, bitRead(data, 2)); // D
      keyboard_set_key(ZX_K_4, bitRead(data, 3)); // U
      keyboard_set_key(ZX_K_5, bitRead(data, 4)); // F
      break;
    case 2: // sinclair 2
      keyboard_set_key(ZX_K_6, bitRead(data, 1)); // L
      keyboard_set_key(ZX_K_7, bitRead(data, 0)); // R
      keyboard_set_key(ZX_K_8, bitRead(data, 2)); // D
      keyboard_set_key(ZX_K_9, bitRead(data, 3)); // U
      keyboard_set_key(ZX_K_0, bitRead(data, 4)); // F
      break;
    case 3: // cursor
      keyboard_set_key(ZX_K_5, bitRead(data, 1)); // L
      keyboard_set_key(ZX_K_6, bitRead(data, 2)); // D
      keyboard_set_key(ZX_K_7, bitRead(data, 3)); // U
      keyboard_set_key(ZX_K_8, bitRead(data, 0)); // R
      keyboard_set_key(ZX_K_0, bitRead(data, 4)); // F
      break;
    case 4: // qaop
      keyboard_set_key(ZX_K_Q, bitRead(data, 3)); // U
      keyboard_set_key(ZX_K_A, bitRead(data, 2)); // D
      keyboard_set_key(ZX_K_O, bitRead(data, 1)); // L
      keyboard_set_key(ZX_K_P, bitRead(data, 0)); // R
      keyboard_set_key(ZX_K_M, bitRead(data, 4)); // F
      break;
  }
}

void setup(void)
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

  keyboard_init(on_keyboard, SEND_ECHO_ON_START);
  mouse_init(on_mouse);
  mouse_set_swap(keyboard_get_mouse_swap());
  rtc_init(on_time);
  joystick_init(on_joystick);
  zxosd_init();

  const char *ver = STRINGIFY(BUILD_VER);
  zxosd_set_avr_build_num(ver);

  // Waiting for FPGA init
  while (!init_done) {
    spi_send(CMD_NONE, 0, 0x00);
    spi_send(CMD_INIT_REQ, 0, 0x00);
  }

  // Request build num from the FPGA
  for (uint8_t i = 0; i < 8; i++) {
    spi_send(CMD_BUILD_REQ, i, 0x00);
  }

  tpopup = millis();
  zxosd_clear();
  keyboard_set_osd_popup(true);
  zxosd_init_popup(EVENT_OSD_POPUP);
  boot_popup = true;

  hal_led1_set(false);
}

void loop(void)
{
  uint32_t n = millis();

  keyboard_handle();
  zxosd_handle();
  keyboard_transmit();
  mouse_handle(keyboard_get_is_menu());
  rtc_handle();
  joystick_handle(keyboard_get_joy_type());

#if USE_HW_BUTTONS
  if (n - tb >= 100) {
    bool btn1 = (hal_adc_read(6) < 100);
    bool btn2 = (hal_adc_read(7) < 100);

    keyboard_set_key(ZX_K_RESET, btn2);
    keyboard_set_key(ZX_K_MAGICK, btn1);

    tb = n;
  }
#endif

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
  if (keyboard_get_pause()) {
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

  // Hide OSD popup after timeout
  if (keyboard_get_is_osd_popup() && (millis() - tpopup > ((boot_popup) ? BOOT_POPUP_TIMEOUT : POPUP_TIMEOUT))) {
    keyboard_set_osd_popup(false);
    boot_popup = false;
  }

  keyboard_reset_osd_controls();
  delay_us(1);
}

int main(void)
{
  hal_timer_init();
  setup();
  for (;;) {
    loop();
  }
  return 0;
}
