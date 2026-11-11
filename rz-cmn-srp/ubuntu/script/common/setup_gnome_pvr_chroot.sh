#!/bin/bash
##############################################################################
# Install the minimal GNOME desktop with PowerVR GPU acceleration on V4H.
##############################################################################

exec > >(tee /tmp/setup_gnome_pvr_chroot.log) 2>&1
set -x

WRAP=/usr/share/pvr-gnome

# ===== (a) Install the minimal GNOME desktop =====
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef \
    gdm3 xorg gnome-shell ubuntu-session gnome-session gnome-control-center \
    gnome-settings-daemon nautilus gnome-shell-extension-desktop-icons-ng \
    gnome-shell-extension-ubuntu-dock network-manager-gnome pipewire-pulse \
    wireplumber gnome-terminal yaru-theme-gtk yaru-theme-icon yaru-theme-sound \
    ubuntu-wallpapers fonts-ubuntu
if ! dpkg -l gdm3 2>/dev/null | grep -q '^ii'; then
    echo "ERROR: gdm3 failed to install — GNOME desktop will not work"
    exit 1
fi

# ===== (b) Install glmark2 benchmarks =====
apt-get install -y glmark2-es2-drm glmark2-es2-wayland

# ===== (c) Disable the profile.d LD_LIBRARY_PATH leak =====
mv /etc/profile.d/pvr-gfx.sh /etc/profile.d/pvr-gfx.sh.disabled 2>/dev/null || true
mv /etc/profile.d/pvr-gfx-env.sh /etc/profile.d/pvr-gfx-env.sh.disabled 2>/dev/null || true

# ===== (d) libpvr-v4h-gnome postinst dpkg-divert logic =====
divert_install() {
    # divert_install <target> <real-name> <wrapper>
    target="$1"; real="$2"; wrapper="$3"
    if [ ! -f "$wrapper" ]; then
        echo "ERROR: wrapper not found: $wrapper (skipping divert of $target)"
        return 1
    fi
    if ! dpkg-divert --list "$target" | grep -q .; then
        dpkg-divert --add --rename --divert "$real" "$target"
    fi
    install -m755 "$wrapper" "$target"
}

apply_gdm_bits() {
    if getent passwd gdm >/dev/null 2>&1; then
        usermod -aG render gdm || true
    fi
    if getent passwd ubuntu >/dev/null 2>&1; then
        usermod -aG render ubuntu || true
    fi
    # 72-pvr-seat.rules (from libpvr1-v4h) puts the render-only GSX node on
    # seat1 as master-of-seat; GDM then loops a doomed greeter for seat1.
    # Disable it for GNOME use (matches libpvr1-v4h-gnome postinst).
    if [ -f /etc/udev/rules.d/72-pvr-seat.rules ]; then
        sed -i 's/^SUBSYSTEM/#SUBSYSTEM/' /etc/udev/rules.d/72-pvr-seat.rules
    fi
}

apply_ros_bits() {
    for distro in /opt/ros/*; do
        for target in "$distro/bin/rviz2" "$distro/lib/rviz2/rviz2"; do
            if [ -e "$target" ] || dpkg-divert --list "$target" | grep -q .; then
                divert_install "$target" "$target.real" "$WRAP/rviz2-wrapper"
            fi
        done
    done
}

apply_electron_bits() {
    t=/opt/Foxglove/foxglove-studio
    if [ -e "$t" ] || dpkg-divert --list "$t" | grep -q .; then
        divert_install "$t" "$t.real" "$WRAP/foxglove-wrapper"
    fi
}

apply_camera_bits() {
    t=/usr/bin/cheese
    if [ -e "$t" ] || dpkg-divert --list "$t" | grep -q .; then
        divert_install "$t" "$t.real" "$WRAP/cheese-wrapper"
    fi
}

apply_native_gles_bits() {
    for t in /usr/bin/glmark2-es2-wayland; do
        if [ -e "$t" ] || dpkg-divert --list "$t" | grep -q .; then
            divert_install "$t" "$t.real" "$WRAP/pvr-egl-wrapper"
        fi
    done
}

# Core GNOME diversions (postinst "configure")
divert_install /usr/bin/gnome-shell /usr/bin/gnome-shell.real \
    "$WRAP/gnome-shell-wrapper"
divert_install /usr/bin/Xwayland /usr/bin/Xwayland.real \
    "$WRAP/Xwayland-wrapper"
divert_install /usr/libexec/gnome-control-center-print-renderer \
    /usr/libexec/gnome-control-center-print-renderer.real \
    "$WRAP/print-renderer-wrapper"

apply_gdm_bits
apply_ros_bits
apply_electron_bits
apply_camera_bits
apply_native_gles_bits

# ===== (e) refresh the linker cache =====
ldconfig

chmod 1777 /tmp

exit 0
