#!/bin/bash
# --------------------------------------------------------------------------#
# This script provides functions that help main script handle yocto part
# --------------------------------------------------------------------------#

# This function help main script bring wic file to yocto output's directory

move_ubuntu_to_yocto_output(){
	# Check output folder availability
	DIR="yocto_rzsbc_board/build/tmp/deploy/images/rzg2l-sbc/target/images"
	if [ -d "$DIR" ]; then
		echo "Found output yocto folder"
		mv "$OUTPUT_WIC"* $DIR
	else
		echo "Output yocto folder not found. Please check the directory path."
		return 1
	fi

	DIR_ROOTFS="yocto_rzsbc_board/build/tmp/deploy/images/rzg2l-sbc/target/images/rootfs"
	if [ -d "$DIR_ROOTFS" ]; then
		echo "Found output yocto rootfs folder"
		mv "$OUTPUT_ROOTFS"* $DIR_ROOTFS
	else
		echo "Output yocto rootfs folder not found. Please check the directory path."
		return 1
	fi
}
