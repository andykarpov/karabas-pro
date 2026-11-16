#!/usr/bin/env python3
"""Summarise or compare per-clock-pair timing reports from report.sh.

Usage:
  compare.py NEW_PAIRS                 worst slack per corner
  compare.py BASE_PAIRS NEW_PAIRS      worst slack per corner, base vs new, and
                                       every clock pair that is below 1 ns in either

Clock pairs between the two clock modes ({c0 c2 clk_14} at ds80 = 0 and
{c1 c3 clk_12} at ds80 = 1) and pairs with AVR_SCK are left out: they are
excluded in the SDC, and reports made before that SDC (master before #126)
would otherwise show impossible paths.
"""
import re
import sys

MODE_A = {"clk[0]", "clk[2]", "clk_14", "clk_7"}
MODE_B = {"clk[1]", "clk[3]", "clk_12", "clk_6"}
LINE = re.compile(r"(\S+)\s+(\S+)\s+(\S+)\s+<-\s+(\S+)\s+(-?[\d.]+)\s+(.*)")


def load(path):
    pairs = {}
    with open(path) as f:
        for line in f:
            m = LINE.match(line)
            if not m:
                continue
            model, kind, to, frm, slack, path_ = m.groups()
            if "AVR_SCK" in (to, frm):
                continue
            if (to in MODE_A and frm in MODE_B) or (to in MODE_B and frm in MODE_A):
                continue
            pairs[(model, kind, to, frm)] = (float(slack), path_)
    return pairs


def worst(pairs):
    w = {}
    for (model, kind, to, frm), (slack, _) in pairs.items():
        key = (model, kind)
        if key not in w or slack < w[key][0]:
            w[key] = (slack, f"{to}<-{frm}")
    return w


def fmt(w):
    return "  ".join(f"{m}/{k}={s:+.3f} ({p})" for (m, k), (s, p) in sorted(w.items()))


if len(sys.argv) == 2:
    print(fmt(worst(load(sys.argv[1]))))
    sys.exit(0)

base, new = load(sys.argv[1]), load(sys.argv[2])
print("base:", fmt(worst(base)))
print("new: ", fmt(worst(new)))
for key in sorted(set(base) | set(new)):
    b = base.get(key, (None, ""))[0]
    n, path_ = new.get(key, (None, ""))
    if (b is not None and b < 1) or (n is not None and n < 1):
        s = lambda v: "   n/a " if v is None else f"{v:+7.3f}"
        print(f"{key[0]:4} {key[1]:5} {key[2]:8}<-{key[3]:9} base {s(b)}  new {s(n)}  {path_[:100]}")
