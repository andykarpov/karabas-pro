/**
                                                                                                                
#       #######                                                 #                                               
#                                                               #                                               
#                                                               #                                               
############### ############### ############### ############### ############### ############### ############### 
#             #               # #                             # #             #               # #               
#             # ############### #               ############### #             # ############### ############### 
#             # #             # #               #             # #             # #             #               # 
#             # ############### #               ############### ############### ############### ############### 
                                                                                                                
        ####### ####### ####### #######                         ############### ############### ############### 
                                                                #             # #               #             # 
                                                                ############### #               #             # 
                                                                #               #               #             # 
https://github.com/andykarpov/karabas-pro                       #               #               ############### 

RP2050 firmware for Karabas-Pro

@author Andy Karpov <andy.karpov@gmail.com>
EU, 2025
*/

#include <Arduino.h>
#include "config.h"
#include "types.h"
#include <SPI.h>
#include <Wire.h>
#include <PioSPI.h>
#include "SdFat.h"
#include <ElapsedTimer.h>
#include <RTC.h>
#include <OSD.h>
#include <SegaController.h>
#include "main.h"
#include "usb_hid_keys.h"
#include "osd_font.h"
#include "app_core_browser.h"
#include "app_file_loader.h"
#include "app_core.h"
#include "file.h"
#include "tusb.h"
#include "Adafruit_TinyUSB.h"
#include "LittleFS.h"
#include "boot_core.h"
#include "PS2KeyAdvanced.h"
#include "PS2Mouse.h"

// todo: PIN_CONF_CLK will be reused as SD_CS_N to access SD from 2040 to FPGA by MCU SPI channel! 
// it should be set to OUTPUT after core loaded in case core has sd_access=1 and set to INPUT in case of sd_access=0
PioSPI spiSD(PIN_MCU_SPI_TX, PIN_MCU_SPI_RX, PIN_MCU_SPI_SCK, PIN_CONF_CLK, SPI_MODE0, SD_SCK_MHZ(16)); // dedicated SD1 SPI
#define SD_CONFIG  SdSpiConfig(PIN_CONF_CLK, SHARED_SPI, SD_SCK_MHZ(16), &spiSD) // SD1 SPI Settings
SPISettings settingsA(SD_SCK_MHZ(16), MSBFIRST, SPI_MODE0); // MCU SPI settings

File file1, file2;
Dir root1;
SdFat32 sd1;
File32 sdfile, sdroot;
ElapsedTimer my_timer, my_timer2;
ElapsedTimer hide_timer;
ElapsedTimer popup_timer;
ElapsedTimer mouse_timer;
RTC zxrtc;
OSD zxosd;

file_list_sort_item_t files[SORT_FILES_MAX];
uint16_t files_len = 0;
uint16_t file_sel = 0;
uint16_t file_page_size = MAX_CORES_PER_PAGE;
uint16_t file_pages = 1;
uint16_t file_page = 1;
file_list_item_t cached_names[MAX_CORES_PER_PAGE];
uint16_t cached_file_from, cached_file_to;

uint8_t ps2_pressed[64];
uint8_t ps2_pressed_size = 0;

// LCTRL LSHIFT LALT LGUI RCTRL RSHIFT RALT RGUI
uint8_t const ps2_usb_modifieds_map[] = { 
  PS2_KEY_L_CTRL, PS2_KEY_L_SHIFT, PS2_KEY_L_ALT, PS2_KEY_L_GUI, PS2_KEY_R_CTRL, PS2_KEY_R_SHIFT, PS2_KEY_R_ALT, PS2_KEY_R_GUI 
};

uint8_t const ps2_usb_key_map[] = {
//   .  err  postf  err    A     B     C     D     E     F     G     H     I     J      K     L  
  0x00, 0x00, 0x00, 0x00, PS2_KEY_A, PS2_KEY_B, PS2_KEY_C, PS2_KEY_D, PS2_KEY_E, PS2_KEY_F, PS2_KEY_G, PS2_KEY_H, PS2_KEY_I, PS2_KEY_J, PS2_KEY_K, PS2_KEY_L,
// M     N     O     P     Q      R    S     T     U     V     W     X     Y     Z     1     2
  PS2_KEY_M, PS2_KEY_N, PS2_KEY_O, PS2_KEY_P, PS2_KEY_Q, PS2_KEY_R, PS2_KEY_S, PS2_KEY_T, PS2_KEY_U, PS2_KEY_V, PS2_KEY_W, PS2_KEY_X, PS2_KEY_Y, PS2_KEY_Z, PS2_KEY_1, PS2_KEY_2,
// 3     4     5     6     7     8     9     0    ent    esc   bks   tab   spc   -     =      [
  PS2_KEY_3, PS2_KEY_4, PS2_KEY_5, PS2_KEY_6, PS2_KEY_7, PS2_KEY_8, PS2_KEY_9, PS2_KEY_0, PS2_KEY_ENTER, PS2_KEY_ESC, PS2_KEY_BS, PS2_KEY_TAB, PS2_KEY_SPACE, PS2_KEY_MINUS, PS2_KEY_EQUAL, PS2_KEY_OPEN_SQ,
// ]      \    \     ;     '     `     ,      .     /   caps   f1    f2    f3    f4    f5    f6     
  PS2_KEY_CLOSE_SQ, PS2_KEY_BACK, PS2_KEY_BACK, PS2_KEY_SEMI, PS2_KEY_SINGLE, PS2_KEY_APOS, PS2_KEY_COMMA, PS2_KEY_DOT, PS2_KEY_DIV, PS2_KEY_CAPS, PS2_KEY_F1, PS2_KEY_F2, PS2_KEY_F3, PS2_KEY_F4, PS2_KEY_F5, PS2_KEY_F6,
// f7    f8    f9    f10   f11   f12  pscr  scrl  paus  ins   home  pgup  del   end   pgdn  right        
  PS2_KEY_F7, PS2_KEY_F8, PS2_KEY_F9, PS2_KEY_F10, PS2_KEY_F11, PS2_KEY_F12, PS2_KEY_PRTSCR, PS2_KEY_SCROLL, PS2_KEY_PAUSE, PS2_KEY_INSERT, PS2_KEY_HOME, PS2_KEY_PGUP, PS2_KEY_DELETE, PS2_KEY_END, PS2_KEY_PGDN, PS2_KEY_R_ARROW,
// left down  up    numl  kp/   kp*   kp-   kp+   kpen  kp1   kp2   kp3   kp4   kp5   kp6   kp7
  PS2_KEY_L_ARROW, PS2_KEY_DN_ARROW, PS2_KEY_UP_ARROW, PS2_KEY_NUM, PS2_KEY_KP_DIV, PS2_KEY_KP_TIMES, PS2_KEY_KP_MINUS, PS2_KEY_KP_PLUS, PS2_KEY_KP_ENTER, PS2_KEY_KP1, PS2_KEY_KP2, PS2_KEY_KP3, PS2_KEY_KP4, PS2_KEY_KP5, PS2_KEY_KP6, PS2_KEY_KP7,
// kp8  kp9   kp0   kp.   \     app   power kp=   f13   f14   f15   f16   f17   f18   f19   f20 
  PS2_KEY_KP8, PS2_KEY_KP9, PS2_KEY_KP0, PS2_KEY_KP_DOT, PS2_KEY_KP_COMMA, 0x00, 0x00, PS2_KEY_KP_EQUAL, PS2_KEY_F13, PS2_KEY_F14, PS2_KEY_F15, PS2_KEY_F16, PS2_KEY_F17, PS2_KEY_F18, PS2_KEY_F19, PS2_KEY_F20,
// f21  f22   f23   f24  
  PS2_KEY_F21, PS2_KEY_F22, PS2_KEY_F23, PS2_KEY_F24
};

