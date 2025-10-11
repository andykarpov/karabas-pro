#include <Arduino.h>
#include "types.h"
#include "config.h"
#include "OSD.h"
#include "usb_hid_keys.h"
#include "SegaController.h"
#include "SdFat.h"
#include "app_core.h"
#include <SPI.h>
#include <algorithm>
#include <tuple>
#include "sorts.h"
#include <LittleFS.h>

uint8_t curr_osd_item;
bool is_filebrowser = false;
int filebrowser_slot = -1;
int prev_filebrowser_slot = -1;
bool prev_is_filebrowser = false;

uint8_t find_first_item() {
  if (core.osd_len > 0) {
    for (uint8_t i = 0; i < core.osd_len; i++) {
      if (core.osd[i].options_len > 0 || core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[i].type == CORE_OSD_TYPE_FILELOADER) {
        return i;
      }
    }
  }
  return 0;
}

uint8_t find_last_item() {
  if (core.osd_len > 0) {
    for (uint8_t i = core.osd_len-1; i >= 0; i--) {
      if (core.osd[i].options_len > 0 || core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[i].type == CORE_OSD_TYPE_FILELOADER) {
        return i;
      }
    }
  }
  return 0;
}

uint8_t find_prev_item() {
  uint8_t first = find_first_item();
  uint8_t last = find_last_item();

  // border case with 0 or 1 items
  if (first == last) {
    return first;
  }

  // if there is a room to decrease - find a previous item
  if (curr_osd_item > first) {
    for (uint8_t i = curr_osd_item-1; i >= first; i--) {
      if (core.osd[i].options_len > 0 || core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[i].type == CORE_OSD_TYPE_FILELOADER) {
        return i;
      }
    }
  }
  // fallback - return last item with options
  return last;
}

uint8_t find_next_item() {
  uint8_t first = find_first_item();
  uint8_t last = find_last_item();

  // border case with 0 or 1 items
  if (first == last) {
    return last;
  }

  // if there is a room to increase - find a next item
  if (curr_osd_item < last) {
    for (uint8_t i = curr_osd_item+1; i <= last; i++) {
      if (core.osd[i].options_len > 0 || core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[i].type == CORE_OSD_TYPE_FILELOADER) {
        return i;
      }
    }
  }
  // fallback - return first item with options
  return first;

}

void app_core_overlay()
{
  // disable popup in overlay mode
  zxosd.hidePopup();

  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  zxosd.clear();

  zxosd.header(core.build, core.id);

  curr_osd_item = find_first_item();
  app_core_menu(APP_COREBROWSER_MENU_OFFSET);

  // footer
  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  zxosd.line(24);
  zxosd.setPos(0,25); zxosd.print("Press Menu+Esc to toggle OSD");
}

void app_core_menu(uint8_t vpos) {
  for (uint8_t i=0; i<core.osd_len; i++) {
    String name = String(core.osd[i].name);
    String hotkey = String(core.osd[i].hotkey);
    zxosd.setPos(0, i+vpos);
    zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
    // text line (32 chars)
    if (core.osd[i].type == CORE_OSD_TYPE_TEXT) {
      name = name + hotkey;
      zxosd.print(name.substring(0,32));
    // normal osd line (name, option, hotkey)
    } else {
      zxosd.print(name.substring(0,10));

      String option;
      if (core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[i].type == CORE_OSD_TYPE_FILELOADER) {
        if (file_slots[core.osd[i].slot_id].is_mounted) {
          option = String(file_slots[core.osd[i].slot_id].filename);
        } else {
          option = String("-NO IMAGE-");
        }
      } else {
        option = String(core.osd[i].options[core.osd[i].val].name);
        while (option.length() < 10) {
          option = option + " ";
        }
      }
      zxosd.setPos(11, i+vpos);
      if (curr_osd_item == i) {
        zxosd.setColor(OSD::COLOR_BLACK, OSD::COLOR_YELLOW_I);
      } else {
        zxosd.setColor(OSD::COLOR_YELLOW_I, OSD::COLOR_BLACK);
      }
      zxosd.print(option.substring(0, 10));

      String hotkey = String(core.osd[i].hotkey);
      zxosd.setColor(OSD::COLOR_CYAN_I, OSD::COLOR_BLACK);
      if (core.osd[i].options_len > 0 || core.osd[i].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[i].type == CORE_OSD_TYPE_FILELOADER) {
        zxosd.setPos(22, i+vpos);
        zxosd.print(hotkey.substring(0,10));
      } else {
        zxosd.setPos(11, i+vpos);
        zxosd.print(hotkey);
      }
    }
  }
  if (core.osd_len <= 19) zxosd.fill(0, 23, 31, 23, ' ');
  if (core.osd_len <= 18) zxosd.fill(0, 22, 31, 22, ' ');
  if (core.osd_len <= 17) zxosd.fill(0, 21, 31, 21, ' ');
}

