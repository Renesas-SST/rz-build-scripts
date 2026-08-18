#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Master orchestrator for PowerVR graphics stack installation on V4H.
# Copies graphics components from Yocto rootfs to Ubuntu rootfs in sequence:
# 1. Copy PowerVR userspace libraries
# 2. Copy libdrm with PowerVR compatibility
# 3. Copy Wayland/Weston with PowerVR backend
# --------------------------------------------------------------------------#

install_graphics_v4h() {
	local yocto_rootfs="${1:-.}"
	local ubuntu_rootfs="${2:-.}"

	echo "=========================================="
	echo "RCar V4H PowerVR Graphics Stack Installer"
	echo "=========================================="
	echo "Yocto rootfs: $yocto_rootfs"
	echo "Ubuntu rootfs: $ubuntu_rootfs"
	echo ""

	# Validate inputs
	if [ ! -d "$yocto_rootfs" ]; then
		echo "ERROR: Yocto rootfs directory does not exist: $yocto_rootfs"
		return 1
	fi

	if [ ! -d "$ubuntu_rootfs" ]; then
		echo "ERROR: Ubuntu rootfs directory does not exist: $ubuntu_rootfs"
		return 1
	fi

	local phase_count=0
	local phase_failed=0

	# Source installation scripts
	INCLUDE_DIR="${SCRIPT_DIR}/../include/common"
	if [ ! -f "${INCLUDE_DIR}/install_powervr_graphics.sh" ]; then
		echo "ERROR: include/common/install_powervr_graphics.sh not found"
		return 1
	fi

	. "${INCLUDE_DIR}/install_powervr_graphics.sh"
	. "${INCLUDE_DIR}/setup_libdrm_pvr.sh"
	. "${INCLUDE_DIR}/setup_wayland_pvr.sh"

	# ===== Phase 1: Copy PowerVR userspace libraries =====
	echo ""
	echo "--- Phase 1: Copying PowerVR userspace libraries ---"
	phase_count=$((phase_count + 1))

	if install_powervr_graphics "$yocto_rootfs" "$ubuntu_rootfs" "/usr/lib/pvr"; then
		echo "Phase 1 COMPLETED"
	else
		echo "Phase 1 FAILED - Continuing with warnings..."
		phase_failed=$((phase_failed + 1))
	fi

	# ===== Phase 2: Copy libdrm with PowerVR patches =====
	echo ""
	echo "--- Phase 2: Copying libdrm with PowerVR compatibility ---"
	phase_count=$((phase_count + 1))

	if setup_libdrm_pvr "$yocto_rootfs" "$ubuntu_rootfs"; then
		echo "Phase 2 COMPLETED"
	else
		echo "Phase 2 FAILED - Continuing with warnings..."
		phase_failed=$((phase_failed + 1))
	fi

	# ===== Phase 3: Copy Wayland/Weston for PowerVR =====
	echo ""
	echo "--- Phase 3: Copying Wayland/Weston for PowerVR ---"
	phase_count=$((phase_count + 1))

	if setup_wayland_pvr "$yocto_rootfs" "$ubuntu_rootfs"; then
		echo "Phase 3 COMPLETED"
	else
		echo "Phase 3 FAILED - Continuing with warnings..."
		phase_failed=$((phase_failed + 1))
	fi

	# ===== Final verification =====
	echo ""
	echo "=========================================="
	echo "Installation Summary"
	echo "=========================================="
	echo "Total phases: $phase_count"
	echo "Phases completed: $((phase_count - phase_failed))"
	echo "Phases with warnings: $phase_failed"
	echo ""

	# Check critical components
	local critical_count=0
	local critical_present=0

	# Check PowerVR libraries
	if [ -d "${ubuntu_rootfs}/usr/lib/pvr" ] && [ -n "$(ls -A ${ubuntu_rootfs}/usr/lib/pvr/*.so* 2>/dev/null)" ]; then
		critical_present=$((critical_present + 1))
		echo "✓ PowerVR libraries copied"
	else
		echo "✗ PowerVR libraries NOT found"
	fi
	critical_count=$((critical_count + 1))

	# Check libdrm
	if [ -f "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/libdrm.so.2" ] || \
	   [ -d "${ubuntu_rootfs}/usr/include/drm" ]; then
		critical_present=$((critical_present + 1))
		echo "✓ libdrm copied"
	else
		echo "✗ libdrm NOT found"
	fi
	critical_count=$((critical_count + 1))

	# Check Wayland
	if [ -f "${ubuntu_rootfs}/usr/bin/weston" ] || \
	   [ -f "${ubuntu_rootfs}/usr/lib/aarch64-linux-gnu/libwayland-client.so.0" ]; then
		critical_present=$((critical_present + 1))
		echo "✓ Wayland/Weston copied"
	else
		echo "✗ Wayland/Weston NOT found"
	fi
	critical_count=$((critical_count + 1))

	echo ""
	echo "Critical components: $critical_present/$critical_count"

	# Final result
	if [ $phase_failed -eq 0 ]; then
		echo ""
		echo "SUCCESS: PowerVR graphics stack fully copied"
		echo ""
		return 0
	else
		echo ""
		echo "WARNING: PowerVR graphics stack copied with some issues"
		echo "Please verify all components are present in Ubuntu rootfs"
		echo ""
		return 1
	fi
}

# Main execution
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
	install_graphics_v4h "$@"
	exit $?
fi
