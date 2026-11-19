#ifndef HOST_UTIL_DELAY_H
#define HOST_UTIL_DELAY_H
void sim_delay_us(double us);
#define _delay_us(us) sim_delay_us(us)
#define _delay_ms(ms) sim_delay_us((ms) * 1000.0)
#endif
