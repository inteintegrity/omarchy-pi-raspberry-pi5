# Image download

The 16 GiB `omarchy-pi.img` is **not stored in this Git repository**. GitHub's normal Git file limit is 100 MB, and a raw 16 GiB image is not suitable for a repository checkout.

## Download

| Item | Value |
|---|---|
| File | `omarchy-pi.img` |
| Size | 17,179,869,184 bytes (16 GiB) |
| SHA-256 | `479d29fded1d9879d3709f6abfb4dd535a35c96139217e780cac3deb0daab2d9` |
| Hugging Face | https://huggingface.co/datasets/xxymood/omarchy-pi-raspberry-pi5 |
| Direct URL | https://huggingface.co/datasets/xxymood/omarchy-pi-raspberry-pi5/resolve/main/omarchy-pi.img |

Download with the Hugging Face CLI:

```bash
hf download xxymood/omarchy-pi-raspberry-pi5 omarchy-pi.img \
  --repo-type dataset --local-dir .
```

Or with `curl`:

```bash
curl -L -o omarchy-pi.img \
  https://huggingface.co/datasets/xxymood/omarchy-pi-raspberry-pi5/resolve/main/omarchy-pi.img
```

Recommended external locations:

- Hugging Face (dataset or model repository with Git LFS/Xet),
- Google Drive or Baidu Netdisk,
- any object storage with a public download link.

If you publish the image elsewhere as a mirror, add the URL here.

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