SegaController sega;
PS2KeyAdvanced kbd;
PS2Mouse mouse;
bool mouse_present;
uint8_t mouse_tries;

static queue_t spi_event_queue;

hid_keyboard_report_t usb_keyboard_report;
hid_mouse_report_t usb_mouse_report;

bool is_osd = false;
bool is_osd_hiding = false; 
bool is_popup_hiding = false;
bool need_redraw = false;

core_item_t core;
core_file_slot_t file_slots[MAX_FILE_SLOTS];

uint8_t osd_state;
uint8_t osd_prev_state = state_main;

bool has_sd = false;
bool has_fs = false;
bool is_configuring = false;

uint16_t joy;

uint8_t uart_idx = 0;
uint8_t evo_rs232_dll = 0;
uint8_t evo_rs232_dlm = 0;
uint32_t serial_speed = 115200;

uint16_t debug_address = 0;
uint16_t prev_debug_address = 0;
uint16_t debug_data = 0;
uint16_t prev_debug_data = 0;

void ps2_int(uint a, uint32_t b)
{
  kbd.ps2interrupt();
}

void setup()
{
  queue_init(&spi_event_queue, sizeof(queue_spi_t), 64);

  joy = 0;

  for (uint8_t i=0; i<MAX_FILE_SLOTS; i++) { file_slots[i] = {0}; }

  // SPI0 to FPGA
  SPI.setSCK(PIN_MCU_SPI_SCK);
  SPI.setRX(PIN_MCU_SPI_RX);
  SPI.setTX(PIN_MCU_SPI_TX);
  //SPI.setCS(PIN_MCU_SPI_CS);
  SPI.begin(false);

  // FPGA bitstream loader
  pinMode(PIN_CONF_NSTATUS, INPUT_PULLUP);
  pinMode(PIN_CONF_NCONFIG, OUTPUT);
  pinMode(PIN_CONF_DONE, INPUT);
  pinMode(PIN_CONF_CLK, INPUT);
  pinMode(PIN_CONF_DATA, INPUT);

  // I2C
  Wire.setSDA(PIN_I2C_SDA);
  Wire.setSCL(PIN_I2C_SCL);
  Wire.setClock(100000);
  Wire.begin();

#if WAIT_SERIAL
  while ( !Serial ) yield();   // wait for native usb
#endif

  d_begin(115200);
  d_println("Karabas Pro RP2040 firmware");

  sega.begin(PIN_JOY_SCK, PIN_JOY_LOAD, PIN_JOY_DATA, PIN_JOY_P7);

  pinMode(PIN_BTN1, INPUT_PULLUP);
  pinMode(PIN_BTN2, INPUT_PULLUP);
  pinMode(PIN_LED1, OUTPUT); digitalWrite(PIN_LED1, HIGH);
  pinMode(PIN_LED2, OUTPUT); digitalWrite(PIN_LED2, HIGH);

  zxrtc.begin(spi_send, on_time);
  zxosd.begin(spi_send);

  osd_state = state_main;

  LittleFSConfig fileSystemConfig = LittleFSConfig();
  fileSystemConfig.setAutoFormat(true);
  LittleFS.setConfig(fileSystemConfig);

  if (!LittleFS.begin()) {
    d_println("Formatting LittleFS");
    LittleFS.format();
    LittleFS.begin();
  }

  root1 = LittleFS.openDir("/");

  // check if required core is exists and copy it from internal resources otherwise
  check_update(FILENAME_BOOT);

  // load boot from littlefs
  do_configure(FILENAME_BOOT);

  osd_state = state_core_browser;
  app_core_browser_read_list();
}

void setup1() {
  for (uint8_t i=0; i<sizeof(ps2_pressed); i++) {
    ps2_pressed[i] = 0;
  }
  ps2_pressed_size = 0;
  kbd.begin(PIN_PS2_KB_DATA, PIN_PS2_KB_CLK, &ps2_int);
  mouse.begin(PIN_PS2_MS_CLK, PIN_PS2_MS_DATA);
  mouse_present = mouse.streamInitialize();
  mouse_timer.reset();
  mouse_tries = MOUSE_INIT_TRIES;
}

void loop()
{
  // read hw buttons to manipulate msc / reboots
  static bool prev_btn1 = false;
  static bool prev_btn2 = false;
  bool btn1 = btn_read(0);
  bool btn2 = btn_read(1);

  zxrtc.handle();

  // set is_osd off after 200ms of real switching off 
  // to avoid esc keypress passes to the host
  if (is_osd_hiding && hide_timer.elapsed() >= 200) {
    is_osd = false;
    is_osd_hiding = false;
  }

  // hide popup after 500 ms
  if (is_popup_hiding && popup_timer.elapsed() >= 500) {
    is_popup_hiding = false;
    zxosd.hidePopup();
    osd_handle(true); // reinit osd
  }

  if (my_timer.elapsed() >= 100) {
      led_write(0, true);
      my_timer.reset();
  }

  if (prev_btn1 != btn1) {
    d_print("Button 1: "); d_println((btn1) ? "on" : "off");
    prev_btn1 = btn1;
    spi_send(CMD_BTN, 0, btn1);
  }

  if (prev_btn2 != btn2) {
    d_print("Button 2: "); d_println((btn2) ? "on" : "off");
    prev_btn2 = btn2;
    spi_send(CMD_BTN, 1, btn2);
  }

  // debug features
  // TODO: remove from production / refactor
  if (btn1) {
    // wait until released
    while (btn1) { btn1 = btn_read(0); delay(100); }
    d_println("Reboot");
    d_flush();
    rp2040.reboot();
  }
  if (btn2) {
      d_println("Reboot to bootloader");
      d_flush();
      rp2040.rebootToBootloader();
  }

  // read joy
  joy = sega.getState();
  static uint16_t prevJoy = 0;

  if (joy != prevJoy) {
    d_printf("SEGA: %u", joy); d_println();
    on_keyboard();
    prevJoy = joy;
    spi_send(CMD_JOYSTICK, 0, lowByte(joy));
    spi_send(CMD_JOYSTICK, 1, highByte(joy));
  }

  osd_handle(false);

  queue_spi_t packet;
	while (queue_try_remove(&spi_event_queue, &packet)) {
    // skip keyboard transmission when osd is active
    if (packet.cmd == CMD_USB_KBD) {
      digitalWrite(PIN_LED2, !(usb_keyboard_report.modifier != 0 || usb_keyboard_report.keycode[0] != 0));
      if (packet.addr == 1 && packet.data != 0) {
          on_keyboard();
      }
      if (!is_osd) {
        spi_send(packet.cmd, packet.addr, packet.data);
      }
    // skip ps/2 scancode transmission when osd is active
    } else if (packet.cmd == CMD_PS2_SCANCODE) {
      if (!is_osd) {
        spi_send(packet.cmd, packet.addr, packet.data);
      }
    // skip joystick transmission when osd is active
    } else if (packet.cmd == CMD_JOYSTICK) {
      if (!is_osd) {
        spi_send(packet.cmd, packet.addr, packet.data);
      }
    }
    else {
      spi_send(packet.cmd, packet.addr, packet.data);
    }
  }

  if (Serial.available() > 0) {
    uart_idx++;
    int uart_rx = Serial.read();
    if (uart_rx != -1) {
      spi_send(CMD_UART, uart_idx, (uint8_t) uart_rx);
    }
  } else {
    spi_send(CMD_NOP, 0 ,0);
  }
}

