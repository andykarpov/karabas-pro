#include "joystick.h"
#include "hal.h"
#include "keyboard.h"
#include "zxosd.h"

#define SC_BTN_UP    0x0001
#define SC_BTN_DOWN  0x0002
#define SC_BTN_LEFT  0x0004
#define SC_BTN_RIGHT 0x0008
#define SC_BTN_B     0x0010
#define SC_BTN_C     0x0020
#define SC_BTN_A     0x0040
#define SC_BTN_START 0x0080
#define SC_CTL_ON    0x1000

static bool s_is_started = false;
static uint8_t s_last_joy_flags = 0;
static uint16_t s_sega_state = 0;
static uint32_t s_sega_last_read_time = 0;
static bool s_sega_six_button_mode = false;

void joystick_init(void)
{

  // Strobe pin (PC1) as output HIGH
  DDRC |= (1 << PC1);
  PORTC |= (1 << PC1);

  // Inputs with pullup:
  // UP (PD6)
  DDRD &= ~(1 << PD6);
  PORTD |= (1 << PD6);

  // DOWN (PB0), LEFT (PB1)
  DDRB &= ~((1 << PB0) | (1 << PB1));
  PORTB |= ((1 << PB0) | (1 << PB1));

  // FIRE1 (PC0), FIRE2 (PC3)
  DDRC &= ~((1 << PC0) | (1 << PC3));
  PORTC |= ((1 << PC0) | (1 << PC3));

  // RIGHT (PB2 / SS): output LOW initially
  DDRB |= (1 << PB2);
  PORTB &= ~(1 << PB2);

  s_is_started = true;
}

bool joystick_started(void)
{
  return s_is_started;
}

static uint16_t sega_read_state(void)
{
  uint32_t n = millis();
  if (n - s_sega_last_read_time < 5) {
    return s_sega_state;
  }

  s_sega_state = 0;

  for (uint8_t cycle = 0; cycle < 8; cycle++) {
    // Set Strobe (PC1) low/high
    if (cycle % 2) {
      PORTC |= (1 << PC1);
    } else {
      PORTC &= ~(1 << PC1);
    }

    _delay_us(50);

    switch (cycle) {
      case 2:
        // Controller connected check: Left (PB1) and Right (PB2) both LOW
        if (!(PINB & (1 << PB1)) && !(PINB & (1 << PB2))) {
          s_sega_state |= SC_CTL_ON;
          if (!(PINC & (1 << PC0))) s_sega_state |= SC_BTN_A;
          if (!(PINC & (1 << PC3))) s_sega_state |= SC_BTN_START;
        }
        break;

      case 3:
        if (!(PIND & (1 << PD6))) s_sega_state |= SC_BTN_UP;
        if (!(PINB & (1 << PB0))) s_sega_state |= SC_BTN_DOWN;
        if (!(PINB & (1 << PB1))) s_sega_state |= SC_BTN_LEFT;
        if (!(PINB & (1 << PB2))) s_sega_state |= SC_BTN_RIGHT;
        if (!(PINC & (1 << PC0))) s_sega_state |= SC_BTN_B;
        if (!(PINC & (1 << PC3))) s_sega_state |= SC_BTN_C;
        break;

      case 4:
        s_sega_six_button_mode = (!(PIND & (1 << PD6)) && !(PINB & (1 << PB0)));
        break;

      default:
        break;
    }
  }

  if (!(s_sega_state & SC_CTL_ON)) {
    s_sega_six_button_mode = false;
  }

  s_sega_last_read_time = n;
  return s_sega_state;
}

void joystick_handle(bool joy_type)
{
  // Stop hardware SPI to read shared PB2 (SS / JOY_RIGHT)
  SPCR &= ~(1 << SPE);

  // Set PB2 as input with pullup
  DDRB &= ~(1 << PB2);
  PORTB |= (1 << PB2);

  uint8_t flags = 0;

  if (!joy_type) {
    // Kempston mode
    if (!(PINC & (1 << PC0))) flags |= (1 << ZX_JOY_FIRE);
    if (!(PINC & (1 << PC3))) flags |= (1 << ZX_JOY_FIRE2);
    if (!(PIND & (1 << PD6))) flags |= (1 << ZX_JOY_UP);
    if (!(PINB & (1 << PB0))) flags |= (1 << ZX_JOY_DOWN);
    if (!(PINB & (1 << PB1))) flags |= (1 << ZX_JOY_LEFT);
    if (!(PINB & (1 << PB2))) flags |= (1 << ZX_JOY_RIGHT);
  } else {
    // Sega mode
    uint16_t st = sega_read_state();
    if (st & SC_BTN_B)     flags |= (1 << ZX_JOY_FIRE);
    if (st & SC_BTN_C)     flags |= (1 << ZX_JOY_FIRE2);
    if (st & SC_BTN_UP)    flags |= (1 << ZX_JOY_UP);
    if (st & SC_BTN_DOWN)  flags |= (1 << ZX_JOY_DOWN);
    if (st & SC_BTN_LEFT)  flags |= (1 << ZX_JOY_LEFT);
    if (st & SC_BTN_RIGHT) flags |= (1 << ZX_JOY_RIGHT);
    if (st & SC_BTN_A)     flags |= (1 << ZX_JOY_A);
    if (st & SC_BTN_START) flags |= (1 << ZX_JOY_B);
  }

  // Restore PB2 as output low for SPI SS
  DDRB |= (1 << PB2);
  PORTB &= ~(1 << PB2);

  // Restore hardware SPI
  SPCR |= (1 << MSTR) | (1 << SPE);

  // Check for change
  if (flags != s_last_joy_flags) {
    s_last_joy_flags = flags;

    // Pack OSD joystick format: [START, A, FIRE2, FIRE, UP, DOWN, LEFT, RIGHT]
    uint8_t osd_joy = 0;
    if (flags & (1 << ZX_JOY_RIGHT)) osd_joy |= (1 << 0);
    if (flags & (1 << ZX_JOY_LEFT))  osd_joy |= (1 << 1);
    if (flags & (1 << ZX_JOY_DOWN))  osd_joy |= (1 << 2);
    if (flags & (1 << ZX_JOY_UP))    osd_joy |= (1 << 3);
    if (flags & (1 << ZX_JOY_FIRE))  osd_joy |= (1 << 4);
    if (flags & (1 << ZX_JOY_FIRE2)) osd_joy |= (1 << 5);
    if (flags & (1 << ZX_JOY_A))     osd_joy |= (1 << 6);
    if (flags & (1 << ZX_JOY_B))     osd_joy |= (1 << 7);

    if (keyboard_get_is_osd_overlay()) {
      zxosd_update_joy_state(osd_joy);
    }
    keyboard_apply_joy(osd_joy);
  }

  // Transmit current state to FPGA
  spi_send(CMD_JOY, 0, flags);
}

uint8_t joystick_get_state(void)
{
  return s_last_joy_flags;
}
