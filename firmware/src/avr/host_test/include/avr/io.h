/* Host build of the AVR firmware: the ATmega328P registers the firmware touches (host_test). */
#ifndef HOST_AVR_IO_H
#define HOST_AVR_IO_H
#include <stdint.h>
extern volatile uint8_t DDRB, DDRC, DDRD, PORTB, PORTC, PORTD, SPCR, SPSR, SPDR, SREG;
uint8_t sim_pin(char port);
#define PINB (sim_pin('B'))
#define PINC (sim_pin('C'))
#define PIND (sim_pin('D'))
#define PB0 0
#define PB1 1
#define PB2 2
#define PB3 3
#define PB4 4
#define PB5 5
#define PB6 6
#define PB7 7
#define PC0 0
#define PC1 1
#define PC2 2
#define PC3 3
#define PC4 4
#define PC5 5
#define PC6 6
#define PD0 0
#define PD1 1
#define PD2 2
#define PD3 3
#define PD4 4
#define PD5 5
#define PD6 6
#define PD7 7
#define SPE 6
#define MSTR 4
#define SPR0 0
#define SPR1 1
#define SPIF 7
#define SPI2X 0
#endif
