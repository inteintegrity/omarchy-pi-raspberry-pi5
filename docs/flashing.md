# Flashing and first boot

## Requirements

- A microSD card of **32 GB or larger**. The image is 16 GiB; a 32 GB card leaves about 13 GiB free after the first-boot root expansion.
- A reliable USB card reader. A USB 3.0 reader and a UHS-I card make a large difference (see performance below).
- Raspberry Pi Imager, or `dd` on Linux/macOS.

## 1. Verify the downloaded image

Windows:

```powershell
certutil -hashfile omarchy-pi.img SHA256
```

Linux/macOS:

```bash
sha256sum omarchy-pi.img
# or: shasum -a 256 omarchy-pi.img
```

Expected:

```text
479d29fded1d9879d3709f6abfb4dd535a35c96139217e780cac3deb0daab2d9
```

Do not flash an image whose checksum does not match.

## 2. Write with Raspberry Pi Imager

1. Open Raspberry Pi Imager.
2. Choose **Use custom image** and select `omarchy-pi.img`. Do not select Raspberry Pi OS from the OS list.
3. Choose the microSD card.
4. Click **Write** and wait for both the write and verify phases to finish. Do not disconnect the card while Imager is writing.

Imager's OS customisation (hostname, user, Wi-Fi, SSH) may not be offered for a plain custom image. The first boot's owner setup asks for the account and system settings. To use Imager's preseed settings, create a release manifest with the upstream `bin/release-image` flow.

## 3. Write with dd (alternative)

Check the device name first; this overwrites it:

```bash
lsblk
sudo dd if=omarchy-pi.img of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

On Linux the target is the whole card device (for example `/dev/sdb`), not a partition.

## 4. First boot

Insert the card into the Raspberry Pi 5, connect HDMI and a keyboard, and power on.

- The firmware reads `config.txt`, selects the Pi 5 device tree, loads `kernel8.img` and `initramfs-linux.img`.
- The kernel mounts the btrfs `@` subvolume using the UUID in `cmdline.txt`.
- `omarchy-rpi-grow-root.service` expands the root partition and filesystem to fill the card.
- Omarchy's owner setup runs on `tty1`: keyboard layout, user name, password, hostname and timezone. The image ships no default account; root is locked until this setup completes.

SSH is installed but the port is closed by default. After first boot:

```bash
sudo ufw allow 22/tcp
```

## Performance

A 16 GiB image is much larger than a typical Raspberry Pi OS download. Measured on a **USB 2.0 card reader**:

- sustained write: about **18 MB/s**
- writing 16 GiB: about **16 minutes**
- plus Imager's read-back verification pass

Raspberry Pi Imager reports `Limited by storage device speed` when the reader or card is the bottleneck. This is normal for USB 2.0 readers. A USB 3.0 reader with a UHS-I card can reduce the write to a few minutes.

## Troubleshooting

### `Some writes failed to complete`

Imager/Raspberry Pi Imager reports this when the underlying write returns an I/O error. Common causes:

- The card or reader disconnected or reset during the write.
- The card is write-protected, failing, or counterfeit/under-capacity.
- The reader is unstable or the USB connection is poor.

Try, in order:

1. Verify the image SHA-256.
2. Reseat the card, try another USB port (avoid hubs), and preferably another card reader.
3. Try a different microSD card.
4. Try another writer: Rufus in DD mode, Win32DiskImager, balenaEtcher, or `dd` on Linux.
5. On a managed/corporate Windows machine, endpoint-security or DLP software that filters removable-media writes can block raw writes. Use an unmanaged machine or ask IT for an approved method rather than bypassing policy.

### Imager crashes during the write

The write error is the primary event; a crash in the UI is secondary. Try another writer and another reader. Check Windows Event Viewer for storage errors (`Microsoft-Windows-Storage-ClassPnP/Operational`) if the failure repeats.

### Windows shows an unexpected partition layout after a failed write

Windows can keep a stale partition view for removable media that was written behind its back. Remove and reinsert the card before judging its contents. A card that repeatedly reports `No Media` or 0 bytes after reinsertion is usually failing or poorly seated.

### The Pi does not boot

- Confirm the boot files exist on the FAT32 partition (`kernel8.img`, `initramfs-linux.img`, `config.txt`, `cmdline.txt`, `bcm2712-rpi-5-b.dtb`).
- Confirm the checksum of the image was correct before flashing.
- Try another card and reader.
- Use a reliable 5 V/5 A USB-C power supply for the Pi 5.
- Connect HDMI before powering on; the first boot runs on `tty1`.