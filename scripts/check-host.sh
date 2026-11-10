#!/bin/bash

# Read-only prerequisite check for the Omarchy Pi image build host.
# It does not install packages or modify the system.

set -u

fail=0

check() {
  local label=$1 command=$2
  if command -v "$command" >/dev/null 2>&1; then
    printf 'ok      %-24s %s\n' "$label" "$(command -v "$command")"
  else
    printf 'MISSING %-24s (%s)\n' "$label" "$command"
    fail=1
  fi
}

echo "== Commands =="
check pacman pacman
check git git
check qemu-aarch64-static qemu-aarch64-static
check systemd-nspawn systemd-nspawn
check mkfs.btrfs mkfs.btrfs
check mkfs.vfat mkfs.vfat
check sfdisk sfdisk
check bsdtar bsdtar
check rsync rsync
check makepkg makepkg
check imagemagick magick
check gpg gpg
check curl curl

echo
echo "== Kernel/features =="
if grep -qw btrfs /proc/filesystems; then
  echo "ok      btrfs filesystem"
else
  echo "MISSING btrfs filesystem (load the module or use a kernel with btrfs)"
  fail=1
fi

if [[ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]]; then
  echo "ok      qemu-aarch64 binfmt handler"
else
  echo "MISSING qemu-aarch64 binfmt handler"
  echo "        Arch WSL: set protectBinfmt=false in /etc/wsl.conf, then"
  echo "        systemctl restart systemd-binfmt (see docs/build-environment.md)"
  fail=1
fi

if mountpoint -q /proc/sys/fs/binfmt_misc 2>/dev/null || [[ -d /proc/sys/fs/binfmt_misc ]]; then
  echo "ok      binfmt_misc mounted"
else
  echo "MISSING binfmt_misc mount"
  fail=1
fi

echo
echo "== Disk space =="
avail_kb=$(df -Pk "$HOME" | awk 'NR==2 {print $4}')
if (( avail_kb >= 30 * 1024 * 1024 )); then
  echo "ok      $(( avail_kb / 1024 / 1024 )) GiB free in $HOME (30 GiB recommended)"
else
  echo "WARNING only $(( avail_kb / 1024 / 1024 )) GiB free in $HOME; 30 GiB recommended"
fi

echo
if (( fail != 0 )); then
  echo "Some prerequisites are missing." >&2
  exit 1
fi
echo "All checked prerequisites are present."