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

# 2. Download ubuntu base
download_ubuntu_base() {
	echo "Downloading Ubuntu base..."
	echo "Latest ubuntu base image file is $LATEST_UBUNTU_IMAGE"

	# Change dir WORK_DIR
	echo "Current working directory is: $WORK_DIR"
	cd "$WORK_DIR" || { echo "Failed to change to WORK_DIR"; return 1; }

	# Install wget
	if ! sudo apt-get install -y wget; then
		echo "Failed to install wget."
		return 1
	fi

	# Default assign to ./ if DOWNLOAD_DIR is unset or empty
	: "${DOWNLOAD_DIR:=./}"

	# Check if there is an exisitng file of any minor version available. Skip download if the file is available.
	EXISTING_FILE=$(find "$DOWNLOAD_DIR" -maxdepth 1 -type f -name "$UBUNTU_BASE_FILE_PATTERN" 2>/dev/null | head -n 1)

	if [ -n "$EXISTING_FILE" ]; then
		echo "Found pre-downloaded image in $DOWNLOAD_DIR:"
		echo "$EXISTING_FILE"
		LOCAL_FILE="$EXISTING_FILE"
	else
		LOCAL_FILE="${DOWNLOAD_DIR}/${UBUNTU_LATEST_IMAGE}"
		echo "Downloading image: $DOWNLOAD_URL"

		# check if the release page has a valid latest image
		if [ -z "$UBUNTU_LATEST_IMAGE" ]; then
			echo " Error: No ARM64 image found on the release page."
			exit 1
		fi

		# Derive the complete Ubuntu base download url and set it to local variable 'url'
		url="${UBUNTU_BASE_URL}${UBUNTU_LATEST_IMAGE}"

		# Print out the urls we are using
		echo "Latest Ubuntu Base 24.04 ARM64 image:"
		echo "$url"

		if ! wget -P "$DOWNLOAD_DIR" "$url"; then
			echo "Failed to download $UBUNTU_LATEST_IMAGE from $url."
			return 1
		fi
		echo "Download completed: $UBUNTU_LATEST_IMAGE"

		echo "download_ubuntu_base completed successfully."
	fi
	return 0
}

# 3. Unpack ubuntu base archive
unpack_ubuntu_base() {
	echo "Extracting Ubuntu base..."

	# Assign the value of UBUNTU_LATEST_IMAGE to local variable 'file_name'
	file_name="${DOWNLOAD_DIR}/${UBUNTU_LATEST_IMAGE}"

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
		return 0
	fi

	# Tar file into target folder
	echo "Extracting $file_name to $target_dir..."
	if ! tar -xf "$file_name" -C "$target_dir"; then
		echo "Failed to extract $file_name."
		return 1
	fi

	echo "unpack_ubuntu_base completed successfully."
	return 0
}

# --------------------------------------------------------------------------#
# function ubuntu_base_prepare use to prepare basic binaries of ubuntu os.
# function ubuntu_base_prepare contain 3 step:
# 1. Install qemu-user-static
# 2. Download ubuntu base
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

	echo "3. Starting unpack_ubuntu_base..."
	unpack_ubuntu_base
	if [ $? -eq 1 ]; then
		echo "unpack_ubuntu_base failed."
		exit 1
	fi
	echo "unpack_ubuntu_base completed successfully."
}
