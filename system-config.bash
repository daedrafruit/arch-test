#!/usr/bin/env -S bash -e -x

source /mnt/root/vars-config.bash

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
pacman -S --noconfirm --needed git base-devel stow firefox waybar ranger wofi kitty flameshot ly

#enable services
systemctl enable NetworkManager systemd-timesyncd ly
	
