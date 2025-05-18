#!/bin/bash
##############################################################################
# This script use to create swap partition.
##############################################################################

#######################################
# Function create_swap use to create swap partition.
# Globals:
#   ROOTFS
# Arguments:
#   None
#######################################
function create_swap() {
	# Change dir to ROOTFS
	echo "Current working directory is: $ROOTFS"
	cd "$ROOTFS" || { echo "Failed to change to ROOTFS"; return 1; }

	# Create a 1GB swap file
	fallocate -l 1G swapfile
	if [ $? -ne 0 ]; then
		echo "Failed to create swap file."
		exit 1
	fi

	# Set the correct permissions
	chmod 600 swapfile
	if [ $? -ne 0 ]; then
		echo "Failed to set permissions on swap file."
		exit 1
	fi

	# Set up the swap area
	mkswap swapfile
	if [ $? -ne 0 ]; then
		echo "Failed to set up swap area."
		exit 1
	fi

	# Enable the swap file
	swapon swapfile
	if [ $? -ne 0 ]; then
		echo "Failed to enable swap file."
		exit 1
	fi

	echo "Swap file created and enabled successfully."
	return 0
}
