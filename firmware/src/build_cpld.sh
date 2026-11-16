#!/bin/sh
# Build the CPLD (EPM3128) in the Quartus image (docker/quartus13/README.md)
# and collect the outputs in firmware/build/cpld-epm3128/.
set -e
cd "$(dirname "$0")"
FW=$(cd .. && pwd)
IMAGE=${QUARTUS_IMAGE:-karabas-quartus:13.0sp1}

echo "Building CPLD sources"
docker run --rm --network none -u "$(id -u):$(id -g)" -v "$FW:/work" \
	-w /work/src/cpld/syn "$IMAGE" sh -c 'make clean && make all'
out="$FW/build/cpld-epm3128"
rm -rf "$out"; mkdir -p "$out"
cp cpld/syn/*.pof cpld/syn/*.rpt cpld/syn/*.summary "$out/"
echo "Done: $out"
