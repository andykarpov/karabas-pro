#!/bin/sh
# Build the Profi FPGA cores (EP4CE10, EP4CE6, EP3C10) in the Quartus image
# (docker/quartus13/README.md) and collect the outputs in
# firmware/build/profi-<device>/, the same layout as the CI artifacts.
set -e
cd "$(dirname "$0")"
FW=$(cd .. && pwd)
IMAGE=${QUARTUS_IMAGE:-karabas-quartus:13.0sp1}

for dev in ep4ce10 ep4ce6 ep3c10; do
	echo "Building Profi FPGA sources for $dev"
	docker run --rm --network none -u "$(id -u):$(id -g)" -v "$FW:/work" \
		-w "/work/src/fpga/profi/syn/$dev" "$IMAGE" sh -c 'make clean && make all jic'
	out="$FW/build/profi-$dev"
	rm -rf "$out"; mkdir -p "$out"
	cp fpga/profi/syn/$dev/*.sof fpga/profi/syn/$dev/*.rbf fpga/profi/syn/$dev/*.jic \
	   fpga/profi/syn/$dev/*.rpt fpga/profi/syn/$dev/*.summary "$out/"
done
echo "Done: $FW/build"
