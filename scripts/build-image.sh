#!/bin/bash

# Build an Omarchy Raspberry Pi image from local checkouts of:
#   omarchy-pi, omarchy (raspberry-pi-platform) and omarchy-pkgs.
#
# Usage:
#   OMARCHY_WORK=~/omarchy-work ./scripts/build-image.sh [output.img] [size]
#
# The upstream build script must run as a normal user with sudo, not as root
# (makepkg refuses to run as root).

set -euo pipefail

work=${OMARCHY_WORK:-$HOME/omarchy-work}
out=${1:-$HOME/omarchy-pi.img}
size=${2:-16G}

for dir in omarchy-pi omarchy omarchy-pkgs; do
  if [[ ! -d $work/$dir ]]; then
    echo "Error: $work/$dir is missing. Clone the three upstream repositories first." >&2
    exit 1
  fi
done

cd "$work/omarchy-pi"
echo "==> Building $out ($size)"
exec bash bin/build-image "$work/omarchy" "$work/omarchy-pkgs" "$out" "$size"