#!/bin/bash
##############################################################################
# This script prepares the rootfs_qt built using the Yocto package.
# Extract file renesas-ubuntu (yocto output).
# Copy boot folder from renesas-ubuntu (yocto output) to rootfs
# Copy kernel module from renesas-ubuntu (yocto output) to rootfs
# Copy Wi-Fi firmware from renesas-ubuntu (yocto output) to rootfs
# Get Bluetooth firmware from Realtek-OpenSource to rootfs
##############################################################################

source "${SCRIPT_DIR}/include/common/prepare_env_rootfs.sh"

# Define global variable:
WORK_DIR=$(pwd)

#######################################
# Extract file renesas-ubuntu (yocto output).
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
extract_renesas_ubuntu_input() {
	echo "Extracting ${renesas_ubuntu_input_name}..."

	# Define local variables
	target_dir="rootfs_qt"
	check_file="rootfs_qt/home"

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check file renesas-ubuntu (yocto output) exists or not
	# If file not exists, return 1
	if [ ! -f "$renesas_ubuntu_input_name" ]; then
		echo "File $renesas_ubuntu_input_name does not exist. Please download it first."
		return 1
	fi

	# Check if the file has already been extracted then skip extraction
	if [ -e "$check_file" ]; then
		echo "File has already been extracted. Skipping extraction."
		return 0
	fi

	# Create target folder to extract file
	if [ ! -d "$target_dir" ]; then
		echo "Directory $target_dir does not exist. Creating it..."
		mkdir "$target_dir"
		if [ $? -ne 0 ]; then
			echo "Failed to create directory $target_dir."
			return 1
		fi
	else
		echo "Directory $target_dir already exists. Skipping creation."
	fi

	# Extract file into target folder
	echo "Extracting $renesas_ubuntu_input_name to $target_dir..."
	tar xf "$renesas_ubuntu_input_name" -C "$target_dir" -v
	if [ $? -ne 0 ]; then
		echo "Failed to extract $renesas_ubuntu_input_name."
		return 1
	fi

	echo "extract_renesas_ubuntu_input completed successfully."
	return 0
}

#######################################
# Copy boot folder from renesas-ubuntu (yocto output) to rootfs
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
copy_boot_folder() {
	echo "Copying kernel files..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	src_boot="rootfs_qt/boot"
	target_dir="rootfs/boot"

	# Check folder src
	if [ ! -d "$src_boot" ]; then
		echo "Source directory '$src_boot' does not exist!"
		return 1
	fi

	# Create target folder
	if [ ! -d "$target_dir" ]; then
		echo "Directory $target_dir does not exist. Creating it..."
		mkdir -p "$target_dir"
		if [ $? -ne 0 ]; then
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

#######################################
# Copy kernel module from renesas-ubuntu (yocto output) to rootfs
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
copy_kernel_modules() {
	echo "Copying copy_kernel_modules folder..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	src_dir="rootfs_qt/lib/modules/"
	target_dir="rootfs/lib"

	# Check folder src
	if [ ! -d "$src_dir" ]; then
		echo "Source directory '$src_dir' does not exist!"
		return 1
	fi

	# Create target folder
	if [ ! -d "$target_dir" ]; then
		echo "Directory $target_dir does not exist. Creating it..."
		mkdir -p "$target_dir"
		if [ $? -ne 0 ]; then
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

#######################################
# Get_bluetooth firmware from Realtek-OpenSource to rootfs
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
get_bluetooth_firmware() {
	echo "Getting Bluetooth firmware..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Create folder bluetooth firmware folder
	mkdir -p "$bluetooth_firmware_target_folder" || { echo "Failed to create directory $bluetooth_firmware_target_folder"; return 1; }

	# Download firmware from URL
	wget "$bluetooth_firmware_link" -O "$bluetooth_firmware_target_folder/$bluetooth_firmware_name" || { echo "Failed to download Bluetooth firmware"; return 1; }

	echo "Bluetooth firmware downloaded and renamed successfully."
	return 0
}

#######################################
# Main function to prepare rootfs_qt
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
rootfs_qt() {
	#Extract file renesas-ubuntu (yocto output).
	echo "Starting extract_renesas_ubuntu_input..."
	extract_renesas_ubuntu_input
	if [ $? -eq 1 ]; then
		echo "extract_renesas_ubuntu_input failed."
		return 1
	fi
	echo "extract_renesas_ubuntu_input completed successfully."

	#Copy boot folder from renesas-ubuntu (yocto output) to rootfs
	echo "5. Starting copy_boot_folder..."
	copy_boot_folder
	if [ $? -eq 1 ]; then
		echo "copy_boot_folder failed."
		return 1
	fi
	echo "copy_boot_folder completed successfully."

	# Copy kernel module from renesas-ubuntu (yocto output) to rootfs
	echo "6. Starting copy_kernel_modules..."
	copy_kernel_modules
	if [ $? -eq 1 ]; then
		echo "copy_kernel_modules failed."
		return 1
	fi
	echo "copy_kernel_modules completed successfully."

	# Copy firmware from renesas-ubuntu (yocto output) to rootfs
	echo "7. Starting copy_firmware..."
	copy_firmware "rootfs_qt" "rootfs"
	if [ $? -eq 1 ]; then
		echo "copy_firmware failed."
		return 1
	fi
	echo "copy_firmware completed successfully."

	# Get Bluetooth firmware from Realtek-OpenSource to rootfs
	echo "8. Starting get_bluetooth_firmware..."
	get_bluetooth_firmware
	if [ $? -eq 1 ]; then
		echo "get_bluetooth_firmware failed."
		return 1
	fi
	echo "get_bluetooth_firmware completed successfully."

	# Copy modprobe conf
	echo "9. Starting copy modprobe conf..."
	copy_modprobe_conf "rootfs_qt" "rootfs"
	if [[ $? -eq 1 ]]; then
		echo "copy_modprobe_conf failed."
		return 1
	fi
	echo "copy_modprobe_conf completed succesfully."

	# Copy network interface
	echo "10. Starting copy network interface..."
	copy_network_interface_conf "rootfs_qt" "rootfs"
	if [[ $? -eq 1 ]]; then
		echo "copy_network_interface_conf failed."
		return 1
	fi
	echo "copy_network_interface_conf completed succesfully."

	# Copy modules_load_d
	echo "10. Starting copy module-loads.d..."
	copy_modules_load_d "rootfs_qt" "rootfs"
	if [[ $? -eq 1 ]]; then
		echo "copy_modules_load_d failed."
		return 1
	fi
	echo "copy_modules_load_d completed succesfully."

	return 0
}