uint8_t get_ps2_usb_modifier() {
  uint8_t result = 0;
  for (uint8_t i=0; i<ps2_pressed_size; i++) {
    for (uint8_t j=0; j<8; j++) {
      if (ps2_usb_modifieds_map[j] == ps2_pressed[i]) {
        result = bitSet(result, j);
      }
    }
  }
  return result;
}

uint8_t get_ps2_usb_key(uint8_t i) {
  uint8_t result = 0;
  for (uint8_t j=0; j<sizeof(ps2_usb_key_map); j++) {
    if (ps2_usb_key_map[j] == ps2_pressed[i]) {
      result = j;
    }
  }
  return result;
}

hid_keyboard_report_t ps2_to_usb(uint16_t c)
{
  bool pressed = !bitRead(c, 15);
  uint8_t key = lowByte(c);

  //d_printf("Key %02X press=%d", key, pressed); d_println();

  uint8_t new_ps2_pressed[64];

  if (pressed) {
    // pressed
    bool found = false;    
    for (uint8_t i=0; i<ps2_pressed_size; i++) {
      if (ps2_pressed[i] == key) found = true;
    }
    // if pressed key was not found in the pressed array - add it
    if (!found && ps2_pressed_size < sizeof(ps2_pressed)) {
      ps2_pressed[ps2_pressed_size] = key;
      ps2_pressed_size++;
    }
  } else {
    // released
    bool found = false;
    for (uint8_t i=0; i<ps2_pressed_size; i++) {
      if (ps2_pressed[i] == key) found = true;
    }
    if (found) {
      uint8_t j = 0;
      // remove released item from array
      for (uint8_t i=0; i<ps2_pressed_size; i++) {
        if (ps2_pressed[i] != key) {
          new_ps2_pressed[j] = ps2_pressed[i];
          j++;
        }
      }
      ps2_pressed_size = j;
      // cope new pressed to ps2_pressed array
      for (uint8_t i=0; i<ps2_pressed_size; i++) {
        ps2_pressed[i] = new_ps2_pressed[i];
      }
    }
  }

  hid_keyboard_report_t report;
  // todo: map ps2_pressed to report.motifier + report.keycode[0-5]

  report.modifier = get_ps2_usb_modifier();
  report.reserved = 0;
  uint8_t max_size = min(ps2_pressed_size, 6);
  uint8_t j=0;
  for (uint8_t i=0; i<max_size; i++) {
    uint8_t usb_key = get_ps2_usb_key(i);
    if (usb_key > 0) {
      report.keycode[j] = usb_key;
      j++; 
    }
  }
  for (uint8_t i=j; i<6; i++) {
    report.keycode[i] = 0;
  }
  return report;
}

void loop1()
{
    // read kbd
  if (kbd.available()) {
    uint16_t c = kbd.read();
    hid_keyboard_report_t report = ps2_to_usb(c);
    process_kbd_report(0, 0, &report, 0);
  }

  // mouse init tries
  if (mouse_tries > 0 && !mouse_present && mouse_timer.elapsed() > 500) {
    mouse_tries--;
    mouse_present = mouse.streamInitialize();
    mouse_timer.reset();
  }

  // read mouse
  if (mouse.reportAvailable() > 0 ) {
    MouseData m = mouse.readReport();
    hid_mouse_report_t report;
    report.buttons = m.status;
    report.pan = 0;
    report.wheel = m.wheel;
    report.x = m.position.x;
    report.y = m.position.y;
    process_mouse_report(0, 0, &report, 0);
  }
}

void update_boot_core_from_flash(const char* filename) {
  file2 = LittleFS.open(filename, "w");
  d_print("Creating "); d_print(filename); d_print(" from internal resources...");
  file2.write(BOOT_CORE, BOOT_CORE_LEN);
  d_print("Done. Copied "); d_print(BOOT_CORE_LEN); d_println(" bytes");
  file2.close();
}

void update_core_from_sd(const char* filename) {
  file2 = LittleFS.open(filename, "w");
  file2.seek(0);
  d_print("Creating "); d_print(filename); d_print(" from sd card file...");
  // todo: copy
  size_t len = 0;
  size_t total = 0;
  uint8_t buf[512];
  sdfile.seek(0);
  while (len = sdfile.read(buf, 512)) {
    file2.write(buf, len);
    total += len;
  }
  d_print("Done. Copied "); d_print(total); d_println(" bytes");
  file2.close();
}

void check_update(const char* filename) {
  // if core does not exists on lfs partition
  if (!LittleFS.exists(filename)) {
    if (strcmp(filename, FILENAME_BOOT) == 0) {
      update_boot_core_from_flash(filename);
    } 
    else {
      update_core_from_sd(filename);
    }
  // if core exists
  } else {
    // for boot core
    if (strcmp(filename, FILENAME_BOOT) == 0) {
      // todo: compare versions of file1 and file2
      file2 = LittleFS.open(filename, "r");
      char ver1[8];
      file2.readBytes(ver1, sizeof(ver1));
      file2.close();
      char ver2[8];
      for (uint8_t i=FILE_POS_CORE_BUILD; i<FILE_POS_CORE_BUILD+8; i++) {
        ver2[i-FILE_POS_CORE_BUILD] = BOOT_CORE[i];
      }
      // update the core
      if (memcmp(ver1, ver2, 8) != 0) {
        update_boot_core_from_flash(filename);
      }
    } 
    // for core from sd card
    else {
      file2 = LittleFS.open(filename, "r");
      char ver1[8];
      file2.seek(FILE_POS_CORE_BUILD);
      file2.readBytes(ver1, sizeof(ver1));
      file2.close();
      char ver2[8];
      sdfile.seek(FILE_POS_CORE_BUILD);
      sdfile.readBytes(ver2, sizeof(ver2));
      // update the core
      if (memcmp(ver1, ver2, 8) != 0) {
        file2 = LittleFS.open(filename, "w");
        sdfile.rewind();
        update_core_from_sd(filename);
      }
    }
  }
}

