#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# The script configures the Ubuntu OS by copying necessary configuration files
# and setting up system parameters.
# --------------------------------------------------------------------------#

# Define global variable:
WORK_DIR=$(pwd)
ROOTFS="./rootfs"
BIN_PATH="$ROOTFS/usr/bin"
ETC_PATH="$ROOTFS/etc"
LOG_PATH="$ROOTFS/var/log"
BOOT_PATH="$ROOTFS/boot"

# 1. Copy qemu-aarch64-static
function copy_qemu() {
	echo "Copying qemu-aarch64-static..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	if [[ -z "$BIN_PATH" ]]; then
		echo "BIN_PATH is not set."
		return 1
	fi

	mkdir -p "$BIN_PATH" || { echo "Failed to create $BIN_PATH"; return 1; }
	cp /usr/bin/qemu-aarch64-static "$BIN_PATH/" || { echo "Failed to copy qemu-aarch64-static"; return 1; }
	echo "Copied qemu-aarch64-static successfully."
	return 0
}

# 2. Copy resolv.conf
function copy_resolv_conf() {
	echo "Copying resolv.conf..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	if [[ -z "$ETC_PATH" ]]; then
		echo "ETC_PATH is not set."
		return 1
	fi

	mkdir -p "$ETC_PATH" || { echo "Failed to create $ETC_PATH"; return 1; }
	cp /etc/resolv.conf "$ETC_PATH/resolv.conf" || { echo "Failed to copy resolv.conf"; return 1; }
	echo "Copied resolv.conf successfully."
	return 0
}

# 3. Set up log file for syslog
function setup_log_file() {
	echo "Setting up log file..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	if [[ -z "$LOG_PATH" ]]; then
		echo "LOG_PATH is not set."
		return 1
	fi

	mkdir -p "$LOG_PATH" || { echo "Failed to create $LOG_PATH"; return 1; }
	LOG_FILE="$LOG_PATH/rsyslog"
	touch "$LOG_FILE" || { echo "Failed to create log file"; return 1; }
	# chown syslog:adm "$LOG_FILE" || { echo "Failed to change log file ownership"; return 1; }
	chmod 666 "$LOG_FILE" || { echo "Failed to change log file permissions"; return 1; }
	echo "Log file set up successfully."
	return 0
}

# 4. Set LightDM configuration
function set_lightdm_config() {
	echo "Setting LightDM configuration..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	if [[ -z "$ETC_PATH" ]]; then
		echo "ETC_PATH is not set."
		return 1
	fi

	LIGHTDM_CONF="$ETC_PATH/lightdm/lightdm.conf"
	mkdir -p "$(dirname "$LIGHTDM_CONF")" || { echo "Failed to create $(dirname "$LIGHTDM_CONF")"; return 1; }
	echo -e "[SeatDefaults]\nuser-session=LXDE" > "$LIGHTDM_CONF" || { echo "Failed to write to $LIGHTDM_CONF"; return 1; }
	echo "LightDM configuration set up successfully."
	return 0
}

# 5. Configure network interfaces
function set_network_config() {
	echo "Configuring network interfaces..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check ETC_PATH
	if [[ -z "$ETC_PATH" ]]; then
		echo "ETC_PATH is not set."
		return 1
	fi

	NETWORK_CONF="$ETC_PATH/network/interfaces"
	# Check and create folder
	mkdir -p "$(dirname "$NETWORK_CONF")" || { echo "Failed to create $(dirname "$NETWORK_CONF")"; return 1; }

	# Check exist file network config
	NETWORK_CONFIG_FILE="./config/ubuntu_core/network_interfaces.conf"
	if [[ ! -f "$NETWORK_CONFIG_FILE" ]]; then
		echo "Configuration file $NETWORK_CONFIG_FILE not found"
		return 1
	fi

	# copy network config
	sudo cp "$NETWORK_CONFIG_FILE" "$NETWORK_CONF" || { echo "Failed to copy $NETWORK_CONFIG_FILE to $NETWORK_CONF"; return 1; }

	echo "Network interfaces configured successfully."
	return 0
}

# --------------------------------------------------------------------------#
# function set_config use to copy config file to ubuntu os.
# function set_config contain steps:
# 1. Copy qemu-aarch64-static
# 2. Copy resolv.conf
# 3. Set up log file for syslog
# 4. Set LightDM configuration
# 5. Configure network interfaces
# --------------------------------------------------------------------------#
# Function set_config
function set_config() {
	echo "Setting configuration..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Call Function to copy QEMU
	copy_qemu
	if [[ $? -eq 1 ]]; then
		echo "Failed to copy qemu-aarch64-static. Exiting."
		return 1
	fi

	# Call Function to copy resolv.conf
	copy_resolv_conf
	if [[ $? -eq 1 ]]; then
		echo "Failed to copy resolv.conf. Exiting."
		return 1
	fi

	# Call Function to set up log file for syslog
	setup_log_file
	if [[ $? -eq 1 ]]; then
		echo "Failed to set up log file. Exiting."
		return 1
	fi

	# Call Function to set up network interfaces
	set_network_config
	if [[ $? -eq 1 ]]; then
		echo "Failed to configure network interfaces. Exiting."
		return 1
	fi

	echo "Configuration completed successfully."
	return 0
}
