#!/bin/bash
# --------------------------------------------------------------------------#
# This script prepares the environment by checking for the required file
# and directories. It ensures that:
# - The file `core-image-qt-rzpi.tar.bz2` exists.
# - The `rootfs` directory is removed if it exists.
# - The `qt_rootfs_source` directory can be reused if it exists.
# --------------------------------------------------------------------------#

file="$core_image_qt_name"

function prepare_env() {

	# Check env
	if [ ! -f "$file" ]; then
		echo "File '$file' not found. Please copy it over."
		return 1
	fi

	if [ -d "rootfs" ]; then
		rm -rf "rootfs"
		echo "Directory 'rootfs' removed."
	fi

	if [ -d "qt_rootfs_source" ]; then
		echo "Directory 'qt_rootfs_source' exists and can be reused."
	fi
}