void update_cores_from_sd() {
  if (sdroot.isOpen()) {
      sdroot.close();
    }
    if (!sdroot.open(&sd1, "/")) {
      return;
    }
    sdroot.rewind();
    while (sdfile.openNext(&sdroot, O_RDONLY)) {
      char filename[32]; sdfile.getName(filename, sizeof(filename));
      uint8_t len = strlen(filename);
      if (strstr(strlwr(filename + (len - 4)), CORE_EXT)) {
        check_update(filename);
      }
      sdfile.close();
    }
}


void do_configure(const char* filename) {
  is_configuring = true;
  fpga_send(filename);
  spi_send(CMD_INIT_START, 0, 0);
  // trigger font loader reset
  zxosd.fontReset();
  // send font data
  for (int i=0; i<OSD_FONT_LEN; i++) {
    zxosd.fontSend(OSD_FONT[i]);
  }
  read_core(filename);
  if (!is_osd) {
    zxosd.clear();
    zxosd.logo(0,0);
    zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    zxosd.setPos(0,5);
    zxosd.print("ROM ");
    zxosd.showPopup();
  }
  read_roms(filename);
  if (!is_osd) {
    zxosd.hidePopup();
    osd_handle(true); // reinit osd
  }

  // try to mount the sd card and update cores sd->littlefs
  has_sd = false;
  if (core.sd_enable) {
    d_println("Trying to mount SD card");
    pinMode(PIN_CONF_CLK, OUTPUT);
    digitalWrite(PIN_CONF_CLK, HIGH);
    has_sd = sd1.begin(SD_CONFIG);
    if (has_sd) {
      d_println("SD card mounted");
      update_cores_from_sd();
    } else {
      d_println("SD card is inaccessible");
      sd1.initErrorPrint(&Serial);
    }
  } else {
    pinMode(PIN_CONF_CLK, INPUT_PULLUP);
    sd1.end();
    has_sd = false;
  }

  spi_send(CMD_INIT_DONE, 0, 0);
  is_configuring = false;
}

bool on_global_hotkeys() {
  
  // menu+esc (joy start+c) to toggle osd only for osd supported cores
  if (core.type != CORE_TYPE_BOOT && core.type != CORE_TYPE_HIDDEN && 
      ((((usb_keyboard_report.modifier & KEY_MOD_LMETA) || (usb_keyboard_report.modifier & KEY_MOD_RMETA)) && usb_keyboard_report.keycode[0] == KEY_ESC) ||
       ((joy & SC_BTN_START) && (joy & SC_BTN_C))
      )
    ) {
    if (!is_osd) {
      is_osd = true;
      zxosd.showMenu();
    } else if (!is_osd_hiding) {
      is_osd_hiding = true;
      hide_timer.reset();
      zxosd.hideMenu();
    }
    return true;
  }

  // ctrl+alt+backspace (joy start+x) to global reset rp2040
  if (
      (((usb_keyboard_report.modifier & KEY_MOD_LCTRL) || (usb_keyboard_report.modifier & KEY_MOD_RCTRL)) && 
      ((usb_keyboard_report.modifier & KEY_MOD_LALT) || (usb_keyboard_report.modifier & KEY_MOD_RALT)) && 
        usb_keyboard_report.keycode[0] == KEY_BACKSPACE) || 
        (((joy & SC_BTN_START) && (joy & SC_BTN_X)))
        ) {
     rp2040.reboot();
     return true;
  }

  // osd hotkey
  for (uint8_t i=0; i<core.osd_len; i++) {
    if (core.osd[i].keys[0] != 0 && (usb_keyboard_report.modifier & core.osd[i].keys[0]) || (core.osd[i].keys[0] == 0)) {
      if (core.osd[i].keys[1] != 0 && (usb_keyboard_report.keycode[0] == core.osd[i].keys[1])) {
        if (core.osd[i].type == CORE_OSD_TYPE_SWITCH || core.osd[i].type == CORE_OSD_TYPE_NSWITCH) {
          if (core.osd[i].options_len > 0) {
            curr_osd_item = i;
            core.osd[i].val++; 
            if (core.osd[i].val > core.osd[i].options_len-1) {
              core.osd[i].val = 0;
            }
            core_send(i);
            if (!is_osd) {
              zxosd.clear();
              zxosd.logo(0, 0);
              zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
              zxosd.setPos(0, 5);
              zxosd.print(core.osd[i].name);
              zxosd.setPos(0,6);
              zxosd.print(core.osd[i].options[core.osd[i].val].name);
              is_popup_hiding = true;
              popup_timer.reset();
              zxosd.showPopup();
            }
            if (core.osd[i].type == CORE_OSD_TYPE_SWITCH) {
              core.osd_need_save = true;
            }
          }
        } else if (core.osd[i].type == CORE_OSD_TYPE_TRIGGER) {
            core_trigger(i);
        } else if (core.osd[i].type == CORE_OSD_TYPE_FILELOADER || core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER) {
          is_osd = true;
          curr_osd_item = i;
          zxosd.showMenu();
        }
        return true;
      }
    }
  }

  if (core.osd_need_save) {
    app_core_save(curr_osd_item);
  }

  return false;
}

void on_keyboard() {

  need_redraw = on_global_hotkeys();

  // in-osd keyboard handle
  if (is_osd) {
    switch (osd_state) {
      case state_core_browser: app_core_browser_on_keyboard(); break;
      case state_main: app_core_on_keyboard(); break;
      case state_file_loader: app_file_loader_on_keyboard(); break;
    }
  }
}

void core_send(uint8_t pos)
{
  if (core.osd[pos].type == CORE_OSD_TYPE_FILEMOUNTER) {
      // todo
      //spi_send(CMD_SWITCHES, pos, (file_slots[core.osd[pos].slot_id].is_mounted) ? 1 : 0);
      //d_printf("File mounter: %s %d", core.osd[pos].name, file_slots[core.osd[pos].slot_id].is_mounted);
  } else if (core.osd[pos].type == CORE_OSD_TYPE_FILELOADER) {
    // do nothing
  } else {
    spi_send(CMD_SWITCHES, pos, core.osd[pos].val);
    d_printf("Switch: %s %d", core.osd[pos].name, core.osd[pos].val);
  }
  d_println();
}

