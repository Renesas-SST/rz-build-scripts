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

	# Create destination directories. Yocto's meta-renesas libpisp_git.bb
	# installs under plain /usr/lib (no multiarch aarch64-linux-gnu subdir).
	mkdir -p "${ubuntu_rootfs}${install_prefix}/lib"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/include"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/share/libpisp"

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
			echo "✗ NOT FOUND or EMPTY: ${src_dir}"
			failed=$((failed + 1))
			return 1
		fi
	}

	# Helper function to copy a required file, failing hard if missing
	copy_required_file() {
		local src_file="$1"
		local dst_dir="$2"

		if [ ! -f "${yocto_rootfs}${src_file}" ]; then
			echo "ERROR: Required libpisp file is missing: ${src_file}"
			failed=$((failed + 1))
			return 1
		fi

		mkdir -p "$dst_dir"
		cp -v "${yocto_rootfs}${src_file}" "$dst_dir/"
		copied=$((copied + 1))
		echo "✓ Copied required file: ${src_file}"
	}

	# ===== Copy libpisp shared library (required) =====
	# Yocto ships the real libpisp.so.1.Y.Z file plus libpisp.so and
	# libpisp.so.1 symlinks (no bare .so.0). Copy the whole family with
	# -P so the symlinks are preserved instead of dereferenced. This is
	# the only artifact this script provides, so a miss fails the install.
	echo ""
	echo "Copying libpisp libraries..."
	if compgen -G "${yocto_rootfs}${install_prefix}/lib/libpisp.so*" > /dev/null; then
		cp -Pv "${yocto_rootfs}${install_prefix}"/lib/libpisp.so* "${ubuntu_rootfs}${install_prefix}/lib/"
		copied=$((copied + 1))
		echo "✓ Copied: libpisp.so* (real file + symlinks)"
	else
		echo "ERROR: Required libpisp library is missing: ${install_prefix}/lib/libpisp.so*"
		failed=$((failed + 1))
		return 1
	fi

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

	# ===== Verify installation =====
	echo ""
	echo "libpisp copy summary:"
	echo "  Copied: $copied"
	echo "  Missing: $failed"
	echo "SUCCESS: libpisp library copied to Ubuntu rootfs"
	return 0
}
