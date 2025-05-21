#!/bin/bash
##############################################################################
# This script prepares the rootfs_qt built using the Yocto package.
# Extract file core-image-qt.
# Copy boot folder from core-image-qt to rootfs
# Copy kernel module from core-image-qt to rootfs
# Copy Wi-Fi firmware from core-image-qt to rootfs
# Get Bluetooth firmware from Realtek-OpenSource to rootfs
##############################################################################

#######################################
# Extract file core-image-qt.
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
tar_core_image_qt() {
	echo "Extracting core-image-qt..."

	# Define local variables
	target_dir="rootfs_qt"
	check_file="rootfs_qt/home"

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check file core_image_qt exists or not
	# If file not exists, return 1
	if [ ! -f "$core_image_qt_name" ]; then
		echo "File $core_image_qt_name does not exist. Please download it first."
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
	echo "Extracting $core_image_qt_name to $target_dir..."
	tar xf "$core_image_qt_name" -C "$target_dir" -v
	if [ $? -ne 0 ]; then
		echo "Failed to extract $core_image_qt_name."
		return 1
	fi

	echo "tar_core_image_qt completed successfully."
	return 0
}

#######################################
# Copy boot folder from core-image-qt to rootfs
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
# Copy kernel module from core-image-qt to rootfs
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
# Copy Wi-Fi firmware from core-image-qt to rootfs
# Globals:
#   WORK_DIR
# Arguments:
#   None
#######################################
copy_wifi_firmware() {
	source_dir="./rootfs_qt/lib/firmware/brcm/"
	dest_dir="./rootfs/lib/firmware/"

	# Change dir WORK_DIR
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check source folder
	if [ ! -d "$source_dir" ]; then
		echo "Source directory $source_dir does not exist."
		return 1
	fi

	# Check destination folder
	if [ ! -d "$dest_dir" ]; then
		echo "Destination directory $dest_dir does not exist. Creating it..."
		mkdir -p "$dest_dir" || { echo "Failed to create destination directory $dest_dir"; return 1; }
	fi

	# Copy folder from source to destination
	echo "Copying Wi-Fi firmware from $source_dir to $dest_dir..."
	cp -r "$source_dir" "$dest_dir" || { echo "Failed to copy wifi firmware."; return 1; }

	echo "Wi-Fi firmware copied successfully to $dest_dir."
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
	#Extract file core-image-qt.
	echo "Starting tar_core_image_qt..."
	tar_core_image_qt
	if [ $? -eq 1 ]; then
		echo "tar_core_image_qt failed."
		return 1
	fi
	echo "tar_core_image_qt completed successfully."

	#Copy boot folder from core-image-qt to rootfs
	echo "5. Starting copy_boot_folder..."
	copy_boot_folder
	if [ $? -eq 1 ]; then
		echo "copy_boot_folder failed."
		return 1
	fi
	echo "copy_boot_folder completed successfully."

	# Copy kernel module from core-image-qt to rootfs
	echo "6. Starting copy_kernel_modules..."
	copy_kernel_modules
	if [ $? -eq 1 ]; then
		echo "copy_kernel_modules failed."
		return 1
	fi
	echo "copy_kernel_modules completed successfully."

	# Copy Wi-Fi firmware from core-image-qt to rootfs
	echo "7. Starting copy_wifi_firmware..."
	copy_wifi_firmware
	if [ $? -eq 1 ]; then
		echo "copy_wifi_firmware failed."
		return 1
	fi
	echo "copy_wifi_firmware completed successfully."

	# Get Bluetooth firmware from Realtek-OpenSource to rootfs
	echo "8. Starting get_bluetooth_firmware..."
	get_bluetooth_firmware
	if [ $? -eq 1 ]; then
		echo "get_bluetooth_firmware failed."
		return 1
	fi
	echo "get_bluetooth_firmware completed successfully."

	return 0
}