void core_send_all() 
{
  for (uint8_t i=0; i<core.osd_len; i++) {
    if (core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER) {
      // todo
      //spi_send(CMD_SWITCHES, i, (file_slots[core.osd[i].slot_id].is_mounted) ? 1 : 0);
    } else if (core.osd[i].type == CORE_OSD_TYPE_FILELOADER) {
      // do nothing
    } else {
      spi_send(CMD_SWITCHES, i, core.osd[i].val);
    }
  }
}

void core_trigger(uint8_t pos)
{
  d_printf("Trigger: %s", core.osd[pos].name);
  d_println();

  d_println("Reset Host");
  spi_send(CMD_SWITCHES, pos, 1);
  delay(100);
  spi_send(CMD_SWITCHES, pos, 0);
}

uint8_t core_eeprom_get(uint8_t pos) {
  return core.eeprom[pos].val;
}

void core_eeprom_set(uint8_t pos, uint8_t val) {
  core.eeprom[pos].val = val;
  core.eeprom_need_save = true;
}

void halt(const char* msg) {
  d_println(msg);
  d_flush();
  bool blink = false;
  for(int i=0; i<50; i++) {
      blink = !blink;
      led_write(0, blink);
      led_write(1, !blink);
      delay(100);
  }
  rp2040.reboot();
}

uint32_t fpga_send(const char* filename) {

  d_print("Configuring FPGA by "); d_println(filename);

  file1 = LittleFS.open(filename, "r");
  if (!file1) {
    halt("Unable to open bitstream file to read");
  }

  // get bitstream size
  uint32_t length = file_read32(FILE_POS_BITSTREAM_LEN);
  d_print("Bitstream size: "); d_println(length, DEC);

  // seek to bitstream start
  file_seek(FILE_POS_BITSTREAM_START);

  // set conf pins to output mode
  pinMode(PIN_CONF_CLK, OUTPUT);
  pinMode(PIN_CONF_DATA, OUTPUT);

  // set dclk, data
  digitalWrite(PIN_CONF_CLK, HIGH);
  digitalWrite(PIN_CONF_DATA, HIGH);

  // pulse NCONFIG
  digitalWrite(PIN_CONF_NCONFIG, HIGH);
  digitalWrite(PIN_CONF_NCONFIG, LOW);
  digitalWrite(PIN_CONF_NCONFIG, HIGH);

  // wait for NSTATUS = 0
  int i = 10;
  while (i-- > 0 & digitalRead(PIN_CONF_NSTATUS) != LOW)
    delay(10);

  my_timer.reset();

  i = 0;
  bool blink = false;
  char line[128];
  uint8_t n;

  digitalWrite(PIN_CONF_CLK, LOW);

  while ((n = file_read_buf(line, (sizeof(line) < length ? sizeof(line) : length) ))) {
    i += n;
    length -=n;

    for (uint8_t s=0; s<n; s++) {
      uint8_t c = line[s];
      for (uint8_t j=0; j<8; ++j) {
        // Set bit of data
        gpio_put(PIN_CONF_DATA, ((c & 0x01) == 0) ? LOW : HIGH);
        c >>= 1;
        // Latch bit of data by CCLK impulse
        gpio_put(PIN_CONF_CLK, HIGH);
        gpio_put(PIN_CONF_CLK, LOW);
      }
    }

    if (i % 8192 == 0) {
      blink = !blink;
      led_write(0, blink);
      led_write(1, blink);
    }
  }
  file1.close();

  pinMode(PIN_CONF_CLK, INPUT);
  pinMode(PIN_CONF_DATA, INPUT);

  d_print(i, DEC); d_println(" bytes done");
  d_print("Elapsed time: "); d_print(my_timer.elapsed(), DEC); d_println(" ms");
  d_flush();

  d_print("Waiting for CONF_DONE... ");
  while(digitalRead(PIN_CONF_DONE) == LOW) {
    delay(10);
  }
  d_println("Done");

  return length;
}

void spi_queue(uint8_t cmd, uint8_t addr, uint8_t data) {
  queue_spi_t packet;
  packet.cmd = cmd;
  packet.addr = addr;
  packet.data = data;
  queue_try_add(&spi_event_queue, &packet);
}

void spi_send(uint8_t cmd, uint8_t addr, uint8_t data) {
  // use default (16 MHz) or custom spi freq from the core config
  SPISettings spi_settings = (core.spi_freq == 0 || core.spi_freq == 255) ? settingsA : SPISettings(SD_SCK_MHZ(core.spi_freq), MSBFIRST, SPI_MODE0);
  SPI.beginTransaction(spi_settings);
  gpio_put(PIN_MCU_SPI_CS, LOW);
  uint8_t rx_cmd = SPI.transfer(cmd);
  uint8_t rx_addr = SPI.transfer(addr);
  uint8_t rx_data = SPI.transfer(data);
  gpio_put(PIN_MCU_SPI_CS, HIGH);
  SPI.endTransaction();
  if ((rx_cmd > 0) && !is_configuring) {
    process_in_cmd(rx_cmd, rx_addr, rx_data);
  }
}

void spi_send16(uint8_t cmd, uint16_t data) {
  uint8_t byte2 = (uint8_t)((data & 0xFF00) >> 8);
  uint8_t byte1 = (uint8_t)((data & 0x00FF));
  spi_send(cmd, 0, byte1);
  spi_send(cmd, 1, byte2);
}

void spi_send24(uint8_t cmd, uint32_t data) {
  uint8_t byte3 = (uint8_t)((data & 0x00FF0000) >> 16);
  uint8_t byte2 = (uint8_t)((data & 0x0000FF00) >> 8);
  uint8_t byte1 = (uint8_t)((data & 0x000000FF));
  spi_send(cmd, 0, byte1);
  spi_send(cmd, 1, byte2);
  spi_send(cmd, 2, byte3);
}

void spi_send32(uint8_t cmd, uint32_t data) {
  uint8_t byte4 = (uint8_t)((data & 0xFF000000) >> 24);
  uint8_t byte3 = (uint8_t)((data & 0x00FF0000) >> 16);
  uint8_t byte2 = (uint8_t)((data & 0x0000FF00) >> 8);
  uint8_t byte1 = (uint8_t)((data & 0x000000FF));
  spi_send(cmd, 0, byte1);
  spi_send(cmd, 1, byte2);
  spi_send(cmd, 2, byte3);
  spi_send(cmd, 2, byte4);
}

void spi_send64(uint8_t cmd, uint64_t data) {
  uint8_t byte8 = (uint8_t)((data & 0xFF00000000000000) >> 56);
  uint8_t byte7 = (uint8_t)((data & 0x00FF000000000000) >> 48);
  uint8_t byte6 = (uint8_t)((data & 0x0000FF0000000000) >> 40);
  uint8_t byte5 = (uint8_t)((data & 0x000000FF00000000) >> 32);
  uint8_t byte4 = (uint8_t)((data & 0x00000000FF000000) >> 24);
  uint8_t byte3 = (uint8_t)((data & 0x0000000000FF0000) >> 16);
  uint8_t byte2 = (uint8_t)((data & 0x000000000000FF00) >> 8);
  uint8_t byte1 = (uint8_t)((data & 0x00000000000000FF));
  spi_send(cmd, 0, byte1);
  spi_send(cmd, 1, byte2);
  spi_send(cmd, 2, byte3);
  spi_send(cmd, 2, byte4);
  spi_send(cmd, 2, byte5);
  spi_send(cmd, 2, byte6);
  spi_send(cmd, 2, byte7);
  spi_send(cmd, 2, byte8);
}

