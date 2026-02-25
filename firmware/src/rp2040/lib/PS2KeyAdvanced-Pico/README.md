# PS2KeyAdvanced-Pico
## Raspberry Pi Pico PS2 Keyboard FULL keyboard protocol support and full keys to integer coding
**V1.0.10** October 2021 - Fix PS2_KEY_PAUSE value and RX/TX barrier on _PS2_BUSY on transmissions

This is a port of techpaul's Arduino library. It has been modified to work in the Pi Pico SDK environment.

Smaller footprint than any others found and more functionality.

For other versions that just read the keycodes for all keyboard types or allow you to get the full UTF-8 configurable for any LATIN keyboard with 
extra functions keys as simple codes see associated repository for [PS2KeyMap library](https://github.com/techpaul/PS2KeyMap). Yes these libraries even provide codes 
for multimedia keys and Function keys F1 to F24 (yes that is F24).

### IMPORTANT NOTE ON SCAN CODE SETS

PS2 keyboard spec specifies THREE Scan Code Sets, however **ONLY SET 2 IS GUARANTEED**.

-  Scan Code Set 1 is the old XT mode rarely  available on keyboards
-  Scan Code Set 2 is the **default** Scan Code Set guaranteed to work
-  Scan Code Set 3 is even rarer to find keyboards that support it. Long abandoned by manufacturers.

**This library ONLY supports Scan Code Set 2**

### Important Hardware Notes

1. Make sure you have data and clock wires connected correctly.
  -  PS2KeyAdvanced requires both pins specified for begin() as in keyboard.begin( data_pin, irq_pin );
2. When using boards with 3V3 I/O (official Pico board) you MUST use a level translator FET or IC like Texas Instruments TXS0102 or similar as most keyboards
 not only operate at 5V but the two wire communications are pulled up by a resistor to 5V at the keyboard end.
3. USB keyboards through PS2 adapter draw **LOTS** of current and can cause processor and/or keyboard to RESET if not EXTERNALLY POWERED. It is best 
to work with 'native' PS2 keyboards.

## Introduction
After looking round for suitable libraries techpaul found that most were lacking in functionality and high in code and data footprint, so techpaul created a series of 
PS2 Keyboard libraries. This is the second which fully supports the PS2 Keyboard Protocol, even allowing you control of keyboard LEDs (some have 4 
LEDs) and changing settings.

The PS2 Keyboard interface is still needed for systems that have no USB and even if you have USB, you want it left for other uses.

The PS2 Keyboard interface is a Bi-directional two wire interface with a clock line and a data line which you connect to your Pico (see above), 
the keyboard protocol has many nuances all of which are used in the other libraries of this series. this library allows you to access the keycodes
 sent from a keyboard into its small buffer and read out the codes with simple methods.

Returns any keypress as 16 bit integer, which includes a coded value for the key along with status for

   - Make/Break
   - CTRL, SHIFT, CAPS, ALT, GUI, ALT-GR Status
   - Alphanumeric/keyboard Function
   - 8 bit key code (defined in public header)

Fully featured PS2 keyboard library to provide

   - All keys have a keycode (ESC, A-Z and 0-9 as ASCII equivalents)
   - All function (F1 to F24), multimedia and movement keys supported
   - Parity checking of data sent/received
   - Resends data and requests resends when needed
   - Functions for get and/or set of
        - Scancode set in use
        - LED and LOCK control
        - ReadID
        - Reset keyboard
        - Send ECHO
   - Ignore Break codes for keys
   - Ignore typematic repeat of CTRL, SHIFT, ALT, Num, Scroll, Caps
   - Handles NUM, CAPS and SCROLL lock keys to LEDs
   - Handles NUM/SCROLL internally

### Installation
1. Add the subdirectory into your project's CMakeLists.txt:
   - add_subdirectory(PS2KeyAdvanced-Pico/src)
2. Add "PS2KeyAdvanced" to your project's target_link_libraries
3. Include "PS2KeyAdvanced.h" in your source code.
   - See src/PS2KeyAdvanced.h for usage details.

### Examples
This library has THREE examples, from simplest to most complex -

  - SimpleTest that uses the serial port to output the converted codes received on every keystroke and auto-repeat.
  - advcodetest that uses serial port and some of the keys pressed to send commands back to the keyboard to see the responses for things like Reset 
  keyboard, Read ID, change Typematic rate (auto-repeat).
  - KeyToLCD - Example that will allow you to display keyboard actions on LCD connected to Raspberry Pi Pico and allow cursor movements to move the cursor on 
  LCD, whilst also displaying strings for keys like ESC, TAB, F1 to F12
  
## Porting to different boards or architectures
See document Porting.md in extra folder for hints to assist in this process
### Version History

| Version | Date | | Description |
|:--|:--:|---|:--|
|V1.0.10| October 2021 | | Fix PS2_KEY_PAUSE value and RX/TX barrier on _PS2_BUSY on transmissions. |
|V1.0.9| July 2021 | | Add ESP32 support from user submissions. See [Issue #21](https://github.com/techpaul/PS2KeyAdvanced/issues/21)|
|V1.0.8| November 2020 | | Add support for STM32 from user Hiabuto-de. Tested on STM32Duino-Framework and PlatformIO on STM32F103C8T6 and an IBM Model M|
|V1.0.7| March 2020 | | Add notes for porting to other platforms, tidy ups, add SAMD1|
|V1.0.6| January 2020 | | Fix typos, correct keyboard reset status improve library.properties and additional reduction for easier platform handling|
|V1.0.4| August 2018 | | Minor reduction in available() method to remove redundant extra safety checks on buffers|
|V1.0.3| July 2018 | | Improved keywords file|

First Public Release Version V1.0.2
### Contributor and Author Details
Author Paul Carpenter, PC Services

Web Site http://www.pcserviceselectronics.co.uk