void app_core_save(uint8_t pos)
{
    if (file1) {
      file1.close();
    }
    file1 = LittleFS.open(core.filename, "wb");
    if (file1) {
      d_println("Unable to open bitstream file to write");
      return;
    }  
    core.osd_need_save = false;
    if (core.osd[pos].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[pos].type == CORE_OSD_TYPE_FILELOADER) {
      // save file mounter data (dir, filename) into the core
      uint32_t offset = file_slots[core.osd[pos].slot_id].offset_dir;
      file_seek(offset); 
      file_write_buf(file_slots[core.osd[pos].slot_id].dir, 256);
      offset = file_slots[core.osd[pos].slot_id].offset_filename;
      file_seek(offset); 
      file_write_buf(file_slots[core.osd[pos].slot_id].filename, 256);
    } else {
      // save switch state into the core
      core.osd[pos].prev_val = core.osd[pos].val;
      file1.seek(FILE_POS_SWITCHES_DATA + pos);
      file1.write(core.osd[pos].val);
    }
    file1.close();  
}

void app_core_on_keyboard() {

  if (is_filebrowser) {

    // down
    if (usb_keyboard_report.keycode[0] == KEY_DOWN || (joy & SC_BTN_DOWN)) {
      if (files_len > 0) {
        if (file_sel < files_len-1) {
          file_sel++;
        } else {
          file_sel = 0;
        }
      }
      need_redraw = true;
    }

    // up
    if (usb_keyboard_report.keycode[0] == KEY_UP || (joy & SC_BTN_UP)) {
      if (file_sel > 0) {
        file_sel--;
      } else {
        file_sel = files_len-1;
      }
      need_redraw = true;
    }

    // right
    if (usb_keyboard_report.keycode[0] == KEY_RIGHT || (joy & SC_BTN_RIGHT)) {
      if (file_sel + file_page_size <= files_len-1) {
        file_sel += file_page_size;
      } else {
        file_sel = files_len-1;
      }
      need_redraw = true;
    }

    // left
    if (usb_keyboard_report.keycode[0] == KEY_LEFT || (joy & SC_BTN_LEFT)) {
      if (file_sel - file_page_size >= 0) {
        file_sel -= file_page_size;
      } else {
        file_sel = 0;
      }
      need_redraw = true;
    }

    // enter
    if (usb_keyboard_report.keycode[0] == KEY_ENTER || (joy & SC_BTN_B) ) {
      if (files_len > 0) {
        if (file1) {
          file1.close();
        }
        String hash = String(files[file_sel].hash);
        hash.trim();
        // goto root (.)
        if (files[file_sel].file_id == 0 && hash == ".") {
          String dir = "/";
          String f = "";
          dir.toCharArray(file_slots[core.osd[curr_osd_item].slot_id].dir, sizeof(file_slots[core.osd[curr_osd_item].slot_id].dir));
          f.toCharArray(file_slots[core.osd[curr_osd_item].slot_id].filename, sizeof(file_slots[core.osd[curr_osd_item].slot_id].filename));
          // re-read files from root
          file_sel = 0;
          cached_file_from = 0;
          cached_file_to = 0;
          file_slots[core.osd[curr_osd_item].slot_id].is_mounted = false;
          app_core_init_filebrowser();
          app_core_filebrowser(APP_COREBROWSER_MENU_OFFSET);
          return;
        }
        // goto parent (..)
        else if (files[file_sel].file_id == 0 && hash == "..") {
          String dir = String(file_slots[core.osd[curr_osd_item].slot_id].dir);
          String f = "";
          f.toCharArray(file_slots[core.osd[curr_osd_item].slot_id].filename, sizeof(file_slots[core.osd[curr_osd_item].slot_id].filename));
          dir = dir.substring(0, dir.lastIndexOf("/"));
          dir.replace("//", "/");
          d_print("Enter directory "); d_print(dir); d_println();
          dir.toCharArray(file_slots[core.osd[curr_osd_item].slot_id].dir, sizeof(file_slots[core.osd[curr_osd_item].slot_id].dir));
          // re-read files from parent dir
          file_sel = 0;
          cached_file_from = 0;
          cached_file_to = 0;
          file_slots[core.osd[curr_osd_item].slot_id].is_mounted = false;
          app_core_init_filebrowser();
          app_core_filebrowser(APP_COREBROWSER_MENU_OFFSET);
          return;
        }
        // open file / dir
        /*else if (file1 = LittleFS.open(files[file_sel].file_id)) {
          // goto new dir name
          if (file1.isDir()) {
            char dirname[255];
            file1.getName(dirname, sizeof(dirname));
            String dir = String(file_slots[core.osd[curr_osd_item].slot_id].dir) + "/" + String(dirname);
            dir.replace("//", "/");
            String f = "";
            dir.toCharArray(file_slots[core.osd[curr_osd_item].slot_id].dir, sizeof(file_slots[core.osd[curr_osd_item].slot_id].dir));
            f.toCharArray(file_slots[core.osd[curr_osd_item].slot_id].filename, sizeof(file_slots[core.osd[curr_osd_item].slot_id].filename));
            file_sel = 0;
            cached_file_from = 0;
            cached_file_to = 0;
            file1.close();
            file_slots[core.osd[curr_osd_item].slot_id].is_mounted = false;
            app_core_init_filebrowser();
            app_core_filebrowser(APP_COREBROWSER_MENU_OFFSET);
            return;
          }
          // file selection (if ext matches)
          else {
            d_printf("Selecting file id %d", files[file_sel].file_id); d_println();
            char filename[255];
            //file1.getSFN(filename, sizeof(filename));
            d_printf("Filename %s", filename);
            // check file ext match
            String exts = String(file_slots[core.osd[curr_osd_item].slot_id].ext);
            exts.toLowerCase(); exts.trim();
            char e[33];
            exts.toCharArray(e, 32);
            uint8_t len = strlen(filename);
            if (exts.length() == 0 || exts.indexOf(strlwr(filename + (len - 4))) != -1) {
              strcpy(file_slots[core.osd[curr_osd_item].slot_id].filename, filename);
              file_slots[core.osd[curr_osd_item].slot_id].is_mounted = true;
              app_core_on_select_file();
              is_filebrowser = false; // exit from file browser mode
            } else {
              d_println("File extension does not match");
              file_slots[core.osd[curr_osd_item].slot_id].is_mounted = false;
            }
          }
          file1.close();
        }*/

        core.osd_need_save = true;
      }
      need_redraw = true;
    }

    // esc
    if (usb_keyboard_report.keycode[0] == KEY_ESC || (joy & SC_BTN_A) ) {
      is_filebrowser = false;
      need_redraw = true;
    }

  } else {

        // down
        if (usb_keyboard_report.keycode[0] == KEY_DOWN || (joy & SC_BTN_DOWN)) {
          curr_osd_item = find_next_item();
          need_redraw = true;
        }

        // up
        if (usb_keyboard_report.keycode[0] == KEY_UP || (joy & SC_BTN_UP)) {
          curr_osd_item = find_prev_item();
          need_redraw = true;
        }

        // right, enter
        if (usb_keyboard_report.keycode[0] == KEY_RIGHT || usb_keyboard_report.keycode[0] == KEY_ENTER  || (joy & SC_BTN_A) || (joy & SC_BTN_B) || (joy & SC_BTN_RIGHT) ) {
          if (core.osd[curr_osd_item].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[curr_osd_item].type == CORE_OSD_TYPE_FILELOADER) {
            is_filebrowser = true;
          } else {
            core.osd[curr_osd_item].val++; 
            if (core.osd[curr_osd_item].val > core.osd[curr_osd_item].options_len-1) {
              core.osd[curr_osd_item].val = 0;
            }
            core_send(curr_osd_item);
            if (core.osd[curr_osd_item].type == CORE_OSD_TYPE_SWITCH) {
              core.osd_need_save = true;
            }
          }
          need_redraw = true;
        }

        // left
        if (usb_keyboard_report.keycode[0] == KEY_LEFT || (joy & SC_BTN_LEFT)) {
          if (core.osd[curr_osd_item].type == CORE_OSD_TYPE_FILEMOUNTER || core.osd[curr_osd_item].type == CORE_OSD_TYPE_FILELOADER) {
            is_filebrowser = true;
          } else {
            if (core.osd[curr_osd_item].val > 0) {
              core.osd[curr_osd_item].val--;
            } else {
              core.osd[curr_osd_item].val = core.osd[curr_osd_item].options_len-1;
            }
            core_send(curr_osd_item);
            if (core.osd[curr_osd_item].type == CORE_OSD_TYPE_SWITCH) {
              core.osd_need_save = true;
            }
          }
          need_redraw = true;
        }
  }

  if (need_redraw) {
    need_redraw = false;
    // cls screen while changing screen mode
    if (prev_is_filebrowser != is_filebrowser) {
      prev_is_filebrowser = is_filebrowser;
      zxosd.fill(0, APP_COREBROWSER_MENU_OFFSET, 31, APP_COREBROWSER_MENU_OFFSET + 16, ' ');
    }
    if (is_filebrowser) {
      if (filebrowser_slot == -1 || filebrowser_slot != core.osd[curr_osd_item].slot_id) {
        filebrowser_slot = app_core_init_filebrowser();
      }
      if (filebrowser_slot != -1) {
        app_core_filebrowser(APP_COREBROWSER_MENU_OFFSET);
      } else {
        is_filebrowser = false;
        prev_is_filebrowser = false;
        app_core_menu(APP_COREBROWSER_MENU_OFFSET);
      }
    } else {
      app_core_menu(APP_COREBROWSER_MENU_OFFSET);
    }
  }

  if (core.osd_need_save) {
    app_core_save(curr_osd_item);
  }
}

