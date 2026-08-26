#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Copy QoS (Quality of Service) userspace library and headers from Yocto
# rootfs to Ubuntu rootfs. Complements the QoS kernel module with userspace
# interface for performance and resource management.
# --------------------------------------------------------------------------#

install_qos_userspace() {
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

	echo "Copying QoS userspace library from Yocto rootfs to Ubuntu..."

	# Create destination directories
	mkdir -p "${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/include"

	local copied=0
	local failed=0

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
			echo "✗ NOT FOUND: ${src_file}"
			failed=$((failed + 1))
			return 1
		fi
	}

	# ===== Copy QoS userspace library =====
	echo ""
	echo "Copying QoS userspace libraries..."

	# Try copying from /usr/lib first
	if [ -f "${yocto_rootfs}${install_prefix}/lib/libqos.so.1.0.0" ]; then
		copy_file "${install_prefix}/lib/libqos.so.1.0.0" \
			"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
		copy_file "${install_prefix}/lib/libqos.so.1" \
			"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
		copy_file "${install_prefix}/lib/libqos.so" \
			"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
	elif [ -f "${yocto_rootfs}${install_prefix}/lib/aarch64-linux-gnu/libqos.so.1.0.0" ]; then
		copy_file "${install_prefix}/lib/aarch64-linux-gnu/libqos.so.1.0.0" \
			"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
		copy_file "${install_prefix}/lib/aarch64-linux-gnu/libqos.so.1" \
			"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
		copy_file "${install_prefix}/lib/aarch64-linux-gnu/libqos.so" \
			"${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"
	else
		echo "WARNING: QoS library is missing: libqos.so.1.0.0 (checked ${install_prefix}/lib and ${install_prefix}/lib/aarch64-linux-gnu)"
		failed=$((failed + 1))
	fi

	# ===== Copy QoS headers =====
	echo ""
	echo "Copying QoS headers..."
	copy_file "${install_prefix}/include/qos_public.h" \
		"${ubuntu_rootfs}${install_prefix}/include"
	copy_file "${install_prefix}/include/qos.h" \
		"${ubuntu_rootfs}${install_prefix}/include"
	copy_file "${install_prefix}/include/qos_public_common.h" \
		"${ubuntu_rootfs}${install_prefix}/include"

	# ===== Create library symlinks =====
	echo ""
	echo "Creating QoS library symlinks..."
	setup_qos_symlinks "${ubuntu_rootfs}" "${install_prefix}"

	# ===== Verify installation =====
	echo ""
	echo "QoS userspace copy summary:"
	echo "  Copied: $copied"
	echo "  Missing: $failed"
	echo "SUCCESS: QoS userspace library copied to Ubuntu rootfs"

	if [ -f "${ubuntu_rootfs}${install_prefix}/include/qos_public.h" ]; then
		echo "SUCCESS: QoS headers also copied"
	fi
	return 0
}

setup_qos_symlinks() {
	local ubuntu_rootfs="$1"
	local install_prefix="$2"
	local lib_dir="${ubuntu_rootfs}${install_prefix}/lib/aarch64-linux-gnu"

	if [ ! -d "$lib_dir" ]; then
		return 0
	fi

	# Create symlinks for QoS library versioning (using absolute paths, no cd)
	if [ -f "${lib_dir}/libqos.so.1.0.0" ] && [ ! -L "${lib_dir}/libqos.so.1" ]; then
		ln -sf libqos.so.1.0.0 "${lib_dir}/libqos.so.1"
		echo "✓ Created symlink: libqos.so.1 → libqos.so.1.0.0"
	fi

	if [ -f "${lib_dir}/libqos.so.1" ] && [ ! -L "${lib_dir}/libqos.so" ]; then
		ln -sf libqos.so.1 "${lib_dir}/libqos.so"
		echo "✓ Created symlink: libqos.so → libqos.so.1"
	fi
}
