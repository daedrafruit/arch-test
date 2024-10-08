#!/usr/bin/env -S bash -e -x

# Usage:
# curl -O https://raw.githubusercontent.com/daedrafruit/arch-test/main/arch.bash
# chmod +x arch.bash
# ./arch.bash

curl -O https://raw.githubusercontent.com/daedrafruit/arch-test/main/vars-config.bash

source ./vars-config.bash

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
pacstrap /mnt $pacstrap_pkgs

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

# Setting root password.
echo "root:$rootpass" | arch-chroot /mnt chpasswd

echo "%wheel ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/wheel
arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
echo "$username:$userpass" | arch-chroot /mnt chpasswd

mkdir /mnt/scripts
cp vars-config.bash /mnt/scripts

curl -O https://raw.githubusercontent.com/daedrafruit/arch-test/main/system-config.bash
cp system-config.bash /mnt/scripts
curl -O https://raw.githubusercontent.com/daedrafruit/arch-test/main/user-config.bash
cp user-config.bash /mnt/scripts

chmod -R 755 /mnt/scripts

# Run system configuration script inside chroot
arch-chroot /mnt /bin/bash -x /scripts/system-config.bash

# Run user configuration script inside chroot as the specified user
arch-chroot /mnt /usr/bin/runuser -u $username /scripts/user-config.bash

# Finish up
echo "Installation complete. You can now reboot."