#!/bin/bash
# Clean build of one Profi FPGA project in the Quartus Docker image, then a
# per-clock-pair timing report.
#
# Usage: scripts/timing/report.sh <ep4ce10|ep4ce6|ep3c10> [REPO_DIR]
#   REPO_DIR  checkout to build (default: this repository); use a git worktree
#             to build another branch, e.g. master as the baseline
#
# Writes into REPO_DIR/firmware/src/fpga/profi/syn/<device>/:
#   build.log, timing_pairs.txt (worst slack per clock pair, slow + fast),
#   timing_failing.txt (failing paths, slow model)
# Compare two builds with scripts/timing/compare.py.
set -euo pipefail
DEV=${1:?usage: $0 <ep4ce10|ep4ce6|ep3c10> [REPO_DIR]}
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(realpath "${2:-$HERE/../..}")
IMAGE=${QUARTUS_IMAGE:-karabas-quartus:13.0sp1}
SYN=$REPO/firmware/src/fpga/profi/syn/$DEV
[ -d "$SYN" ] || { echo "no project $SYN" >&2; exit 1; }

cp "$HERE/pairs.tcl" "$SYN/timing_pairs.tcl"
trap 'rm -f "$SYN/timing_pairs.tcl"' EXIT
docker run --rm --network none -u "$(id -u):$(id -g)" -v "$REPO:/work" \
  -w "/work/firmware/src/fpga/profi/syn/$DEV" "$IMAGE" bash -c "
    make clean >/dev/null
    make all > build.log 2>&1 || { tail -20 build.log; exit 1; }
    quartus_sta -t timing_pairs.tcl karabas_pro_$DEV timing_pairs.txt timing_failing.txt > timing_sta.log 2>&1 \
      || { tail -20 timing_sta.log; exit 1; }"

grep -E 'Total logic elements' "$SYN/karabas_pro_$DEV.fit.summary"
echo "failing paths: $(wc -l < "$SYN/timing_failing.txt")"
python3 -I "$HERE/compare.py" "$SYN/timing_pairs.txt"
