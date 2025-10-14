#!/bin/env python3

#########################################################
# Karabas Pro Core Generator v1.0                       #
#                                                       #
# (c) 2025 Andy Karpov <andy.karpov@gmail.com>          #
#########################################################

import json
import argparse
import sys
import os
from types import SimpleNamespace

msg = "Karabas Pro binary core maker v1.0"
parser = argparse.ArgumentParser(description = msg)
parser.add_argument('json_file')
parser.add_argument('output_file')
args = parser.parse_args()
filename = args.json_file
outfile = args.output_file

def file_check(name):
    if not os.path.isfile(name):
        print("Unable to read file ", name)
        exit(1)    

def file_read(name, mode = "r"):
    file_check(name)
    f = open(name, mode)
    data = f.read()
    f.close()
    return data    

d = json.loads(file_read(filename), object_hook=lambda d: SimpleNamespace(**d))

# check bitstream and roms exists
bitstream = file_read(d.bitstream, "rb")
bitstream_size = len(bitstream)

# total rom size
rom_size = 0
for rom in d.roms:
    r = file_read(rom.filename, "rb")
    rom_is_external = rom.external if hasattr(rom, "external") else False
    # embedded rom
    if not rom_is_external:
        rom_size = rom_size + len(r)
    # external rom - only a filename size is appended
    else:
        rom_size = rom_size + len(rom.filename)

o = open(outfile, "wb")

# header block
o.write("kpro".encode("ascii")) # signature
o.write(d.id.ljust(32)[:32].encode("ascii")) # core id
o.write(d.name.ljust(32)[:32].encode("ascii")) # core name
o.write(d.build.ljust(8)[:8].encode("ascii")) # core build
o.write(b'\x01' if d.visible else b'\x00') # visible (in the list of cores in boot mode)
o.write(d.order.to_bytes(1, 'big')) # order number 0-255
# core type
# 0 - boot (boot mode, osd is a file browser to choose a core from SD1)
# 1 - osd (normal osd mode, toggled by menu+esc)
# 2 - fileloader (file loader mode. osd started on core load, on menu+esc it is possible to choose another file to load)
# 255 - none (osd is hidden)
o.write(b'\x00' if d.type == 'boot' else b'\x01' if d.type == 'osd' else b'\x02' if d.type == 'fileloader' else b'\xff')
o.write(d.eeprom_bank.to_bytes(1, 'big')) # eeprom bank (0-3 - 24c08, 255 - no eeprom, 4-254 - in the core file)
o.write(bitstream_size.to_bytes(4, 'big')) # size of bitstream in bytes
o.write((rom_size + len(d.roms)*8).to_bytes(4, 'big')) # size of roms block (file sizes + 8 bytes each file)
o.write(d.rtc_mode.to_bytes(1, 'big') if hasattr(d, "rtc_mode") else b'\x00') # rtc mode 0=mc146818a, 1=ds1307
o.write(d.dir.ljust(32)[:32].encode('ascii') if hasattr(d, "dir") else b'\x00' * 32) # 32 bytes initial dir in fileloader mode
o.write(d.filename.ljust(32)[:32].encode('ascii') if hasattr(d, "filename") else b'\x00' * 32) # 32 bytes last selected filename in fileloader mode
o.write(d.extensions.ljust(32)[:32].encode('ascii') if hasattr(d, "extensions") else b'\x00' * 32) # 32 bytes allowed file extensions (comma separated string) 
o.write(d.spi_freq.to_bytes(1, 'big') if hasattr(d, "spi_freq") else b'\x00') # spi freq
o.write(d.sd_access.to_bytes(1, 'big') if hasattr(d, "sd_access") else b'\x00') # sd access
o.write(b'\xFF' * 32) # reserved 32 bytes
o.write(b'\xFF' * 37) # reserved 37 bytes
o.write(b'\xFF' * 256) # eeprom 256 bytes
for osd in d.osd: # write defaults to switches
    o.write(osd.default.to_bytes(1, 'big') if hasattr(osd, "default") else b'\x00')
o.write(b'\x00' * (256 - len(d.osd))) # switches 256 bytes
o.write(b'\x00' * 256) # reserved 256 bytes

# bitstream block
o.write(bitstream)

# roms block
for rom in d.roms:
    r = file_read(rom.filename, "rb")
    rom_is_external = rom.external if hasattr(rom, "external") else False
    # rom size is a file size if rom is embedded or length of the filename if rom is external
    r_size = len(r) if not rom_is_external else len(rom.filename)
    # set the upper bit of r_size as rom_is_external flag
    r_size = r_size | (1 << 31) if rom_is_external else r_size;
    o.write(r_size.to_bytes(4, 'big'))
    o.write(rom.address.to_bytes(4, 'big'))
    # dump rom content if rom is embedded or filename if rom is extenrnal
    o.write(r) if not rom_is_external else o.write(rom.filename)

