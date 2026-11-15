#!/bin/bash
# Pack the Karabas-Pro Profi release bundle from committed files.
#
# Usage: scripts/package_release.sh NAME [OUT_DIR]
#   NAME     bundle name, e.g. v26102401-romain2A1b02; the zip is
#            karabas-pro-NAME.zip with a top-level karabas-pro-NAME/ folder
#   OUT_DIR  where to write the zip (default: current directory)
#
# Layout of the bundle:
#   README.md                      firmware/releases/profi/README.md
#   avr/ ep3c10/ ep4ce6/ ep4ce10/ epm3128/ rom/
#                                  firmware/releases/profi/<same>
#   software/wifi/                 software/profi/net-tools/release/*.$c, player.bin
#   software/pqdos/                software/profi/net-tools/release/for_pqdos/
#
# Everything comes from the tree as committed (binaries in firmware/releases
# are reviewed through PRs), nothing is rebuilt here.
set -euo pipefail

NAME=${1:?usage: $0 NAME [OUT_DIR]}
OUT_DIR=$(realpath "${2:-.}")
ROOT=$(cd "$(dirname "$0")/.." && pwd)
REL=$ROOT/firmware/releases/profi
NET=$ROOT/software/profi/net-tools/release
TOP=karabas-pro-$NAME

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
B=$TMP/$TOP
mkdir -p "$B/software/wifi"

cp "$REL/README.md" "$B/"
for d in avr ep3c10 ep4ce6 ep4ce10 epm3128 rom; do
  [ -d "$REL/$d" ] || { echo "missing $REL/$d" >&2; exit 1; }
  cp -r "$REL/$d" "$B/"
done
rm -f "$B/rom/.gitattributes"

cp "$NET"/*.\$c "$NET/player.bin" "$B/software/wifi/"
cp -r "$NET/for_pqdos" "$B/software/pqdos"

rm -f "$OUT_DIR/$TOP.zip"
( cd "$TMP" && zip -qr -X "$OUT_DIR/$TOP.zip" "$TOP" )
echo "$OUT_DIR/$TOP.zip"
