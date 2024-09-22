#!/usr/bin/env -S bash -e -x

# Select the target disk for installation

hostname="fruit"
rootpass="password"
username="daedr"
userpass="password"

locale="en_US.UTF-8"
kblayout="us"

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
    mkpart SWAP linux-swap 1GiB 5GiB \
    mkpart ROOT ext4 5GiB 100%

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

# Enable NetworkManager
systemctl enable NetworkManager --root=/mnt

# Set hostname, locale, and keyboard layout
echo "$hostname" > /mnt/etc/hostname
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "$locale UTF-8" > /mnt/etc/locale.gen
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Configure the system
arch-chroot /mnt /bin/bash -x -e <<EOF

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

EOF

# Set root password
echo "root:$rootpass" | arch-chroot /mnt chpasswd

# Add a user with sudo privileges
echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/wheel
arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
echo "$username:$userpass" | arch-chroot /mnt chpasswd

# Finish up
echo "Installation complete. You can now reboot."
