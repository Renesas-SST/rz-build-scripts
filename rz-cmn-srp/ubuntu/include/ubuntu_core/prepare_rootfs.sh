#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# This script prepares the Ubuntu OS environment by copying necessary binaries
# and files from the rootfs source to the target Ubuntu system.
# --------------------------------------------------------------------------#

source "${SCRIPT_DIR}/include/common/prepare_env_rootfs.sh"

# Define global variable:
WORK_DIR=$(pwd)

# 1. Tar file renesas-ubuntu (yocto input)
function extract_renesas_ubuntu_input() {
	echo "Extracting ${renesas_ubuntu_input_name}..."

	local file_name="$renesas_ubuntu_input_name"
	local target_dir="artifacts_rootfs_source"
	local check_file="artifacts_rootfs_source/home"

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check file renesas-ubuntu (yocto input)
	if [[ ! -f "$file_name" ]]; then
		echo "File $file_name does not exist. Please download it first."
		return 1
	fi

	# Check if the file has already been extracted
	if [[ -e "$check_file" ]]; then
		echo "File has already been extracted. Skipping extraction."
		return 0
	fi

	# Create target folder
	if [[ ! -d "$target_dir" ]]; then
		echo "Directory $target_dir does not exist. Creating it..."
		mkdir "$target_dir"
		if [[ $? -ne 0 ]]; then
			echo "Failed to create directory $target_dir."
			return 1
		fi
	else
		echo "Directory $target_dir already exists. Skipping creation."
	fi

	# Tar file into target folder
	echo "Extracting $file_name to $target_dir..."
	tar -xf "$file_name" -C "$target_dir"
	if [[ $? -ne 0 ]]; then
		echo "Failed to extract $file_name."
		return 1
	fi

	ls $target_dir
	echo "extract_renesas_ubuntu_input completed successfully."
	return 0
}

# 2. Copy boot folder
function copy_boot_folder() {
	echo "Copying kernel files..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	local src_boot="artifacts_rootfs_source/boot"
	local target_dir="rootfs/boot"

	# Check folder src
	if [[ ! -d "$src_boot" ]]; then
		echo "Source directory '$src_boot' does not exist!"
		return 1
	fi

	# Create target folder
	if [[ ! -d "$target_dir" ]]; then
		echo "Directory $target_dir does not exist. Creating it..."
		mkdir -p "$target_dir"
		if [[ $? -ne 0 ]]; then
			echo "Failed to create directory $target_dir."
			return 1
		fi
	else
		echo "Directory $target_dir already exists. Skipping creation."
	fi

	# Copy folder boot
	cp -r $src_boot/* "$target_dir" || { echo "Failed to copy 'boot' directory"; return 1; }
	echo "Copied contain in '$src_boot' directory to '$target_dir'."

	echo "copy completed successfully."
	return 0
}

# Copy kernel module
function copy_kernel_modules() {
	echo "Copying copy_kernel_modules folder..."
	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }
	local src_dir="artifacts_rootfs_source/lib/modules/"
	local target_dir="rootfs/lib"
	# Check folder src
	if [[ ! -d "$src_dir" ]]; then
		echo "Source directory '$src_dir' does not exist!"
		return 1
	fi
	# Create target folder
	if [[ ! -d "$target_dir" ]]; then
		echo "Directory $target_dir does not exist. Creating it..."
		mkdir -p "$target_dir"
		if [[ $? -ne 0 ]]; then
			echo "Failed to create directory $target_dir."
			return 1
		fi
	else
		echo "Directory $target_dir already exists. Skipping creation."
	fi
	# Copy folder
	cp -r $src_dir "$target_dir" || { echo "Failed to copy '$src_dir' directory"; return 1; }
	echo "Copied folder '$src_dir' directory to '$target_dir'."
	echo "Copy completed successfully."
	return 0
}

# --------------------------------------------------------------------------#
# function prepare_rootfs use to copy binaries of artifacts_rootfs_source to ubuntu os.
# function prepare_rootfs contain 2 steps:
# 1. Extract file renesas-ubuntu (yocto input)
# 2. Copy boot folder, qt library, wifi firmware folder
# --------------------------------------------------------------------------#

# Function main
function prepare_rootfs() {
	echo "Starting extract_renesas_ubuntu_input..."
	# Call extract_renesas_ubuntu_input to create a tarball of the core image for the QT system
	extract_renesas_ubuntu_input
	if [[ $? -eq 1 ]]; then
		echo "extract_renesas_ubuntu_input failed."
		return 1
	fi
	echo "extract_renesas_ubuntu_input completed successfully."

	echo "Starting copy_boot_folder and copy_firmware..."
	# Call copy_boot_folder to copy necessary boot files for the system
	copy_boot_folder
	if [[ $? -eq 1 ]]; then
		echo "copy_boot_folder failed."
		return 1
	fi

	# Call copy_firmware to copy the required firmware files to the system
	copy_firmware "artifacts_rootfs_source" "rootfs"
	if [[ $? -eq 1 ]]; then
		echo "copy_firmware failed."
		return 1
	fi
	echo "copy_boot_folder and copy_firmware completed successfully."

	echo "Starting copy_kernel_modules..."
	# Call copy_kernel_modules to copy the kernel modules to the target system
	copy_kernel_modules
	if [[ $? -eq 1 ]]; then
		echo "copy_kernel_modules failed."
		return 1
	fi
	echo "copy_kernel_modules completed successfully."

	# Copy modprobe conf
	echo "Starting copy modprobe conf..."
	copy_modprobe_conf "artifacts_rootfs_source" "rootfs"
	if [[ $? -eq 1 ]]; then
			echo "copy_modprobe_conf failed."
			return 1
	fi
	echo "copy_modprobe_conf completed succesfully."

	# Copy network interface
	echo "Starting copy network interface..."
	copy_network_interface_conf "artifacts_rootfs_source" "rootfs"
	if [[ $? -eq 1 ]]; then
			echo "copy_network_interface_conf failed."
			return 1
	fi
	echo "copy_network_interface_conf completed succesfully."

	# Copy modules_load_d
	echo "Starting copy module-loads.d..."
	copy_modules_load_d "artifacts_rootfs_source" "rootfs"
	if [[ $? -eq 1 ]]; then
			echo "copy_modules_load_d failed."
			return 1
	fi
	echo "copy_modules_load_d completed succesfully."

	return 0
}
