#include <Arduino.h>
#include "config.h"
#include "types.h"
#include "main.h"
#include "OSD.h"
#include "SdFat.h"
#include "SegaController.h"
#include "usb_hid_keys.h"
#include <algorithm>
#include <tuple>
#include "app_core_browser.h"
#include "sorts.h"
#include <cstdio>
#include <iostream>
using namespace std;

core_list_item_t cores[MAX_CORES];
uint8_t cores_len = 0;
uint8_t core_sel = 0;
const uint8_t core_page_size = MAX_CORES_PER_PAGE;
const uint8_t ft_core_page_size = MAX_CORES_PER_PAGE/2;
uint8_t core_pages = 1;
uint8_t core_page = 1;
uint16_t rot = 0;
ElapsedTimer autoload_timer;
bool autoload_enabled;
uint32_t autoload_countdown;

void app_core_browser_overlay() {
  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  zxosd.clear();
  zxosd.header(core.build, core.id);
  zxosd.setPos(0,5);
  app_core_browser_menu(APP_COREBROWSER_MENU_OFFSET);  
  // footer
  zxosd.line(21);
  zxosd.line(23);
  zxosd.setPos(1,24); zxosd.print("Please use arrows to navigate");
  zxosd.setPos(1,25); zxosd.print("Press Enter to load selection");
}

void app_core_browser_menu(uint8_t vpos) {
  core_pages = ceil((float)cores_len / core_page_size);
  core_page = ceil((float)(core_sel+1)/core_page_size);
  uint8_t core_from = (core_page-1)*core_page_size;
  uint8_t core_to = core_page*core_page_size > cores_len ? cores_len : core_page*core_page_size;
  uint8_t core_fill = core_page*core_page_size;
  uint8_t pos = vpos;
  for(uint8_t i=core_from; i < core_to; i++) {
    zxosd.setPos(0, pos);
    if (core_sel == i) {
      zxosd.setColor(OSD::COLOR_BLACK, OSD::COLOR_WHITE);
    } else {
      zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    }
    char name[18]; memcpy(name, cores[i].name, 17); name[17] = '\0';
    char b[40];
    sprintf(b, "%-3d ", i+1); 
    zxosd.print(b);
    zxosd.print(name);
    zxosd.print(cores[i].build);
    zxosd.print(cores[i].flash ? " FS" : " SD");
    pos++;
  }
  if (core_fill > core_to) {
    for (uint8_t i=core_to; i<core_fill; i++) {
      zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
      for (uint8_t j=0; j<32; j++) {
        zxosd.print(" ");
      }
    }
  }
  zxosd.setPos(8, vpos + core_page_size + 1); zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  char b[40];
  sprintf(b, "Page %02d of %02d", core_page, core_pages); 
  zxosd.print(b);
}

core_list_item_t app_core_browser_get_item() {
  core_list_item_t core;
  strcpy(core.filename, file1.name());
  core.flash = true;
  file_seek(FILE_POS_CORE_ID); file_read_bytes(core.id, 32); core.id[32] = '\0';
  file_seek(FILE_POS_CORE_NAME); file_read_bytes(core.name, 32); core.name[32] = '\0';
  uint8_t visible; file_seek(FILE_POS_CORE_VISIBLE); visible = file_read(); core.visible = (visible > 0);
  file_seek(FILE_POS_CORE_ORDER); core.order = file_read();
  file_seek(FILE_POS_CORE_TYPE); core.type = file_read();
  file_seek(FILE_POS_CORE_BUILD); file_read_bytes(core.build, 8); core.build[8] = '\0';
  return core;
}

void app_core_browser_read_list() {
  root1 = LittleFS.openDir("/");
  root1.rewind();
  while (root1.next()) {
    if (root1.fileSize()) {
      file1 = root1.openFile("r");
      char filename[32]; strcpy(filename, file1.name());
      uint8_t len = strlen(filename);
      if (strstr(strlwr(filename + (len - 4)), CORE_EXT)) {
        cores[cores_len] = app_core_browser_get_item();
        cores_len++;
      }
      file1.close();
    }
  }
  // sort by core order number
  std::sort(cores, cores + cores_len);
  
  autoload_enabled = false;
  // pre-select autoload core
  for (uint8_t i=0; i<cores_len; i++) {
    String s1 = String("todo");
    String s2 = String(cores[i].id);
    s1.trim();
    s2.trim();
//    d_println(s1);
//    d_println(s2);
//    d_println(hw_setup.autoload_enabled);
    if (!autoload_enabled && s2.equals(s1)) {
      autoload_enabled = true;
      autoload_countdown = 15;
      core_sel = i;
      autoload_timer.reset();
    }
  }

}

void app_core_browser_on_keyboard() {
      if (cores_len > 0) {
        // down
        if (usb_keyboard_report.keycode[0] == KEY_DOWN || (joy & SC_BTN_DOWN) || (joy & SC_BTN_DOWN)) {
          autoload_enabled = false;
          if (core_sel < cores_len-1) {
            core_sel++;
          } else {
            core_sel = 0;
          }
        }

        // up
        if (usb_keyboard_report.keycode[0] == KEY_UP  || (joy & SC_BTN_UP) || (joy & SC_BTN_UP)) {
          autoload_enabled = false;
          if (core_sel > 0) {
            core_sel--;
          } else {
            core_sel = cores_len-1;
          }
        }

        // right
        if (usb_keyboard_report.keycode[0] == KEY_RIGHT || (joy & SC_BTN_RIGHT) || (joy & SC_BTN_RIGHT)) {
          autoload_enabled = false;
          if (core_sel + core_page_size <= cores_len-1) {
            core_sel += core_page_size;
          } else {
            core_sel = cores_len-1;
          }
        }

        // left
        if (usb_keyboard_report.keycode[0] == KEY_LEFT || (joy & SC_BTN_LEFT) || (joy & SC_BTN_LEFT)) {
          autoload_enabled = false;
          if (core_sel - core_page_size >= 0) {
            core_sel -= core_page_size;
          } else {
            core_sel = 0;
          }
        }
        
        // enter
        if (usb_keyboard_report.keycode[0] == KEY_ENTER || (joy & SC_BTN_A) || (joy & SC_BTN_B)) {
          autoload_enabled = false;
          d_printf("Selected core %s to boot from menu", cores[core_sel].filename); d_println(); 
          String f = String(cores[core_sel].filename); f.trim(); 
          char buf[32]; f.toCharArray(buf, sizeof(buf));
          do_configure(buf);
          switch (core.type) {
            case CORE_TYPE_BOOT: osd_state = state_core_browser; break;
            case CORE_TYPE_OSD: osd_state = state_main; break;
            case CORE_TYPE_FILELOADER: osd_state = state_file_loader; break;
            default: osd_state = state_main;
          }
        }

        // redraw core browser on keypress
        if (osd_state == state_core_browser) {
          app_core_browser_menu(APP_COREBROWSER_MENU_OFFSET);
        }
      }
}

void app_core_browser_on_time() {
  if (autoload_enabled) {
    if (autoload_timer.elapsed() > autoload_countdown * 1000) {
      autoload_enabled = false;
      String f = String(cores[core_sel].filename); f.trim(); 
      char buf[32]; f.toCharArray(buf, sizeof(buf));
      do_configure(buf);
      switch (core.type) {
        case CORE_TYPE_BOOT: osd_state = state_core_browser; break;
        case CORE_TYPE_OSD: osd_state = state_main; break;
        case CORE_TYPE_FILELOADER: osd_state = state_file_loader; break;
        default: osd_state = state_main;
      }
    }
  }
}
