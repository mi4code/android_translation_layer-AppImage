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

sudo pacman -Rdd --noconfirm chaotic-keyring chaotic-mirrorlist 2>/dev/null || true
# Install latest keyring
sudo pacman -U --noconfirm \
https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst
# Install latest mirrorlist
sudo pacman -U --noconfirm \
https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
# Refresh pacman databases
sudo pacman -Rdd --noconfirm chaotic-keyring chaotic-mirrorlist 2>/dev/null || true
# Install latest keyring
sudo pacman -U --noconfirm \
https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst
# Install latest mirrorlist
sudo pacman -U --noconfirm \
https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
# Refresh pacman databases
sudo pacman -Syy

make-aur-package --chaotic-aur android_translation_layer-git
