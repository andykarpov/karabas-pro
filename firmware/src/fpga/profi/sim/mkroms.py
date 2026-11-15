#!/usr/bin/env python3
"""Convert the OSD font (Intel HEX) and icons (MIF) to plain text for GHDL.

Usage: mkroms.py RTL_VIDEO_DIR OUT_DIR
Writes OUT_DIR/font.txt (2048 hex bytes) and OUT_DIR/icons.txt (2048 bits).
"""
import re
import sys

src, out = sys.argv[1], sys.argv[2]

font = [0] * 2048
with open(f"{src}/font.hex") as f:
    for line in f:
        line = line.strip()
        if not line.startswith(":") or int(line[7:9], 16) != 0:
            continue
        n, addr = int(line[1:3], 16), int(line[3:7], 16)
        for i in range(n):
            font[addr + i] = int(line[9 + 2 * i:11 + 2 * i], 16)

icons = [0] * 2048
body = False
with open(f"{src}/icons.mif") as f:
    for line in f:
        line = line.split("--")[0].strip()
        if line.upper().startswith("CONTENT"):
            body = True
            continue
        m = re.match(r"\[?(\d+)(?:\.\.(\d+))?\]?\s*:\s*(\d+)\s*;", line)
        if body and m:
            lo = int(m.group(1))
            hi = int(m.group(2)) if m.group(2) else lo
            for a in range(lo, hi + 1):
                icons[a] = int(m.group(3))

with open(f"{out}/font.txt", "w") as f:
    f.write("\n".join(f"{b:02X}" for b in font) + "\n")
with open(f"{out}/icons.txt", "w") as f:
    f.write("\n".join(str(b) for b in icons) + "\n")
