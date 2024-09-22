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

# Select the target disk for installation
echo "Available disks for installation:"
select ENTRY in $(lsblk -dpnoNAME | grep -P "/dev/sd|nvme|vd"); do
    DISK="$ENTRY"
    echo "Arch Linux will be installed on the following disk: $DISK"
    break
done

# Confirm disk wipe
read -p "This will delete the current partition table on $DISK. Do you agree? [y/N]: " disk_response
if ! [[ "${disk_response,,}" =~ ^(yes|y)$ ]]; then
    echo "Quitting."
    exit
fi

# Wipe the selected disk
wipefs -af "$DISK"
sgdisk -Zo "$DISK"

# Create partition scheme (EFI, SWAP, and root)
parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 1GiB \
    set 1 esp on \
    mkpart SWAP linux-swap 1GiB 9GiB \
    mkpart ROOT ext4 9GiB 100%

# Assign partitions to variables
ESP="/dev/disk/by-partlabel/ESP"
SWAP="/dev/disk/by-partlabel/SWAP"
ROOT="/dev/disk/by-partlabel/ROOT"

# Inform the Kernel of the partition changes
partprobe "$DISK"

# Format the EFI and Root partitions
mkfs.fat -F 32 "$ESP"
mkfs.ext4 "$ROOT"

# Setup the SWAP partition
mkswap "$SWAP"
swapon "$SWAP"

# Mount the root and EFI partitions
mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$ESP" /mnt/boot

# Install the base system
pacstrap /mnt base base-devel linux linux-firmware sudo networkmanager grub efibootmgr

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Set hostname, locale, and keyboard layout
echo "$hostname" > /mnt/etc/hostname
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "$locale UTF-8" > /mnt/etc/locale.gen
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Configure the system
arch-chroot /mnt /bin/bash -x -e <<EOF

    # Set root password
    echo "root:$rootpass" | chpasswd

    # Add user and set password
    useradd -m -G wheel -s /bin/bash "$username"
    echo "$username:$userpass" | chpasswd
	
	# Setting up timezone.
	ln -sf /usr/share/zoneinfo/US/Arizona /etc/localtime

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
	
EOF

# Configure as user
arch-chroot /mnt /usr/bin/runuser -u $username -c '
	cd /home/$username

	# install yay
	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg -si --noconfirm
	cd /home/$username

	# Install packages using yay
	yay -S --noconfirm swayfx sway-nvidia
			
	# Clone dotfiles
	git clone https://github.com/daedrafruit/dotfiles.git
	# remove existing bashrc
	rm /home/$username/.bashrc
	# stow dotfiles
	cd /home/$username/dotfiles
	stow sway waybar wofi kitty flameshot bashrc ranger
'
	
# Finish up
echo "Installation complete. You can now reboot."