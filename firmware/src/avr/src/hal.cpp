#include "hal.h"

/****************************************************************************/
// Timer0 1ms Tick
/****************************************************************************/

static volatile uint32_t s_millis = 0;

#if !defined(ARDUINO)
ISR(TIMER0_COMPA_vect)
{
  s_millis++;
}
#endif

void hal_timer_init(void)
{
#if !defined(ARDUINO)
  // CTC mode, prescaler 64, 16MHz / 64 / 250 = 1000 Hz (1 ms)
  TCCR0A = (1 << WGM01);
  TCCR0B = (1 << CS01) | (1 << CS00);
  OCR0A = 249;
  TIMSK0 |= (1 << OCIE0A);
  sei();
#endif
}

#if !defined(ARDUINO)
uint32_t millis(void)
{
  uint32_t m;
  uint8_t sreg = SREG;
  cli();
  m = s_millis;
  SREG = sreg;
  return m;
}
#endif

void delay_ms(uint16_t ms)
{
  while (ms--) {
    _delay_ms(1);
  }
}

void delay_us(uint16_t us)
{
  while (us--) {
    _delay_us(1);
  }
}

/****************************************************************************/
// SPI Master Driver
/****************************************************************************/

void hal_spi_init(void)
{
  // MOSI (PB3), SCK (PB5), SS hardware (PB2) as output
  DDRB |= (1 << PB3) | (1 << PB5) | (1 << PB2);
  // MISO (PB4) as input with pullup
  DDRB &= ~(1 << PB4);
  PORTB |= (1 << PB4);

  // Dedicated CS pin to FPGA (PD7) as output, set HIGH
  DDRD |= (1 << PD7);
  PORTD |= (1 << PD7);

  // SPE: SPI Enable, MSTR: Master, SPR0: Prescaler 16 (1 MHz at 16 MHz)
  SPCR = (1 << SPE) | (1 << MSTR) | (1 << SPR0);
  SPSR = 0;
}

uint8_t hal_spi_transfer(uint8_t data)
{
  SPCR |= (1 << SPE) | (1 << MSTR);
  SPDR = data;
  while (!(SPSR & (1 << SPIF)));
  return SPDR;
}

/****************************************************************************/
// Hardware TWI (I2C) Master Driver
/****************************************************************************/

#define TWI_TIMEOUT 10000

static bool twi_start(uint8_t address)
{
  uint16_t timeout = TWI_TIMEOUT;
  TWCR = (1 << TWINT) | (1 << TWSTA) | (1 << TWEN);
  while (!(TWCR & (1 << TWINT))) {
    if (--timeout == 0) return false;
  }

  uint8_t status = TWSR & 0xF8;
  if (status != 0x08 && status != 0x10) return false; // START or REPEATED START

  timeout = TWI_TIMEOUT;
  TWDR = address;
  TWCR = (1 << TWINT) | (1 << TWEN);
  while (!(TWCR & (1 << TWINT))) {
    if (--timeout == 0) return false;
  }

  status = TWSR & 0xF8;
  return (status == 0x18 || status == 0x40); // SLA+W ACK or SLA+R ACK
}

static void twi_stop(void)
{
  TWCR = (1 << TWINT) | (1 << TWSTO) | (1 << TWEN);
  uint16_t timeout = TWI_TIMEOUT;
  while ((TWCR & (1 << TWSTO))) {
    if (--timeout == 0) break;
  }
}

static bool twi_write_byte(uint8_t data)
{
  uint16_t timeout = TWI_TIMEOUT;
  TWDR = data;
  TWCR = (1 << TWINT) | (1 << TWEN);
  while (!(TWCR & (1 << TWINT))) {
    if (--timeout == 0) return false;
  }
  return ((TWSR & 0xF8) == 0x28); // Data ACK
}

static uint8_t twi_read_byte(bool ack)
{
  uint16_t timeout = TWI_TIMEOUT;
  TWCR = (1 << TWINT) | (1 << TWEN) | (ack ? (1 << TWEA) : 0);
  while (!(TWCR & (1 << TWINT))) {
    if (--timeout == 0) return 0xFF;
  }
  return TWDR;
}

void hal_twi_init(void)
{
  // 100 kHz at 16 MHz CPU
  TWSR = 0;
  TWBR = 72;
  TWCR = (1 << TWEN);
}

