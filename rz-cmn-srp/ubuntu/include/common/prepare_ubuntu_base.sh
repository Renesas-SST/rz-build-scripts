#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# This script prepares the basic Ubuntu OS binaries required for the project.
# --------------------------------------------------------------------------#

# Define global variable:
WORK_DIR=$(pwd)

# 1. Install qemu-user-static
install_qemu() {
	echo "Config binfmt..."
	# Mount binfmt to enable this feature
	if ! mountpoint -q /proc/sys/fs/binfmt_misc; then
		echo "Mounting binfmt_misc..."
		if sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc; then
			echo "binfmt_misc mounted successfully."
		else
			echo "Failed to mount binfmt_misc."
			return 1
		fi
		echo "binfmt_misc mounted successfully."
	else
		echo "binfmt_misc is already mounted."
	fi

	# Config interpreter for qemu
	magic='\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00'
	mask='\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'
	arch='aarch64'
	interpreter="/usr/bin/qemu-$arch-static"
	# Check interpreter file's existance
	if [ ! -f "$interpreter" ]; then
		echo "Interpreter file $interpreter does not exist. Registering QEMU interpreter..."
		echo ":qemu-$arch:M::$magic:$mask:$interpreter:" | sudo tee /proc/sys/fs/binfmt_misc/register
		echo "QEMU interpreter registered successfully."
	else
		echo "Interpreter file $interpreter already exists."
	fi

	echo "Installing qemu-user-static..."

	# Update
	if ! sudo apt-get update; then
		echo "Failed to update package list."
		return 1
	fi

	# Install qemu-user-static
	if ! sudo apt-get install -y qemu-user-static zstd; then
		echo "Failed to install qemu-user-static."
		return 1
	fi

	echo "install_qemu completed successfully."
	return 0
}

# 2. Download ubuntu 22.04-base
download_ubuntu_base() {
	echo "Downloading Ubuntu 22.04-base..."

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Install wget
	if ! sudo apt-get install -y wget; then
		echo "Failed to install wget."
		return 1
	fi

	# Check if UBUNTU_BASE_FILE_NAME is defined, if not, assign the default value 'ubuntu-base-22.04-base-arm64.tar.gz'
	: "${UBUNTU_BASE_FILE_NAME:=ubuntu-base-22.04-base-arm64.tar.gz}"

	# Check if UBUNTU_BASE_LINK is defined, if not, assign the default URL
	: "${UBUNTU_BASE_LINK:=https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/$UBUNTU_BASE_FILE_NAME}"

	# Assign the value of UBUNTU_BASE_FILE_NAME to local variable 'file_name'
	file_name="$UBUNTU_BASE_FILE_NAME"

	# Assign the value of UBUNTU_BASE_LINK to local variable 'url'
	url="$UBUNTU_BASE_LINK"

	if [ ! -e "$file_name" ]; then
		echo "File $file_name not found. Downloading..."
		if ! wget "$url"; then
			echo "Failed to download $file_name from $url."
			return 1
		fi
		echo "Download completed: $file_name"
	else
		echo "File $file_name already exists. Skipping download."
	fi

	echo "download_ubuntu_base completed successfully."
	return 0
}

# 3. Tar file ubuntu base
tar_ubuntu_base() {
	echo "Extracting Ubuntu base..."

	# Check if UBUNTU_BASE_FILE_NAME is defined, if not, assign the default value 'ubuntu-base-22.04-base-arm64.tar.gz'
	: "${UBUNTU_BASE_FILE_NAME:=ubuntu-base-22.04-base-arm64.tar.gz}"

	# Assign the value of UBUNTU_BASE_FILE_NAME to local variable 'file_name'
	file_name="$UBUNTU_BASE_FILE_NAME"

	target_dir="rootfs"

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Check file ubuntu-base
	if [ ! -f "$file_name" ]; then
		echo "File $file_name does not exist. Please download it first."
		return 1
	fi

	# Create target folder
	if [ ! -d "$target_dir" ]; then
		echo "Directory $target_dir does not exist. Creating it..."
		if ! mkdir "$target_dir"; then
			echo "Failed to create directory $target_dir."
			return 1
		fi
	else
		echo "Directory $target_dir already exists. Skipping creation."
	fi

	# Tar file into target folder
	echo "Extracting $file_name to $target_dir..."
	if ! tar -xf "$file_name" -C "$target_dir"; then
		echo "Failed to extract $file_name."
		return 1
	fi

	echo "tar_ubuntu_base completed successfully."
	return 0
}

# --------------------------------------------------------------------------#
# function ubuntu_base_prepare use to prepare basic binaries of ubuntu os.
# function ubuntu_base_prepare contain 3 step:
# 1. Install qemu-user-static
# 2. Download ubuntu 22.04-base
# 3. Tar file ubuntu base
# --------------------------------------------------------------------------#

# Main function ubuntu_base_prepare
ubuntu_base_prepare() {
	echo "1. Starting install_qemu..."
	install_qemu
	if [ $? -eq 1 ]; then
		echo "install_qemu failed."
		exit 1
	fi
	echo "install_qemu completed successfully."

	echo "2. Starting download_ubuntu_base..."
	download_ubuntu_base
	if [ $? -eq 1 ]; then
		echo "download_ubuntu_base failed."
		exit 1
	fi
	echo "download_ubuntu_base completed successfully."

	echo "3. Starting tar_ubuntu_base..."
	tar_ubuntu_base
	if [ $? -eq 1 ]; then
		echo "tar_ubuntu_base failed."
		exit 1
	fi
	echo "tar_ubuntu_base completed successfully."
}
