#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Copy libcamera framework with the rkisp1 ISP pipeline support (R-Car Gen4
# uses the rkisp1 driver/IPA, not a dedicated "rcar" IPA) from Yocto rootfs
# to Ubuntu rootfs. Includes IPA plugins and sensor tuning files.
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

	echo "Copying libcamera framework (rkisp1 pipeline) from Yocto rootfs..."

	# Create destination directories. Yocto's meta-renesas libcamera_git.bb
	# installs under plain /usr/lib (no multiarch aarch64-linux-gnu subdir).
	mkdir -p "${ubuntu_rootfs}${install_prefix}/lib"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/lib/libcamera/ipa"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/include"
	mkdir -p "${ubuntu_rootfs}${install_prefix}/share/libcamera/ipa/rkisp1"

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
			echo "ERROR: Required libcamera file is missing: ${src_file}"
			failed=$((failed + 1))
			return 1
		fi

		mkdir -p "$dst_dir"
		cp -v "${yocto_rootfs}${src_file}" "$dst_dir/"
		copied=$((copied + 1))
		echo "✓ Copied required file: ${src_file}"
	}

	# ===== Copy libcamera core libraries (required) =====
	# Yocto ships each lib as a real ${name}.so.X.Y.Z file plus ${name}.so
	# and ${name}.so.X.Y symlinks (no bare .so.0). Copy the whole family
	# with -P so the symlinks are preserved instead of dereferenced. Both
	# libraries are load-bearing for anything linking against libcamera,
	# so a miss here fails the whole install.
	echo ""
	echo "Copying libcamera libraries..."
	if compgen -G "${yocto_rootfs}${install_prefix}/lib/libcamera.so*" > /dev/null; then
		cp -Pv "${yocto_rootfs}${install_prefix}"/lib/libcamera.so* "${ubuntu_rootfs}${install_prefix}/lib/"
		copied=$((copied + 1))
		echo "✓ Copied: libcamera.so* (real file + symlinks)"
	else
		echo "ERROR: Required libcamera library is missing: ${install_prefix}/lib/libcamera.so*"
		failed=$((failed + 1))
		return 1
	fi

	if compgen -G "${yocto_rootfs}${install_prefix}/lib/libcamera-base.so*" > /dev/null; then
		cp -Pv "${yocto_rootfs}${install_prefix}"/lib/libcamera-base.so* "${ubuntu_rootfs}${install_prefix}/lib/"
		copied=$((copied + 1))
		echo "✓ Copied: libcamera-base.so* (real file + symlinks)"
	else
		echo "ERROR: Required libcamera-base library is missing: ${install_prefix}/lib/libcamera-base.so*"
		failed=$((failed + 1))
		return 1
	fi

	# ===== Copy libcamera IPA plugins (required) =====
	# R-Car Gen4's ISP is driven through the rkisp1 driver/IPA; there is
	# no separate "rcar" IPA module, and the .so modules sit flat in
	# .../ipa/ (no per-pipeline subdirectory). Without the IPA module
	# libcamera enumerates the camera but every capture request fails,
	# so treat a miss here the same as a missing core library.
	echo ""
	echo "Copying libcamera IPA plugins..."
	copy_dir "${install_prefix}/lib/libcamera/ipa" \
		"${ubuntu_rootfs}${install_prefix}/lib/libcamera/ipa" || return 1

	# ===== Copy libcamera IPA proxy workers (required) =====
	# The rkisp1 IPA runs in an isolated process started through
	# rkisp1_ipa_proxy from libexec/libcamera. Without it libcamera cannot
	# start the camera ("Failed to get proxy worker path"), so a miss here
	# fails the install like the IPA module itself.
	echo ""
	echo "Copying libcamera IPA proxy worker..."
	mkdir -p "${ubuntu_rootfs}${install_prefix}/libexec/libcamera"
	copy_required_file "${install_prefix}/libexec/libcamera/rkisp1_ipa_proxy" \
		"${ubuntu_rootfs}${install_prefix}/libexec/libcamera" || return 1
	chmod 755 "${ubuntu_rootfs}${install_prefix}/libexec/libcamera/rkisp1_ipa_proxy"

	# ===== Copy sensor tuning files =====
	echo ""
	echo "Copying sensor tuning files..."
	copy_dir "${install_prefix}/share/libcamera/ipa/rkisp1" \
		"${ubuntu_rootfs}${install_prefix}/share/libcamera/ipa/rkisp1"

	# ===== Copy headers =====
	echo ""
	echo "Copying libcamera headers..."
	copy_dir "${install_prefix}/include/libcamera" \
		"${ubuntu_rootfs}${install_prefix}/include/libcamera"

	# ===== Verify installation =====
	echo ""
	echo "libcamera copy summary:"
	echo "  Copied: $copied"
	echo "  Missing: $failed"
	echo "SUCCESS: libcamera (rkisp1 pipeline) copied to Ubuntu rootfs"
	return 0
}