int app_core_init_filebrowser() {

  /*if (!has_sd) return -1;

  // working dir
  String dir = String(file_slots[core.osd[curr_osd_item].slot_id].dir);
  if (dir == "") { dir = "/"; }
  if (dir.charAt(0) != '/') { dir = '/' + dir; }
  dir.toCharArray(file_slots[core.osd[curr_osd_item].slot_id].dir, sizeof(file_slots[core.osd[curr_osd_item].slot_id].dir));
  String sfilename = String( file_slots[core.osd[curr_osd_item].slot_id].filename);
  String sfullname = dir + "/" + sfilename;
  sd1.chdir(dir);

  if (root1.isOpen()) {
    root1.close();
  }
  root1 = sd1.open(dir);
  d_print("Open dir "); d_print(dir); d_println();

  if (file1.isOpen()) {
    file1.close();
  }

  d_println("Read file list");
  root1.rewind();
  files_len = 0;
  file_sel = 0;
  memset(files, 0, sizeof(files));
  memset(cached_names, 0, sizeof(cached_names));
  cached_file_from = 0;
  cached_file_to = 0;

  // add root entry
  files[files_len].file_id = 0;
  String s = String("."); s.toCharArray(files[files_len].hash, sizeof(files[files_len].hash));
  files_len++;

  // add parent dir entry
  if (dir.length() > 1) {
    files[files_len].file_id = 0;
    String s = String(".."); s.toCharArray(files[files_len].hash, sizeof(files[files_len].hash));
    files_len++;
  }

  uint16_t presel_id = 0;
  while (file1.openNext(&root1, O_RDONLY)) {
    char filename[14]; file1.getSFN(filename, sizeof(filename));
    uint8_t len = strlen(filename);  
    if (files_len < SORT_FILES_MAX) {
      memcpy(files[files_len].hash, filename, SORT_HASH_LEN);
      files[files_len].file_id = file1.dirIndex();
      String core_f = String(file_slots[core.osd[curr_osd_item].slot_id].filename);
      String f = String(filename);
      core_f.toLowerCase();
      f.toLowerCase();
      if (core_f.length() > 0 && core_f.indexOf(f) == 0) {
        presel_id = files[files_len].file_id;
      }
      files_len++;
    }
    file1.close();
  }

  d_print("Files count "); d_print(files_len); d_println();

  std::sort(files, files + files_len);

  // preselect file in browser after sorting
  for (uint16_t i=0; i<files_len; i++) {
    if (presel_id == files[i].file_id) {
      file_sel = i;
    }
  }

  return core.osd[curr_osd_item].slot_id;*/
  return -1;
}

