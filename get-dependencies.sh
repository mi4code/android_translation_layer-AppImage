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

echo "Initializing pacman keyring..."
sudo pacman-key --init
sudo pacman-key --populate archlinux
# Refresh keys from keyservers
sudo pacman-key --refresh-keys
# ---- Install Chaotic-AUR keyring and mirrorlist ----
echo "Installing Chaotic-AUR keyring and mirrorlist..."
sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst
sudo pacman -U --noconfirm https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
# Refresh databases
sudo pacman -Syy

make-aur-package --chaotic-aur android_translation_layer-git
