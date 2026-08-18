#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Copy libcamera framework with R-Car Gen4 ISP pipeline support from Yocto
# rootfs to Ubuntu rootfs. Includes IPA plugins and sensor tuning files.
# --------------------------------------------------------------------------#

install_libcamera() {
	local yocto_rootfs="${1:-.}"
	local ubuntu_rootfs="${2:-.}"
	local install_prefix="${3:-/usr}"

	# Convert to absolute paths
	if [[ "$yocto_rootfs" != /* ]]; then
		yocto_rootfs="$(cd "$yocto_rootfs" 2>/dev/null && pwd)" || yocto_rootfs="${PWD}/${yocto_rootfs}"
	fi
	if [[ "$ubuntu_rootfs" != /* ]]; then
		ubuntu_rootfs="$(cd "$ubuntu_rootfs" 2>/dev/null && pwd)" || ubuntu_rootfs="${PWD}/${ubuntu_rootfs}"
	fi

	# Validate inputs
	if [ ! -d "$yocto_rootfs" ]; then
		echo "ERROR: Yocto rootfs directory does not exist: $yocto_rootfs"
		return 1
	fi

	if [ ! -d "$ubuntu_rootfs" ]; then
		echo "ERROR: Ubuntu rootfs directory does not exist: $ubuntu_rootfs"
		return 1
	fi

	echo "Copying libcamera framework with R-Car Gen4 ISP from Yocto rootfs..."

	# Create destination directories
	mkdir -p "${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/lib/libcamera/ipa"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/include"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/bin"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/share/libcamera/ipa/rcar"

	local copied=0

	# Helper function to copy files with validation
	copy_file() {
		local src_file="$1"
		local dst_dir="$2"

		if [ -f "${yocto_rootfs}${src_file}" ]; then
			mkdir -p "$dst_dir"
			cp -v "${yocto_rootfs}${src_file}" "$dst_dir/" || return 1
			copied=$((copied + 1))
			echo "✓ Copied: ${src_file}"
			return 0
		else
			return 1
		fi
	}

	# Helper function to copy directories with validation
	copy_dir() {
		local src_dir="$1"
		local dst_dir="$2"

		if [ -d "${yocto_rootfs}${src_dir}" ] && [ -n "$(ls -A "${yocto_rootfs}${src_dir}" 2>/dev/null)" ]; then
			mkdir -p "$dst_dir"
			cp -rv "${yocto_rootfs}${src_dir}"/* "$dst_dir/" 2>/dev/null || true
			copied=$((copied + 1))
			echo "✓ Copied directory: ${src_dir}"
			return 0
		else
			return 1
		fi
	}

	# ===== Copy libcamera core libraries =====
	echo ""
	echo "Copying libcamera libraries..."
	copy_file "${install_prefix}/lib/aarch64-linux-gnu/libcamera.so.0" \
		"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
	copy_file "${install_prefix}/lib/aarch64-linux-gnu/libcamera-base.so.0" \
		"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"

	# ===== Copy libcamera IPA plugins =====
	echo ""
	echo "Copying libcamera IPA plugins..."
	copy_dir "${install_prefix}/lib/libcamera/ipa/rcar" \
		"${ubuntu_rootfs}${install_prefix}/lib/libcamera/ipa/rcar"
	copy_dir "${install_prefix}/lib/libcamera/ipa/rkisp1" \
		"${ubuntu_rootfs}${install_prefix}/lib/libcamera/ipa/rkisp1"

	# ===== Copy libcamera tools =====
	echo ""
	echo "Copying libcamera tools..."
	copy_file "${install_prefix}/bin/libcamera-ctl" "${ubuntu_rootfs}${install_prefix}/bin"
	copy_file "${install_prefix}/bin/libcamera-hello" "${ubuntu_rootfs}${install_prefix}/bin"

	# ===== Copy sensor tuning files =====
	echo ""
	echo "Copying sensor tuning files..."
	copy_file "${install_prefix}/share/libcamera/ipa/rcar/imx219.yaml" \
		"${ubuntu_rootfs}${install_prefix}/share/libcamera/ipa/rcar"
	copy_file "${install_prefix}/share/libcamera/ipa/rcar/imx708.yaml" \
		"${ubuntu_rootfs}${install_prefix}/share/libcamera/ipa/rcar"

	# Copy entire IPA directory for all tuning files
	copy_dir "${install_prefix}/share/libcamera/ipa" \
		"${ubuntu_rootfs}${install_prefix}/share/libcamera/ipa"

	# ===== Copy headers =====
	echo ""
	echo "Copying libcamera headers..."
	copy_dir "${install_prefix}/include/libcamera" \
		"${ubuntu_rootfs}${install_prefix}/include/libcamera"

	# ===== Create library symlinks =====
	echo ""
	echo "Creating libcamera library symlinks..."
	setup_libcamera_symlinks "${ubuntu_rootfs}" "${install_prefix}"

	# ===== Verify installation =====
	echo ""
	echo "libcamera copy summary:"
	echo "  Copied: $copied components"

	if [ -f "${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu/libcamera.so.0" ] || \
	   [ -d "${ubuntu_rootfs}${install_prefix}/lib/libcamera/ipa" ]; then
		echo "SUCCESS: libcamera with R-Car Gen4 ISP copied to Ubuntu rootfs"
		return 0
	else
		echo "WARNING: libcamera components not fully found in Yocto rootfs"
		echo "Some components may need to be installed via apt"
		return 0
	fi
}

setup_libcamera_symlinks() {
	local ubuntu_rootfs="$1"
	local install_prefix="$2"
	local lib_dir="${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"

	cd "$lib_dir" 2>/dev/null || return 0

	# Create main symlinks
	if [ -f "libcamera.so.0" ] && [ ! -L "libcamera.so" ]; then
		ln -sf libcamera.so.0 libcamera.so
		echo "✓ Created symlink: libcamera.so → libcamera.so.0"
	fi

	if [ -f "libcamera-base.so.0" ] && [ ! -L "libcamera-base.so" ]; then
		ln -sf libcamera-base.so.0 libcamera-base.so
		echo "✓ Created symlink: libcamera-base.so → libcamera-base.so.0"
	fi
}
