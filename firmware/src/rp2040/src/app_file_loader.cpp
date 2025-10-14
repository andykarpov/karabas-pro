#include <Arduino.h>
#include "config.h"
#include "types.h"
#include "main.h"
#include "OSD.h"
#include "usb_hid_keys.h"
#include "SegaController.h"
#include "SdFat.h"
#include <algorithm>
#include <tuple>
#include "app_file_loader.h"
#include <SPI.h>
#include "sorts.h"

void app_file_loader_read_list(bool forceIndex = false) {

  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  zxosd.frame(8,8,24,12, 1);
  zxosd.fill(9,9,23,11, 32);
  zxosd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  zxosd.setPos(9, 9);
  zxosd.print("Scanning files");
  zxosd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  zxosd.setPos(9,10);
  zxosd.print("Please wait...");
  delay(500);

  // files from sd1 card

  /*if (has_sd) {
    String dir = String(core.dir);
    dir.trim();
    if (dir.length() == 0) dir = "/";
    if (dir.charAt(0) != '/') dir = "/" + dir;
    char d[256];
    dir.toCharArray(d, 255);
    if (root1.isOpen()) {
      root1.close();
    }
    if (!root1.open(d)) {

        zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
        zxosd.frame(8,8,24,12, 1);
        zxosd.fill(9,9,23,11, 32);
        zxosd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
        zxosd.setPos(9, 9);
        zxosd.print("Error occured");
        zxosd.setPos(9,10);
        char b[255];
        sprintf(b, "Bad dir %s", d); 
        zxosd.print(b);
        delay(1000);
        app_file_loader_read_list(forceIndex);
        return;
    }
    root1.rewind();

    d_println("Read file list");
    files_len = 0;
    file_sel = 0;
    memset(files, 0, sizeof(files));
    String exts = String(core.file_extensions);
    exts.toLowerCase(); exts.trim();
    char e[33];
    exts.toCharArray(e, 32);
    while (file1.openNext(&root1, O_RDONLY)) {
      char filename[14]; file1.getSFN(filename, sizeof(filename));
      uint8_t len = strlen(filename);
      if (!file1.isDirectory() && files_len < SORT_FILES_MAX) {
        if (exts.length() == 0 || exts.indexOf(strlwr(filename + (len - 4))) != -1) {
          memcpy(files[files_len].hash, filename, SORT_HASH_LEN);
          files[files_len].file_id = file1.dirIndex();
          files_len++;
        }
      }
      file1.close();
    }

  } else {
    zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    zxosd.frame(8,8,24,12, 1);
    zxosd.fill(9,9,23,11, 32);
    zxosd.setColor(OSD::COLOR_RED_I, OSD::COLOR_BLACK);
    zxosd.setPos(9, 9);
    zxosd.print("Error occured");
    zxosd.setPos(9,10);
    zxosd.print("Check SD card");
    delay(1000);
    app_file_loader_read_list(forceIndex);
    return;
  }*/

  // sort by file name
  std::sort(files, files + files_len);
  
  // cleanup error messages
  /*if (has_sd) {
    zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    zxosd.fill(8,8,24,12, 32);  
  }*/

  // select and load prev file on boot
  /*if (has_sd && files_len > 0 && core.last_file_id > 0) {
    //d_printf("Looking for last file id = %d", core.last_file_id); d_println();
    for (uint16_t i=0; i<files_len; i++) {
      if (core.last_file_id == files[i].file_id) {
          file_sel = i;
          //d_printf("Found %d pos", i); d_println();
          if (file1.open(&root1, core.last_file_id)) {
            app_file_loader_send_file(core.last_file_id);
            file1.close();
          }
          // hide osd
          if (!is_osd_hiding) {
            is_osd_hiding = true;
            hide_timer.reset();
            zxosd.hideMenu();
          }
      }
    }
  }*/
}

