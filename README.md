# Omarchy on Raspberry Pi 5

A reproducible build recipe for a bootable **Omarchy** image for the **Raspberry Pi 5**, assembled from the community [`omarchy-pi`](https://github.com/linyiru/omarchy-pi) project on top of Arch Linux ARM.

The image was built on an x86_64 Arch Linux host with `qemu-user-static` and `systemd-nspawn`, written to a 32 GB microSD card, and booted successfully on a Raspberry Pi 5.

> **Status:** community prototype. This is not an official Omarchy release. Review the upstream projects and use it at your own risk.

## What is in this repository

| Item | Description |
|---|---|
| `README.md` | Build, verification and flashing guide |
| `scripts/build-image.sh` | Wrapper around the upstream `bin/build-image` |
| `scripts/check-host.sh` | Read-only check of build-host prerequisites |
| `docs/build-environment.md` | Arch Linux / WSL2 build-host setup, including the problems found in practice |
| `docs/verification.md` | Partition, boot-file and package verification |
| `docs/flashing.md` | microSD flashing, first boot and performance notes |
| `docs/image-download.md` | External download location for the 16 GiB image |
| `docs/recomputer-ai-lab-project.md` | Draft project write-up |
| `logs/build.log` | Full log of the successful build |
| `BUILD-INFO.txt` | Versions, commit hashes and image checksum |

The **16 GiB image is not stored in this Git repository**. Download it from Hugging Face:

**https://huggingface.co/datasets/xxymood/omarchy-pi-raspberry-pi5**

SHA-256, download commands and verification steps are in [`docs/image-download.md`](docs/image-download.md).

## Verified configuration

| Component | Version / value |
|---|---|
| Board | Raspberry Pi 5 |
| Boot medium | 32 GB microSD (the image also fits a larger card; the root is grown on first boot) |
| Base rootfs | Arch Linux ARM `rpi-aarch64` |
| Kernel | `linux-rpi` 6.18.60-1 |
| Raspberry Pi firmware | `raspberrypi-bootloader` 20261102-1 |
| Omarchy packages | `omarchy-dev` / `omarchy-settings-dev` `4.0.0.r6740.ge5e835e-1` |
| Omarchy Pi boot package | `omarchy-rpi-boot` 0.4.0-1 |
| Desktop | Hyprland 0.57.1-1 |
| Image size | 16 GiB (17,179,869,184 bytes) |
| Image SHA-256 | `479d29fded1d9879d3709f6abfb4dd535a35c96139217e780cac3deb0daab2d9` |

## Image layout

- MBR partition table.
- Partition 1: 512 MiB FAT32 boot partition, starting at 8 MiB.
- Partition 2: btrfs root.
- btrfs subvolumes: `@` (`/`), `@home` (`/home`), `@log` (`/var/log`), `@pkg` (`/var/cache/pacman/pkg`), `@factory` (read-only factory snapshot) and `@/.snapshots`.
- Boot files: Raspberry Pi firmware, `kernel8.img`, `initramfs-linux.img`, `config.txt`, `cmdline.txt`, device trees (including `bcm2712-rpi-5-b.dtb`) and overlays.
- The kernel command line and `/etc/fstab` mount the btrfs `@` subvolume by filesystem UUID.

On first boot `omarchy-rpi-grow-root.service` grows the root partition and btrfs filesystem to fill the card. The image ships no user account; root is locked until Omarchy's owner setup on `tty1` creates one.

## Upstream sources

The image is built from these community repositories, without modifying their source:

| Repository | Branch | Commit used |
|---|---|---|
| [`linyiru/omarchy-pi`](https://github.com/linyiru/omarchy-pi) | `main` | `b19674e2ebc89b4a4bb6d1aac06c80a7979fd461` |
| [`linyiru/omarchy`](https://github.com/linyiru/omarchy) | `raspberry-pi-platform` | `e5e835ee8b3098c0736d17a1b71d46608f3e23e9` |
| [`omacom/omarchy-pkgs`](https://github.com/omacom/omarchy-pkgs) | `master` | `e1bbf8545182f2ac00cb1455427c6d9e0a41ec39` |

Other inputs:

- Arch Linux ARM `ArchLinuxARM-rpi-aarch64-latest.tar.gz`, verified against the Arch Linux ARM GPG key (`68B3537F39A313B3E574D06777193F152BDBE6A6`).
- Node.js ARM64 tarball from `nodejs.org`, checked against `SHASUMS256.txt`.
- aarch64 packages from Arch Linux ARM, `pkgs.omarchy.org`, and packages built locally by `bin/build-packages`.

## Build host requirements

- **Arch Linux x86_64** (native or WSL2). The upstream build script uses the host's `pacman` to download aarch64 packages, so an Ubuntu/Debian host is not sufficient.
- `sudo`, a non-root build user (makepkg refuses to run as root).
- `qemu-user-static` and `qemu-user-static-binfmt` (x86_64 hosts).
- `systemd-nspawn` (part of `systemd`), `btrfs-progs`, `dosfstools`, `rsync`, `libarchive`, `base-devel`, `git`, `gnupg`, `curl`, `zstd`, `util-linux`.
- `imagemagick`: required by the `omarchy-settings-dev` PKGBUILD. The upstream README does not list it, and `bin/build-packages` runs makepkg with `--nodeps`, so the build fails at the `magick` step if it is missing.
- Working loop devices with partition scanning, btrfs kernel support, and enough free space for the 16 GiB image plus the package cache (about 30 GB recommended).

`scripts/check-host.sh` checks most of these items without changing the system.

## Build

```bash
# 1. Clone the three repositories.
mkdir -p ~/omarchy-work
git clone --branch main https://github.com/linyiru/omarchy-pi.git ~/omarchy-work/omarchy-pi
git clone --branch raspberry-pi-platform https://github.com/linyiru/omarchy.git ~/omarchy-work/omarchy
git clone --branch master https://github.com/omacom/omarchy-pkgs.git ~/omarchy-work/omarchy-pkgs

# 2. Build as a normal user with sudo (not as root).
cd ~/omarchy-work/omarchy-pi
bin/build-image \
  ~/omarchy-work/omarchy \
  ~/omarchy-work/omarchy-pkgs \
  ~/omarchy-pi.img \
  16G
```

The wrapper in this repository does the same thing with configurable paths:

```bash
OMARCHY_WORK=~/omarchy-work ./scripts/build-image.sh ~/omarchy-pi.img 16G
```

Downloads and build checks are cached in `~/.cache/omarchy-pi` (`OMARCHY_PI_CACHE`). The first build downloads an 811 MB Arch Linux ARM rootfs and roughly 2.5 GB of aarch64 packages; later builds reuse them. On the reference host the successful build took about 20 minutes after the package download.

If the Arch Linux ARM mirror or GitHub is slow or blocked from your network, see [`docs/build-environment.md`](docs/build-environment.md) for mirror and proxy options. The build itself is performed by the unmodified upstream script.

## Verify the image

```bash
file omarchy-pi.img
sfdisk -d omarchy-pi.img

# Mount the image's subvolumes and boot partition.
sudo ~/omarchy-work/omarchy-pi/bin/disk mount ~/omarchy-pi.img /mnt/omarchy

ls -lh /mnt/omarchy/boot/kernel8.img \
       /mnt/omarchy/boot/initramfs-linux.img \
       /mnt/omarchy/boot/config.txt \
       /mnt/omarchy/boot/cmdline.txt \
       /mnt/omarchy/boot/bcm2712-rpi-5-b.dtb

cat /mnt/omarchy/etc/fstab
cat /mnt/omarchy/var/lib/omarchy/image/target
btrfs subvolume list /mnt/omarchy

sudo ~/omarchy-work/omarchy-pi/bin/disk umount /mnt/omarchy
```

Expected values are recorded in [`docs/verification.md`](docs/verification.md).

## Flash to microSD

1. Verify the image checksum (see [`docs/image-download.md`](docs/image-download.md) if you downloaded it).
2. Open **Raspberry Pi Imager**.
3. Choose **Use custom image** and select `omarchy-pi.img`. Do **not** choose Raspberry Pi OS from the OS list.
4. Select the microSD card and write.

Raspberry Pi Imager's OS customisation fields may not be available for a plain custom image. The first boot's owner setup asks for the account, hostname, timezone and password. If you want Imager's preseed settings, use the upstream `bin/release-image` flow to create a release manifest.

More details, including `dd` and first-boot notes: [`docs/flashing.md`](docs/flashing.md).

## Performance

A 16 GiB raw image is much larger than a typical Raspberry Pi OS download. On a **USB 2.0 card reader** the measured sustained write speed was about **18 MB/s**, which means roughly 16 minutes of writing plus Imager's verification pass. A USB 3.0 reader and a UHS-I card typically reduce this to a few minutes. The Imager window reports `Limited by storage device speed` when the card or reader is the bottleneck; that is expected.

## Troubleshooting

- **Imager reports `Some writes failed to complete`:** re-check the card and reader first. Verify the image SHA-256, reseat the card, try another USB port, and preferably another reader. A failing or counterfeit card can fail partway through a large write.
- **Imager crashes while writing:** try another writer (Rufus in DD mode, Win32DiskImager, balenaEtcher, or `dd` on Linux) and another reader. On managed/corporate Windows machines, endpoint-security or DLP software that filters removable-media writes can interfere with raw disk writes; use an unmanaged machine or ask IT for an approved method.
- **The card shows `No Media` or an unexpected partition layout:** remove and reinsert it, or use another reader. Windows can also keep a stale partition view after a raw write; reinsert the card before judging its contents.
- **First boot takes a while:** the image rebuilds its initramfs and sets up the pacman keyring on the Pi. See the upstream README for expected timings.

## Credits and license

This repository's build recipe and documentation are released under the MIT License. The image is assembled from the upstream projects listed above; their licenses and copyrights apply to their components. `omarchy-pi` is Copyright (c) Lawrence Lin and is MIT-licensed.

The project is based entirely on community work. Please report upstream image/build issues to the corresponding upstream repositories.