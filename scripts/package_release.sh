#!/bin/bash
# Pack the Karabas-Pro Profi release bundle from build outputs.
#
# Usage: scripts/package_release.sh NAME ARTIFACTS_DIR [OUT_DIR]
#   NAME           bundle name, e.g. v26111612; the zip is karabas-pro-NAME.zip
#                  with a top-level karabas-pro-NAME/ folder
#   ARTIFACTS_DIR  build outputs, one directory per CI artifact:
#                    profi-ep4ce10/ profi-ep4ce6/ profi-ep3c10/   (build-fpga.yml)
#                    cpld-epm3128/                                (build-fpga.yml)
#                    karabas-pro-avr-firmware/                    (build-avr.yml)
#   OUT_DIR        where to write the zip (default: current directory)
#
# Layout of the bundle:
#   README.md, rom/                firmware/releases/profi/ (committed)
#   ep4ce10/ ep4ce6/ ep3c10/       *.jic, <project>.sof, <project>.rbf from the build
#                                  + Quartus Programmer chains *.cdf (committed)
#   epm3128/                       karabas_pro_cpld.pof from the build
#   avr/                           karabas_pro.hex and the *.eep files from the build
#   software/wifi/                 software/profi/net-tools/release/*.$c, player.bin
#   software/pqdos/                software/profi/net-tools/release/for_pqdos/
#
# Every .jic that a committed .cdf refers to must be present in the build.
set -euo pipefail

NAME=${1:?usage: $0 NAME ARTIFACTS_DIR [OUT_DIR]}
ART=$(realpath "${2:?usage: $0 NAME ARTIFACTS_DIR [OUT_DIR]}")
OUT_DIR=$(realpath "${3:-.}")
ROOT=$(cd "$(dirname "$0")/.." && pwd)
REL=$ROOT/firmware/releases/profi
NET=$ROOT/software/profi/net-tools/release
TOP=karabas-pro-$NAME

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
B=$TMP/$TOP
mkdir -p "$B/software/wifi" "$B/epm3128" "$B/avr"

need() { [ -f "$1" ] || { echo "missing build output: $1" >&2; exit 1; }; }

cp "$REL/README.md" "$B/"
cp -r "$REL/rom" "$B/"
rm -f "$B/rom/.gitattributes"

for dev in ep4ce10 ep4ce6 ep3c10; do
  A=$ART/profi-$dev
  P=karabas_pro_$dev
  mkdir -p "$B/$dev"
  need "$A/$P.sof"; need "$A/$P.rbf"
  cp "$A/$P.sof" "$A/$P.rbf" "$A"/${P}_*.jic "$B/$dev/"
  cp "$REL/$dev"/*.cdf "$B/$dev/"
  # every programmer chain must find its .jic
  for jic in $(grep -ho 'SFLPath("[^"]*")' "$REL/$dev"/*.cdf | sed 's/SFLPath("\(.*\)")/\1/'); do
    need "$B/$dev/$jic"
  done
done

need "$ART/cpld-epm3128/karabas_pro_cpld.pof"
cp "$ART/cpld-epm3128/karabas_pro_cpld.pof" "$B/epm3128/"

AVR=$ART/karabas-pro-avr-firmware
for f in karabas_pro.hex karabas_pro.eep karabas_pro_revA.eep karabas_pro_revC.eep karabas_pro_revD.eep; do
  need "$AVR/$f"
  cp "$AVR/$f" "$B/avr/"
done

cp "$NET"/*.\$c "$NET/player.bin" "$B/software/wifi/"
cp -r "$NET/for_pqdos" "$B/software/pqdos"

rm -f "$OUT_DIR/$TOP.zip"
( cd "$TMP" && zip -qr -X "$OUT_DIR/$TOP.zip" "$TOP" )
echo "$OUT_DIR/$TOP.zip"
