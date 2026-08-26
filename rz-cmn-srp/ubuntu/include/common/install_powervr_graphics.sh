#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Copy PowerVR userspace graphics libraries from Yocto rootfs to Ubuntu rootfs.
# These are required for PowerVR GPU rendering stack for V4H boards.
# Includes libraries, firmware, services, and environment configuration.
# --------------------------------------------------------------------------#

install_powervr_graphics() {
	local yocto_rootfs="${1:-.}"
	local ubuntu_rootfs="${2:-.}"
	local pvr_install_dir="${3:-/usr/lib/pvr}"

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

	echo "Copying PowerVR graphics libraries from Yocto rootfs to Ubuntu..."

	# Create destination directories
	mkdir -p "${ubuntu_rootfs}${pvr_install_dir}"
	mkdir -p "${ubuntu_rootfs}/lib/firmware"
	mkdir -p "${ubuntu_rootfs}/usr/include/pvr"
	mkdir -p "${ubuntu_rootfs}/etc/systemd/system"
	mkdir -p "${ubuntu_rootfs}/etc/profile.d"
	mkdir -p "${ubuntu_rootfs}/etc/udev/rules.d"
	mkdir -p "${ubuntu_rootfs}/etc/modules-load.d"

	local copied=0
	local failed=0

	# Helper function to copy files with validation
	copy_file() {
        local pattern="$1"
        local dst_dir="$2"
        local found=0

        mkdir -p "$dst_dir"

        for src in ${yocto_rootfs}${pattern}; do
            if [ -f "$src" ]; then
                cp -v "$src" "$dst_dir/" || return 1
                chmod 644 "$dst_dir/$(basename "$src")"
                copied=$((copied + 1))
                echo "Copied: $(basename "$src")"
                found=1
            fi
        done

        if [ "$found" -eq 0 ]; then
            echo "NOT FOUND: $pattern"
        fi

        return 0
	}

	copy_required_file() {
		local source_file="$1"
		local dst_dir="$2"
		local source_path="${yocto_rootfs}${source_file}"

		if [ ! -f "$source_path" ]; then
			echo "ERROR: Required PowerVR runtime file is missing: $source_file"
			return 1
		fi

		mkdir -p "$dst_dir"
		install -m 0644 "$source_path" "$dst_dir/"
		copied=$((copied + 1))
		echo "Copied required file: $(basename "$source_file")"
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
			return 0
		fi
	}

	# ===== Copy PowerVR libraries from /usr/lib/pvr =====
	echo ""
	echo "Copying PowerVR libraries..."
	copy_dir "/usr/lib/pvr" "${ubuntu_rootfs}${pvr_install_dir}"

	# libkms is installed outside /usr/lib/pvr by Yocto but is required by the
	# proprietary PVR GBM and Wayland libraries. Keep this private copy in the
	# PVR library directory so Ubuntu's Mesa libdrm stack remains untouched.
	copy_required_file "/usr/lib/libkms.so.1.0.0" "${ubuntu_rootfs}${pvr_install_dir}" || return 1

    # ===== Copy PowerVR firmware =====
    echo ""
    echo "Copying PowerVR firmware..."
    copy_file "/lib/firmware/rgx.fw*" "${ubuntu_rootfs}/lib/firmware"
    copy_file "/lib/firmware/rgx.sh*" "${ubuntu_rootfs}/lib/firmware"

	# ===== Copy PowerVR headers (development package) =====
	echo ""
	echo "Copying PowerVR headers..."
	copy_dir "/usr/include/pvr" "${ubuntu_rootfs}/usr/include/pvr"

	# ===== Copy PowerVR services (systemd) =====
	echo ""
	echo "Copying PowerVR systemd services..."
	copy_file "/etc/systemd/system/rc.pvr.service" "${ubuntu_rootfs}/etc/systemd/system"

	# pvr-gfx-select.service ships as a vendor unit under /usr/lib/systemd/system
	# (not /etc/systemd/system) and is enabled via a multi-user.target.wants
	# symlink in the Yocto source rootfs. Mirror that layout so systemd picks
	# it up and Weston's Wants=/After=pvr-gfx-select.service resolves.
	if [ -f "${yocto_rootfs}/usr/lib/systemd/system/pvr-gfx-select.service" ]; then
		mkdir -p "${ubuntu_rootfs}/usr/lib/systemd/system"
		mkdir -p "${ubuntu_rootfs}/etc/systemd/system/multi-user.target.wants"
		cp -v "${yocto_rootfs}/usr/lib/systemd/system/pvr-gfx-select.service" "${ubuntu_rootfs}/usr/lib/systemd/system/"
		ln -sfn "/usr/lib/systemd/system/pvr-gfx-select.service" "${ubuntu_rootfs}/etc/systemd/system/multi-user.target.wants/pvr-gfx-select.service"
		copied=$((copied + 1))
		echo "Enabled: pvr-gfx-select.service (multi-user.target.wants)"
	else
		echo "NOT FOUND: /usr/lib/systemd/system/pvr-gfx-select.service"
	fi

	# The apt weston package ships a weston.service with no PowerVR awareness.
	# Replace it with the Yocto team's version, which already has
	# Wants=/After=pvr-gfx-select.service and EnvironmentFile=-/run/pvr-gfx.env
	# so Weston picks up LD_LIBRARY_PATH=/usr/lib/pvr automatically on V4H.
	if [ -f "${yocto_rootfs}/usr/lib/systemd/system/weston.service" ]; then
		mkdir -p "${ubuntu_rootfs}/usr/lib/systemd/system"
		cp -v "${yocto_rootfs}/usr/lib/systemd/system/weston.service" "${ubuntu_rootfs}/usr/lib/systemd/system/weston.service"
		copied=$((copied + 1))
		echo "Replaced: weston.service (with pvr-gfx-select integration)"
	else
		echo "NOT FOUND: /usr/lib/systemd/system/weston.service (keeping apt default)"
	fi

	copy_required_file "/etc/powervr.ini" "${ubuntu_rootfs}/etc" || return 1
	copy_required_file "/etc/udev/rules.d/72-pvr-seat.rules" "${ubuntu_rootfs}/etc/udev/rules.d" || return 1

	# ===== Copy PowerVR executables and scripts =====
	echo ""
	echo "Copying PowerVR executables..."
	mkdir -p "${ubuntu_rootfs}/usr/bin"
	mkdir -p "${ubuntu_rootfs}/usr/local/bin"
	copy_file "/usr/bin/pvrinit" "${ubuntu_rootfs}/usr/bin"
	copy_file "/usr/bin/pvr-gfx-select" "${ubuntu_rootfs}/usr/bin"
	copy_file "/etc/profile.d/pvr-gfx.sh" "${ubuntu_rootfs}/etc/profile.d"

	# Copy local bin files if they exist
	if [ -d "${yocto_rootfs}/usr/local/bin" ]; then
		cp -rv "${yocto_rootfs}/usr/local/bin"/* "${ubuntu_rootfs}/usr/local/bin/" 2>/dev/null || true
	fi

	# ===== Copy init.d script =====
	echo ""
	echo "Copying PowerVR init scripts..."
	mkdir -p "${ubuntu_rootfs}/etc/init.d"
	copy_file "/etc/init.d/pvrinit" "${ubuntu_rootfs}/etc/init.d"

	# ===== Copy pkgconfig and dev files =====
	echo ""
	echo "Copying PowerVR development files..."
	copy_dir "/usr/lib/pvr/pkgconfig" "${ubuntu_rootfs}/usr/lib/pvr/pkgconfig"

	# ===== Copy Vulkan and OpenCL support =====
	echo ""
	echo "Copying PowerVR Vulkan and OpenCL..."
	copy_dir "/usr/share/pvr/vulkan" "${ubuntu_rootfs}/usr/share/pvr/vulkan"
	copy_dir "/usr/share/pvr/OpenCL" "${ubuntu_rootfs}/usr/share/pvr/OpenCL"

	# ===== Create symlinks for libraries =====
	echo ""
	echo "Creating library symlinks..."
	setup_powervr_symlinks "${ubuntu_rootfs}" "${pvr_install_dir}"
	configure_pvrsrvkm_autoload "${ubuntu_rootfs}"

	# ===== Create environment scripts =====
	echo ""
	echo "Creating PowerVR environment configuration..."
	mkdir -p "${ubuntu_rootfs}/etc/profile.d"
	cat > "${ubuntu_rootfs}/etc/profile.d/pvr-gfx-env.sh" <<'EOF'
#!/bin/bash
# PowerVR graphics environment setup
export LD_LIBRARY_PATH="/usr/lib/pvr:/usr/lib/pvr/gbm:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="/usr/lib/pvr/pkgconfig:${PKG_CONFIG_PATH:-}"
EOF
	chmod 755 "${ubuntu_rootfs}/etc/profile.d/pvr-gfx-env.sh"
	echo "✓ Created: /etc/profile.d/pvr-gfx-env.sh"

	# ===== Verify installation =====
	echo ""
	echo "PowerVR graphics copy summary:"
	echo "  Copied: $copied"

	if [ -f "${ubuntu_rootfs}${pvr_install_dir}/libkms.so.1.0.0" ] && \
	   [ -L "${ubuntu_rootfs}${pvr_install_dir}/libkms.so.1" ] && \
	   [ -f "${ubuntu_rootfs}/etc/powervr.ini" ] && \
	   [ -f "${ubuntu_rootfs}/etc/modules-load.d/pvrsrvkm.conf" ]; then
		echo "SUCCESS: PowerVR libraries copied to Ubuntu rootfs"
		echo "Library directory contents:"
		ls -lh "${ubuntu_rootfs}${pvr_install_dir}/" 2>/dev/null | head -10
		return 0
	else
		echo "ERROR: PowerVR runtime integration is incomplete"
		return 1
	fi
}

setup_powervr_symlinks() {
	local ubuntu_rootfs="$1"
	local pvr_install_dir="$2"

	local lib_dir="${ubuntu_rootfs}${pvr_install_dir}"
	if [ ! -d "$lib_dir" ]; then
		return 0
	fi

	# Create SONAME symlinks (using absolute paths, no cd)
	if [ -f "${lib_dir}/libEGL.so" ] && [ ! -L "${lib_dir}/libEGL.so.1" ]; then
		ln -sf libEGL.so "${lib_dir}/libEGL.so.1"
		echo "✓ Created symlink: libEGL.so.1 → libEGL.so"
	fi

	if [ -f "${lib_dir}/libGLESv2.so" ] && [ ! -L "${lib_dir}/libGLESv2.so.2" ]; then
		ln -sf libGLESv2.so "${lib_dir}/libGLESv2.so.2"
		echo "✓ Created symlink: libGLESv2.so.2 → libGLESv2.so"
	fi

	if [ -f "${lib_dir}/libkms.so.1.0.0" ]; then
		ln -sfn libkms.so.1.0.0 "${lib_dir}/libkms.so.1"
		ln -sfn libkms.so.1.0.0 "${lib_dir}/libkms.so"
		echo "Created PowerVR libkms SONAME symlinks"
	fi

	# Create compatibility links for other libraries
	for lib in libIMGegl.so libPVRScopeServices.so libsrv_um.so libusc.so; do
		if [ -f "${lib_dir}/${lib}" ] && [ ! -L "${lib_dir}/${lib}.0" ]; then
			ln -sf "$lib" "${lib_dir}/${lib}.0"
		fi
	done
}

configure_pvrsrvkm_autoload() {
	local ubuntu_rootfs="$1"
	local modprobe_dir
	local config_file

	# The Yocto source rootfs blacklists pvrsrvkm. Remove only that entry from
	# the Ubuntu destination and leave all unrelated module policy intact.
	for modprobe_dir in \
		"${ubuntu_rootfs}/etc/modprobe.d" \
		"${ubuntu_rootfs}/usr/lib/modprobe.d" \
		"${ubuntu_rootfs}/lib/modprobe.d"; do
		[ -d "$modprobe_dir" ] || continue
		while IFS= read -r -d '' config_file; do
			sed -i -E '/^[[:space:]]*blacklist[[:space:]]+pvrsrvkm([[:space:]]*(#.*)?)?$/d' "$config_file"
		done < <(find "$modprobe_dir" -type f -name '*.conf' -print0)
	done

	mkdir -p "${ubuntu_rootfs}/etc/modules-load.d"
	printf '%s\n' 'pvrsrvkm' > "${ubuntu_rootfs}/etc/modules-load.d/pvrsrvkm.conf"

	cat > "${ubuntu_rootfs}/etc/systemd/system/pvr-modprobe.service" <<'EOF'
[Unit]
Description=Load PowerVR kernel module
After=systemd-udevd.service local-fs.target
Before=display-manager.service graphical.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/modprobe pvrsrvkm
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
	chmod 644 "${ubuntu_rootfs}/etc/systemd/system/pvr-modprobe.service"
	mkdir -p "${ubuntu_rootfs}/etc/systemd/system/multi-user.target.wants"
	ln -sfn ../pvr-modprobe.service \
		"${ubuntu_rootfs}/etc/systemd/system/multi-user.target.wants/pvr-modprobe.service"
	echo "Configured pvrsrvkm autoload and PowerVR module service"
}
