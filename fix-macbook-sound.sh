#!/bin/bash
# Build and install the CS8409 MacBook Pro audio driver (davidjo/snd_hda_macbookpro)
# against Ubuntu's own sound source for the running kernel.
set -e
cd "$(dirname "$0")"
K=$(uname -r)
TARBALL=linux-source-7.0.0-ubuntu43.tar.bz2
DRIVER=~/snd_hda_macbookpro-2026
DRIVER_COMMIT=89b22ff

if [ "$K" != "7.0.0-43-generic" ]; then
  echo "Warning: this sound source was taken from kernel 7.0.0-43, but you are running $K."
  echo "It may not build or work. Press Ctrl+C to stop, or Enter to try anyway."; read
fi

sudo apt install -y dkms linux-headers-$K

[ -d "$DRIVER" ] || git clone https://github.com/davidjo/snd_hda_macbookpro.git "$DRIVER"
git -C "$DRIVER" checkout -q $DRIVER_COMMIT

# The driver's build script looks for this file; give it Ubuntu's sound source.
if [ -f /usr/src/linux-source-7.0.0.tar.bz2 ] && [ ! -f /usr/src/linux-source-7.0.0.tar.bz2.vanilla-backup ]; then
  sudo cp /usr/src/linux-source-7.0.0.tar.bz2 /usr/src/linux-source-7.0.0.tar.bz2.vanilla-backup
fi
sudo cp "$TARBALL" /usr/src/linux-source-7.0.0.tar.bz2
sudo ln -sfn "$DRIVER" /usr/src/snd_hda_macbookpro-0.1

sudo dkms remove snd_hda_macbookpro/0.1 -k $K 2>/dev/null || true
sudo rm -rf "$DRIVER/build"
sudo dkms install snd_hda_macbookpro/0.1 -k $K
sudo depmod -a $K
echo "Done. Now reboot: sudo reboot"
