# Image verification

The image built for this repository was checked on the build host before being copied to the SD card.

## File

| Property | Value |
|---|---|
| File | `omarchy-pi.img` |
| Size | 17,179,869,184 bytes (16 GiB) |
| SHA-256 | `479d29fded1d9879d3709f6abfb4dd535a35c96139217e780cac3deb0daab2d9` |
| `file` output | DOS/MBR boot sector; partition 1 ID 0x0c, active; partition 2 ID 0x83 |

The SHA-256 was calculated on the build host and again on the Windows copy; both matched.

## Partition table

```text
label: dos
label-id: 0x5491a93b
unit: sectors
sector-size: 512

omarchy-pi.img1 : start=       16384, size=     1048576, type=c, bootable
omarchy-pi.img2 : start=     1064960, size=    32489472, type=83
```

| Partition | Offset | Size | Type |
|---|---:|---:|---|
| 1 | 8 MiB | 512 MiB | FAT32 boot, bootable |
| 2 | 520 MiB | ~15.5 GiB | btrfs root |

## Boot partition

Mounted with `bin/disk mount`:

| File | Size | Purpose |
|---|---:|---|
| `kernel8.img` | 27 MB | Raspberry Pi kernel |
| `initramfs-linux.img` | 17 MB | initramfs built without `autodetect` |
| `config.txt` | — | firmware configuration |
| `cmdline.txt` | — | kernel command line |
| `bcm2712-rpi-5-b.dtb` | 77 KB | Raspberry Pi 5 device tree |
| `overlays/` | 388 files | firmware overlays, including `vc4-kms-v3d.dtbo` |
| `start4.elf`, `fixup4.dat` | — | Raspberry Pi firmware |

`config.txt` contains:

```text
initramfs initramfs-linux.img followkernel
dtoverlay=vc4-kms-v3d
```

`cmdline.txt` points at the btrfs root by UUID:

```text
root=UUID=99b9d395-b8df-475e-afbc-ff574442dec8 rootfstype=btrfs rootflags=subvol=@ rw rootwait ...
```

## Root filesystem

`/etc/fstab` mounts the same btrfs filesystem with the expected subvolumes:

```text
UUID=99b9d395-b8df-475e-afbc-ff574442dec8  /  btrfs  noatime,compress=zstd,subvol=@  0 0
UUID=99b9d395-b8df-475e-afbc-ff574442dec8  /home  btrfs  noatime,compress=zstd,subvol=@home  0 0
UUID=99b9d395-b8df-475e-afbc-ff574442dec8  /var/log  btrfs  noatime,compress=zstd,subvol=@log  0 0
UUID=99b9d395-b8df-475e-afbc-ff574442dec8  /var/cache/pacman/pkg  btrfs  noatime,compress=zstd,subvol=@pkg  0 0
UUID=410A-A211  /boot  vfat  rw,relatime,fmask=0022,dmask=0022  0 2
```

btrfs subvolumes:

```text
ID 256 path @
ID 257 path @home
ID 258 path @log
ID 259 path @pkg
ID 260 path .snapshots
ID 261 path @factory
```

Other checks:

```text
$ cat /mnt/omarchy/etc/os-release
NAME="Omarchy"
PRETTY_NAME="Omarchy"
ID=omarchy
ID_LIKE=arch

$ cat /mnt/omarchy/var/lib/omarchy/image/target
format=1
platform=raspberrypi
```

## Installed packages

The image contains 953 pacman packages. The key versions are:

```text
omarchy-dev            4.0.0.r6740.ge5e835e-1
omarchy-settings-dev   4.0.0.r6740.ge5e835e-1
omarchy-rpi-boot       0.4.0-1
omarchy-pi-keyring     20261004-1
linux-rpi              6.18.60-1
raspberrypi-bootloader 20261102-1
omarchy-keyring        20251027-1
hyprland               0.57.1-1
```

Enabled services include `NetworkManager`, `sshd`, `ufw`, `cups`, `omarchy-provision-hardware` and `omarchy-provision-owner`.

## Boot test

The image was written to a 32 GB microSD card and booted on a Raspberry Pi 5. The Pi's firmware loaded the kernel and initramfs from the FAT32 boot partition and mounted the btrfs `@` subvolume; the first boot then ran the hardware/owner provisioning.

The image is a community prototype. A successful boot does not imply that every Raspberry Pi accessory or every Wi-Fi/Bluetooth configuration has been tested.