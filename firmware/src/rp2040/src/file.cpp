#include <Arduino.h>
#include "config.h"
#include "types.h"
#include "file.h"
#include "main.h"

void file_seek(uint32_t pos) {
    file1.seek(pos);
}

uint8_t file_read() {
    return file1.read();
}

size_t file_read_bytes(char *buf, size_t len) {
    return file1.readBytes(buf, len);
}

int file_read_buf(char *buf, size_t len) {
    return file1.readBytes(buf, len);
}

int file_write_buf(char *buf, size_t len) {
    return file1.write(buf, len);
}

uint16_t file_read16(uint32_t pos) {
  file_seek(pos);
  uint16_t res = 0;
  uint8_t buf[2] = {0};
  file1.read(buf, sizeof(buf));
  res = buf[1] + buf[0]*256;  
  return res;
}

uint32_t file_read24(uint32_t pos) {
  file_seek(pos);
  uint32_t res = 0;
  uint8_t buf[3] = {0};
  file1.read(buf, sizeof(buf));
  res = buf[2] + buf[1]*256 + buf[0]*256*256;
  return res;
}

uint32_t file_read32(uint32_t pos) {
  file_seek(pos);
  uint32_t res = 0;
  uint8_t buf[4] = {0};
  file1.read(buf, sizeof(buf));
  res = buf[3] + buf[2]*256 + buf[1]*256*256 + buf[0]*256*256*256;
  return res;
}

void file_get_name(char *buf, size_t len) {
  strcpy(buf, file1.name());
}

void file_write16(uint32_t pos, uint16_t val) {
  file_seek(pos);
  file_seek(pos);
  file1.write((uint8_t) val >> 8);
  file_seek(pos+1);
  file1.write((uint8_t) val);
}
