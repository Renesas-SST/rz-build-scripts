#!/bin/bash
# --------------------------------------------------------------------------#
# This script provides functions that help main script handle yocto part
# --------------------------------------------------------------------------#

# This function help main script can build yocto
build_yocto() {
	# Initialize a variable to store the result
	result=""

	# Loop until we find the output file
	while [ -z "$result" ]; do
		# Run bitbake
		su -c "(cd ../rz-sbc/ && IMAGE=renesas-ubuntu DISTRO=ubuntu-tiny ./rzsbc_yocto.sh build)" "$MAIN_USER"

		# Check the output
		result=$(find ../rz-sbc/yocto_rzsbc_board/build/tmp/deploy/ -name '*.tar.bz2' -exec cp {} ./${core_image_qt_name} \; && echo "File copied successfully.")

		# Exit if yocto does not build successfully
		if [ -z "$result" ]; then
			echo "[Yocto]: No output files found. Retrying..."
		else
			echo "Yocto output have been built."
		fi
	done
}

# This function help main script bring wic file to yocto output's directory
move_ubuntu_to_yocto_output(){
	# Check output folder availability
	DIR="../rz-sbc/yocto_rzsbc_board/build/tmp/deploy/images/rzg2l-sbc/target/images"
	if [ -d "$DIR" ]; then
		echo "Found output yocto folder"
		mv "$OUTPUT_WIC"* $DIR
	else
		echo "Output yocto folder not found. Please check the directory path."
		return 1
	fi

	DIR_ROOTFS="../rz-sbc/yocto_rzsbc_board/build/tmp/deploy/images/rzg2l-sbc/target/images/rootfs"
	if [ -d "$DIR_ROOTFS" ]; then
		echo "Found output yocto rootfs folder"
		mv "$OUTPUT_ROOTFS"* $DIR_ROOTFS
	else
		echo "Output yocto rootfs folder not found. Please check the directory path."
		return 1
	fi
}
