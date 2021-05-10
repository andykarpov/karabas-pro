# Updating ESP8266 stock firmware

## How to update ESP8266 stock AT firmware

For some reason, a stock firmware may be outdated and incompatible with the uGoph browser by nihirash.
So, it's easy to update that module without desoldering.

### What you'll need

- The latest release of the AT firmware, better to grab it from the official espressif github repo, like https://github.com/espressif/ESP8266_NONOS_SDK/releases/tag/v3.0.4. Then download and unpack it. The desired AT firmware is under the `bin` folder
- esptool script or other esp8266 flash tool
- An USB-UART module with 3.3v levels

### Step-by-step instruction

1) Open Quartus Programmer file `karabas_pro_esp_bridge.cdf` and flash a service firmware into FPGA, power off the board
2) Connect your USB-UART module: RX pin to PIN_121, TX pin to PIN_141, GND to GND
3) Solder a bridge between GND and the esp8266 GPIO0 pin, restart the board
4) detect a flash chip size by calling the esptool like this: `esptool --port /dev/ttyUSB0 flash_id`
5) For 32Mbit flash use the following command: `esptool --port /dev/ttyUSB0 --baud 115200 write_flash -fm qio -ff 40m -fs 16m-c1 0x00000 boot_v1.7.bin 0x01000 at/1024+1024/user1.2048.new.5.bin 0x1fc000 esp_init_data_default_v08.bin 0xfe000 blank.bin 0x1fe000 blank.bin`
6) You're done. Disconnect the power, desolder a solder bridge, flash a normal karabas_pro firmware (depends on your board revision) into the FPGA
7) Now follow the instructions how to use your ESP8266 module ;)