void app_core_filebrowser(uint8_t vpos) {
  // todo: draw files
  file_pages = ceil((float)files_len / file_page_size);
  file_page = ceil((float)(file_sel+1)/file_page_size);
  uint16_t file_from = (file_page-1)*file_page_size;
  uint16_t file_to = file_page*file_page_size > files_len ? files_len : file_page*file_page_size;
  uint16_t file_fill = file_page*file_page_size;
  uint16_t pos = vpos;
  uint16_t j = 0;

  /*if (root1.isOpen()){
    root1.close();
  }*/

  String dir = String(file_slots[core.osd[curr_osd_item].slot_id].dir);
  //root1 = sd1.open(dir);

  if (files_len > 0) {
    for(uint16_t i=file_from; i < file_to; i++) {
      zxosd.setPos(0, pos);
      if (file_sel == i) {
        zxosd.setColor(OSD::COLOR_BLACK, OSD::COLOR_WHITE);
      } else {
        zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
      }
      // display 32 chars
      char name[33]; 

      if (cached_file_from == file_from && cached_file_to == file_to) {
        memcpy(name, cached_names[j].name, sizeof(name));
      } else {
        String h = String(files[i].hash);
        if (files[i].file_id == 0 && (h == "." || h == "..")) {
          h.toCharArray(name, sizeof(name));
          h.toCharArray(cached_names[j].name, sizeof(cached_names[j].name));
        }
        /*else if (file1.open(&root1, files[i].file_id)) {
          char filename[255];
          file1.getName(filename, sizeof(filename));
          String f(filename);
          f.trim();
          f.toCharArray(name, sizeof(name));
          f.toCharArray(cached_names[j].name, sizeof(cached_names[j].name));
          file1.close();
        }*/
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
  }
  if (file_fill > file_to) {
    for (uint16_t i=file_to; i<file_fill; i++) {
      zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
      for (uint16_t j=0; j<32; j++) {
        zxosd.print(" ");
      }
    }
  }
  // display current dir
  zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  zxosd.line(21);
  zxosd.fill(0, vpos + file_page_size + 1, 31, vpos + file_page_size + 1, ' ');
  zxosd.setPos(8, vpos + file_page_size + 1); 
  dir = dir.substring(0, 20);
  zxosd.print("Dir "); zxosd.print(dir);
  // display pager
  zxosd.setPos(8, vpos + file_page_size + 2); zxosd.setColor(OSD::COLOR_WHITE, OSD::COLOR_BLACK);
  char b[40];
  sprintf(b, "Page %03d of %03d", file_page, file_pages); 
  zxosd.print(b);

}

void app_core_on_select_file() {
  if (core.osd[curr_osd_item].type == CORE_OSD_TYPE_FILELOADER) {

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

    // send ioctl slot id, file data for file loader type
    spi_send(CMD_IOCTL_SLOT, 0, core.osd[curr_osd_item].slot_id);

    uint64_t fsize = 0;
    spi_send64(CMD_IOCTL_SIZE, fsize);
    String fname = String(file_slots[core.osd[curr_osd_item].slot_id].dir) + "/" + String(file_slots[core.osd[curr_osd_item].slot_id].filename);
    File file = LittleFS.open(fname, "rb");
    fsize = file.size();
    spi_send64(CMD_IOCTL_SIZE, fsize);

    String ext = fname.substring(fname.lastIndexOf('.')+1);
    for(uint8_t i = 0; i<ext.length(); i++) {
      spi_send(CMD_IOCTL_EXT, i, ext.charAt(i));
    }

    for(uint64_t i = 0; i < fsize; i++) {
      if (i % 8192 == 0) {
        zxosd.progress(9, 11, 15, i, fsize);
      }
      if (i % 256 == 0) {
        spi_send24(CMD_IOCTL_BANK, i >> 8);
      }
      uint8_t data = file.read();
      spi_send(CMD_IOCTL_DATA, (uint8_t)((i & 0x00000000000000FF)), data);
    }
    file.close();
    zxosd.setColor(OSD::COLOR_GREEN_I, OSD::COLOR_BLACK);
    zxosd.progress(9, 11, 15, fsize, fsize);

  } else if (core.osd[curr_osd_item].type == CORE_OSD_TYPE_FILEMOUNTER) {
    // send img slot id, size for file mounter type
    /*spi_send(CMD_IMG_SLOT, 0, core.osd[curr_osd_item].slot_id);
    uint64_t fsize = 0;
    spi_send64(CMD_IMG_SIZE, fsize);
    String fname = String(file_slots[core.osd[curr_osd_item].slot_id].dir) + "/" + String(file_slots[core.osd[curr_osd_item].slot_id].filename);
    File32 file = sd1.open(fname);
    fsize = file.size();
    spi_send64(CMD_IMG_SIZE, fsize);
    file.close();*/
  }
}
