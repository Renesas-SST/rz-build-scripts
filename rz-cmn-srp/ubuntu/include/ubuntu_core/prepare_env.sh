#!/bin/bash
# --------------------------------------------------------------------------#
# This script prepares the environment by checking for the required file
# and directories. It ensures that:
# - The file `renesas-ubuntu.tar.bz2` exists.
# - The `rootfs` directory is removed if it exists. This function only works if 
# CLEAN_ALL is set to 1 in config.ini
# - The `qt_rootfs_source` directory can be reused if it exists.
# --------------------------------------------------------------------------#

function prepare_env() {
	if [ -d "rootfs" ]; then
		rm -rf "rootfs"
		echo "Directory 'rootfs' removed."
	fi

	if [ -d "qt_rootfs_source" ] || [ -d "rootfs_qt" ]; then
		echo "Directory rootfs qt exists and can be reused."
	fi
}