bool hal_twi_write_reg(uint8_t dev_addr, uint8_t reg_addr, uint8_t data)
{
  if (!twi_start((dev_addr << 1) | 0)) {
    twi_stop();
    return false;
  }
  if (!twi_write_byte(reg_addr) || !twi_write_byte(data)) {
    twi_stop();
    return false;
  }
  twi_stop();
  return true;
}

bool hal_twi_read_reg(uint8_t dev_addr, uint8_t reg_addr, uint8_t *data)
{
  if (!twi_start((dev_addr << 1) | 0)) {
    twi_stop();
    return false;
  }
  if (!twi_write_byte(reg_addr)) {
    twi_stop();
    return false;
  }
  if (!twi_start((dev_addr << 1) | 1)) {
    twi_stop();
    return false;
  }
  *data = twi_read_byte(false); // NACK
  twi_stop();
  return true;
}

bool hal_twi_write_buf(uint8_t dev_addr, uint8_t reg_addr, const uint8_t *buf, uint8_t len)
{
  if (!twi_start((dev_addr << 1) | 0)) {
    twi_stop();
    return false;
  }
  if (!twi_write_byte(reg_addr)) {
    twi_stop();
    return false;
  }
  for (uint8_t i = 0; i < len; i++) {
    if (!twi_write_byte(buf[i])) {
      twi_stop();
      return false;
    }
  }
  twi_stop();
  return true;
}

bool hal_twi_read_buf(uint8_t dev_addr, uint8_t reg_addr, uint8_t *buf, uint8_t len)
{
  if (len == 0) return true;
  if (!twi_start((dev_addr << 1) | 0)) {
    twi_stop();
    return false;
  }
  if (!twi_write_byte(reg_addr)) {
    twi_stop();
    return false;
  }
  if (!twi_start((dev_addr << 1) | 1)) {
    twi_stop();
    return false;
  }
  for (uint8_t i = 0; i < len; i++) {
    buf[i] = twi_read_byte(i < (len - 1)); // ACK all except last
  }
  twi_stop();
  return true;
}

/****************************************************************************/
// ADC Driver (Fast ADC for BTN1 on ADC6, BTN2 on ADC7)
/****************************************************************************/

void hal_adc_init(void)
{
  // Enable ADC, prescaler 64 (16 MHz / 64 = 250 kHz)
  ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1);
}

uint16_t hal_adc_read(uint8_t channel)
{
  // AVCC reference with external capacitor at AREF pin
  ADMUX = (1 << REFS0) | (channel & 0x07);
  ADCSRA |= (1 << ADSC);
  while (ADCSRA & (1 << ADSC));
  return ADC;
}

extern "C" void __cxa_pure_virtual(void)
{
  while (1);
}

/****************************************************************************/
// External Interrupts (INT0 / PD2, INT1 / PD3)
/****************************************************************************/

static void (*s_int0_cb)(void) = 0;
static void (*s_int1_cb)(void) = 0;

ISR(INT0_vect)
{
  if (s_int0_cb) s_int0_cb();
}

ISR(INT1_vect)
{
  if (s_int1_cb) s_int1_cb();
}

void hal_attach_interrupt(uint8_t pin, void (*handler)(void), uint8_t mode)
{
  if (pin == 2 || pin == 0) {
    s_int0_cb = handler;
    EICRA = (EICRA & ~((1 << ISC01) | (1 << ISC00))) | ((mode == FALLING ? 2 : (mode == RISING ? 3 : 1)) << ISC00);
    EIFR |= (1 << INTF0);
    EIMSK |= (1 << INT0);
  } else if (pin == 3 || pin == 1) {
    s_int1_cb = handler;
    EICRA = (EICRA & ~((1 << ISC11) | (1 << ISC10))) | ((mode == FALLING ? 2 : (mode == RISING ? 3 : 1)) << ISC10);
    EIFR |= (1 << INTF1);
    EIMSK |= (1 << INT1);
  }
}

void hal_detach_interrupt(uint8_t pin)
{
  if (pin == 2 || pin == 0) {
    EIMSK &= ~(1 << INT0);
    s_int0_cb = 0;
  } else if (pin == 3 || pin == 1) {
    EIMSK &= ~(1 << INT1);
    s_int1_cb = 0;
  }
}
