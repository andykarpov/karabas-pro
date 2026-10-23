#ifndef __HAL_H__
#define __HAL_H__

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <avr/eeprom.h>
#include <util/delay.h>

#ifndef F_CPU
#define F_CPU 16000000UL
#endif

typedef uint8_t byte;
typedef uint16_t word;
typedef bool boolean;

// Arduino pin compatibility
#ifndef A0
#define A0 14
#define A1 15
#define A2 16
#define A3 17
#define A4 18
#define A5 19
#define A6 20
#define A7 21
#endif

// Interrupt modes
#ifndef CHANGE
#define CHANGE 1
#endif
#ifndef FALLING
#define FALLING 2
#endif
#ifndef RISING
#define RISING 3
#endif
#ifndef NOT_AN_INTERRUPT
#define NOT_AN_INTERRUPT -1
#endif
#ifndef digitalPinToInterrupt
#define digitalPinToInterrupt(p) (((p) == 2) ? 0 : (((p) == 3) ? 1 : NOT_AN_INTERRUPT))
#endif

#ifdef __cplusplus
extern "C" {
#endif

void hal_attach_interrupt(uint8_t pin, void (*handler)(void), uint8_t mode);
void hal_detach_interrupt(uint8_t pin);

#ifdef __cplusplus
}
#endif

#define attachInterrupt(pin, handler, mode) hal_attach_interrupt(pin, handler, mode)
#define detachInterrupt(pin) hal_detach_interrupt(pin)

// Bit manipulation macros
#ifndef bitRead
#define bitRead(value, bit) (((value) >> (bit)) & 0x01)
#endif
#ifndef bitSet
#define bitSet(value, bit) ((value) |= (1UL << (bit)))
#endif
#ifndef bitClear
#define bitClear(value, bit) ((value) &= ~(1UL << (bit)))
#endif
#ifndef bitWrite
#define bitWrite(value, bit, bitvalue) ((bitvalue) ? bitSet(value, bit) : bitClear(value, bit))
#endif
#ifndef lowByte
#define lowByte(w) ((uint8_t) ((w) & 0xff))
#endif
#ifndef highByte
#define highByte(w) ((uint8_t) ((w) >> 8))
#endif

#ifndef min
#define min(a,b) ((a)<(b)?(a):(b))
#endif
#ifndef max
#define max(a,b) ((a)>(b)?(a):(b))
#endif
#ifndef constrain
#define constrain(amt,low,high) ((amt)<(low)?(low):((amt)>(high)?(high):(amt)))
#endif

// EEPROM helpers
static inline uint8_t hal_eeprom_read(uint16_t addr) {
  return eeprom_read_byte((const uint8_t*)addr);
}
static inline void hal_eeprom_update(uint16_t addr, uint8_t val) {
  eeprom_update_byte((uint8_t*)addr, val);
}

#ifndef HIGH
#define HIGH 1
#endif
#ifndef LOW
#define LOW 0
#endif
#ifndef INPUT
#define INPUT 0
#endif
#ifndef OUTPUT
#define OUTPUT 1
#endif
#ifndef INPUT_PULLUP
#define INPUT_PULLUP 2
#endif

// Direct port GPIO helpers
static inline void hal_gpio_pin_mode(uint8_t pin, uint8_t mode) {
  if (pin < 8) {
    if (mode == OUTPUT) DDRD |= (1 << pin);
    else {
      DDRD &= ~(1 << pin);
      if (mode == INPUT_PULLUP) PORTD |= (1 << pin);
      else PORTD &= ~(1 << pin);
    }
  } else if (pin < 14) {
    uint8_t b = pin - 8;
    if (mode == OUTPUT) DDRB |= (1 << b);
    else {
      DDRB &= ~(1 << b);
      if (mode == INPUT_PULLUP) PORTB |= (1 << b);
      else PORTB &= ~(1 << b);
    }
  } else if (pin <= 19) {
    uint8_t c = pin - 14;
    if (mode == OUTPUT) DDRC |= (1 << c);
    else {
      DDRC &= ~(1 << c);
      if (mode == INPUT_PULLUP) PORTC |= (1 << c);
      else PORTC &= ~(1 << c);
    }
  }
}

static inline void hal_gpio_write(uint8_t pin, uint8_t val) {
  if (pin < 8) {
    if (val) PORTD |= (1 << pin); else PORTD &= ~(1 << pin);
  } else if (pin < 14) {
    uint8_t b = pin - 8;
    if (val) PORTB |= (1 << b); else PORTB &= ~(1 << b);
  } else if (pin <= 19) {
    uint8_t c = pin - 14;
    if (val) PORTC |= (1 << c); else PORTC &= ~(1 << c);
  }
}

static inline uint8_t hal_gpio_read(uint8_t pin) {
  if (pin < 8) return (PIND & (1 << pin)) ? HIGH : LOW;
  if (pin < 14) return (PINB & (1 << (pin - 8))) ? HIGH : LOW;
  if (pin <= 19) return (PINC & (1 << (pin - 14))) ? HIGH : LOW;
  return LOW;
}

#ifndef pinMode
#define pinMode(pin, mode) hal_gpio_pin_mode(pin, mode)
#endif
#ifndef digitalWrite
#define digitalWrite(pin, val) hal_gpio_write(pin, val)
#endif
#ifndef digitalRead
#define digitalRead(pin) hal_gpio_read(pin)
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Delays & tick
void delay_ms(uint16_t ms);
void delay_us(uint16_t us);
void hal_timer_init(void);

void setup(void);
void loop(void);

#ifndef ARDUINO
static inline void delay(uint16_t ms) { delay_ms(ms); }
static inline void delayMicroseconds(uint16_t us) { delay_us(us); }
uint32_t millis(void);
#else
void delay(unsigned long ms);
void delayMicroseconds(unsigned int us);
unsigned long millis(void);
#endif

// SPI Master
void hal_spi_init(void);
uint8_t hal_spi_transfer(uint8_t data);
void spi_send(uint8_t cmd, uint8_t addr, uint8_t data);

static inline void hal_spi_cs_low(void)  { PORTD &= ~(1 << PD7); }
static inline void hal_spi_cs_high(void) { PORTD |=  (1 << PD7); }

// TWI (I2C) Master
void hal_twi_init(void);
bool hal_twi_write_reg(uint8_t dev_addr, uint8_t reg_addr, uint8_t data);
bool hal_twi_read_reg(uint8_t dev_addr, uint8_t reg_addr, uint8_t *data);
bool hal_twi_write_buf(uint8_t dev_addr, uint8_t reg_addr, const uint8_t *buf, uint8_t len);
bool hal_twi_read_buf(uint8_t dev_addr, uint8_t reg_addr, uint8_t *buf, uint8_t len);

// ADC for hardware buttons (ADC6, ADC7)
void hal_adc_init(void);
uint16_t hal_adc_read(uint8_t channel);

// GPIO Fast Helpers
static inline void hal_led1_set(bool on) { if (on) PORTC |= (1 << PC2); else PORTC &= ~(1 << PC2); }
static inline void hal_led2_set(bool on) { if (on) PORTC |= (1 << PC1); else PORTC &= ~(1 << PC1); }

#ifdef __cplusplus
}
#endif

#endif // __HAL_H__
