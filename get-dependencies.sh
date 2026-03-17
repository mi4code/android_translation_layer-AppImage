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
sudo -u builder bash <<'EOF'
cd /home/builder

# build yay
sudo pacman -S --noconfirm --needed go wget git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm

# install libvixl (use debian as source cos not availible on arch; needed on arm)
yay -S --noconfirm dpkg
wget http://ftp.de.debian.org/debian/pool/main/v/vixl/libvixl5_5.1.0-6+b1_arm64.deb
wget http://ftp.de.debian.org/debian/pool/main/v/vixl/libvixl-dev_5.1.0-6+b1_arm64.deb
sudo dpkg --force-depends --install libvixl5_*.deb
sudo dpkg --force-depends --install libvixl-dev_*.deb
sudo dpkg --configure -a
sudo ln -s /usr/lib/aarch64-linux-gnu/libvixl.so /usr/lib/libvixl.so
sudo ln -s /usr/lib/aarch64-linux-gnu/libvixl.so.5 /usr/lib/libvixl.so.5
sudo ln -s /usr/lib/aarch64-linux-gnu/libvixl.so.5.1.0 /usr/lib/libvixl.so.5.1.0

# build without skia (no longer dependency, but still required by the aur package and wont build)
#yay -S --noconfirm android_translation_layer-git
yay -S --noconfirm \
  art_standalone \
  bionic_translation \
  libopensles-standalone 
yay -G android_translation_layer-git
cd android_translation_layer-git
sed -i '/skia-sharp-atl/d' PKGBUILD
makepkg -si --noconfirm

EOF

#make-aur-package --chaotic-aur android_translation_layer-git
