#!/bin/bash 

install_weston() {
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

	sudo cp $wic_rootfs/usr/bin/openvt.kbd $rootfs/usr/bin

	#install dependencies
	sudo mount -t proc /proc "$work_dir/proc"
	sudo mount -t sysfs /sys "$work_dir/sys"
	sudo mount -o bind /dev "$work_dir/dev"
	sudo mount -o bind /dev/pts "$work_dir/dev/pts"

sudo chroot $work_dir /bin/bash <<'EOF'
	set -x

	sudo mkdir usr/lib/aarch64-linux-gnu/pkgconfig

	sudo ln -s  /usr/bin/openvt.kbd /usr/bin/openvt

	sudo apt-get install libinput-dev libpixman-1-dev libxkbcommon-dev libcairo-dev libpango1.0-dev  kmod  rsync -y
	set +x

	exit
EOF

	sudo umount "$work_dir/proc"
	sudo umount "$work_dir/sys"
	sudo umount "$work_dir/dev/pts"
	sudo umount "$work_dir/dev"

	#----------------------------porting wayland----------------------------
	#bin
	sudo cp $wic_rootfs/usr/bin/wayland* $rootfs/usr/bin

	#include
	cp $wic_rootfs/usr/include/wayland*.h $rootfs/usr/include

	#lib
	sudo cp -pr $wic_rootfs/usr/lib/libwayland* $rootfs/usr/lib/aarch64-linux-gnu

	#pkgconfig  /usr/share/pkgconfig /usr/lib/pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/wayland*.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig

	#share
	sudo mkdir $rootfs/usr/share/aclocal
	sudo cp $wic_rootfs/usr/share/aclocal/wayland* $rootfs/usr/share/aclocal
	sudo cp -r $wic_rootfs/usr/share/wayland $rootfs/usr/share

	#----------------------------porting wayland-protocols----------------------------
	sudo cp -r $wic_rootfs/usr/share/wayland-protocols $rootfs/usr/share
	sudo cp  $wic_rootfs/usr/share/pkgconfig/wayland-protocols.pc $rootfs/usr/share/pkgconfig

	#----------------------------porting weston----------------------------
	#bin
	sudo cp $wic_rootfs/usr/bin/wcap-decode $rootfs/usr/bin
	sudo cp $wic_rootfs/usr/bin/weston* $rootfs/usr/bin

	#include
	cp -r $wic_rootfs/usr/include/libweston-8 $rootfs/usr/include
	cp -r $wic_rootfs/usr/include/weston $rootfs/usr/include

	#lib -p save the attributes
	sudo cp -pr $wic_rootfs/usr/lib/libweston* $rootfs/usr/lib/aarch64-linux-gnu  
	sudo cp -pr $wic_rootfs/usr/lib/weston $rootfs/usr/lib/aarch64-linux-gnu 

	#pkgconfig  /usr/share/pkgconfig /usr/lib/pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/*weston*.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig

	#libffi
	sudo cp $wic_rootfs/usr/lib/pkgconfig/*libffi*.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig
	sudo cp -pr $wic_rootfs/usr/lib/*libffi* $rootfs/usr/lib/aarch64-linux-gnu 

	#libexec
	sudo cp  $wic_rootfs/usr/libexec/weston* $rootfs/usr/libexec 

	#share
	sudo cp -r $wic_rootfs/usr/share/libweston-8 $rootfs/usr/share
	sudo cp  $wic_rootfs/usr/share/pkgconfig/*weston* $rootfs/usr/share/pkgconfig
	sudo cp -r $wic_rootfs/usr/share/wayland-sessions $rootfs/usr/share
	sudo cp -r $wic_rootfs/usr/share/weston $rootfs/usr/share

	#need libjped-dev, ubuntu default install is verson 8, we need is version 62
	#so copy the jpeg from wic
	sudo cp -pr $wic_rootfs/usr/lib/libjpeg* $rootfs/usr/lib/aarch64-linux-gnu  


	#----------------------------porting libdrm----------------------------
	#bin
	sudo cp $wic_rootfs/usr/bin/kms* $rootfs/usr/bin
	sudo cp $wic_rootfs/usr/bin/etn* $rootfs/usr/bin
	sudo cp $wic_rootfs/usr/bin/mode* $rootfs/usr/bin
	sudo cp $wic_rootfs/usr/bin/proptest $rootfs/usr/bin
	sudo cp $wic_rootfs/usr/bin/vbltest $rootfs/usr/bin

	#include
	cp -r $wic_rootfs/usr/include/freedreno $rootfs/usr/include
	cp -r $wic_rootfs/usr/include/libdrm $rootfs/usr/include
	cp -r $wic_rootfs/usr/include/libkms $rootfs/usr/include
	cp -r $wic_rootfs/usr/include/omap $rootfs/usr/include
	cp $wic_rootfs/usr/include/libsync.h $rootfs/usr/include
	cp $wic_rootfs/usr/include/*drm*.h $rootfs/usr/include

	#lib -p save the attributes
	sudo rsync -avl $wic_rootfs/usr/lib/libdrm* $rootfs/usr/lib/aarch64-linux-gnu  
	sudo rsync -avl $wic_rootfs/usr/lib/libkms* $rootfs/usr/lib/aarch64-linux-gnu 

	#pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/libdrm*.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/libkms*.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig

	#share
	sudo cp -r $wic_rootfs/usr/share/libdrm $rootfs/usr/share

	#----------------------------porting gpu mali_um----------------------------
	#include
	cp -r $wic_rootfs/usr/include/CL $rootfs/usr/include
	#cp -r $wic_rootfs/usr/include/CL_GLES $rootfs/usr/include
	cp -r $wic_rootfs/usr/include/GLES $rootfs/usr/include

	#pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/egl.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/gbm.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/glesv1.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/glesv1_cm.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/glesv2.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/OpenCL.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig
	sudo cp $wic_rootfs/usr/lib/pkgconfig/wayland-egl.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig

	#lib -p save the attributes
	sudo cp -p $wic_rootfs/usr/lib/libEGL.so $rootfs/usr/lib/aarch64-linux-gnu  
	sudo cp -p $wic_rootfs/usr/lib/libgbm.so $rootfs/usr/lib/aarch64-linux-gnu 
	sudo cp -p $wic_rootfs/usr/lib/libGLESv1_CM.so $rootfs/usr/lib/aarch64-linux-gnu  
	sudo cp -p $wic_rootfs/usr/lib/libGLESv2.so $rootfs/usr/lib/aarch64-linux-gnu 
	sudo cp -p $wic_rootfs/usr/lib/libOpenCL.so $rootfs/usr/lib/aarch64-linux-gnu  
	# sudo cp -p $wic_rootfs/usr/lib/libwayland-egl.so $rootfs/usr/lib/aarch64-linux-gnu 

	#----------------------------porting gpu mali libmali.so----------------------------
	#lib -p save the attributes
	sudo cp -pr $wic_rootfs/usr/lib/mali_wayland $rootfs/usr/lib/aarch64-linux-gnu  
	sudo cp -pr $wic_rootfs/usr/lib/mali_fbdev $rootfs/usr/lib/aarch64-linux-gnu 
	sudo cp -p $wic_rootfs/usr/lib/libmali.so $rootfs/usr/lib/aarch64-linux-gnu 

	#----------------------------porting gpu ko----------------------------
	# sudo mkdir $rootfs/lib/modules
	# sudo cp -pr $wic_rootfs/lib/modules/* $rootfs/lib/modules
	# sudo cp $wic_rootfs/etc/modules-load.d/* $rootfs/etc/modules-load.d

	#----------------------------porting weston-init----------------------------
	#etc
	sudo cp $wic_rootfs/etc/default/weston $rootfs/etc/default
	sudo cp $wic_rootfs/etc/init.d/weston@ $rootfs/etc/init.d
	sudo cp $wic_rootfs/etc/profile.d/weston.sh $rootfs/etc/profile.d
	sudo cp $wic_rootfs/etc/udev/rules.d/71-weston-drm.rules $rootfs/etc/udev/rules.d
	sudo cp -r $wic_rootfs/etc/xdg/weston $rootfs/etc/xdg

	#this rule is to prevent weston service running
	if [ "$IS_WESTON_ENABLE" -eq 0 ]; then
		echo 'ACTION=="add", SUBSYSTEM=="graphics", KERNEL=="fb0", ENV{SYSTEMD_WANTS}=""' | sudo tee $rootfs/etc/udev/rules.d/99-disable-weston.rules
		echo 'ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card0", ENV{SYSTEMD_WANTS}=""' | sudo tee -a $rootfs/etc/udev/rules.d/99-disable-weston.rules
	fi

	#lib
	sudo cp $wic_rootfs/lib/systemd/system/weston@.service $rootfs/lib/systemd/system

	#bin
	sudo cp $wic_rootfs/usr/bin/weston-start $rootfs/usr/bin
	#sudo cp $wic_rootfs/usr/bin/openvt* $rootfs/usr/bin

	set +x
}