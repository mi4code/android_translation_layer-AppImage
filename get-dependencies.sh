#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm pipewire-audio patchelf

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-mesa libxml2-mini opus-mini gdk-pixbuf2-mini librsvg-mini

# Comment this out if you need an AUR package
echo "Making AUR package..."
echo "---------------------------------------------------------------"

# ---- Initialize and refresh pacman keys ----
sudo pacman -Syy --noconfirm
#sudo pacman -S --noconfirm chaotic-keyring chaotic-mirrorlist

# create a non-root user for building AUR packages + allow sudo without password
sudo useradd -m builder
sudo passwd -d builder
echo "builder ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/builder

# run as the builder user
sudo -u builder BUILD_NB="$BUILD_NB" bash <<'EOF'
cd /home/builder

# build yay
sudo pacman -S --noconfirm --needed go wget git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm

# install libvixl (use debian as source cos not availible on arch/aur; needed only on arm64)
if [ "$(uname -m)" = "aarch64" ]; then
  yay -S --noconfirm dpkg
  wget http://ftp.de.debian.org/debian/pool/main/v/vixl/libvixl5_5.1.0-6+b1_arm64.deb
  wget http://ftp.de.debian.org/debian/pool/main/v/vixl/libvixl-dev_5.1.0-6+b1_arm64.deb
  sudo dpkg --force-depends --install libvixl5_*.deb
  sudo dpkg --force-depends --install libvixl-dev_*.deb
  sudo dpkg --configure -a
  sudo ln -s /usr/lib/aarch64-linux-gnu/libvixl.so /usr/lib/libvixl.so
  sudo ln -s /usr/lib/aarch64-linux-gnu/libvixl.so.5 /usr/lib/libvixl.so.5
  sudo ln -s /usr/lib/aarch64-linux-gnu/libvixl.so.5.1.0 /usr/lib/libvixl.so.5.1.0
fi

# install this java (otherwise arm build fails with 'java.lang.OutOfMemoryError: Java heap space') + install sdl3 (optional dependency for running some apks)
sudo pacman -S --noconfirm jdk21-openjdk sdl3

# build without skia (no longer dependency, but still required by the aur package and wont build)
#yay -S --noconfirm android_translation_layer-git
yay -S --noconfirm \
  bionic_translation-git \
  art_standalone-git \
  libopensles-standalone-git
yay -G android_translation_layer-git
cd android_translation_layer-git
sed -i '/skia-sharp-atl/d' PKGBUILD
makepkg -si --noconfirm

# build and install nb-qemu atl native bridge
if [ "$BUILD_NB" -eq 1 ]; then
  sudo pacman -S --noconfirm capstone clang lld
  git clone https://gitlab.com/mi4code/nb-qemu
  cd nb-qemu
  git submodule update --init --recursive
  sed -i '33s|.*|           $(BUILDDIR)/libnb-qemu-GLESv2.so \\|' libnb-qemu/Makefile
  make PREFIX=/usr/
  # (as we cant build gles1, we need to somehow replace it to avoid errors, this works just perfectly)
  cp ./builddir/libnb-qemu/libnb-qemu-GLESv2.so ./builddir/libnb-qemu/libnb-qemu-GLESv1_CM.so
  sudo make PREFIX=/usr/ install
  # (not sure why, but this is the correct libc that works) 
  sudo rm /usr/share/libnb-qemu-guest/libc.so
  sudo cp ./libnb-qemu-guest/sysroot/libc.so /usr/share/libnb-qemu-guest
fi

# create helper script
if [ "$BUILD_NB" -eq 1 ]; then
  sudo tee /usr/bin/android-translation-layer-script > /dev/null << 'EF'
#!/usr/bin/bash
NB_QEMU_SYSROOT=$APPDIR/share/libnb-qemu-guest android-translation-layer "$@" -X '-Xforce-nb-testing' -X "-XX:NativeBridge=$APPDIR/lib/libnb-qemu.so"
EF
else
sudo tee /usr/bin/android-translation-layer-script > /dev/null << 'EF'
#!/usr/bin/bash
android-translation-layer "$@"
EF
fi
sudo chmod +x /usr/bin/android-translation-layer-script

EOF

#make-aur-package --chaotic-aur android_translation_layer-git
