#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# The script configures DNS settings for the Ubuntu OS.
# --------------------------------------------------------------------------#

# Define global variable:	
WORK_DIR=$(pwd)
ROOTFS="./rootfs"
BIN_PATH="$ROOTFS/usr/bin"
ETC_PATH="$ROOTFS/etc"
LOG_PATH="$ROOTFS/var/log"
BOOT_PATH="$ROOTFS/boot"

# Configure DNS
set_dns_config() {
	echo "Configuring network interfaces..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check ETC_PATH
	if [[ -z "$ETC_PATH" ]]; then
		echo "ETC_PATH is not set."
		return 1
	fi

	# Resolved setting
	RESOLVE_CONF="$ETC_PATH/systemd"
	# Check and create folder
	mkdir -p "$(dirname "$RESOLVE_CONF")" || { echo "Failed to create $(dirname "$RESOLVE_CONF")"; return 1; }

	# Check exist file network config
	RESOLVE_CONFIG_FILE="${SCRIPT_DIR}/config/ubuntu_core/resolved.conf"
	if [[ ! -f "$RESOLVE_CONFIG_FILE" ]]; then
		echo "Configuration file $RESOLVE_CONFIG_FILE not found"
		return 1
	fi

	# copy network config
	sudo cp "$RESOLVE_CONFIG_FILE" "$RESOLVE_CONF" || { echo "Failed to copy $RESOLVE_CONFIG_FILE to $RESOLVE_CONF"; return 1; }

	echo "DNS configured successfully."
	return 0
}


# --------------------------------------------------------------------------#
# Install DNS config after install
set_config_after_install() {
	echo "Setting configuration after install packages..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Call Function to set up 
	set_dns_config
	if [[ $? -eq 1 ]]; then
		echo "Failed to configure DNS. Exiting."
		return 1
	fi

	echo "set_config_after_install completed successfully."
	return 0
}