void app_file_loader_menu(uint8_t vpos) {
  file_pages = ceil((float)files_len / file_page_size);
  file_page = ceil((float)(file_sel+1)/file_page_size);
  uint16_t file_from = (file_page-1)*file_page_size;
  uint16_t file_to = file_page*file_page_size > files_len ? files_len : file_page*file_page_size;
  uint16_t file_fill = file_page*file_page_size;
  uint16_t pos = vpos;
  uint16_t j = 0;

  /*if (files_len > 0) {    
    for(uint16_t i=file_from; i < file_to; i++) {
      zxosd.setPos(0, pos);
      if (file_sel == i) {
        zxosd.setColor(OSD::COLOR_BLACK, OSD::COLOR_WHITE);
      } else {
        zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
      }
      // display 32 chars
      char name[32+1]; 
      
      // copy name from cache
      if ((cached_file_from == file_from) && (cached_file_to == file_to)) {
        memcpy(name, cached_names[j].name, sizeof(name));
      } 
      // get name from filename and put into cache
      else {

        if (file1.open(&root1, files[i].file_id)) {
          char filename[255];
          file1.getName(filename, sizeof(filename));
          String exts = String(core.file_extensions); exts.toLowerCase(); exts.trim();
          String f(filename);
          f.toCharArray(name, sizeof(name));
          f.toCharArray(cached_names[j].name, sizeof(cached_names[j].name));
          cached_names[j].name[32] = '\0';
          file1.close();
        }
      }

      zxosd.print(name);
      // fill name with spaces
      uint8_t l = strlen(name);
      if (l < 32) {
        for (uint8_t ll=l; ll<32; ll++) {
          zxosd.print(" ");
        }
      }
      pos++;
      j++;
    }
    cached_file_from = file_from;
    cached_file_to = file_to;
  }*/
  if (file_fill > file_to) {
    for (uint16_t i=file_to; i<file_fill; i++) {
      zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
      for (uint16_t j=0; j<32; j++) {
        zxosd.print(" ");
      }
    }
  }
  zxosd.setPos(8, vpos + file_page_size + 1); zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  char b[40];
  sprintf(b, "Page %03d of %03d", file_page, file_pages); 
  zxosd.print(b);
}

void app_file_loader_overlay(bool initSD = true, bool recreateIndex = false) {
  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  zxosd.clear();

  zxosd.header(core.build, core.id);

  // collect files from sd
  if (initSD) {
      app_file_loader_read_list(recreateIndex);
  }

  zxosd.setPos(0,5);
  app_file_loader_menu(APP_COREBROWSER_MENU_OFFSET);  

  // footer
  zxosd.line(21);
  zxosd.line(23);
  zxosd.setPos(1,24); zxosd.print("Please use arrows to navigate");
  zxosd.setPos(1,25); zxosd.print("Press Enter to load selection");
}

void app_file_loader_save()
{
    /*sd1.chvol();
    if (!file1.open(core.filename, FILE_WRITE)) {
      d_println("Unable to open bitstream file to write");
      return;
    }
    if (!file1.isWritable()) {
      d_println("File is not writable");
      return;
    }
    core.last_file_id = files[file_sel].file_id;
    file_write16(FILE_POS_FILELOADER_FILE, core.last_file_id);
    file1.close();*/
}

void app_file_loader_send_file(uint16_t file_id) {
  
  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  zxosd.frame(8,8,24,12, 1);
  zxosd.fill(9,9,23,11, 32);
  zxosd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  zxosd.setPos(9, 9);
  zxosd.print("Preparing...   ");
  zxosd.setColor(OSD::COLOR_MAGENTA_I, OSD::COLOR_BLACK);
  zxosd.setPos(9,10);
  zxosd.print("Please wait.   ");

  /*if (root1.isOpen()) {
    root1.close();
  }

  if (!root1.isOpen()) {
    String dir = String(core.dir);
    dir.trim();
    if (dir.length() == 0) dir = "/";
    if (dir.charAt(0) != '/') dir = "/" + dir;
    //sd1.chdir(dir);
    char dirname[255];
    dir.toCharArray(dirname, sizeof(dirname));
    if (!root1.open(&sd1, dirname)) {
      d_printf("Unable to open dir %s", dirname); d_println();
      return;
    } else {
      //d_printf("Dir %s open", dirname); d_println();
    }
  }

  if (file1.isOpen()) {
    file1.close();
  }

  if (!file1.open(&root1, file_id, FILE_READ)) {
    d_printf("Unable to open file %d", file_id); d_println();
    d_flush();
    app_file_loader_overlay(false, false);
    return;
  }*/

  uint8_t buf[512];
  int c;

  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  zxosd.frame(8,8,24,12, 1);
  zxosd.fill(9,9,23,11, 32);
  zxosd.setColor(OSD::COLOR_YELLOW_I, OSD::COLOR_BLACK);
  zxosd.setPos(9, 9);
  zxosd.print("Loading...     ");
  zxosd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
  zxosd.setPos(9,10);
  zxosd.print("Please wait.   ");
  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);

  // trigger reset
  spi_send(CMD_FILELOADER, 0, 3); // 11 - active = 1, reset = 1
  spi_send(CMD_FILELOADER, 0, 2); // 10 - active = 1, reset = 0

  uint64_t file_size = file1.size();

  d_printf("Sending file %d (%d bytes)", file_id, (uint32_t)((file_size))); d_println();
  d_flush();
  
