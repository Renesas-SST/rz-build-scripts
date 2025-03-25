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

# Add group to support wpa_supplicant.service
groupadd netdev

# Remove the password for the root user
passwd -d root

if [ $? -eq 0 ]; then
	echo "Password for user 'root' has been successfully removed."
else
	echo "Failed to remove password for user 'root'."
	exit 1
fi

# --------------------------------------------------------------------------#
# Description:
# User: rzpi
# Password: 1
# --------------------------------------------------------------------------#

# Define the new user
USERNAME="rzpi"
PASSWORD="1"
: ${SSH_NO_PASS_LOGIN:=1}

# Check if user already exists then don't create it
if id "$USERNAME" > /dev/null 2>&1; then
	echo "User '$USERNAME' already exists."
else
	# Create user and set password
	useradd -m -s /bin/bash "$USERNAME"
	if [ "$SSH_NO_PASS_LOGIN" -eq 1 ]; then
		passwd -d "${USERNAME}"
	else
		echo "${USERNAME}:${PASSWORD}" | chpasswd
	fi
	# Disable forced password change
	passwd -x 99999 "$USERNAME"
	passwd -n 0 "$USERNAME"

	# Add user to the sudo group
	usermod -aG sudo "$USERNAME"

	# Check groups
	groups "$USERNAME"

	echo "User '$USERNAME' created and granted privileges successfully."
fi
