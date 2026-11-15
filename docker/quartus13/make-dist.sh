#!/bin/bash
# Produce quartus-13.0sp1-min-linux64.tar.xz: a trimmed command-line copy of an
# existing Quartus II 13.0sp1 Web Edition installation, enough to build every
# karabas-pro project (Cyclone III, Cyclone IV E, MAX3000A).
#
# Usage: make-dist.sh [QUARTUS_DIR] [OUT_DIR]
#   QUARTUS_DIR  installed quartus/ directory (default /opt/altera/quartus)
#   OUT_DIR      where to write the tarball  (default current directory)
#
# Requires: rsync, curl, 7z (p7zip) and cpio, xz, sha256sum.
set -euo pipefail

SRC=${1:-/opt/altera/quartus}
OUT_DIR=$(realpath "${2:-.}")
NAME=quartus-13.0sp1-min-linux64.tar.xz

# Fixed TBB 4.1 (Quartus 13 ships a libtbb that hangs quartus_map on modern
# distros, see https://retroramblings.net/?p=2049)
TBB_URL=https://vault.centos.org/7.5.1804/os/x86_64/Packages/tbb-4.1-9.20130314.el7.x86_64.rpm
TBB_SHA256=504fb33391f3a8ea34e4591d0297757d8a3d0b7dc658d953b5fe2bc379fd2a94

[ -x "$SRC/linux64/quartus_map" ] || { echo "no Quartus at $SRC" >&2; exit 1; }
grep -q '13.0 SP1' "$SRC/readme.txt" || { echo "$SRC is not Quartus 13.0 SP1" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
OUT=$TMP/altera
mkdir -p "$OUT/quartus" "$OUT/ip"

echo "Copying Quartus (without GUI, JRE, Qt, 32-bit, EDA, IP, DSP, SOPC)..."
rsync -a \
  --exclude='/linux/' --exclude='/eda/' --exclude='/cusp/' --exclude='/dspba/' \
  --exclude='/dsp_builder/' --exclude='/sopc_builder/' --exclude='/extlibs32/' \
  --exclude='/drivers/' --exclude='/qdesigns/' \
  --exclude='/linux64/jre/' --exclude='/linux64/jre64/' --exclude='/linux64/qt/' \
  --exclude='/linux64/qt_example_app/' --exclude='/linux64/perl/' \
  --exclude='/common/ip/' --exclude='/common/devinfo/' \
  "$SRC/" "$OUT/quartus/"
# Quartus lists these directories at startup; keep them as empty dirs
mkdir -p "$OUT/quartus/eda/hspice" "$OUT/quartus/common/ip" "$OUT/quartus/linux"

echo "Copying device data (Cyclone III, Cyclone IV E, MAX3000A)..."
DI=$SRC/common/devinfo
DO=$OUT/quartus/common/devinfo
mkdir -p "$DO"
find "$DI" -maxdepth 1 -type f -exec cp -a {} "$DO/" \;
for d in "$DI"/*/; do
  f=$(basename "$d")
  case "$f" in
    cycloneiii|cycloneive|max3000a)
      rsync -a "$d" "$DO/$f/" ;;
    programmer)
      # programming files for EPM3128 (a3128*), EP3C10, EP4CE*, EPCS configuration devices
      mkdir -p "$DO/$f"
      find "$d" -maxdepth 1 -type f \( -name 'a3*' -o -name 'ep3c*' -o -name 'ep4ce*' \
        -o -name 'epcs*' -o ! -name '*_pcf.ddb' \) -exec cp -a {} "$DO/$f/" \; ;;
    *)
      # other families: only the header, so device family enumeration still works
      mkdir -p "$DO/$f"
      find "$d" -maxdepth 1 -type f -name '*_hdr.ddb' -exec cp -a {} "$DO/$f/" \; ;;
  esac
done

echo "Replacing bundled libtbb with TBB 4.1..."
curl -fsSL -o "$TMP/tbb.rpm" "$TBB_URL"
echo "$TBB_SHA256  $TMP/tbb.rpm" | sha256sum -c -
mkdir "$TMP/tbb"
( cd "$TMP/tbb" && 7z x -so "$TMP/tbb.rpm" 2>/dev/null | cpio -idm --quiet )
cp -f "$TMP"/tbb/usr/lib64/libtbb.so.2 "$TMP"/tbb/usr/lib64/libtbbmalloc.so.2 \
      "$TMP"/tbb/usr/lib64/libtbbmalloc_proxy.so.2 "$OUT/quartus/linux64/"

echo "Packing $NAME..."
tar -C "$TMP" -cf - altera | xz -T0 -6 > "$OUT_DIR/$NAME"
( cd "$OUT_DIR" && sha256sum "$NAME" | tee "$NAME.sha256" )
