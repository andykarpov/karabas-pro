#ifndef HOST_AVR_INTERRUPT_H
#define HOST_AVR_INTERRUPT_H
#define ISR(v) void v(void)
#define sei() ((void)0)
#define cli() ((void)0)
#endif