# --------------------------------------------------------------------------#
# Description:
# Userspace camera tools for the Ubuntu image: the libcamera GStreamer plugin
# and the "cam" tool from the Yocto rootfs. The GStreamer core and the other
# plugins come from the Ubuntu packages (apt), only libgstlibcamera.so is taken
# from Yocto. "cam -l" is required by Camshark and v4l2-init.sh.
# --------------------------------------------------------------------------#
install_libcamera_userspace() {
	local yocto_rootfs="${1:-.}"
	local ubuntu_rootfs="${2:-.}"
	local gst_dir="${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/gstreamer-1.0"

	if [ ! -d "$yocto_rootfs" ] || [ ! -d "$ubuntu_rootfs" ]; then
		echo "ERROR: install_libcamera_userspace: rootfs directory does not exist"
		return 1
	fi

	echo "Copying libcamera GStreamer plugin and cam tool..."

	if [ ! -f "${yocto_rootfs}/usr/lib/gstreamer-1.0/libgstlibcamera.so" ]; then
		echo "ERROR: Required file is missing: /usr/lib/gstreamer-1.0/libgstlibcamera.so"
		return 1
	fi
	mkdir -p "$gst_dir"
	cp -v "${yocto_rootfs}/usr/lib/gstreamer-1.0/libgstlibcamera.so" "$gst_dir/" || return 1
	chmod 644 "${gst_dir}/libgstlibcamera.so"

	if [ ! -f "${yocto_rootfs}/usr/bin/cam" ]; then
		echo "ERROR: Required file is missing: /usr/bin/cam"
		return 1
	fi
	mkdir -p "${ubuntu_rootfs}/usr/bin"
	cp -v "${yocto_rootfs}/usr/bin/cam" "${ubuntu_rootfs}/usr/bin/cam" || return 1
	chmod 755 "${ubuntu_rootfs}/usr/bin/cam"

	# cam is linked against libjpeg.so.62 (libjpeg-turbo of Yocto); Ubuntu only
	# has libjpeg.so.8. A different soname, so both can be installed together.
	if compgen -G "${yocto_rootfs}/usr/lib/libjpeg.so.62*" > /dev/null; then
		cp -Pv "${yocto_rootfs}"/usr/lib/libjpeg.so.62* "${ubuntu_rootfs}/usr/lib/" || return 1
	else
		echo "ERROR: Required file is missing: /usr/lib/libjpeg.so.62*"
		return 1
	fi

	echo "SUCCESS: libgstlibcamera.so, cam and libjpeg.so.62 copied to Ubuntu rootfs"
	return 0
}

# --------------------------------------------------------------------------#
# Description:
# Check that every shared library needed by the camera binaries exists in the
# Ubuntu rootfs. Run it after the apt packages are installed. Prints
# "MISSING" lines and returns 1 when something cannot be resolved.
# --------------------------------------------------------------------------#
verify_libcamera_userspace() {
	local ubuntu_rootfs="${1:-.}"
	local missing=0
	local file lib dir found

	if ! command -v readelf > /dev/null 2>&1; then
		echo "WARNING: readelf not found, skipping the camera library check"
		return 0
	fi

	for file in \
		"usr/bin/cam" \
		"usr/lib/aarch64-linux-gnu/gstreamer-1.0/libgstlibcamera.so" \
		"usr/lib/libcamera.so" \
		"usr/lib/libcamera-base.so" \
		"usr/libexec/libcamera/rkisp1_ipa_proxy" \
		"usr/lib/libcamera/ipa/ipa_rkisp1.so"; do
		if [ ! -e "${ubuntu_rootfs}/${file}" ]; then
			echo "MISSING file: /${file}"
			missing=$((missing + 1))
			continue
		fi
		for lib in $(readelf -d "${ubuntu_rootfs}/${file}" 2>/dev/null | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p'); do
			# A library is found when it exists in any of the loader directories
			# (ls with several paths fails when only one of them is absent, so
			# test them one by one)
			found=0
			for dir in usr/lib/aarch64-linux-gnu lib/aarch64-linux-gnu usr/lib lib; do
				if [ -e "${ubuntu_rootfs}/${dir}/${lib}" ]; then
					found=1
					break
				fi
			done
			if [ "$found" -eq 0 ]; then
				echo "MISSING library for /${file}: ${lib}"
				missing=$((missing + 1))
			fi
		done
	done

	for file in usr/bin/gst-launch-1.0 usr/bin/gst-inspect-1.0 \
		usr/lib/aarch64-linux-gnu/gstreamer-1.0/libgstximagesink.so \
		usr/lib/aarch64-linux-gnu/gstreamer-1.0/libgstvideoconvertscale.so; do
		if [ ! -e "${ubuntu_rootfs}/${file}" ]; then
			echo "MISSING file: /${file}"
			missing=$((missing + 1))
		fi
	done

	if [ "$missing" -ne 0 ]; then
		echo "ERROR: camera userspace check found ${missing} missing item(s)"
		return 1
	fi
	echo "SUCCESS: camera userspace check passed (cam, libgstlibcamera.so and their libraries resolve)"
	return 0
}
