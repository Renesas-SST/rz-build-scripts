#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Copy RCar Gen4 PCIe firmware from Yocto rootfs to Ubuntu rootfs.
# This firmware is required for PCIe device support on RCar V4H (Sparrow Hawk).
# --------------------------------------------------------------------------#

install_v4h_pcie_firmware() {
	local yocto_rootfs="${1:-.}"
	local ubuntu_rootfs="${2:-.}"

	# Validate inputs
	if [ ! -d "$yocto_rootfs" ]; then
		echo "ERROR: Yocto rootfs directory does not exist: $yocto_rootfs"
		return 1
	fi

	if [ ! -d "$ubuntu_rootfs" ]; then
		echo "ERROR: Ubuntu rootfs directory does not exist: $ubuntu_rootfs"
		return 1
	fi

	echo "Copying PCIe firmware from Yocto rootfs to Ubuntu..."

	# Create destination directories
	mkdir -p "${ubuntu_rootfs}/lib/firmware"

	local copied=0
	local failed=0

	# Helper function to copy files with validation
	copy_firmware_file() {
		local src_file="$1"
		local dst_dir="$2"

		if [ -f "${yocto_rootfs}${src_file}" ]; then
			mkdir -p "$dst_dir"
			cp -v "${yocto_rootfs}${src_file}" "$dst_dir/" || return 1
			chmod 644 "$dst_dir/$(basename "${src_file}")"
			copied=$((copied + 1))
			echo "✓ Copied: ${src_file}"
			return 0
		else
			echo "✗ NOT FOUND: ${src_file}"
			failed=$((failed + 1))
			return 1
		fi
	}

	# Copy PCIe firmware files from RCAR_V4H_UBUNTU_COPY_ANALYSIS.md
	copy_firmware_file "/lib/firmware/rcar_gen4_pcie.bin" "${ubuntu_rootfs}/lib/firmware"
	copy_firmware_file "/lib/firmware/LICENCE.r8a779g_pcie_phy" "${ubuntu_rootfs}/lib/firmware"
	copy_firmware_file "/lib/firmware/ap1302_ar1335_single_fw.bin" "${ubuntu_rootfs}/lib/firmware"

	# Copy NXP WiFi firmware if available
	if [ -f "${yocto_rootfs}/lib/firmware/nxp/sdiouartiw416_combo_v0.bin" ]; then
		mkdir -p "${ubuntu_rootfs}/lib/firmware/nxp"
		cp -v "${yocto_rootfs}/lib/firmware/nxp/sdiouartiw416_combo_v0.bin" "${ubuntu_rootfs}/lib/firmware/nxp/" || true
		chmod 644 "${ubuntu_rootfs}/lib/firmware/nxp/sdiouartiw416_combo_v0.bin"
		copied=$((copied + 1))
		echo "✓ Copied: /lib/firmware/nxp/sdiouartiw416_combo_v0.bin"
	fi

	# Verify installation
	echo ""
	echo "PCIe firmware copy summary:"
	echo "  Copied: $copied"
	echo "  Missing: $failed"

	if [ -f "${ubuntu_rootfs}/lib/firmware/rcar_gen4_pcie.bin" ]; then
		echo "SUCCESS: PCIe firmware copied to Ubuntu rootfs"
		ls -lh "${ubuntu_rootfs}/lib/firmware/rcar_gen4_pcie.bin"
		return 0
	else
		echo "ERROR: PCIe firmware copy failed"
		return 1
	fi
}
