# Project draft: Omarchy on Raspberry Pi 5

> This is a draft for a reComputer AI Lab / Seeed Studio project page. It is written in English so it can be adapted directly. Replace the image placeholders and the download TODO before publishing.

## Title

**Build and Run Omarchy on a Raspberry Pi 5**

## Summary

This project builds a bootable Arch Linux ARM image for the Raspberry Pi 5 and turns it into an Omarchy desktop. The image is assembled on an x86_64 Arch Linux host using QEMU user emulation and `systemd-nspawn`, then written to a microSD card and booted on a Raspberry Pi 5. It provides a full Hyprland-based Omarchy desktop with a btrfs root, automatic first-boot root expansion, and owner setup on the Pi itself.

The build recipe, logs, checksums and verification notes are in the companion GitHub repository:

`https://github.com/inteintegrity/omarchy-pi-raspberry-pi5`

## Introduction

Omarchy is an opinionated Arch Linux + Hyprland desktop. `omarchy-pi` extends it to the Raspberry Pi with the Raspberry Pi platform support branch of Omarchy. Because the target is ARM64 and the build host is x86_64, the image root is executed under `qemu-user-static` inside `systemd-nspawn`.

The result is a 16 GiB raw image with:

- an MBR partition table,
- a 512 MiB FAT32 boot partition,
- a btrfs root with `@`, `@home`, `@log`, `@pkg` and a read-only `@factory` snapshot,
- Raspberry Pi firmware, `kernel8.img`, `initramfs-linux.img`, the Pi 5 device tree and 388 overlays,
- Omarchy, Hyprland and the Raspberry Pi default package set.

## What you need

### Hardware

- Raspberry Pi 5
- microSD card, 32 GB or larger (32 GB is enough; about 13 GiB remains after root expansion)
- USB card reader (USB 3.0 strongly recommended)
- HDMI display, keyboard, and a 5 V/5 A USB-C power supply

### Build host

- Arch Linux x86_64, native or WSL2
- QEMU user emulation (`qemu-user-static`, `qemu-user-static-binfmt`)
- `systemd-nspawn`, `btrfs-progs`, `dosfstools`, `rsync`, `libarchive`, `base-devel`, ImageMagick
- About 30 GB free space

## Step 1: Build the image

```bash
git clone --branch main https://github.com/linyiru/omarchy-pi.git
git clone --branch raspberry-pi-platform https://github.com/linyiru/omarchy.git
git clone --branch master https://github.com/omacom/omarchy-pkgs.git

cd omarchy-pi
bin/build-image \
  ../omarchy ../omarchy-pkgs \
  ~/omarchy-pi.img 16G
```

The detailed host setup, including QEMU binfmt under WSL2 and the ImageMagick dependency, is in the GitHub repository. The build takes about 20 minutes after the package download on the reference host.

## Step 2: Verify the image

```bash
sha256sum omarchy-pi.img
# 479d29fded1d9879d3709f6abfb4dd535a35c96139217e780cac3deb0daab2d9
```

The boot partition should contain `kernel8.img`, `initramfs-linux.img`, `config.txt`, `cmdline.txt`, `bcm2712-rpi-5-b.dtb` and `overlays/`.

## Step 3: Write the microSD card

1. Open Raspberry Pi Imager.
2. Choose **Use custom image** and select `omarchy-pi.img`.
3. Select the microSD card and write.
4. Wait for the write and verification to finish. A USB 2.0 reader may take about 16 minutes for the write alone; the UI reports `Limited by storage device speed` when the reader is the bottleneck.

## Step 4: First boot

Insert the card into the Pi 5, connect HDMI and a keyboard, and power on.

- The firmware loads the kernel and initramfs from the FAT32 boot partition.
- The kernel mounts the btrfs root by UUID.
- The root partition is expanded to fill the card.
- Omarchy's owner setup on `tty1` creates the user, sets the password, hostname and timezone.
- The Hyprland desktop starts after setup.

> **Screenshot to add:** first boot / Omarchy owner setup on the Pi.

> **Screenshot to add:** Omarchy desktop running on the Raspberry Pi 5.

## Results

- The image built successfully from the community `omarchy-pi` sources.
- It was written to a 32 GB microSD card and booted on a Raspberry Pi 5.
- The Omarchy desktop runs on the Pi's GPU with the packaged Hyprland stack.
- The first boot grows the root filesystem and completes owner setup on the Pi.

## Notes and limitations

- This is a community prototype, not an official Omarchy release.
- The image is 16 GiB; use a 32 GB or larger card.
- A USB 2.0 card reader limits writes to about 18 MB/s. Use USB 3.0 for a much faster flash.
- Raspberry Pi Imager's custom-image flow may not expose account/Wi-Fi/SSH preset fields; owner setup on the Pi handles the account.
- Endpoint-security or DLP software on managed Windows machines can interfere with raw removable-media writes. Use an unmanaged machine or an approved method.

## Download

The image is distributed outside GitHub because of its size. Download it from Hugging Face:

**https://huggingface.co/datasets/xxymood/omarchy-pi-raspberry-pi5**

SHA-256:

`479d29fded1d9879d3709f6abfb4dd535a35c96139217e780cac3deb0daab2d9`

## Credits

- [`linyiru/omarchy-pi`](https://github.com/linyiru/omarchy-pi) — Raspberry Pi image build and boot support (MIT)
- [`linyiru/omarchy`](https://github.com/linyiru/omarchy) — `raspberry-pi-platform` branch
- [`omacom/omarchy-pkgs`](https://github.com/omacom/omarchy-pkgs) — Omarchy package build recipes
- Omarchy, Arch Linux ARM, Hyprland and the Raspberry Pi firmware projects

## Repository

`https://github.com/inteintegrity/omarchy-pi-raspberry-pi5`