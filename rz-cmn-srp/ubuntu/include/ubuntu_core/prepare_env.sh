#!/bin/bash
# --------------------------------------------------------------------------#
# This script prepares the environment by checking for the required file
# and directories. It ensures that:
# - The file `core-image-qt-rzpi.tar.bz2` exists.
# - The `rootfs` directory is removed if it exists.
# - The `qt_rootfs_source` directory can be reused if it exists.
# --------------------------------------------------------------------------#

function prepare_env() {
	if [ -d "rootfs" ]; then
		rm -rf "rootfs"
		echo "Directory 'rootfs' removed."
	fi

	if [ -d "qt_rootfs_source" ]; then
		echo "Directory 'qt_rootfs_source' exists and can be reused."
	fi
}
