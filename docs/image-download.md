# Image download

The 16 GiB `omarchy-pi.img` is **not stored in this Git repository**. GitHub's normal Git file limit is 100 MB, and a raw 16 GiB image is not suitable for a repository checkout.

## Download

| Item | Value |
|---|---|
| File | `omarchy-pi.img` |
| Size | 17,179,869,184 bytes (16 GiB) |
| SHA-256 | `479d29fded1d9879d3709f6abfb4dd535a35c96139217e780cac3deb0daab2d9` |
| External download | **TODO: add the external storage URL here** |

Recommended external locations:

- Hugging Face (dataset or model repository with Git LFS/Xet),
- Google Drive or Baidu Netdisk,
- any object storage with a public download link.

If you publish the image externally, update this file and the download note in `README.md` with the URL.

## Verify after download

Windows:

```powershell
certutil -hashfile omarchy-pi.img SHA256
```

Linux/macOS:

```bash
sha256sum omarchy-pi.img
```

The output must be:

```text
479d29fded1d9879d3709f6abfb4dd535a35c96139217e780cac3deb0daab2d9
```

## Build it yourself

If no external download is available, build the image from source using the instructions in the main [`README.md`](../README.md) and [`docs/build-environment.md`](build-environment.md). The exact upstream commits and package versions are recorded in `BUILD-INFO.txt`.