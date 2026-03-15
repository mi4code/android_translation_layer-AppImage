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

#sudo pacman -Syy --noconfirm
#sudo pacman -S --noconfirm chaotic-keyring chaotic-mirrorlist
sudo pacman -Syy --noconfirm

# create a non-root user for building AUR packages
sudo useradd -m builder
sudo passwd -d builder

# allow sudo without password
echo "builder ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/builder
sudo pacman -S --noconfirm go
# build yay as the builder user
sudo -u builder bash <<'EOF'
cd /home/builder
sudo pacman -S --noconfirm --needed wget git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm

# install libvixl (use debian as source since not availible on arch; needed on arm)
yay -S --noconfirm dpkg
wget http://ftp.de.debian.org/debian/pool/main/v/vixl/libvixl5_5.1.0-6+b1_arm64.deb
wget http://ftp.de.debian.org/debian/pool/main/v/vixl/libvixl-dev_5.1.0-6+b1_arm64.deb
sudo dpkg --force-depends --install libvixl5_*.deb
sudo dpkg --force-depends --install libvixl-dev_*.deb
sudo dpkg --configure -a
echo "-----lib:"
ls /usr/lib/*vixl*
echo "-----lib-aarch:"
ls /usr/lib/aarch64-linux-gnu/*vixl*
sudo cp /usr/lib/aarch64-linux-gnu/*vixl* /usr/lib/

# build without skia (no longer dependency, but still required by the aur package)
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
