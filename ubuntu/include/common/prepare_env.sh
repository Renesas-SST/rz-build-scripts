#!/bin/bash
# --------------------------------------------------------------------------#
# This script prepares the environment by checking for the required file
# and directories. It ensures that:
# - The file `core-image-qt-rzpi.tar.bz2` exists.
# - The `rootfs` directory is removed if it exists. This function only works if 
# CLEAN_ALL is set to 1 in config.ini
# - The `qt_rootfs_source` directory can be reused if it exists.
# --------------------------------------------------------------------------#

file="$core_image_qt_name"
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
	fi

	if [ -d "qt_rootfs_source" ] || [ -d "rootfs_qt" ]; then
		echo "Directory rootfs qt exists and can be reused."
	fi
}
