#!/bin/bash
# --------------------------------------------------------------------------#
# This script prepares the environment by checking for the required file
# and directories. It ensures that:
# - The file `renesas-ubuntu.tar.bz2` exists.
# - The `rootfs` directory is removed if it exists. This function only works if 
# CLEAN_ALL is set to 1 in config.ini
# - The `qt_rootfs_source` directory can be reused if it exists.
# --------------------------------------------------------------------------#

function prepare_env() {
	if [ -d "rootfs" ]; then
		rm -rf "rootfs"
		echo "Directory 'rootfs' removed."
	fi

	if [ -d "qt_rootfs_source" ] || [ -d "rootfs_qt" ]; then
		echo "Directory rootfs qt exists and can be reused."
	fi
}

#######################################
# Function copy_file_conf copies a config file to a target directory.
# Globals:
#   SCRIPT_DIR
# Arguments:
#   - config subfolder name (e.g., ubuntu_lxde, ubuntu_core, common)
#   - file name in the config folder
#   - target folder in the Ubuntu OS
#   - permission of file
#######################################
copy_file_conf() {
	config_subfolder="$1"
	file_name="$2"
	target_folder="$3"
	file_permission="$4"

	# Check if file exists in the config folder
	if [ ! -f "${SCRIPT_DIR}/config/${config_subfolder}/${file_name}" ]; then
		echo "File ${file_name} does not exist in the config folder ${config_subfolder}."
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
	cp "${SCRIPT_DIR}/config/${config_subfolder}/${file_name}" "${target_folder}"
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
