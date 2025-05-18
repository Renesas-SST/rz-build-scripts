#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Root user can be access without password at first
# --------------------------------------------------------------------------#

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
	echo "Please run this script as root or using sudo."
	exit 1
fi

# Changes the ownership of critical sudo-related files to root.
chown root:root /usr/libexec/sudo/sudoers.so
chown root:root /etc/sudo.conf
chown root:root /etc/sudoers

chown root:root /etc/sudoers.d
chown root:root /etc/sudoers.d/README

chown root:root /usr/bin/sudo
chmod 4755 /usr/bin/sudo

# Remove the password for the root user
passwd -d root

if [ $? -eq 0 ]; then
	echo "Password for user 'root' has been successfully removed."
else
	echo "Failed to remove password for user 'root'."
	exit 1
fi
