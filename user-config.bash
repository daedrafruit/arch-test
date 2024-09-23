#!/usr/bin/env -S bash -e -x

source /scripts/vars-config.bash

# Configure as user

cd /home/$username

# install yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd /home/$username

# Install packages using yay
yay -S --noconfirm $aur_pkgs
		
# Clone dotfiles
git clone https://github.com/daedrafruit/dotfiles.git
# remove existing bashrc
rm /home/$username/.bashrc
# stow dotfiles
cd /home/$username/dotfiles
stow $stow_args