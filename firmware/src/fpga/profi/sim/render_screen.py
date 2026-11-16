# Render a ZX Spectrum screen dump (6912 hex bytes, one per line) to a PNG.
# Usage: render_screen.py screen5.txt screen5.png   (needs Pillow)
import sys
from PIL import Image
pal=[(0,0,0),(0,0,205),(205,0,0),(205,0,205),(0,205,0),(0,205,205),(205,205,0),(205,205,205)]
palb=[(0,0,0),(0,0,255),(255,0,0),(255,0,255),(0,255,0),(0,255,255),(255,255,0),(255,255,255)]
d=[int(l,16) for l in open(sys.argv[1])]
im=Image.new('RGB',(256,192))
for y in range(192):
    for xb in range(32):
        p=d[((y&0xC0)<<5)|((y&7)<<8)|((y&0x38)<<2)|xb]
        at=d[6144+(y>>3)*32+xb]
        P=palb if at&0x40 else pal
        ink=P[at&7]; paper=P[(at>>3)&7]
        for b in range(8):
            im.putpixel((xb*8+b,y), ink if p&(0x80>>b) else paper)
im.resize((512,384),Image.NEAREST).save(sys.argv[2])