void serial_set_speed(uint8_t dll, uint8_t dlm) {
  uint32_t speed = 0;
  if (dll == 0 && dlm == 0) {
    speed = 256000; // zx evo special case
  } else if (bitRead(dlm, 7) == 1) {
    // native atmega mode
    dlm = bitClear(dlm, 7);
    // (uint16)((DLM&0x7F)*256+DLL) = (691200/<скорость в бодах>)-1 
    speed = 691200 / ((dlm*256) + dll + 1);
  } else {
    // standard mode
    speed = 115200 / ((dlm*256) + dll);
  }
  // switch serial spseed
  if (serial_speed != speed) {
    serial_speed = speed;
    Serial.end();
    Serial.begin(speed);
  }
}

void serial_data(uint8_t addr, uint8_t data) {
    if (addr == 0) {
      // ts zifi 115200
      if (serial_speed != 115200) {
        serial_speed = 115200;
        Serial.end();
        Serial.begin(serial_speed);
      }
      Serial.write(data);
    } else if (addr == 1) {
      // evo rs232 dll
      evo_rs232_dll = data;
      serial_set_speed(evo_rs232_dll, evo_rs232_dlm);
    } else if (addr == 2) {
      // evo rs232 set dlm
      evo_rs232_dlm = data;
      serial_set_speed(evo_rs232_dll, evo_rs232_dlm);
    } else if (addr == 3) {
      // evo rs232 data
      Serial.write(data);
    }
}

void process_in_cmd(uint8_t cmd, uint8_t addr, uint8_t data) {

  if (cmd == CMD_UART) {
    serial_data(addr, data);
  } else if (cmd == CMD_RTC) {
    zxrtc.setData(addr, data);
  } else if (cmd == CMD_DEBUG_DATA) {
    debug_data = addr*256 + data;
  } else if (cmd == CMD_DEBUG_ADDRESS) {
    debug_address = addr*256 + data;
  } else if (cmd == CMD_NOP) {
    //d_println("Nop");
  }
  if (prev_debug_data != debug_data) {
    prev_debug_data = debug_data;
    d_printf("Debug: %04x", debug_data); d_println();
  }
}

void on_time() {
  zxosd.setPos(24, 0);
  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  static bool dots_blink = !dots_blink;
  String dots = String(dots_blink ? ':' : ' ');
  uint8_t h = zxrtc.getHour();
  uint8_t m = zxrtc.getMinute();
  uint8_t s = zxrtc.getSecond();
  if (h < 10) zxosd.print(0); zxosd.print(h);
  if (dots_blink) zxosd.print(":"); else zxosd.print(" ");
  if (m < 10) zxosd.print(0); zxosd.print(m);
  if (dots_blink) zxosd.print(":"); else zxosd.print(" ");
  if (s < 10) zxosd.print(0); zxosd.print(s);

  zxosd.setPos(24, 1);
  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  uint8_t d = zxrtc.getDay();
  uint8_t mo = zxrtc.getMonth();
  uint8_t y = zxrtc.getYear();
  if (d < 10) zxosd.print(0); zxosd.print(d); zxosd.print("/");
  if (mo < 10) zxosd.print(0); zxosd.print(mo); zxosd.print("/");
  if (y < 10) zxosd.print(0); zxosd.print(y);

  // on time callback
  app_core_browser_on_time();
}

