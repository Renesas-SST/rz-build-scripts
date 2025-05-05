#!/bin/bash
# --------------------------------------------------------------------------#
# This script provides functions that help main script handle yocto part
# --------------------------------------------------------------------------#

# This function help main script can build yocto
build_yocto() {
	# Run the build and wait for it to finish
	su -c "(cd ../yocto/ && IMAGE=renesas-ubuntu DISTRO=ubuntu-tiny ./rzsbc_yocto.sh build)" "$MAIN_USER"

	if [ $? -ne 0 ]; then
		echo "[Yocto]: Build script failed. Exiting."
		exit 1
	fi

	# Find the output file and try to copy it
	output_file=$(find ../yocto/yocto_rzsbc_board/build/tmp/deploy/ -name "${core_image_qt_name}" | head -n 1)

	if [ -z "$output_file" ]; then
		echo "[Yocto]: No output files found."
		exit 1
	fi

	cp "$output_file" "./${core_image_qt_name}"
	if [ $? -eq 0 ]; then
		echo "[Yocto]: File copied successfully."
	else
		echo "[Yocto]: Failed to copy output file."
		exit 1
	fi
}

# This function help main script bring wic file to yocto output's directory
move_ubuntu_to_yocto_output(){
	# Check output folder availability
	DIR="../yocto/yocto_rzsbc_board/build/tmp/deploy/images/rzpi/target/images"
	if [ -d "$DIR" ]; then
		echo "Found output yocto folder"
		mv "$OUTPUT_WIC"* $DIR
	else
		echo "Output yocto folder not found. Please check the directory path."
		return 1
	fi

	DIR_ROOTFS="../yocto/yocto_rzsbc_board/build/tmp/deploy/images/rzpi/target/images/rootfs"
	if [ -d "$DIR_ROOTFS" ]; then
		echo "Found output yocto rootfs folder"
		mv "$OUTPUT_ROOTFS"* $DIR_ROOTFS
	else
		echo "Output yocto rootfs folder not found. Please check the directory path."
		return 1
	fi
}
