#!/usr/bin/env bash

# Ensure the script is run as root for system-wide installation
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Create the system-wide fonts directory and a temporary directory for download
mkdir -p /usr/share/fonts/custom
mkdir -p /tmp/fonts-download

# Download the ZIP file to the temporary directory
curl -L -o /tmp/fonts-download/oldschool_pc_font_pack_v2.2_linux.zip https://int10h.org/oldschool-pc-fonts/download/oldschool_pc_font_pack_v2.2_linux.zip

# Unzip the fonts into the temporary directory
unzip /tmp/fonts-download/oldschool_pc_font_pack_v2.2_linux.zip -d /tmp/fonts-download

# Create a folder with the same name as the ZIP file (without .zip)
mkdir -p /usr/share/fonts/custom/oldschool_pc_font_pack_v2.2_linux

# Move the entire extracted folder to the newly created folder inside the fonts directory
mv /tmp/fonts-download/* /usr/share/fonts/custom/oldschool_pc_font_pack_v2.2_linux/

# Set the appropriate permissions
chmod -R 755 /usr/share/fonts/custom/oldschool_pc_font_pack_v2.2_linux

# Update the font cache
fc-cache -fv

# Clean up
rm -rf /tmp/fonts-download

# Confirm installation
echo "Fonts installed successfully in /usr/share/fonts/custom/oldschool_pc_font_pack_v2.2_linux!"
