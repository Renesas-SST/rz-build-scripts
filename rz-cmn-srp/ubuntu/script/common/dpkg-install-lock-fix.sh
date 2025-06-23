echo "Attempting to install systemd and core dependencies normally..."

SYSTEMD_PACKAGES=(systemd systemd-timesyncd systemd-resolved)

setup_environment() {
	export LC_ALL=C
	# Ensure /tmp exists and is correctly permissioned
	mkdir -p /tmp
	chmod 1777 /tmp
	apt update
	apt clean
	apt autoclean
	apt upgrade -y
	apt update

	# Set DEBIAN_FRONTEND globally
	export DEBIAN_FRONTEND=noninteractive

	# Install debconf-utils for preconfiguring
	apt install -y debconf-utils sudo

	# time zone data turn to default if not defined
	TIME_ZONE_AREA="${TIME_ZONE_AREA:=Asia}"
	TIME_ZONE_CITY="${TIME_ZONE_CITY:=Ho_Chi_Minh}"
	echo "tzdata tzdata/Areas select $TIME_ZONE_AREA" | sudo debconf-set-selections
	echo "tzdata tzdata/Zones/$TIME_ZONE_AREA select $TIME_ZONE_CITY" | sudo debconf-set-selections
	DEBIAN_FRONTEND=noninteractive dpkg-reconfigure tzdata

	# Update apt cache
	apt-get update || { echo "ERROR: apt-get update failed."; return 1; }
}

move_postinst() {
    local pkg=$1
    local postinst="/var/lib/dpkg/info/${pkg}.postinst"
    if [ -f "$postinst" ]; then
        mv "$postinst" /tmp/
        echo "Moved ${pkg}.postinst to /tmp/"
    fi
}

restore_postinst() {
    local pkg=$1
    local tmpfile="/tmp/${pkg}.postinst"
    if [ -f "$tmpfile" ]; then
        mv "$tmpfile" /var/lib/dpkg/info/
        echo "Restored ${pkg}.postinst"
    fi
}

recover_broken_install() {
    dpkg --configure -a || echo "dpkg --configure failed"
    apt install -f -y || echo "apt install -f failed"
}

patch_systemd_sysusers() {
    if ! command -v systemd-sysusers >/dev/null 2>&1; then
        echo "Patching systemd-sysusers with dummy echo..."
        cd /bin && mv -f systemd-sysusers{,.org} && ln -s echo systemd-sysusers && cd -
    fi
}

install_package_group() {
    local packages=("$@")
    for pkg in "${packages[@]}"; do
        apt install -y "$pkg" || echo "Initial install failed for $pkg"
    done
    for pkg in "${packages[@]}"; do
        move_postinst "$pkg"
    done
    recover_broken_install
    for pkg in "${packages[@]}"; do
        restore_postinst "$pkg"
    done
}

install_single_package_with_recovery() {
    local pkg=$1
    apt install -y "$pkg" || echo "Initial install failed for $pkg"
    move_postinst "$pkg"
    recover_broken_install
    restore_postinst "$pkg"
}

# ---------- Main ----------
main() {
    echo "Starting installation of packages with recovery..."

    setup_environment

    echo "Installing systemd group..."
    install_package_group "${SYSTEMD_PACKAGES[@]}"

    patch_systemd_sysusers

    echo "Installing polkitd..."
    install_single_package_with_recovery "polkitd"

    echo "Installing udev..."
    install_single_package_with_recovery "udev"

    echo "All installations and recovery complete."
}

main