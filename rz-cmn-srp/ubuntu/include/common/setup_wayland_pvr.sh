#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Copy Wayland/Weston and libraries from Yocto rootfs to Ubuntu rootfs.
# Sets up Wayland client/server libraries and Weston compositor configuration
# for PowerVR GPU rendering support on V4H.
# --------------------------------------------------------------------------#

setup_wayland_pvr() {
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

	echo "Copying Wayland/Weston from Yocto rootfs to Ubuntu..."

	# Create required directories
	mkdir -p "${ubuntu_rootfs}/etc/xdg/weston"
	mkdir -p "${ubuntu_rootfs}/usr/bin"
	mkdir -p "${ubuntu_rootfs}/etc/systemd/system"
	mkdir -p "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"

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
			echo "ERROR: Required Wayland/Weston file is missing: ${src_file}"
			failed=$((failed + 1))
			return 1
		fi

		mkdir -p "$dst_dir" || { failed=$((failed + 1)); return 1; }
		cp -v "${yocto_rootfs}${src_file}" "$dst_dir/" || { failed=$((failed + 1)); return 1; }
		copied=$((copied + 1))
		echo "✓ Copied required file: ${src_file}"
		return 0
	}

	# ===== Copy Wayland client/server libraries =====
	echo ""
	echo "Copying Wayland libraries..."
	copy_required_file "/usr/lib/libwayland-client.so.0" \
		"${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu" || return 1
	copy_file "/usr/lib/libwayland-server.so.0" \
		"${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"
	copy_file "/usr/lib/libwayland-cursor.so.0" \
		"${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"
	copy_file "/usr/lib/libwayland-egl.so.1" \
		"${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"

	# ===== Copy Weston binaries and libraries =====
	echo ""
	echo "Copying Weston compositor..."
	copy_required_file "/usr/bin/weston" "${ubuntu_rootfs}/usr/bin" || return 1
	copy_file "/usr/bin/weston-info" "${ubuntu_rootfs}/usr/bin"
	copy_file "/usr/bin/weston-launch" "${ubuntu_rootfs}/usr/bin"

	# Copy Weston modules and backends
	echo ""
	echo "Copying Weston modules..."
	copy_dir "/usr/lib/weston" \
		"${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/weston"

	# ===== Copy Weston configuration =====
	echo ""
	echo "Copying Weston configuration..."
	copy_file "/etc/xdg/weston/weston.ini" "${ubuntu_rootfs}/etc/xdg/weston"

	# ===== Create default Weston configuration if not copied =====
	if [ ! -f "${ubuntu_rootfs}/etc/xdg/weston/weston.ini" ]; then
		echo "Creating Weston configuration..."
		mkdir -p "${ubuntu_rootfs}/etc/xdg/weston"
		cat > "${ubuntu_rootfs}/etc/xdg/weston/weston.ini" <<'EOF'
[core]
backend=drm-backend.so
xwayland=false

[output]
name=HDMI-1
mode=current
transform=normal

[shell]
locking=true
panel-location=top
background-type=solid
background-color=0xff000000

[input-device]
type=touchpad
EOF
		chmod 644 "${ubuntu_rootfs}/etc/xdg/weston/weston.ini"
		echo "✓ Created: /etc/xdg/weston/weston.ini"
	fi

	# ===== Create library symlinks =====
	echo ""
	echo "Creating Wayland library symlinks..."
	setup_wayland_symlinks "${ubuntu_rootfs}"

	# ===== Verify installation =====
	echo ""
	echo "Wayland/Weston copy summary:"
	echo "  Copied: $copied"
	echo "  Missing: $failed"
	echo "SUCCESS: Wayland/Weston copied to Ubuntu rootfs"
	return 0
}

setup_wayland_symlinks() {
	local ubuntu_rootfs="$1"
	local lib_dir="${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu"

	if [ ! -d "$lib_dir" ]; then
		return 0
	fi

	# Create symlinks for Wayland libraries (using absolute paths, no cd)
	if [ -f "${lib_dir}/libwayland-client.so.0" ] && [ ! -L "${lib_dir}/libwayland-client.so" ]; then
		ln -sf libwayland-client.so.0 "${lib_dir}/libwayland-client.so"
		echo "✓ Created symlink: libwayland-client.so → libwayland-client.so.0"
	fi

	if [ -f "${lib_dir}/libwayland-server.so.0" ] && [ ! -L "${lib_dir}/libwayland-server.so" ]; then
		ln -sf libwayland-server.so.0 "${lib_dir}/libwayland-server.so"
		echo "✓ Created symlink: libwayland-server.so → libwayland-server.so.0"
	fi

	if [ -f "${lib_dir}/libwayland-cursor.so.0" ] && [ ! -L "${lib_dir}/libwayland-cursor.so" ]; then
		ln -sf libwayland-cursor.so.0 "${lib_dir}/libwayland-cursor.so"
		echo "✓ Created symlink: libwayland-cursor.so → libwayland-cursor.so.0"
	fi

	if [ -f "${lib_dir}/libwayland-egl.so.1" ] && [ ! -L "${lib_dir}/libwayland-egl.so" ]; then
		ln -sf libwayland-egl.so.1 "${lib_dir}/libwayland-egl.so"
		echo "✓ Created symlink: libwayland-egl.so → libwayland-egl.so.1"
	fi
}
