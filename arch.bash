#!/usr/bin/env -S bash -e -x

# curl -O https://raw.githubusercontent.com/daedrafruit/arch-test/main/arch.bash

# Select the target disk for installation

hostname="fruit"
rootpass="password"
username="daedr"
userpass="password"

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
    mkpart ROOT ext4 1025MiB 100%

# Assign partitions to variables
ESP="/dev/disk/by-partlabel/ESP"
ROOT="/dev/disk/by-partlabel/ROOT"

# Inform the Kernel of the partition changes
partprobe "$DISK"

# Format the partitions
mkfs.fat -F 32 "$ESP" &>/dev/null
mkfs.ext4 "$ROOT" &>/dev/null

# Mount the root and EFI partitions
mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$ESP" /mnt/boot

# Install the base system
pacstrap /mnt base base-devel linux linux-firmware sudo networkmanager grub

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

#enable networkmanager
systemctl enable NetworkManager --root=/mnt &>/dev/null

# Set hostname, locale, and keyboard layout
echo "$hostname" > /mnt/etc/hostname

locale="en_US.UTF-8"
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "$locale UTF-8" > /mnt/etc/locale.gen

kblayout="us"
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Configuring the system.
arch-chroot /mnt /bin/bash -e <<EOF

    # Setting up timezone.
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null

    # Setting up clock.
    hwclock --systohc

    # Generating locales.
    locale-gen &>/dev/null

    # Generating a new initramfs.
    mkinitcpio -P &>/dev/null

    # Installing GRUB.
    grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB &>/dev/null

    # Creating grub config file.
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

EOF

# Set root password
echo "root:$rootpass" | arch-chroot /mnt chpasswd

# Add a user with sudo privileges
echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/wheel
arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
echo "$username:$userpass" | arch-chroot /mnt chpasswd

# Enable essential services
arch-chroot /mnt systemctl enable NetworkManager

# Finish up
echo "Installation complete. You can now reboot."