uint32_t cnt = 0;

  while(c = file1.read(buf, sizeof(buf))) {
    for (int j=0; j<c; j++) {
      app_file_loader_send_byte(cnt, buf[j]);
      cnt++;
      if (cnt % 8192 == 0) {
        zxosd.progress(9, 11, 15, cnt, file_size);
      }
    }
  }
  zxosd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
  zxosd.progress(9, 11, 15, file_size, file_size);
  
  // 00 - active = 0, reset = 0
  spi_send(CMD_FILELOADER, 0, 0);

  file1.close();
  d_printf("Sent %u bytes", cnt); d_println();
  delay(100);

  // reload menu
  app_file_loader_overlay(false, false);
}

void app_file_loader_on_keyboard() 
{
          if (files_len > 0) {
        // down
        if (usb_keyboard_report.keycode[0] == KEY_DOWN || (joy & SC_BTN_DOWN)) {
          if (file_sel < files_len-1) {
            file_sel++;
          } else {
            file_sel = 0;
          }
        }

        // up
        if (usb_keyboard_report.keycode[0] == KEY_UP || (joy & SC_BTN_UP)) {
          if (file_sel > 0) {
            file_sel--;
          } else {
            file_sel = files_len-1;
          }
        }

        // right
        if (usb_keyboard_report.keycode[0] == KEY_RIGHT || (joy & SC_BTN_RIGHT)) {
          if (file_sel + file_page_size <= files_len-1) {
            file_sel += file_page_size;
          } else {
            file_sel = files_len-1;
          }
        }

        // left
        if (usb_keyboard_report.keycode[0] == KEY_LEFT || (joy & SC_BTN_LEFT)) {
          if (file_sel - file_page_size >= 0) {
            file_sel -= file_page_size;
          } else {
            file_sel = 0;
          }
        }

        // R = recreate file index
        if (usb_keyboard_report.keycode[0] == KEY_R) {
            file_sel = 0;
            app_file_loader_overlay(true, true);
        }
        
        // enter
        if (usb_keyboard_report.keycode[0] == KEY_ENTER || (joy & SC_BTN_A) || (joy & SC_BTN_B)) {
          app_file_loader_save();
          app_file_loader_send_file(files[file_sel].file_id);
          // hide osd
          if (!is_osd_hiding) {
            is_osd_hiding = true;
            hide_timer.reset();
            zxosd.hideMenu();
          }
        }

        // redraw file loader on keypress
        if (osd_state == state_file_loader) {
          app_file_loader_menu(APP_COREBROWSER_MENU_OFFSET);
        }
      }
}

void app_file_loader_send_byte(uint32_t addr, uint8_t data) {
  // send file bank address every 256 bytes
  if (addr % 256 == 0) {
    uint8_t filebank3 = (uint8_t)((addr & 0xFF000000) >> 24);
    uint8_t filebank2 = (uint8_t)((addr & 0x00FF0000) >> 16);
    uint8_t filebank1 = (uint8_t)((addr & 0x0000FF00) >> 8);
    //d_printf("File bank %d %d %d", filebank1, filebank2, filebank3); d_println();
    spi_send(CMD_FILEBANK, 0, filebank1);
    spi_send(CMD_FILEBANK, 1, filebank2);
    spi_send(CMD_FILEBANK, 2, filebank3);
  }
  // send lower 256 bytes
  uint8_t fileaddr = (uint8_t)((addr & 0x000000FF));
  spi_send(CMD_FILEDATA, fileaddr, data);
}

