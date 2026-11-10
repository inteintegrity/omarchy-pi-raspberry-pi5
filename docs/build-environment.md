# Build environment

This is the practical setup used to build the image: Arch Linux x86_64 under WSL2, with QEMU user emulation and `systemd-nspawn`. A native Arch Linux host works the same way.

The upstream project requires **Arch Linux** because `bin/build-image` uses the host's `pacman` to download aarch64 packages. Ubuntu or Debian cannot run the build unmodified.

## 1. Install Arch Linux (WSL2)

```powershell
wsl --install archlinux
wsl -d archlinux
```

Inside the distribution, confirm that systemd is PID 1 and pacman works:

```bash
ps -p 1 -o comm=
pacman --version
```

The official Arch WSL image ships with systemd enabled. If yours does not, add the following to `/etc/wsl.conf` and restart the distribution:

```ini
[boot]
systemd=true
```

## 2. Install build dependencies

```bash
pacman -Syu --needed \
  base-devel git \
  qemu-user-static qemu-user-static-binfmt \
  btrfs-progs dosfstools rsync libarchive sudo \
  gnupg curl zstd util-linux archlinux-keyring \
  imagemagick
```

`imagemagick` is easy to miss: `omarchy-settings-dev` calls `magick` in `package()` and `bin/build-packages` runs makepkg with `--nodeps`, so without it the build stops at:

```text
PKGBUILD: line 417: magick: command not found
```

## 3. Register the ARM binfmt handler

On an x86_64 host, the Arch Linux ARM rootfs is executed through `qemu-aarch64-static`. The `qemu-user-static-binfmt` package installs the binfmt.d configuration.

### Native Arch

```bash
systemctl restart systemd-binfmt
ls /proc/sys/fs/binfmt_misc/qemu-aarch64
```

### WSL2

WSL protects its own binfmt interpreter by default, which prevents binfmt.d from registering QEMU. Set:

```ini
# /etc/wsl.conf
[boot]
systemd=true
protectBinfmt=false
```

Then preserve Windows interop explicitly with a binfmt.d entry:

```text
# /etc/binfmt.d/WSLInterop.conf
:WSLInterop:M::MZ::/init:P
```

Restart the service and check both handlers:

```bash
systemctl restart systemd-binfmt
ls /proc/sys/fs/binfmt_misc/ | grep -E 'qemu-aarch64|WSLInterop'
```

Test that a Windows executable still starts from WSL:

```bash
/mnt/c/Windows/System32/cmd.exe /c echo INTEROP_OK
```

## 4. Verify the rest of the host

Run the read-only check from this repository:

```bash
./scripts/check-host.sh
```

It verifies `pacman`, QEMU, `systemd-nspawn`, btrfs tools, `mkfs.vfat`, `sfdisk`, `bsdtar`, `rsync`, `makepkg`, ImageMagick, the binfmt handler and free space.

A quick manual check of loop partitions and btrfs is also useful:

```bash
truncate -s 512M /tmp/test.img
printf 'label: dos\nstart=8MiB, size=128MiB, type=c, bootable\nstart=136MiB, type=83\n' | sfdisk --quiet /tmp/test.img
loop=$(losetup --find --show --partscan /tmp/test.img)
ls -l "${loop}p1" "${loop}p2"
mkfs.vfat -F 32 -n BOOT "${loop}p1"
mkfs.btrfs -q -L test "${loop}p2"
mkdir -p /tmp/test-mnt
mount "${loop}p2" /tmp/test-mnt
btrfs subvolume create /tmp/test-mnt/@
umount /tmp/test-mnt
losetup -d "$loop"
rm -f /tmp/test.img
```

## 5. Create a non-root build user

`makepkg` refuses to run as root and the upstream script expects a user with `sudo`:

```bash
useradd -m -s /bin/bash builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-builder
chmod 0440 /etc/sudoers.d/10-builder
su - builder
```

Put the repositories in the builder's home so `makepkg` and `git` can read them:

```bash
mkdir -p ~/omarchy-work
git clone --branch main https://github.com/linyiru/omarchy-pi.git ~/omarchy-work/omarchy-pi
git clone --branch raspberry-pi-platform https://github.com/linyiru/omarchy.git ~/omarchy-work/omarchy
git clone --branch master https://github.com/omacom/omarchy-pkgs.git ~/omarchy-work/omarchy-pkgs
```

## 6. Network and mirror notes

The build downloads:

- `ArchLinuxARM-rpi-aarch64-latest.tar.gz` from `os.archlinuxarm.org` (811 MB),
- the Arch Linux ARM package databases and packages,
- Node.js for arm64,
- the Omarchy packages.

Downloads are cached in `~/.cache/omarchy-pi` (`OMARCHY_PI_CACHE`).

### Slow or blocked GitHub

If `git clone` cannot reach GitHub, configure an HTTPS proxy for Git:

```bash
git config --global http.proxy http://HOST:PORT
git config --global https.proxy http://HOST:PORT
```

The same proxy can be exported before running the build.

### Slow or blocked Arch Linux ARM mirror

The rootfs and its signature can be pre-downloaded into the cache, so the build script does not fetch them itself:

```bash
mkdir -p ~/.cache/omarchy-pi
cd ~/.cache/omarchy-pi
curl -fL -o ArchLinuxARM-rpi-aarch64-latest.tar.gz \
  https://MIRROR/archlinuxarm/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
curl -fL -o ArchLinuxARM-rpi-aarch64-latest.tar.gz.sig \
  https://MIRROR/archlinuxarm/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz.sig
```

The build script still verifies the signature against the Arch Linux ARM key.

### Proxy inside systemd-nspawn

`bin/build-image` runs the image stages in `systemd-nspawn`. nspawn does not pass the caller's proxy environment into the container by default. If the ARM mirror is only reachable through a proxy, add a machine drop-in (the build mounts the image at `~/.cache/omarchy-pi/mnt`, so the machine name is `mnt`):

```ini
# /etc/systemd/nspawn/mnt.nspawn
[Exec]
Environment=HTTP_PROXY=http://HOST:PORT
Environment=HTTPS_PROXY=http://HOST:PORT
Environment=http_proxy=http://HOST:PORT
Environment=https_proxy=http://HOST:PORT
```

The host's own `pacman` and `curl` also need the proxy. Because the script uses `sudo`, tell sudo to keep the variables:

```text
# /etc/sudoers.d/90-omarchy-proxy
Defaults env_keep += "http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY no_proxy NO_PROXY"
```

This drop-in is only needed during the build and can be removed afterwards.

## 7. Build

As the non-root user:

```bash
cd ~/omarchy-work/omarchy-pi
bin/build-image \
  ~/omarchy-work/omarchy \
  ~/omarchy-work/omarchy-pkgs \
  ~/omarchy-pi.img \
  16G
```

Or use the wrapper in this repository:

```bash
OMARCHY_WORK=~/omarchy-work ./scripts/build-image.sh ~/omarchy-pi.img 16G
```

The build prints a `TIMING` line for each stage. In the reference run the whole build took 1184 seconds (about 20 minutes) after the package download, on a WSL2 host with 15 GiB RAM.

## 8. Cleanup

The build leaves the image, the package cache and the extracted rootfs under `~/.cache/omarchy-pi`. The temporary nspawn proxy drop-in can be deleted after a successful build:

```bash
rm -f /etc/systemd/nspawn/mnt.nspawn
```