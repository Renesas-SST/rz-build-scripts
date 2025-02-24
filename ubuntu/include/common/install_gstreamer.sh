#!/bin/bash

sudo apt install rsync -y
install_gstreamer() {
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

	wic_locale_folder=''$wic_rootfs'/usr/share/locale/'
	work_locale_folder=''$work_dir'/usr/share/locale/'

	set -x 

	sudo mkdir -p ''$work_dir'/usr/lib/aarch64-linux-gnu/pkgconfig'

	#----------------------------porting codec----------------------------
	#etc
	sudo cp -pr $wic_rootfs/etc/omxr $rootfs/etc

	#include 
	sudo cp $wic_rootfs/usr/local/include/OMX*  $rootfs/usr/local/include/

	#lib
	sudo rsync -avl $wic_rootfs/usr/lib64/libomxr* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libuvcs* $rootfs/usr/lib/aarch64-linux-gnu/

	#----------------------------porting vspm----------------------------
	cp $wic_rootfs/usr/local/include/fdp_drv.h  $rootfs/usr/local/include/
	cp $wic_rootfs/usr/local/include/isu_drv.h  $rootfs/usr/local/include/
	cp $wic_rootfs/usr/local/include/vsp_drv.h  $rootfs/usr/local/include/
	cp $wic_rootfs/usr/local/include/vspm_cmn.h  $rootfs/usr/local/include/

	sudo rsync -avl $wic_rootfs/usr/lib64/libvspm* $rootfs/usr/lib/aarch64-linux-gnu/

	#----------------------------porting vspmif----------------------------
	sudo cp $wic_rootfs/usr/local/include/vspm_if.h  $rootfs/usr/local/include/

	#----------------------------porting uvcs_drv----------------------------
	#sudo cp $wic_rootfs/usr/local/include/uvcs_ioctl.h  $rootfs/usr/local/include/

	#----------------------------porting mmngr----------------------------
	#include
	sudo cp $wic_rootfs/usr/local/include/mmngr_private_cmn.h  $rootfs/usr/local/include/
	sudo cp $wic_rootfs/usr/local/include/mmngr_public_cmn.h  $rootfs/usr/local/include/
	sudo cp $wic_rootfs/usr/local/include/mmngr_user_private.h  $rootfs/usr/local/include/
	sudo cp $wic_rootfs/usr/local/include/mmngr_user_public.h  $rootfs/usr/local/include/

	#lib
	sudo rsync -avl $wic_rootfs/usr/lib64/libmmngr* $rootfs/usr/lib/aarch64-linux-gnu/


	#----------------------------porting mmngrbuf----------------------------
	#include
	sudo cp $wic_rootfs/usr/local/include/mmngr_buf_private_cmn.h  $rootfs/usr/local/include/
	sudo cp $wic_rootfs/usr/local/include/mmngr_buf_user_private.h  $rootfs/usr/local/include/
	sudo cp $wic_rootfs/usr/local/include/mmngr_buf_user_public.h $rootfs/usr/local/include/

	#lib
	sudo rsync -avl $wic_rootfs/usr/lib64/libmmngrbuf* $rootfs/usr/lib/aarch64-linux-gnu/

	#----------------------------porting gstreamer1.0----------------------------
	#bin
	sudo cp $wic_rootfs/usr/bin/gst* $rootfs/usr/bin/

	#include
	sudo cp -r $wic_rootfs/usr/include/gstreamer-1.0 $rootfs/usr/include/

	#lib Gst-1.0.typelib  GstBase-1.0.typelib  GstCheck-1.0.typelib  GstController-1.0.typelib  GstNet-1.0.typelib 
	sudo cp -p $wic_rootfs/usr/lib64/girepository-1.0/Gst* $rootfs/usr/lib/aarch64-linux-gnu/girepository-1.0/
	# libgstcoreelements.so
	sudo rsync -avl $wic_rootfs/usr/lib64/gstreamer-1.0 $rootfs/usr/lib/aarch64-linux-gnu/

	sudo rsync -avl $wic_rootfs/usr/lib64/libgst* $rootfs/usr/lib/aarch64-linux-gnu/

	#libexec notify -rwsr-xr-x 1 liuxindz liuxindz 61920 Jul 27 12:38 libexec/gstreamer-1.0/gst-ptp-helper   
	sudo rsync -avl $wic_rootfs/usr/libexec/gstreamer-1.0 $rootfs/usr/libexec/

	#pkgconfig  /usr/share/pkgconfig /usr/lib64/pkgconfig
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/gst*.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#share
	sudo cp $wic_rootfs/usr/share/aclocal/gst-element-check-1.0.m4 $rootfs/usr/share/aclocal/
	sudo cp $wic_rootfs/usr/share/gir-1.0/Gst*.gir $rootfs/usr/share/gir-1.0/
	sudo cp $wic_rootfs/usr/share/locale/en_GB/LC_MESSAGES/gst*.mo $rootfs/usr/share/locale/en_GB/LC_MESSAGES/

	#----------------------------porting gstreamer1.0-libav----------------------------
	#depends gstreamer1.0 gstreamer1.0-plugins-base ffmpeg
	#lib
	#sudo rsync -avl $wic_rootfs/usr/lib64/gstreamer-1.0/libgstlibav.so $rootfs/usr/lib/aarch64-linux-gnu/gstreamer-1.0/

	#----------------------------porting gstreamer1.0-omx----------------------------
	#etc 
	sudo cp -p $wic_rootfs/etc/xdg/gstomx.conf $rootfs/etc/xdg/

	#lib
	#sudo rsync -avl $wic_rootfs/usr/lib64/gstreamer-1.0/libgstomx.so $rootfs/usr/lib/aarch64-linux-gnu/gstreamer-1.0/

	#----------------------------porting gstreamer1.0-plugin-vspmfilter----------------------------
	#sudo rsync -avl $wic_rootfs/usr/lib64/gstreamer-1.0/libgstvspmfilter.so $rootfs/usr/lib/aarch64-linux-gnu/gstreamer-1.0/

	#----------------------------porting gstreamer1.0-plugins-base----------------------------
	#etc 
	sudo cp -p $wic_rootfs/etc/gstpbfilter.conf   $rootfs/etc/

	#share
	sudo rsync -avl $wic_rootfs/usr/share/gst-plugins-base $rootfs/usr/share/

	#----------------------------porting gstreamer1.0-plugins-bad----------------------------
	sudo rsync -avl $wic_rootfs/usr/share/gstreamer-1.0 $rootfs/usr/share/

	#----------------------------porting gstreamer1.0-plugins-good----------------------------

	#----------------------------porting gstreamer1.0-plugins-ugly----------------------------

	#----------------------------porting gstreamer1.0-rtsp-server----------------------------

	#----------------------------porting gstreamer plugin----------------------------

	#----------------------------porting v4l2-utils----------------------------
	#usr/bin
	sudo rsync -avl $wic_rootfs/usr/bin/cec-* $rootfs/usr/bin/
	sudo rsync -avl $wic_rootfs/usr/bin/dvb* $rootfs/usr/bin/
	sudo rsync -avl $wic_rootfs/usr/bin/*-ctl $rootfs/usr/bin/
	sudo rsync -avl $wic_rootfs/usr/bin/decode* $rootfs/usr/bin/
	sudo rsync -avl $wic_rootfs/usr/bin/ir* $rootfs/usr/bin/
	sudo rsync -avl $wic_rootfs/usr/bin/v4l2* $rootfs/usr/bin/
	#usr/include
	sudo rsync -avl $wic_rootfs/usr/include/libdvbv5 $rootfs/usr/include
	sudo rsync -avl $wic_rootfs/usr/include/libv4l* $rootfs/usr/include
	sudo rsync -avl $wic_rootfs/usr/include/mediactl $rootfs/usr/include
	#usr/lib64
	sudo rsync -avl $wic_rootfs/usr/lib64/libdvbv5* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libmediactl* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libv4l $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libv4l* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/v4l* $rootfs/usr/lib/aarch64-linux-gnu/

	#usr/sbin
	sudo rsync -avl $wic_rootfs/usr/sbin/v4l2* $rootfs/usr/sbin/

	#----------------------------porting v4l2-init----------------------------
	sudo rsync -avl $wic_rootfs/home/root/v4l2* $rootfs/home/root/
	sudo rsync -avl $wic_rootfs/home/root/v4l2* $rootfs/root/
	#a52
	sudo rsync -avl $wic_rootfs/usr/include/a52dec $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/liba52* $rootfs/usr/lib/aarch64-linux-gnu/

	#sbc
	sudo rsync -avl $wic_rootfs/usr/include/sbc $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libsbc* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/sbc.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#gdk-pixbuf
	sudo rsync -avl $wic_rootfs/usr/include/gdk-pixbuf-2.0 $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libgdk_pixbuf* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp  $wic_rootfs/usr/lib64/girepository-1.0/GdkPix* $rootfs/usr/lib/aarch64-linux-gnu/girepository-1.0/
	sudo rsync -avl $wic_rootfs/usr/lib64/gdk-pixbuf-2.0 $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp  $wic_rootfs/usr/share/gir-1.0/GdkPix* $rootfs/usr/share/gir-1.0/
	sudo cp  $wic_rootfs/usr/share/locale/en_GB/LC_MESSAGES/gdk-pixbuf.mo $rootfs/usr/share/locale/en_GB/LC_MESSAGES/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/gdk-pixbuf-2.0.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#tag
	sudo rsync -avl $wic_rootfs/usr/include/taglib $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libtag* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/taglib* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#faac
	sudo cp  $wic_rootfs/usr/bin/faac $rootfs/usr/bin/
	sudo rsync -avl $wic_rootfs/usr/include/faac* $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libfaac* $rootfs/usr/lib/aarch64-linux-gnu/

	#curl
	sudo rsync -avl $wic_rootfs/usr/include/curl $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libcurl* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp  $wic_rootfs/usr/share/aclocal/libcurl.m4 $rootfs/usr/share/aclocal/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libcurl.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#bayer2raw
	# sudo rsync -avl $wic_rootfs/usr/include/bayer2raw* $rootfs/usr/include/
	# sudo rsync -avl $wic_rootfs/usr/lib64/libbayer2* $rootfs/usr/lib/aarch64-linux-gnu/
	# sudo cp  $wic_rootfs/usr/share/bayer* $rootfs/usr/share/

	#avfileter
	sudo rsync -avl $wic_rootfs/usr/lib64/libavfilter* $rootfs/usr/lib/aarch64-linux-gnu/

	#webp
	sudo rsync -avl $wic_rootfs/usr/include/webp $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libwebp* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libwebp* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#lame 
	sudo rsync -avl $wic_rootfs/usr/include/lame $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libmp3lame* $rootfs/usr/lib/aarch64-linux-gnu/

	#speex
	sudo rsync -avl $wic_rootfs/usr/include/speex $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libspeex* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp  $wic_rootfs/usr/share/aclocal/speex.m4 $rootfs/usr/share/aclocal/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/speex.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#rsvg
	sudo rsync -avl $wic_rootfs/usr/include/librsvg* $rootfs/usr/include/
	sudo cp  $wic_rootfs/usr/share/gir-1.0/Rsvg* $rootfs/usr/share/gir-1.0/
	sudo cp  $wic_rootfs/usr/lib64/girepository-1.0/Rsvg* $rootfs/usr/lib/aarch64-linux-gnu/girepository-1.0/
	sudo rsync -avl $wic_rootfs/usr/lib64/librsvg* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/librsvg* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#libsoup
	sudo rsync -avl $wic_rootfs/usr/include/libsoup* $rootfs/usr/include/
	sudo cp  $wic_rootfs/usr/lib64/girepository-1.0/Soup* $rootfs/usr/lib/aarch64-linux-gnu/girepository-1.0/
	sudo rsync -avl $wic_rootfs/usr/lib64/libsoup* $rootfs/usr/lib/aarch64-linux-gnu/
	#sudo cp  $wic_rootfs/usr/share/gir-1.0/Soup* $rootfs/usr/share/gir-1.0/
	#copy locale LC_MESSAGE
	find "$wic_locale_folder" -type f -name "libsoup.mo" -exec dirname {} \; | while read -r dir; do
		parent_dir=$(dirname "$dir")
		sudo cp -r "$parent_dir" "$work_locale_folder"
	done
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libsoup-2.4.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#faad2
	sudo rsync -avl $wic_rootfs/usr/include/faad.h $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/neaacdec.h $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libfaad* $rootfs/usr/lib/aarch64-linux-gnu/

	#flac
	sudo rsync -avl $wic_rootfs/usr/include/FLAC* $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libFLAC* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/share/aclocal/libFLAC* $rootfs/usr/share/aclocal/
	sudo rsync -avl  $wic_rootfs/usr/share/alsa $rootfs/usr/share/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/flac* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#alsa-lib
	sudo rsync -avl $wic_rootfs/usr/include/alsa $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/asoundlib.h $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/sys/asoundlib.h $rootfs/usr/include/sys/

	sudo rsync -avl $wic_rootfs/usr/lib64/libasound* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libatopology* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/share/aclocal/alsa.m4 $rootfs/usr/share/aclocal/
	sudo rsync -avl  $wic_rootfs/usr/share/alsa $rootfs/usr/share/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/alsa* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#alsa-state
	sudo cp  $wic_rootfs/etc/asound.conf $rootfs/etc/
	sudo cp  $wic_rootfs/etc/init.d/alsa-state $rootfs/etc/init.d/
	sudo rsync -avl  $wic_rootfs/var/lib/alsa $rootfs/var/lib/

	#alsa-plugins
	#sudo rsync -avl $wic_rootfs/etc/alsa $rootfs/etc/
	#sudo rsync -avl $wic_rootfs/usr/lib64/alsa-lib $rootfs/usr/lib/aarch64-linux-gnu/

	#alsa-utils
	sudo rsync -avl $wic_rootfs/lib/systemd/system/alsa* $rootfs/lib/systemd/system/
	sudo rsync -avl  $wic_rootfs/lib/systemd/system/sound.target.wants $rootfs/lib/systemd/system/
	sudo rsync -avl $wic_rootfs/lib/udev/rules.d/*alsa* $rootfs/lib/udev/rules.d/

	sudo rsync -avl  $wic_rootfs/usr/bin/aconnect $rootfs/usr/bin/
	sudo rsync -avl  $wic_rootfs/usr/bin/alsa* $rootfs/usr/bin/
	sudo rsync -avl  $wic_rootfs/usr/bin/aplay* $rootfs/usr/bin/
	sudo rsync -avl  $wic_rootfs/usr/bin/amidi $rootfs/usr/bin/
	sudo rsync -avl  $wic_rootfs/usr/bin/amixer $rootfs/usr/bin/
	sudo rsync -avl  $wic_rootfs/usr/bin/aseqdump $rootfs/usr/bin/
	sudo rsync -avl  $wic_rootfs/usr/bin/aseqnet $rootfs/usr/bin/
	sudo rsync -avl  $wic_rootfs/usr/bin/iecset $rootfs/usr/bin/
	sudo rsync -avl  $wic_rootfs/usr/bin/speaker-test $rootfs/usr/bin/
	sudo rsync -avl  $wic_rootfs/usr/bin/arecord* $rootfs/usr/bin/

	sudo rsync -avl  $wic_rootfs/usr/sbin/alsactl $rootfs/usr/sbin/

	sudo cp -rf $wic_rootfs/usr/share/sounds $rootfs/usr/share/
	find "$wic_locale_folder" -type f -name "alsa-utils.mo" -exec dirname {} \; | while read -r dir; do
		parent_dir=$(dirname "$dir")
		sudo cp -r "$parent_dir" "$work_locale_folder"
	done

	#ffmpeg
	sudo rsync -avl $wic_rootfs/usr/include/libavcodec $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/libavdevice $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/libavfilter $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/libavformat $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/libavutil $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/libavresample $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/libpostproc $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/libswresample $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/include/libswscale $rootfs/usr/include/

	sudo cp $wic_rootfs/usr/bin/ffmpeg $rootfs/usr/bin/
	sudo cp $wic_rootfs/usr/bin/ffprobe $rootfs/usr/bin/
	sudo rsync -avl $wic_rootfs/usr/lib64/libavcodec* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libavdevice* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libavfilter* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libavformat* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libavutil* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libavresample* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libpostproc* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libswresample* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/libswscale* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp -r $wic_rootfs/usr/share/ffmpeg $rootfs/usr/lib/aarch64-linux-gnu/

	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libavcodec.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libavdevice.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libavfilter.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libavformat.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libavutil.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libavresample.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libpostproc.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libswresample.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libswscale.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/


	#libtheora
	sudo rsync -avl $wic_rootfs/usr/include/theora $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libtheora* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/theora* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#x264
	sudo rsync -avl $wic_rootfs/usr/include/x264* $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libx264* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/x264.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#mpeg2dec
	sudo rsync -avl $wic_rootfs/usr/include/mpeg2dec $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libmpeg2* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libmpeg2* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#libmpg123
	sudo rsync -avl $wic_rootfs/usr/include/*123* $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libmpg123* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/*123.pc $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#libtiff
	# sudo cp $wic_rootfs/usr/bin/tiff* $rootfs/usr/bin/
	# sudo cp $wic_rootfs/usr/bin/fax* $rootfs/usr/bin/
	# sudo cp $wic_rootfs/usr/bin/pal2rgb $rootfs/usr/bin/
	# sudo cp $wic_rootfs/usr/bin/*tiff $rootfs/usr/bin/
	# sudo rsync -avl $wic_rootfs/usr/include/tiff* $rootfs/usr/include/
	# sudo rsync -avl $wic_rootfs/usr/lib64/libtiff* $rootfs/usr/lib/aarch64-linux-gnu/
	# sudo cp $wic_rootfs/usr/lib64/pkgconfig/libtiff* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#libpng
	sudo rsync -avl $wic_rootfs/usr/include/*png* $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libpng* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libpng* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#pulseaudio
	sudo rsync -avl $wic_rootfs/usr/include/pulse $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/etc/pulse  $rootfs/etc/
	sudo rsync -avl $wic_rootfs/usr/lib64/libpulse* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo rsync -avl $wic_rootfs/usr/lib64/pulseaudio $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libpulse* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#libcroco
	sudo rsync -avl $wic_rootfs/usr/include/libcroco* $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libcroco* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/libcroco* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#libvorbis
	sudo rsync -avl $wic_rootfs/usr/include/vorbis $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libvorbis* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/vorbis* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#libsndfile
	sudo rsync -avl $wic_rootfs/usr/include/sndfile* $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/libsndfile* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/sndfile* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#orc
	sudo rsync -avl $wic_rootfs/usr/include/orc* $rootfs/usr/include/
	sudo rsync -avl $wic_rootfs/usr/lib64/liborc* $rootfs/usr/lib/aarch64-linux-gnu/
	sudo cp $wic_rootfs/usr/lib64/pkgconfig/orc* $rootfs/usr/lib/aarch64-linux-gnu/pkgconfig/

	#----------------------------porting kernel ko----------------------------
	# sudo mkdir $rootfs/lib/modules
	# sudo cp -pr $wic_rootfs/lib/modules/* $rootfs/lib/modules
	# sudo cp $wic_rootfs/etc/modules-load.d/* $rootfs/etc/modules-load.d

	set +x
}