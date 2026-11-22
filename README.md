# MacBook Pro speaker fix for Ubuntu

On some Intel MacBook Pros, Ubuntu doesn't drive the built-in speakers and headphone jack. These Macs use a Cirrus Logic CS8409 audio chip, and Ubuntu's built-in driver doesn't fully support it.

This repo records the fix that worked on one machine:

| | |
|---|---|
| Mac | MacBook Pro 14,1 (13", 2017, no Touch Bar) |
| OS | Ubuntu 24.04.2 LTS (HWE kernel) |
| Kernel | `7.0.0-43-generic` |
| Driver | [davidjo/snd_hda_macbookpro](https://github.com/davidjo/snd_hda_macbookpro) at commit `89b22ff` (Sep 2026) |

## Why the driver's own installer wasn't enough

The driver patches the kernel's `sound/hda` source and builds a replacement `snd-hda-codec-cs8409` module. To get that source, its installer looks for `/usr/src/linux-source-7.0.0.tar.bz2`.

The first attempt used the upstream (vanilla) 7.0 sound source. The module built, but the speakers didn't work. Ubuntu's 7.0.0-43 kernel carries its own changes to `sound/hda` (in `codecs/conexant.c`, `codecs/realtek/*`, `codecs/hdmi/*` and more). A module built from vanilla source doesn't match the kernel it's loaded into.

The fix: rebuild the module from **Ubuntu's** `sound/` source for 7.0.0-43. That source is included here as `linux-source-7.0.0-ubuntu43.tar.bz2`, containing only the `sound/` directory (about 140 files, 395 KB, GPL-2.0 like the kernel).

## Install

```bash
git clone https://github.com/Stvn444/macbook-audio-fix
cd macbook-audio-fix
./fix-macbook-sound.sh
sudo reboot
```

The script:
1. Installs `dkms` and the kernel headers.
2. Clones the driver to `~/snd_hda_macbookpro-2026` and pins it to `89b22ff`.
3. Backs up any existing `/usr/src/linux-source-7.0.0.tar.bz2` to `.vanilla-backup`, then puts Ubuntu's sound source in its place.
4. Registers the driver with DKMS and builds and installs the module.

## Check that it worked

After the reboot:

```bash
lsmod | grep cs8409          # snd_hda_codec_cs8409 should be listed
dkms status                  # snd_hda_macbookpro/0.1, <kernel>, x86_64: installed
```

These two kernel messages are normal for an out-of-tree driver:

```
snd_hda_codec_cs8409: loading out-of-tree module taints kernel.
snd_hda_codec_cs8409: module verification failed: signature and/or required key missing
```

If **Secure Boot** is on, the unsigned module won't load. Either turn Secure Boot off or enroll a MOK key when DKMS asks.

## After a kernel update

DKMS rebuilds the driver automatically, but it'll use whatever sound source is in `/usr/src`. The included tarball only matches **7.0.0-43**. If sound breaks after an update, you need the `sound/` directory from that new kernel's Ubuntu source, packed the same way:

```
linux-source-7.0.0/
└── sound/...
```

Then put it at `/usr/src/linux-source-7.0.0.tar.bz2` (or whatever version the driver's installer asks for) and run:

```bash
sudo dkms remove snd_hda_macbookpro/0.1 -k $(uname -r)
sudo dkms install snd_hda_macbookpro/0.1 -k $(uname -r)
sudo reboot
```

## Undo

```bash
sudo dkms remove snd_hda_macbookpro/0.1 --all
sudo mv /usr/src/linux-source-7.0.0.tar.bz2.vanilla-backup /usr/src/linux-source-7.0.0.tar.bz2
sudo reboot
```

## Credits

All the driver work is by [davidjo](https://github.com/davidjo/snd_hda_macbookpro). This repo only records the build setup that worked on Ubuntu 24.04 with the 7.0.0-43 kernel.