void read_core(const char* filename) {

  file1 = LittleFS.open(filename, "r");

  if (!file1) {
    halt("Unable to open bitstream file to read");
  }

  core.flash = false;
  strcpy(core.filename, file1.name());
  core.filename[32] = '\0';
  file_seek(FILE_POS_CORE_NAME); file_read_bytes(core.name, 32); core.name[32] = '\0';
  uint8_t visible; file_seek(FILE_POS_CORE_VISIBLE); visible = file_read(); core.visible = (visible > 0);
  file_seek(FILE_POS_CORE_ORDER); core.order = file_read();
  file_seek(FILE_POS_CORE_TYPE); core.type = file_read();
  // show OSD on boot (only for boot and fileloader cores)
  is_osd = false;
  switch (core.type) {
    case CORE_TYPE_BOOT: is_osd = true; break;
    case CORE_TYPE_OSD: is_osd = false; break;
    case CORE_TYPE_FILELOADER: is_osd = true; break;
    default: is_osd = false;
  }  
  d_print("Core type: ");
  switch (core.type) {
    case CORE_TYPE_BOOT: d_println("Boot"); break;
    case CORE_TYPE_OSD: d_println("Normal"); break;
    case CORE_TYPE_FILELOADER: d_println("Fileloader"); break;
    case CORE_TYPE_HIDDEN: d_println("Hidden"); break;
    default: d_println("Reserved");
  }
  core.bitstream_length = file_read32(FILE_POS_BITSTREAM_LEN);
  file_seek(FILE_POS_CORE_ID); file_read_bytes(core.id, 32); core.id[32] = '\0';
  file_seek(FILE_POS_CORE_BUILD); file_read_bytes(core.build, 8); core.build[8] = '\0';
  file_seek(FILE_POS_CORE_EEPROM_BANK); core.eeprom_bank = file_read();
  file_seek(FILE_POS_RTC_TYPE); core.rtc_type = file_read();
  file_seek(FILE_POS_FILELOADER_DIR); file_read_bytes(core.dir, 32); core.dir[32] = '\0';
  file_seek(FILE_POS_FILELOADER_FILE); core.last_file_id = file_read16(FILE_POS_FILELOADER_FILE);
  file_seek(FILE_POS_FILELOADER_EXTENSIONS); file_read_bytes(core.file_extensions, 32); core.file_extensions[32] = '\0';
  file_seek(FILE_POS_SPI_FREQ); core.spi_freq = file_read();
  uint8_t sd_enable; file_seek(FILE_POS_SD_ENABLE); sd_enable = file_read(); core.sd_enable = (sd_enable > 0);
  uint32_t roms_len = file_read32(FILE_POS_ROM_LEN);
  uint32_t offset = FILE_POS_BITSTREAM_START + core.bitstream_length + roms_len;
  //d_print("OSD section: "); d_println(offset);
  file_seek(offset); core.osd_len = file_read();
  //d_print("OSD len: "); d_println(core.osd_len);

  d_print("Core SPI Frequency: "); if (core.spi_freq > 0 && core.spi_freq < 255) { d_print(core.spi_freq); d_println(" MHz"); } else d_println("default");
  
  for (uint8_t i=0; i<MAX_FILE_SLOTS; i++) { file_slots[i].is_mounted = false; }

  for (uint8_t i=0; i<core.osd_len; i++) {
    core.osd[i].type = file_read();
    file_read();
    file_read_bytes(core.osd[i].name, 16); core.osd[i].name[16] = '\0';
    core.osd[i].def = file_read();
    core.osd[i].val = core.osd[i].def;
    core.osd[i].prev_val = core.osd[i].def;

    // filemounter osd type:
    // loading initial dir, filename, extensions and trying to mount file, if any
    if (core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[i].type == CORE_OSD_TYPE_FILELOADER) {
      core.osd[i].options_len = 0;
      core.osd[i].slot_id = file_read();
      file_slots[core.osd[i].slot_id].is_autoload = bitRead(core.osd[i].slot_id, 7);
      core.osd[i].slot_id = bitClear(core.osd[i].slot_id, 7);
      file_slots[core.osd[i].slot_id].is_mounted = false;
      file_read_bytes(file_slots[core.osd[i].slot_id].ext, 256); file_slots[core.osd[i].slot_id].ext[255] = '\0';
      file_slots[core.osd[i].slot_id].offset_dir = file1.position();
      file_read_bytes(file_slots[core.osd[i].slot_id].dir, 256); file_slots[core.osd[i].slot_id].dir[255] = '\0';
      String dir = String(file_slots[core.osd[i].slot_id].dir);
      if (dir == "") { dir = "/"; }
      if (dir.charAt(0) != '/') { dir = '/' + dir; }
      dir.toCharArray(file_slots[core.osd[i].slot_id].dir, sizeof(file_slots[core.osd[i].slot_id].dir));
      file_slots[core.osd[i].slot_id].offset_filename = file1.position();
      file_read_bytes(file_slots[core.osd[i].slot_id].filename, 256); file_slots[core.osd[i].slot_id].filename[255] = '\0';
      String sfilename = String( file_slots[core.osd[i].slot_id].filename); sfilename.trim();
      String sfullname = dir + "/" + sfilename; sfullname.trim();
      if (sfilename.length() > 0 && LittleFS.exists(sfullname)) {
        file_slots[core.osd[i].slot_id].is_mounted = true; //file_slots[core.osd[i].slot_id].file = sd1.open(sfullname, O_READ);
        if (file_slots[core.osd[i].slot_id].is_autoload) {
          // todo: autoload (spi commands to the host)
          // todo: depends on type
        }
      }
    }
      // otherwise - reading options structure
      else {
      core.osd[i].options_len = file_read();
      if (core.osd[i].options_len > 8) {
        core.osd[i].options_len = 8; // something goes wrong
      } 
      for (uint8_t j=0; j<core.osd[i].options_len; j++) {
        file_read_bytes(core.osd[i].options[j].name, 16); core.osd[i].options[j].name[16] = '\0';
      }
    }
    file_read_bytes(core.osd[i].hotkey, 16); core.osd[i].hotkey[16] = '\0';
    core.osd[i].keys[0] = file_read();
    core.osd[i].keys[1] = file_read();
    file_read(); // reserved
    file_read(); 
    file_read();
  }

  // read eeprom data from file (in case rombank = 4 and up)
  // 255 means no eeprom allowed by core
  if (core.eeprom_bank >= MAX_EEPROM_BANKS && core.eeprom_bank != NO_EEPROM_BANK) {
    for (uint8_t i=0; i<255; i++) {
      file_seek(FILE_POS_EEPROM_DATA + i);
      core.eeprom[i].val = file_read();
      core.eeprom[i].prev_val = core.eeprom[i].val;
    }
  }
  zxrtc.setEepromBank(core.eeprom_bank);
  zxrtc.setRtcType(core.rtc_type);
  zxrtc.sendAll();

  // read saved switches
  for(uint8_t i=0; i<core.osd_len; i++) {
    file_seek(FILE_POS_SWITCHES_DATA + i);
    core.osd[i].val = file_read();
    if (core.osd[i].val > core.osd[i].options_len-1) {
      core.osd[i].val = core.osd[i].def;
    }
    core.osd[i].prev_val = core.osd[i].val;
  }
  core_send_all();

  // re-send rtc registers
  zxrtc.sendAll();

  // dump parsed OSD items
  for(uint8_t i=0; i<core.osd_len; i++) {
    d_printf("OSD %d: type: %d name: %s def: %d len: %d keys: [%d %d %d]", i, core.osd[i].type, core.osd[i].name, core.osd[i].def, core.osd[i].options_len, core.osd[i].keys[0], core.osd[i].keys[1], core.osd[i].keys[2]); 
    d_println();
    for (uint8_t j=0; j<core.osd[i].options_len; j++) {
      d_print(core.osd[i].options[j].name); d_print(", "); 
    } 
    d_println();
    d_print(core.osd[i].hotkey); d_println();
  }

  file1.close();

  // mount slots
  for(uint8_t i=0; i<core.osd_len; i++) {
    if (core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER) {
      String dir = String(file_slots[core.osd[i].slot_id].dir);
      if (dir == "") { dir = "/"; }
      if (dir.charAt(0) != '/') { dir = '/' + dir; }
      dir.toCharArray(file_slots[core.osd[i].slot_id].dir, sizeof(file_slots[core.osd[i].slot_id].dir));
      String sfilename = String( file_slots[core.osd[i].slot_id].filename);
      String sfullname = dir + "/" + sfilename;
      if (sfilename.length() > 0 && LittleFS.exists(sfullname)) {
        // todo
        //file_slots[core.osd[i].slot_id].is_mounted = file_slots[core.osd[i].slot_id].file = sd1.open(sfullname, O_READ);
      }
      core_send(i);
    }
  }

  zxosd.hidePopup();
  if (is_osd) {
    zxosd.showMenu();
  } else {
    zxosd.hideMenu();
  }

  osd_handle(true);
}

