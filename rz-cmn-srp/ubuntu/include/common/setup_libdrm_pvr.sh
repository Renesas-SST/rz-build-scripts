#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Copy libdrm with PowerVR support from Yocto rootfs to Ubuntu rootfs.
# This includes libraries, headers, and pkgconfig files for DRM/KMS support.
# --------------------------------------------------------------------------#

setup_libdrm_pvr() {
	local yocto_rootfs="${1:-.}"
	local ubuntu_rootfs="${2:-.}"

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

	echo "Copying libdrm with PowerVR support from Yocto rootfs to Ubuntu..."

	# Create destination directories
	mkdir -p "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"
	mkdir -p "${ubuntu_rootfs}/usr/include/drm"
	mkdir -p "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/pkgconfig"

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

	# ===== Copy libdrm shared libraries =====
	echo ""
	echo "Copying libdrm libraries..."
	copy_file "/usr/lib/aarch64-linux-gnu/libdrm.so.2" "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"
	copy_file "/usr/lib/aarch64-linux-gnu/libkms.so.1" "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"
	copy_file "/usr/lib/aarch64-linux-gnu/libdrm_freedreno.so.1" "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"

	# ===== Copy libdrm headers =====
	echo ""
	echo "Copying libdrm headers..."
	copy_dir "/usr/include/drm" "${ubuntu_rootfs}/usr/include/drm"

	# ===== Copy pkgconfig files =====
	echo ""
	echo "Copying libdrm pkgconfig files..."
	copy_file "/usr/lib/aarch64-linux-gnu/pkgconfig/libdrm.pc" \
		"${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/pkgconfig"
	copy_file "/usr/lib/aarch64-linux-gnu/pkgconfig/libkms.pc" \
		"${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/pkgconfig"
	copy_file "/usr/lib/aarch64-linux-gnu/pkgconfig/libdrm_freedreno.pc" \
		"${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/pkgconfig"

	# ===== Create symlinks for versioned libraries =====
	echo ""
	echo "Creating library symlinks..."
	setup_libdrm_symlinks "${ubuntu_rootfs}"

	# ===== Verify installation =====
	echo ""
	echo "libdrm copy summary:"
	echo "  Copied: $copied components"

	if [ -f "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/libdrm.so.2" ]; then
		echo "SUCCESS: libdrm copied to Ubuntu rootfs"
		ls -lh "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/libdrm"* 2>/dev/null || true
		return 0
	else
		echo "WARNING: libdrm libraries not found in Yocto rootfs"
		echo "This may not be critical if libdrm is provided by Ubuntu base"
		return 0
	fi
}

setup_libdrm_symlinks() {
	local ubuntu_rootfs="$1"
	local lib_dir="${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"

	if [ ! -d "$lib_dir" ]; then
		return 0
	fi

	# Create main symlinks (using absolute paths, no cd)
	if [ -f "${lib_dir}/libdrm.so.2" ] && [ ! -L "${lib_dir}/libdrm.so" ]; then
		ln -sf libdrm.so.2 "${lib_dir}/libdrm.so"
		echo "✓ Created symlink: libdrm.so → libdrm.so.2"
	fi

	if [ -f "${lib_dir}/libkms.so.1" ] && [ ! -L "${lib_dir}/libkms.so" ]; then
		ln -sf libkms.so.1 "${lib_dir}/libkms.so"
		echo "✓ Created symlink: libkms.so → libkms.so.1"
	fi

	if [ -f "${lib_dir}/libdrm_freedreno.so.1" ] && [ ! -L "${lib_dir}/libdrm_freedreno.so" ]; then
		ln -sf libdrm_freedreno.so.1 "${lib_dir}/libdrm_freedreno.so"
		echo "✓ Created symlink: libdrm_freedreno.so → libdrm_freedreno.so.1"
	fi
}
