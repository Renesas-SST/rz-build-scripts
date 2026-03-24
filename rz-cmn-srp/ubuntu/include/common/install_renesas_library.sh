#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# The script install the libraries and headers for mmngr, drpai, and u-dma-buf, 
# as well as OpenCV accelerated by DRP and its dependencies.
# --------------------------------------------------------------------------#

. ${SCRIPT_DIR}/config.ini

install_drpai() {
	# Headers
	sudo cp ${wic_rootfs}/usr/include/linux/drpai*.h ${rootfs}/usr/include/linux/

	# Libraries
	wget ${LIB_TVM_URL}
	sudo mv libtvm_runtime.so ${rootfs}/usr/lib/aarch64-linux-gnu/

	# If use TVM version latest, change the URL to: https://github.com/renesas-rz/rzv_drp-ai_tvm/tree/main/obj/build_runtime/v2h/lib
	# And copy all files to your rootfs.
}

install_mmngr() {
	# Automatically load the library
	sudo cp ${wic_rootfs}/lib/modules-load.d/mmngr.conf ${rootfs}/etc/modules-load.d/
	sudo cp ${wic_rootfs}/lib/modules-load.d/mmngrbuf.conf ${rootfs}/etc/modules-load.d/

	# Headers
	sudo cp ${wic_rootfs}/usr/local/include/mmngr_public_cmn.h ${rootfs}/usr/include/
	sudo cp ${wic_rootfs}/usr/local/include/mmngr_private_cmn.h ${rootfs}/usr/include/
	sudo cp ${wic_rootfs}/usr/local/include/mmngr_buf_private_cmn.h ${rootfs}/usr/include/
	sudo cp ${wic_rootfs}/usr/local/include/mmngr_user_public.h ${rootfs}/usr/include/
	sudo cp ${wic_rootfs}/usr/local/include/mmngr_user_private.h ${rootfs}/usr/include/
	sudo cp ${wic_rootfs}/usr/local/include/mmngr_buf_user_private.h ${rootfs}/usr/include/
	sudo cp ${wic_rootfs}/usr/local/include/mmngr_buf_user_public.h ${rootfs}/usr/include/

	# Libraries
	sudo rsync -avl ${wic_rootfs}/usr/lib/libmmngrbuf.so* ${rootfs}/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl ${wic_rootfs}/usr/lib/libmmngr.so* ${rootfs}/usr/lib/aarch64-linux-gnu/
}

install_renesas_library() {
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

	#install dependencies
	sudo mount -t proc /proc "$work_dir/proc"
	sudo mount -t sysfs /sys "$work_dir/sys"
	sudo mount -o bind /dev "$work_dir/dev"
	sudo mount -o bind /dev/pts "$work_dir/dev/pts"

	# Create essential directories and setup rules for mmngr, drpai, opencv, and u-dma-buf
	# Export the ld config path for Renesas libraries
	sudo chroot "$work_dir" /bin/bash <<'EOF'
	set -x

	# Alow non-root user to use ping command
	sudo setcap cap_net_raw+ep /bin/ping

	# Create Renesas directory structure
	mkdir -p /etc/modules-load.d \
			 /etc/udev/rules.d

	# udev rules
	printf 'KERNEL=="rgnmmbuf", MODE="0666"\n' > etc/udev/rules.d/99-mmngrbuf.rules
	printf 'KERNEL=="rgnmm", MODE="0666"\n'    > etc/udev/rules.d/99-mmngr.rules
	printf 'KERNEL=="drpai0", MODE="0666"\n'   > etc/udev/rules.d/99-drpai.rules
	printf 'KERNEL=="drp1", MODE="0666"\n'     > etc/udev/rules.d/99-drp.rules
EOF

	sudo umount "$work_dir/proc"
	sudo umount "$work_dir/sys"
	sudo umount "$work_dir/dev/pts"
	sudo umount "$work_dir/dev"

	# Porting mmngr
	install_mmngr

	# Porting drpai
	install_drpai
}
