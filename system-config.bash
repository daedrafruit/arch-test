#!/usr/bin/env -S bash -e -x

source /scripts/vars-config.bash

# Set root password
echo "root:$rootpass" | chpasswd

# Add user and set password
useradd -m -G wheel -s /bin/bash "$username"
echo "$username:$userpass" | chpasswd

# Setting up timezone.
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime

# Setting up clock.
hwclock --systohc

# Generating locales.
locale-gen

# Generating a new initramfs.
mkinitcpio -P

# Installing GRUB.
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

# Creating grub config file.
grub-mkconfig -o /boot/grub/grub.cfg

# Additional Packages
# consider nvidia mesa amd-ucode
pacman -S --noconfirm --needed $pacman_pkgs

#enable services
systemctl enable $services

# download background
mkdir -p /usr/share/backgrounds/tiling
curl -o /usr/share/backgrounds/tiling/tiling-cats.png https://cdn.osxdaily.com/wp-content/uploads/2017/12/classic-mac-os-tile-wallpapers-4.png

curl -O https://raw.githubusercontent.com/daedrafruit/arch-test/main/fonts-install.bash
chmod +x fonts-install.bash
./fonts-install.bash
	
