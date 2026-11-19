#!/usr/bin/env python3
"""Turn a log of the AVR host stand (firmware/src/avr/host_test) into a replay file for the
FPGA benches of run_avr_link.sh.

Usage: avr_replay.py v1|v2 LOG OUT [--all] [--marks N]

Output lines:
  F b0 b1 b2      a v1 frame (hex)
  P n b0 .. bn-1  a v2 packet of n bytes (hex)
  M k             sample the core side (k = the pass of the main loop)

v1 frames that cannot change the outputs of avr.vhd are dropped (unless --all): NOP, INIT and
BUILD requests, and a keyboard, joystick or mouse X / Y frame equal to the last frame with the
same command and address (they write the same register again); keyboard frame 06 stays when
one of the frames 01..05 went since the last 06 (it latches the matrix). v2 POLL packets are dropped.
--marks N stops after N passes (the prefix check of the filter).
"""
import sys


def main():
    kind, src, dst = sys.argv[1:4]
    keep_all = '--all' in sys.argv
    limit = None
    if '--marks' in sys.argv:
        limit = int(sys.argv[sys.argv.index('--marks') + 1])
    last = {}
    kbd_dirty = False
    marks = 0
    with open(src) as f, open(dst, 'w') as o:
        for line in f:
            if line.startswith('M '):
                o.write('M %d\n' % marks)
                marks += 1
                if limit is not None and marks >= limit:
                    break
                continue
            if not line[:1].isdigit() or ':' not in line:
                continue
            bs = line.split(':', 1)[1].split('|')[0].split()
            if kind == 'v1':
                if len(bs) != 3:
                    continue
                cmd, addr = bs[0], bs[1]
                if not keep_all:
                    if cmd in ('FF', 'FD', 'F0'):
                        continue
                    if cmd in ('01', '0D') or (cmd == '0A' and addr in ('0A', '0B')):
                        key = (cmd, addr)
                        # keyboard frame 06 latches the matrix of frames 01..05: it stays
                        # whenever one of them went since the last 06
                        latch = cmd == '01' and addr == '06' and kbd_dirty
                        if last.get(key) == bs[2] and not latch:
                            continue
                        last[key] = bs[2]
                        if cmd == '01' and addr in ('01', '02', '03', '04', '05'):
                            kbd_dirty = True
                        if cmd == '01' and addr == '06':
                            kbd_dirty = False
                o.write('F %s\n' % ' '.join(bs))
            else:
                if bs[:2] == ['00', '00'] and not keep_all:
                    continue
                o.write('P %d %s\n' % (len(bs), ' '.join(bs)))
        o.write('E\n')


if __name__ == '__main__':
    main()
