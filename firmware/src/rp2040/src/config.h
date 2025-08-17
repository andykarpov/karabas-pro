#pragma once

#ifndef BUILD_VER
#define BUILD_VER DEVBUILD
#endif

#define STRINGIZE(x) #x
#define STRINGIZE_VALUE_OF(x) STRINGIZE(x)

#define PIN_MCU_SPI_SCK 22 // sck
#define PIN_MCU_SPI_CS 21  // ss
#define PIN_MCU_SPI_RX 20 // miso
#define PIN_MCU_SPI_TX 23 // mosi

#define PIN_I2C_SDA 12 
#define PIN_I2C_SCL 13 

#define PIN_JOY_SCK 10 
#define PIN_JOY_DATA 9 
#define PIN_JOY_LOAD 11 
#define PIN_JOY_P7 8

#define PIN_CONF_NCONFIG 18 
#define PIN_CONF_NSTATUS 16 
#define PIN_CONF_DATA 14 
#define PIN_CONF_CLK 15 
#define PIN_CONF_DONE 17 

#define PIN_PS2_KB_DATA 24
#define PIN_PS2_KB_CLK 25
#define PIN_PS2_MS_DATA 4
#define PIN_PS2_MS_CLK 5

#define PIN_BTN1 6
#define PIN_BTN2 7
#define PIN_LED1 3
#define PIN_LED2 19

#define MOUSE_INIT_TRIES 5

#define CMD_USB_KBD 0x01
#define CMD_USB_MOUSE 0x02
#define CMD_JOYSTICK 0x03
#define CMD_BTN 0x04
#define CMD_SWITCHES 0x05
#define CMD_ROMBANK 0x06
#define CMD_ROMDATA 0x07
#define CMD_ROMLOADER 0x08
#define CMD_SPI_CONTROL 0x09
#define CMD_PS2_SCANCODE 0x0B
#define CMD_FILEBANK 0x0C
#define CMD_FILEDATA 0x0D
#define CMD_FILELOADER 0x0E

#define CMD_USB_GAMEPAD 0x11 // deprecated
#define CMD_USB_JOYSTICK 0x12 // deprecated

#define CMD_OSD 0x20

#define CMD_DEBUG_ADDRESS 0x30
#define CMD_DEBUG_DATA 0x31

// filemounter files will be initiated (when core start or when new file is selected) in the following order:
// send SLOT num  - 1 byte
// send STATUS reg - 1 byte (with bits BUSY=1, DONE=0) - todo
// send file SIZE - 4 bytes (value=0 when no file is mounted)
// send MOUNTED - 1 byte (0, then 1 to trigger the latch on fpga side)
// send STATUS reg - 1 byte (BUSY=0, DONE=1) - todo

#define CMD_IMG_SLOT 0x40
#define CMD_IMG_SIZE 0x41
#define CMD_IMG_LBA 0x42
#define CMD_IMG_SEC 0x43
#define CMD_IMG_BUF_BANK 0x44
#define CMD_IMG_BUF_DATA 0x45

// todo: other IMG commands here

// fileloader files will be transferred in the following order:
// 1. send SLOT num  - 1 byte
// 2. send file SIZE - 4 bytes
// 3. send file EXT  - 3 bytes lowercase
// 4. while not EOF: 
// 4.1. send bank when pos % 256 = 0
// 4.2. send data bytes (0-255)
// on the FPGA side the transfer begins on sending a SLOT number
// and ends on the last byte was received
// the core itself should decide what to do with the incoming data, e.g. parse header, write data directly to the memory location, etc

#define CMD_IOCTL_SLOT 0x50 // (0, uint8_t): set current slot number (0-3)
#define CMD_IOCTL_SIZE 0x51 // (0-7, uint8_t): fileloader file size
#define CMD_IOCTL_BANK 0x52 // (0-7, uint8_t): fileloader bank
#define CMD_IOCTL_DATA 0x53 // (0-255, uint8_t): fileloader byte
#define CMD_IOCTL_EXT 0x54 // (0-3, uint8_t): fileloader file ext

#define CMD_RTC 0xFA
#define CMD_FLASHBOOT 0xFB
#define CMD_UART 0xFC
#define CMD_INIT_START 0xFD
#define CMD_INIT_DONE 0xFE
#define CMD_NOP 0xFF

#define CORE_TYPE_BOOT 0x00
#define CORE_TYPE_OSD 0x01
#define CORE_TYPE_FILELOADER 0x02
#define CORE_TYPE_HIDDEN 0xff

#define CORE_OSD_TYPE_SWITCH 0x00        // drop-down like control to select a value from predifined options 
#define CORE_OSD_TYPE_NSWITCH 0x01       // non-volatile dropdown. the selected value is not stored on change
#define CORE_OSD_TYPE_TRIGGER 0x02       // sends a pulse while pressed. the value also is not stored anywhere
#define CORE_OSD_TYPE_HIDDEN 0x03        // hidden value 
#define CORE_OSD_TYPE_TEXT 0x04          // just a text line (32 characters wide)
#define CORE_OSD_TYPE_FILEMOUNTER 0x05   // mounts a selected file image as virtual drive (img_*)
#define CORE_OSD_TYPE_FILELOADER 0x06    // immediately transfer a selected file to the fpga side (ioctl_*)

#define MAX_CORES 255
#define MAX_FILES 255
#define MAX_FILE_SLOTS 8
#define MAX_JOY_DRIVERS 255
#define MAX_USB_JOYSTICKS 4
#define MAX_CORES_PER_PAGE 16
#define MAX_OSD_ITEMS 32
#define MAX_OSD_ITEM_OPTIONS 8
#define MAX_EEPROM_ITEMS 256
#define MAX_EEPROM_BANKS 4
#define NO_EEPROM_BANK 255

#define FILE_POS_CORE_ID 4
#define FILE_POS_CORE_NAME 36
#define FILE_POS_CORE_BUILD 68
#define FILE_POS_CORE_VISIBLE 76
#define FILE_POS_CORE_ORDER 77
#define FILE_POS_CORE_TYPE 78
#define FILE_POS_CORE_EEPROM_BANK 79
#define FILE_POS_BITSTREAM_LEN 80
#define FILE_POS_ROM_LEN 84
#define FILE_POS_RTC_TYPE 88
#define FILE_POS_FILELOADER_DIR 89
#define FILE_POS_FILELOADER_FILE 121
#define FILE_POS_FILELOADER_EXTENSIONS 153
#define FILE_POS_SPI_FREQ 185
#define FILE_POS_EEPROM_DATA 256
#define FILE_POS_SWITCHES_DATA 512
#define FILE_POS_BITSTREAM_START 1024

#define CORE_EXT ".kp1"

#define FILENAME_BOOT "/boot.kp1"

#define APP_COREBROWSER_MENU_OFFSET 5

#define SORT_HASH_LEN 4
#define SORT_FILES_MAX 8000

#ifndef WAIT_SERIAL
#define WAIT_SERIAL 0
#endif

#define d_begin(...)   Serial.begin(__VA_ARGS__);
#define d_print(...)   Serial.print(__VA_ARGS__);
#define d_printf(...)  Serial.printf(__VA_ARGS__);
#define d_write(...)   Serial.write(__VA_ARGS__);
#define d_println(...) Serial.println(__VA_ARGS__);
#define d_flush(...)   Serial.flush(__VA_ARGS__);
