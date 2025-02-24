#!/bin/bash
##############################################################################
# This script sets up the Ubuntu OS configuration by performing the following:
# 1. Copy qemu-aarch64-static
# 2. Copy resolv.conf
# 3. Set up log file for syslog
# 4. Set LightDM configuration
# 5. Configure network interfaces
# 6. Configure network manager
# 7. Configure camera ov5640
##############################################################################

# Define global variables
WORK_DIR=$(pwd)
ROOTFS="./rootfs"
BIN_PATH="$ROOTFS/usr/bin"
ETC_PATH="$ROOTFS/etc"

#######################################
# Function copy_qemu use to copy qemu-aarch64-static to ubuntu os.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
copy_qemu() {
	echo "Copying qemu-aarch64-static..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check BIN_PATH
	if [ -z "$BIN_PATH" ]; then
		echo "BIN_PATH is not set."
		return 1
	fi

	# Create folder BIN_PATH
	mkdir -p "$BIN_PATH" || { echo "Failed to create $BIN_PATH"; return 1; }

	# Copy qemu-aarch64-static
	cp /usr/bin/qemu-aarch64-static "$BIN_PATH/" || { echo "Failed to copy qemu-aarch64-static"; return 1; }
	echo "Copied qemu-aarch64-static successfully."
	return 0
}


#######################################
# Function copy_resolv_conf use to copy resolv.conf to ubuntu os.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
copy_resolv_conf() {
	echo "Copying resolv.conf..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check ETC_PATH
	if [ -z "$ETC_PATH" ]; then
		echo "ETC_PATH is not set."
		return 1
	fi

	# Create folder ETC_PATH
	mkdir -p "$ETC_PATH" || { echo "Failed to create $ETC_PATH"; return 1; }

	# Copy resolv.conf
	cp /etc/resolv.conf "$ETC_PATH/resolv.conf" || { echo "Failed to copy resolv.conf"; return 1; }
	echo "Copied resolv.conf successfully."
	return 0
}

#######################################
# Function copy_file_conf use to copy conf target dir in ubuntu os.
# Globals:
#   WORK_DIR
# Arguments:
#    - file name in folder config
#    - target folder in ubuntu os
#    - permission of file
#######################################
copy_file_conf() {
	file_name="$1"
	target_folder="$2"
	file_permission="$3"

	# Check if file exists in the config folder
	if [ ! -f "${WORK_DIR}/config/ubuntu_lxde/${file_name}" ]; then
		echo "File ${file_name} does not exist in the config folder."
		return 1
	fi

	# Check if target folder exists
	if [ ! -d "${target_folder}" ]; then
		echo "Target folder ${target_folder} does not exist. Creating it..."
		mkdir -p "${target_folder}"
		if [ $? -ne 0 ]; then
			echo "Failed to create target folder ${target_folder}."
			return 1
		fi
	fi

	# Copy the file to the target folder
	cp "${WORK_DIR}/config/ubuntu_lxde/${file_name}" "${target_folder}"
	if [ $? -ne 0 ]; then
		echo "Failed to copy file ${file_name} to ${target_folder}."
		return 1
	fi

	# Set the permissions of the copied file
	chmod "${file_permission}" "${target_folder}/${file_name}"
	if [ $? -ne 0 ]; then
		echo "Failed to set permissions for file ${target_folder}/${file_name}."
		return 1
	fi

	echo "File ${file_name} successfully copied to ${target_folder} with permissions ${file_permission}."
	return 0
}

#######################################
# Function set_config use to copy config file to ubuntu os.
# 1. Copy qemu-aarch64-static
# 2. Copy resolv.conf
# 3. Set up log file for syslog
# 4. Set LightDM configuration
# 5. Configure network interfaces
# 6. Configure network manager
# 7. Configure camera ov5640
#######################################
set_config() {
	echo "Setting configuration..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Copy qemu-aarch64-static
	copy_qemu
	if [ $? -eq 1 ]; then
		echo "Failed to copy qemu-aarch64-static. Exiting."
		return 1
	fi

	# Copy resolv.conf
	copy_resolv_conf
	if [ $? -eq 1 ]; then
		echo "Failed to copy resolv.conf. Exiting."
		return 1
	fi

	# Set up rsyslog file
	copy_file_conf "rsyslog" "rootfs/var/log" "666"
	if [ $? -eq 1 ]; then
		echo "Failed to set up log file. Exiting."
		return 1
	fi

	# Set LightDM configuration
	copy_file_conf "lightdm.conf" "rootfs/etc/lightdm" "644"
	if [ $? -eq 1 ]; then
		echo "Failed to configure LightDM. Exiting."
		return 1
	fi

	# Configure network interfaces
	copy_file_conf "interfaces" "rootfs/etc/network" "644"
	if [ $? -eq 1 ]; then
		echo "Failed to configure network interfaces. Exiting."
		return 1
	fi

	# Configure network manager
	copy_file_conf "NetworkManager.conf" "rootfs/etc/NetworkManager" "644"
	if [ $? -eq 1 ]; then
		echo "Failed to configure network manager. Exiting."
		return 1
	fi

	# Configure camera ov5640
	copy_file_conf "v4l2-init.sh" "rootfs/etc/profile.d" "755"
	if [ $? -eq 1 ]; then
		echo "Failed to configure camera ov5640. Exiting."
		return 1
	fi

	echo "Configuration completed successfully."
	return 0
}

