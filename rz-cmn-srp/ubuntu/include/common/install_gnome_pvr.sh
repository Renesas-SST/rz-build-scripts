#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Stage the GNOME + PowerVR desktop files into the Ubuntu rootfs. Copies the
# base PVR GPU userspace files from files_to_add/pvr, creates the required
# SONAME symlinks, then stages the pvr-gnome wrapper assets.
# The chroot half is done by script/common/setup_gnome_pvr_chroot.sh.
# --------------------------------------------------------------------------#

install_gnome_pvr() {
	local yocto_rootfs="${1:-.}"
	local ubuntu_rootfs="${2:-.}"
	local assets_dir="${3:-${SCRIPT_DIR}/files_to_add/pvr-gnome}"
	local pvr_dir="${4:-${SCRIPT_DIR}/files_to_add/pvr}"
	# Convert to absolute paths
	if [[ "$yocto_rootfs" != /* ]]; then
		yocto_rootfs="$(cd "$yocto_rootfs" 2>/dev/null && pwd)" || yocto_rootfs="${PWD}/${yocto_rootfs}"
	fi
	if [[ "$ubuntu_rootfs" != /* ]]; then
		ubuntu_rootfs="$(cd "$ubuntu_rootfs" 2>/dev/null && pwd)" || ubuntu_rootfs="${PWD}/${ubuntu_rootfs}"
	fi
	if [[ "$assets_dir" != /* ]]; then
		assets_dir="$(cd "$assets_dir" 2>/dev/null && pwd)" || assets_dir="${PWD}/${assets_dir}"
	fi
	if [[ "$pvr_dir" != /* ]]; then
		pvr_dir="$(cd "$pvr_dir" 2>/dev/null && pwd)" || pvr_dir="${PWD}/${pvr_dir}"
	fi

	# Validate inputs
	if [ ! -d "$ubuntu_rootfs" ]; then
		echo "ERROR: Ubuntu rootfs directory does not exist: $ubuntu_rootfs"
		return 1
	fi
	if [ ! -d "$pvr_dir" ] || [ -z "$(ls -A "$pvr_dir" 2>/dev/null)" ]; then
		echo "ERROR: Base PVR files directory not found or empty: $pvr_dir"
		return 1
	fi
	if [ ! -d "$assets_dir" ] || [ -z "$(ls -A "$assets_dir" 2>/dev/null)" ]; then
		echo "ERROR: pvr-gnome assets directory not found or empty: $assets_dir"
		return 1
	fi

	echo "Staging GNOME + PowerVR desktop files into Ubuntu rootfs..."

	# ===== (a1) Copy Yocto-identical PVR .so files from Yocto rootfs =====
	echo ""
	echo "Copying Yocto-identical PVR .so files from: $yocto_rootfs/usr/lib/pvr/"
	local yocto_pvr="${yocto_rootfs}/usr/lib/pvr"
	local ubuntu_pvr="${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/pvr"
	if [ ! -d "$yocto_pvr" ]; then
		echo "ERROR: Yocto PVR directory not found: $yocto_pvr"
		return 1
	fi
	mkdir -p "$ubuntu_pvr"
	local yocto_libs=(
		libEGL.so libGLESv2.so libIMGegl.so libPVRScopeServices.so
		libdlc_REL.so libpvrDRM_WSEGL.so libsrv_um.so libsutu_display.so
		libufwriter.so libusc.so
	)
	for lib in "${yocto_libs[@]}"; do
		if [ ! -f "${yocto_pvr}/${lib}" ]; then
			echo "ERROR: Missing Yocto PVR lib: ${yocto_pvr}/${lib}"
			return 1
		fi
		cp -a "${yocto_pvr}/${lib}" "${ubuntu_pvr}/${lib}"
	done
	echo "OK: 10 Yocto-identical .so files copied into Ubuntu rootfs"

	# ===== (a2) Copy deb-exclusive PVR files from files_to_add/pvr =====
	echo ""
	echo "Copying deb-exclusive PVR files from: $pvr_dir"
	cp -a "${pvr_dir}"/. "${ubuntu_rootfs}/"
	echo "OK: Deb-exclusive PVR files copied into Ubuntu rootfs"

	# ===== (b) Create symlinks matching the deb layout =====
	echo ""
	echo "Creating PVR symlinks in rootfs..."
	local pvr_lib="${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/pvr"
	local gbm_lib="${ubuntu_rootfs}/usr/lib/gbm"

	# pvr/ directory symlinks
	( cd "${pvr_lib}" && \
		ln -sf libEGL.so               libEGL.so.1 && \
		ln -sf libGLESv2.so            libGLESv2.so.2 && \
		ln -sf libPVROCL.so            libOpenCL.so && \
		ln -sf libgbm.so.1             libgbm.so && \
		ln -sf libgbm.so.1.0.0         libgbm.so.1 && \
		ln -sf libkms.so.1             libkms.so && \
		ln -sf libkms.so.1.0.0         libkms.so.1 && \
		ln -sf libpvrWAYLAND_WSEGL.so.3           libpvrWAYLAND_WSEGL.so && \
		ln -sf libpvrWAYLAND_WSEGL.so.3.1.1       libpvrWAYLAND_WSEGL.so.3 && \
		ln -sf libwayland-kms.so.0.0.0             libwayland-kms.so.0 \
	)
	echo "OK: 10 symlinks created in pvr/"

	# gbm/ directory symlinks
	( cd "${gbm_lib}" && \
		ln -sf libgbm_kms.so.1         libgbm_kms.so && \
		ln -sf libgbm_kms.so.1.0.0     libgbm_kms.so.1 \
	)
	echo "OK: 2 symlinks created in gbm/"

	# ===== (c) Stage the pvr-gnome asset tree (wrappers, shim .so, env config) =====
	echo ""
	echo "Staging pvr-gnome assets from: $assets_dir"
	cp -a "${assets_dir}"/. "${ubuntu_rootfs}/"
	echo "OK: Staged pvr-gnome asset tree into Ubuntu rootfs"
	if [ ! -f "${ubuntu_rootfs}/usr/share/pvr-gnome/gnome-shell-wrapper" ]; then
		echo "ERROR: gnome-shell-wrapper not found after staging -- asset copy failed"
		return 1
	fi

	# ===== (d) Autoload pvrsrvkm kernel module at boot =====
	echo ""
	echo "Setting up pvrsrvkm module autoload..."
	mkdir -p "${ubuntu_rootfs}/usr/lib/modules-load.d"
	echo "pvrsrvkm" > "${ubuntu_rootfs}/usr/lib/modules-load.d/pvrsrvkm.conf"
	echo "OK: Created /usr/lib/modules-load.d/pvrsrvkm.conf"

	# ===== (e) Vulkan ICD symlink =====
	echo ""
	echo "Creating Vulkan ICD symlink..."
	mkdir -p "${ubuntu_rootfs}/etc/vulkan/icd.d"
	ln -sf /usr/share/pvr/vulkan/icd.d/powervr_icd.json \
		"${ubuntu_rootfs}/etc/vulkan/icd.d/powervr_icd.json"
	echo "OK: Created /etc/vulkan/icd.d/powervr_icd.json symlink"

	# ===== Summary =====
	echo ""
	echo "GNOME + PowerVR staging summary:"
	echo "  base PVR: 10 .so from Yocto rootfs + deb-exclusive files from files_to_add/pvr"
	echo "  symlinks: 12 SONAME symlinks (10 pvr/ + 2 gbm/)"
	echo "  wrappers: pvr-gnome asset tree staged"
	echo "  module:   pvrsrvkm.conf autoload"
	echo "  vulkan:   ICD symlink -> powervr_icd.json"
	echo "SUCCESS: GNOME + PowerVR files staged to Ubuntu rootfs"
	return 0
}
