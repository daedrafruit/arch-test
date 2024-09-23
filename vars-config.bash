#!/usr/bin/env -S bash -e -x

# Usage:
# curl -O https://raw.githubusercontent.com/daedrafruit/arch-test/main/arch.bash
# chmod +x arch.bash
# ./arch.bash

hostname="fruit"
rootpass="password"
username="daedr"
userpass="password"

locale="en_US.UTF-8"
kblayout="us"
timezone="US/Arizona"

pacstrap_pkgs="base base-devel linux linux-firmware sudo networkmanager grub efibootmgr"
pacman_pkgs="git base-devel stow firefox waybar ranger wofi kitty flameshot ly"
aur_pkgs="swayfx"

stow_args="sway waybar wofi kitty flameshot bashrc ranger"

services="NetworkManager systemd-timesyncd ly"
