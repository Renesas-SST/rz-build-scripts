#!/bin/bash

sudo apt install rsync -y
install_imdt_utils() {
	if [ -n "$1" ]; then
		if [ ! -e "$1" ]; then
			echo "ubuntu rootfs doesn't exist"
			return 1
		fi
		rootfs=$1
		work_dir=$1
	else
		rootfs='rootfs'
		work_dir='rootfs'
	fi

	if [ -n "$2" ]; then
		if [ ! -e "$2" ]; then
			echo "qt rootfs source doesn't exist"
			return 1
		fi
		wic_rootfs=$2
	else
		wic_rootfs='qt_rootfs_source'
	fi

	set -x 

	#----------------------------copy imdt utils----------------------------
	sudo mkdir -p $rootfs/opt/imdt
	sudo rsync -avl "$wic_rootfs/opt/imdt/" "$rootfs/opt/imdt/"

	set +x
}
