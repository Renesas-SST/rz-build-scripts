#!/bin/bash
# --------------------------------------------------------------------------#
# This script prepares the environment by checking for the required file
# and directories. It ensures that:
# - The file `renesas-ubuntu.tar.bz2` exists.
# - The `rootfs` directory is removed if it exists. This function only works if 
# CLEAN_ALL is set to 1 in config.ini
# - The `qt_rootfs_source` directory can be reused if it exists.
# --------------------------------------------------------------------------#

<<<<<<< HEAD:rz-cmn-srp/ubuntu/include/common/prepare_env.sh
file="$renesas_ubuntu_input_name"
CLEAN_ALL="${CLEAN_ALL:-0}"
function prepare_env() {

	# Check env
	if [ ! -f "$file" ]; then
		echo "File '$file' not found. Please copy it over."
		return 1
	fi

	if [ "$CLEAN_ALL" -eq 1 ]; then
		if [ -d "rootfs" ]; then
			rm -rf "rootfs"
			echo "Directory 'rootfs' has been removed."
		fi
=======
function prepare_env() {
	if [ -d "rootfs" ]; then
		rm -rf "rootfs"
		echo "Directory 'rootfs' removed."
>>>>>>> 8e8bbc4... rz-cmn-srp: Refactor build script and layout:rz-cmn-srp/ubuntu/include/ubuntu_core/prepare_env.sh
	fi

	if [ -d "qt_rootfs_source" ] || [ -d "rootfs_qt" ]; then
		echo "Directory rootfs qt exists and can be reused."
	fi
}
