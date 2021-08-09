/* ------------------------------------------------------------
 * "THE BEERWARE LICENSE" (Revision 42):
 * <cvmanjoo@gmail.com> wrote this code. As long as you retain this
 * notice, you can do whatever you want with this stuff. If we
 * meet someday, and you think this stuff is worth it, you can
 * buy me a beer in return.
 * ------------------------------------------------------------
 * ------------------------------------------------------------
 * RTC.h - Library to set & get time from I2C RTCs for Arduino
 * Created by Manjunath CV. July 08, 2017, 02:18 AM
 * Released into the public domain.
 * -----------------------------------------------------------*/

#ifndef RTC_H

//define all the rtc clocks.
//#define DS1307_H
//#define DS3231_H
//#define PCF8563_H

#define CLOCK_H24 0
#define CLOCK_H12 1

#define HOUR_AM 0
#define HOUR_PM 1
#define HOUR_24 2

#define SQW001Hz 10
#define SQW01kHz 11
#define SQW04kHz 14
#define SQW08kHz 18
#define SQW32kHz 32

#include <time.h>
#include <Arduino.h>
#include <SBWire.h>

/*
 * DateTime Class
 * */
 
class DateTime {
	public:
		DateTime();
		DateTime(uint16_t y, uint8_t mo, uint8_t d, uint8_t h, uint8_t mi, uint8_t s);
		DateTime(uint8_t hour, uint8_t min, uint8_t sec);
		uint8_t seconds;
        uint8_t minutes;
        uint8_t hours;
        uint8_t day;
        uint8_t week;
        uint8_t month;
		uint16_t year;			
};



#define DS1307_ADDR 0x68

class DS1307
{
    public:
        bool begin();

        bool isRunning(void);
        void startClock(void);
        void stopClock();

        void setHourMode(uint8_t h_mode);
        uint8_t getHourMode();

        void setMeridiem(uint8_t meridiem);
        uint8_t getMeridiem();

        void setSeconds(uint8_t second);
        void setMinutes(uint8_t minute);
        void setHours(uint8_t hour);
        void setDay(uint8_t day);
        void setWeek(uint8_t week);
        void setMonth(uint8_t month);
        void setYear(uint16_t year);

        void setDate(uint8_t day, uint8_t month, uint16_t year);
        void setTime(uint8_t hour, uint8_t minute, uint8_t second);

        void setDateTime(char* date, char* time);

        uint8_t getSeconds();
        uint8_t getMinutes();
        uint8_t getHours();
        uint8_t getDay();
        uint8_t getWeek();
        uint8_t getMonth();
        uint16_t getYear();

        void setEpoch(time_t epoch);
        time_t getEpoch();

        void setOutPin(uint8_t mode);
        bool isOutPinEnabled();
        bool isSqweEnabled();

    private:
        uint8_t bin2bcd (uint8_t val);
        uint8_t bcd2bin (uint8_t val);
};

class NVRAM
{
    public:
        bool begin();
        uint8_t read(uint8_t address);
        void write(uint8_t address, uint8_t value);
        void read(uint8_t address, uint8_t *buf, uint8_t size);
        void write(uint8_t address, uint8_t *buf, uint8_t size);
        uint8_t length = 56;
    private:
};




#endif   /* RTC_H */
