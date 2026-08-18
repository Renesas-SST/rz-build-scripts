#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Copy libpisp (PiSP - Raspberry Pi ISP) library from Yocto rootfs to Ubuntu rootfs.
# Includes libraries, headers, and tuning configuration files.
# --------------------------------------------------------------------------#

install_libpisp() {
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

	echo "Copying libpisp library from Yocto rootfs to Ubuntu..."

	# Create destination directories
	mkdir -p "${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/include"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/share/libpisp"

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

	# ===== Copy libpisp shared libraries =====
	echo ""
	echo "Copying libpisp libraries..."
	copy_file "${install_prefix}/lib/aarch64-linux-gnu/libpisp.so.0" \
		"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
	copy_file "${install_prefix}/lib/aarch64-linux-gnu/libpisp.so" \
		"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"

	# ===== Copy libpisp headers =====
	echo ""
	echo "Copying libpisp headers..."
	copy_dir "${install_prefix}/include/libpisp" \
		"${ubuntu_rootfs}${install_prefix}/include/libpisp"

	# ===== Copy libpisp tuning and configuration =====
	echo ""
	echo "Copying libpisp tuning files..."
	copy_dir "${install_prefix}/share/libpisp" \
		"${ubuntu_rootfs}${install_prefix}/share/libpisp"

	# Create symlink for convenient access to tuning files
	mkdir -p "${ubuntu_rootfs}/etc/libpisp"
	if [ ! -L "${ubuntu_rootfs}/etc/libpisp/tuning" ]; then
		ln -sf "${install_prefix}/share/libpisp" "${ubuntu_rootfs}/etc/libpisp/tuning" 2>/dev/null || true
		echo "✓ Created symlink: /etc/libpisp/tuning"
	fi

	# ===== Create library symlinks =====
	echo ""
	echo "Creating libpisp library symlinks..."
	setup_libpisp_symlinks "${ubuntu_rootfs}" "${install_prefix}"

	# ===== Verify installation =====
	echo ""
	echo "libpisp copy summary:"
	echo "  Copied: $copied components"

	if [ -f "${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu/libpisp.so.0" ] || \
	   [ -f "${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu/libpisp.so" ]; then
		echo "SUCCESS: libpisp library copied to Ubuntu rootfs"
		return 0
	else
		echo "WARNING: libpisp library not found in Yocto rootfs"
		echo "This component may not be essential for your configuration"
		return 0
	fi
}

setup_libpisp_symlinks() {
	local ubuntu_rootfs="$1"
	local install_prefix="$2"
	local lib_dir="${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"

	if [ ! -d "$lib_dir" ]; then
		return 0
	fi

	# Create main symlink (using absolute paths, no cd)
	if [ -f "${lib_dir}/libpisp.so.0" ] && [ ! -L "${lib_dir}/libpisp.so" ]; then
		ln -sf libpisp.so.0 "${lib_dir}/libpisp.so"
		echo "✓ Created symlink: libpisp.so → libpisp.so.0"
	fi
}