# usb key map

# special keys (both left+right)
kb_special = { "Ctrl": 0x11, "Shift": 0x22, "Alt": 0x44, "Menu":0x88 }

# normal keys (not all)
kb_keys = {
    "A": 0x04, "B": 0x05, "C": 0x06, "D": 0x07, "E": 0x08, "F": 0x09, "G": 0x0a, "H": 0x0b,
    "I": 0x0c, "J": 0x0d, "K": 0x0e, "L": 0x0f, "M": 0x10, "N": 0x11, "O": 0x12, "P": 0x13,
    "Q": 0x14, "R": 0x15, "S": 0x16, "T": 0x17, "U": 0x18, "V": 0x19, "W": 0x1a, "X": 0x1b,
    "Y": 0x1c, "Z": 0x1d, "1": 0x1e, "2": 0x1f, "3": 0x20, "4": 0x21, "5": 0x22, "6": 0x23,
    "7": 0x24, "8": 0x25, "9": 0x26, "0": 0x27,

    "Enter": 0x28, "Esc": 0x29, "Bkspace": 0x2a, "Tab": 0x2b, "Space": 0x2c, "Caps": 0x39,
    
    "F1": 0x3a, "F2": 0x3b, "F3": 0x3c, "F4": 0x3d, "F5": 0x3e, "F6": 0x3f, "F7": 0x40,
    "F8": 0x41, "F9": 0x42, "F10": 0x43, "F11": 0x44, "F12": 0x45,

    "PtrScr": 0x46, "ScrLk": 0x47, "Pause": 0x48, "Ins": 0x49, "Del": 0x4c, "Home": 0x4a,
    "End": 0x4d, "PgUp": 0x4b, "PgDn": 0x4e, "Right": 0xf, "Left": 0x50, "Down": 0x51, "Up": 0x52
}

# parse string of hotkeys into bytearray of usb keycodes
def parse_hotkey(value):
    ret = bytearray()
    hotkeys = value.split('+', 3)
    special = 0
    for h in hotkeys:
        if h in kb_special:
            special = special + kb_special[h]
    ret.append(special)
    keys = []
    for h in hotkeys:
        if h in kb_keys:
            keys.append(kb_keys[h])
    if len(keys):
        for k in keys[:2]:
            ret.append(k)
    return ret

# osd
o.write(len(d.osd).to_bytes(1, 'big')) # count of osd parameters
for osd in d.osd:
    o.write(b'\x00' if osd.type == 'S' else b'\x01' if osd.type == 'N' else b'\x02' if osd.type == 'T' else b'\x03' if osd.type == 'H' else b'\x04' if osd.type == 'P' else b'\x05' if osd.type =='F' else b'\x06' if osd.type == 'FL' else b'\xFF') # parameter type
    o.write(b'\x00') # reserved
    o.write(osd.name.ljust(16)[:16].encode("ascii")) # option name
    o.write(osd.default.to_bytes(1, 'big') if hasattr(osd, "default") else b'\x00') # default value
    
    # file mounter struct
    if osd.type=='F' or osd.type=='FL':
        slot = osd.slot if hasattr(osd, "slot") else 0
        autoload = osd.autoload if hasattr(osd, "autoload") else 0
        if autoload: # write autoload bit as 7th bit of slot value
            slot = slot | (1 << 7)
        o.write(slot.to_bytes(1, 'big'))
        o.write(osd.extensions.ljust(256)[:256].encode('ascii') if hasattr(osd, "extensions") else b'\x00' * 256)
        o.write(osd.dir.ljust(256)[:256].encode('ascii') if hasattr(osd, "dir") else b'\x00' * 256)
        o.write(osd.filename.ljust(256)[:256].encode('ascii') if hasattr(osd, "filename") else b'\x00' * 256)
    # osd options struct
    else:
        o.write(len(osd.options).to_bytes(1, 'big') if hasattr(osd, "options") and osd.options and len(osd.options) > 0 else b'\x00') # number of options
        if hasattr(osd, "options") and osd.options and len(osd.options) > 0:
            for opt in osd.options:
                o.write(opt.ljust(16)[:16].encode("ascii")) #option name

    # hotkey or second line of text
    if (osd.type == 'P'):
        o.write(osd.name.ljust(32)[16:32].encode("ascii")) # second part of text line as hotkey
    else:
        o.write(osd.hotkey.ljust(16)[:16].encode("ascii") if hasattr(osd, "hotkey") else "                ".encode("ascii")) # option hotkey
    o.write(parse_hotkey(osd.hotkey) if hasattr(osd, "hotkey") else b'\00'*2) # option keycodes (parsed)
    o.write(b'\x00'*3) # reserved

#print(d.name, d.build)
#print(bitstream_size, rom_size)

o.close()