void read_roms(const char* filename) {

  file1 = LittleFS.open(filename, "r");
  if (!file1) {
    halt("Unable to open bitstream file to read");
  }

  uint32_t bitstream_length = file_read32(FILE_POS_BITSTREAM_LEN);
  uint32_t roms_len = file_read32(FILE_POS_ROM_LEN);
  d_print("ROMS len "); d_println(roms_len);
  if (roms_len > 0) {
    spi_send(CMD_ROMLOADER, 0, 1);
  }
  uint32_t offset = 0;
  uint32_t rom_idx = 0;
  while (roms_len > 0) {
    uint32_t rom_len = file_read32(FILE_POS_BITSTREAM_START + bitstream_length + offset);
    bool rom_is_external = bitRead(rom_len, 31);
    rom_len = bitClear(rom_len, 31);
    uint32_t rom_addr = file_read32(FILE_POS_BITSTREAM_START + bitstream_length + offset + 4);
    d_print("ROM #"); d_print(rom_idx); d_print(": addr="); d_print(rom_addr); d_print(", len="); d_println(rom_len);
    if (rom_is_external) {
      char rom_filename[256];
      d_print("External ROM "); d_println(rom_filename);

      // todo: read and send external rom from sd1
      if (LittleFS.exists(rom_filename)) {
        file2 = LittleFS.open(rom_filename, "r");
        char buf[256];
        int i=0;
        while (int c = file2.readBytes(buf, sizeof(buf))) {
          for (int j=0; j<256; j++) {

            uint32_t addr = rom_addr + i*256 + j;
            uint8_t data = buf[j];

            // send rombank address every 256 bytes
              if (addr % 256 == 0) {
                uint8_t rombank3 = (uint8_t)((addr & 0xFF000000) >> 24);
                uint8_t rombank2 = (uint8_t)((addr & 0x00FF0000) >> 16);
                uint8_t rombank1 = (uint8_t)((addr & 0x0000FF00) >> 8);
                //d_printf("ROM bank %d %d %d", rombank1, rombank2, rombank3); d_println();
                spi_send(CMD_ROMBANK, 0, rombank1);
                spi_send(CMD_ROMBANK, 1, rombank2);
                spi_send(CMD_ROMBANK, 2, rombank3);
              }
              // send lower 256 bytes
              uint8_t romaddr = (uint8_t)((addr & 0x000000FF));
              spi_send(CMD_ROMDATA, romaddr, data);

          }
          if (rom_len > 0) {
            zxosd.setPos(4,5+rom_idx);
            //uint8_t perc = ceil((float) i*256 * (100.0 / rom_len));
            zxosd.print(rom_idx+1); zxosd.print(": ");
            char b[40];
            sprintf(b, "%05d", (i+1)*256); zxosd.print(b); zxosd.print(" ");
          }
          i++;
        }
        file2.close();
      } else {
        zxosd.setPos(4,5+rom_idx);
        zxosd.print(rom_idx+1); zxosd.print(": ");
        zxosd.print(" NO FILE");
      }
    } else {
      for (uint32_t i=0; i<rom_len/256; i++) {
        char buf[256];
        int c = file_read_bytes(buf, sizeof(buf));
        for (int j=0; j<256; j++) {

          uint32_t addr = rom_addr + i*256 + j;
          uint8_t data = buf[j];

          // send rombank address every 256 bytes
            if (addr % 256 == 0) {
              uint8_t rombank3 = (uint8_t)((addr & 0xFF000000) >> 24);
              uint8_t rombank2 = (uint8_t)((addr & 0x00FF0000) >> 16);
              uint8_t rombank1 = (uint8_t)((addr & 0x0000FF00) >> 8);
              //d_printf("ROM bank %d %d %d", rombank1, rombank2, rombank3); d_println();
              spi_send(CMD_ROMBANK, 0, rombank1);
              spi_send(CMD_ROMBANK, 1, rombank2);
              spi_send(CMD_ROMBANK, 2, rombank3);
            }
            // send lower 256 bytes
            uint8_t romaddr = (uint8_t)((addr & 0x000000FF));
            spi_send(CMD_ROMDATA, romaddr, data);

        }
        if (rom_len > 0) {
          zxosd.setPos(4,5+rom_idx);
          //uint8_t perc = ceil((float) i*256 * (100.0 / rom_len));
          zxosd.print(rom_idx+1); zxosd.print(": ");
          char b[40];
          sprintf(b, "%05d", (i+1)*256); zxosd.print(b); zxosd.print(" ");
        }
      }
    }
    offset = offset + rom_len + 8;
    roms_len = roms_len - rom_len - 8;
    rom_idx++;
    if (roms_len > 0) {
      // next rom
      zxosd.setPos(0, 5+rom_idx);
      zxosd.print("ROM ");
    }
  }
  //delay(100);
  spi_send(CMD_ROMLOADER, 0, 0);

  file1.close();
}

void osd_handle(bool force) {
  if (is_osd || force) {
    if ((osd_prev_state != osd_state) || force) {
      osd_prev_state = osd_state;
      switch(osd_state) {
        case state_core_browser:
          app_core_browser_overlay();
        break;
        case state_main:
          app_core_overlay();
        break;
        case state_file_loader:
          app_file_loader_overlay(true, false);
        break;
      }
    }
  }  
}

bool btn_read(uint8_t num) {
  if (num == 0) { 
    return !digitalRead(PIN_BTN1);
  } else {
    return !digitalRead(PIN_BTN2);
  }
}

void led_write(uint8_t num, bool on) {
  if (num == 0) { 
    digitalWrite(PIN_LED1, !on);
  } else {
    digitalWrite(PIN_LED2, !on);
  }
}

static void process_kbd_report(uint8_t dev_addr, uint8_t instance, hid_keyboard_report_t const *report, uint16_t len)
{
  static hid_keyboard_report_t prev_report = {0};

  uint8_t change = ((report->modifier ^ prev_report.modifier) || (report->keycode[0] ^ prev_report.keycode[0]) 
    || (report->keycode[1] ^ prev_report.keycode[1])
    || (report->keycode[2] ^ prev_report.keycode[2])
    || (report->keycode[3] ^ prev_report.keycode[3])
    || (report->keycode[4] ^ prev_report.keycode[4])
    || (report->keycode[5] ^ prev_report.keycode[5]));
  if (change != 0) {
    usb_keyboard_report = *report;
    spi_queue(CMD_USB_KBD, 0, report->modifier);
    for(uint8_t i=0; i<6; i++) {
      spi_queue(CMD_USB_KBD, i+1, report->keycode[i]);
    }
    d_printf("HID Keyboard: %02x %02x %02x %02x %02x %02x %02x", 
      report->modifier, 
      report->keycode[0], 
      report->keycode[1],
      report->keycode[2],
      report->keycode[3],
      report->keycode[4],
      report->keycode[5]
    );
    d_println();
    prev_report = *report;
  }
}

static void process_mouse_report(uint8_t dev_addr, uint8_t instance, hid_mouse_report_t const * report, uint16_t len) {

  static hid_mouse_report_t prev_report = {0};

  bool change = ((report->x ^ prev_report.x) || 
                 (report->y ^ prev_report.y) || 
                 (report->buttons ^ prev_report.buttons) ||
                 (report->wheel ^ prev_report.wheel));
  if (change) {
    //d_print("Mouse protocol len="); d_println(len);
    usb_mouse_report = *report;
    spi_queue(CMD_USB_MOUSE, 0, report->x);
    spi_queue(CMD_USB_MOUSE, 1, report->y);
    spi_queue(CMD_USB_MOUSE, 2, report->wheel);
    spi_queue(CMD_USB_MOUSE, 3, report->buttons);
    d_printf("HID Mouse XYZB: %02x %02x %02x %02x", report->x, report->y, report->wheel, report->buttons);
    d_println();
    prev_report = *report;
    prev_report.wheel = 0;
  }
}

/////////