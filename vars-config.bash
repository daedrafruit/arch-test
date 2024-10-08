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

pacstrap_pkgs="virtualbox-guest-utils base base-devel linux linux-firmware sudo networkmanager grub efibootmgr"
pacman_pkgs="foot unzip git base-devel stow firefox waybar ranger wofi swaybg kitty ly ttf-font-awesome"
flameshot_pkgs="flameshot xdg-desktop-portal xdg-desktop-portal-wlr wl-clipboard grim"

aur_pkgs="swayfx"

stow_args="sway waybar wofi kitty flameshot bashrc ranger"

services="vboxservice NetworkManager systemd-timesyncd ly"
