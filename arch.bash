#!/usr/bin/env -S bash -e -x

# Clear the terminal
clear

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

# Create partition scheme (EFI and root)
parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 1025MiB \
    set 1 esp on \
    mkpart root ext4 1025MiB 100%

# Assign partitions to variables
ESP="/dev/disk/by-partlabel/ESP"
ROOT="/dev/disk/by-partlabel/root"

# Inform the Kernel of the partition changes
partprobe "$DISK"

# Format the partitions
mkfs.fat -F 32 "/dev/$ESP"
mkfs.ext4 "/dev/$ROOT"

# Mount the root and EFI partitions
mount "/dev/$ROOT" /mnt
mkdir -p /mnt/boot
mount "/dev/$ESP" /mnt/boot

# Install the base system
pacstrap /mnt base base-devel linux linux-headers linux-firmware sudo networkmanager

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Set hostname, locale, and keyboard layout
hostname="fruit"
echo "$hostname" > /mnt/etc/hostname

locale="en_US.UTF-8"
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "$locale UTF-8" > /mnt/etc/locale.gen

kblayout="us"
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Enter the chroot environment for configuration
arch-chroot /mnt /bin/bash -e <<EOF
    # Set timezone to Arizona
    ln -sf /usr/share/zoneinfo/US/Arizona /etc/localtime
    hwclock --systohc

    # Generate locales
    locale-gen

    # Set up GRUB bootloader
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

    # Set root password
    echo "root:rootpassword" | chpasswd

    # Add a user with sudo privileges
    useradd -m -G wheel -s /bin/bash username
    echo "username:userpassword" | chpasswd
    echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
EOF


# Enable essential services
arch-chroot /mnt systemctl enable NetworkManager

# Finish up
echo "Installation complete. You can now reboot."
