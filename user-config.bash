#!/usr/bin/env -S bash -e -x

source /mtn/root/vars-config.bash

# Configure as user

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