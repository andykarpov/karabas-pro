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

static bool s_init_done = false;

static bool s_led1_state = false;
static bool s_led2_state = false;
static bool s_led1_overwrite = false;
static bool s_led2_overwrite = false;
static uint32_t s_tl1 = 0;
static bool s_blink_state = false;

static uint32_t s_tb = 0;
static uint32_t s_tl = 0;
static uint32_t s_tl2 = 0;

static void process_in_cmd(uint8_t cmd, uint8_t addr, uint8_t data);

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
  if (cmd == CMD_INIT_REQ && !s_init_done) {
    s_init_done = true;
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

  if (cmd == CMD_LED_WRITE) {
    if (keyboard_get_led_override()) {
      s_led1_state     = bitRead(data, 0);
      s_led2_state     = bitRead(data, 1);
      s_led1_overwrite = bitRead(data, 2);
      s_led2_overwrite = bitRead(data, 3);
    }
  }

  if (cmd == CMD_RTC) {
    rtc_set_data(addr, data);
  }
}

static inline void led1_set(bool state)
{
  hal_led1_set(state);
}

static inline void led2_set(bool state)
{
  if (keyboard_get_joy_type()) {
    hal_led2_set(true);
  } else {
    hal_led2_set(state);
  }
}

int main(void)
{
  // 1. Hardware timer initialization
  hal_timer_init();

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

  // 2. Subsystem inits
  keyboard_init();
  mouse_init();
  rtc_init();
  joystick_init();
  zxosd_init();

  zxosd_set_avr_build_num(STRINGIFY(BUILD_VER));

  // 3. Waiting for FPGA init handshake
  while (!s_init_done) {
    spi_send(CMD_NONE, 0, 0x00);
    spi_send(CMD_INIT_REQ, 0, 0x00);
  }

  // Request build number from FPGA
  for (uint8_t i = 0; i < 8; i++) {
    spi_send(CMD_BUILD_REQ, i, 0x00);
  }

  // 4. Show boot splash popup
  zxosd_show_boot_popup();
  hal_led1_set(false);

  // 5. Main event loop
  for (;;) {
    uint32_t n = millis();

    // Process keyboard & trigger LED1 activity if key was pressed
    if (keyboard_handle()) {
      s_tl = n;
      if (keyboard_get_led_override()) {
        if (!s_led1_overwrite) led1_set(true);
      } else {
        led1_set(true);
      }
    }

    zxosd_handle();
    keyboard_transmit();
    mouse_handle(keyboard_get_is_menu());
    rtc_handle();
    joystick_handle(keyboard_get_joy_type());

    if (keyboard_get_hw_buttons()) {
      if (n - s_tb >= 100) {
        bool btn1 = (hal_adc_read(6) < 100);
        bool btn2 = (hal_adc_read(7) < 100);

        keyboard_set_key(ZX_K_RESET, btn2);
        keyboard_set_key(ZX_K_MAGICK, btn1);

        s_tb = n;
      }
    }

    if (keyboard_get_led_override()) {
      if (s_led1_overwrite) {
        if (s_led1_state) {
          led1_set(true);
        }
        if (n - s_tl1 >= 100) {
          s_tl1 = n;
          if (!s_led1_state) led1_set(false);
        }
      } else {
        if (n - s_tl >= 100) led1_set(false);
      }

      if (s_led2_overwrite) {
        if (s_led2_state) {
          led2_set(true);
        }
        if (n - s_tl2 >= 100) {
          s_tl2 = n;
          if (!s_led2_state) led2_set(false);
        }
      } else {
        led2_set(true);
      }
    } else {
      if (keyboard_get_pause()) {
        if (n - s_tl2 >= 500) {
          s_tl2 = n;
          s_blink_state = !s_blink_state;
          led2_set(s_blink_state);
        }
      } else {
        led2_set(true);
      }

      if (n - s_tl >= 100) {
        led1_set(false);
      }
    }

    keyboard_reset_osd_controls();
  }

  return 0;
}
