#!/bin/bash

# Copy the Sparrow-Hawk camera helper scripts (/opt/rcar-v4h-sparrow-hawk, installed by the
# sparrow-hawk-camera-utils recipe of meta-renesas) from the Yocto rootfs to the Ubuntu rootfs.
# $1: Ubuntu rootfs (default: rootfs)
# $2: Yocto rootfs that holds /opt/rcar-v4h-sparrow-hawk (default: qt_rootfs_source)
# A missing source directory is not an error: the recipe exists only in newer meta-renesas.
install_sparrow_hawk_utils() {
	local rootfs="${1:-rootfs}"
	local wic_rootfs="${2:-qt_rootfs_source}"
	local src="$wic_rootfs/opt/rcar-v4h-sparrow-hawk"

	if [ ! -d "$rootfs" ]; then
		echo "ubuntu rootfs doesn't exist"
		return 1
	fi

	if [ ! -d "$src" ]; then
		echo "WARNING: $src not found, the Sparrow-Hawk camera scripts are not installed."
		return 0
	fi

	sudo mkdir -p "$rootfs/opt/rcar-v4h-sparrow-hawk"
	sudo rsync -avl "$src/" "$rootfs/opt/rcar-v4h-sparrow-hawk/" || return 1
	echo "Installed /opt/rcar-v4h-sparrow-hawk"
	return 0
}
