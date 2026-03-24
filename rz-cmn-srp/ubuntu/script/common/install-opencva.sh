#!/bin/bash
# install_opencv_arm64.sh
# One-script installer for DRP-accelerated OpenCV on RZ/V2H
# Usage:
# wget -qO install_opencv_arm64.sh https://raw.githubusercontent.com/renesas-rdk/rzv2h_opencv_accelerated_debs/main/install_opencv_arm64.sh
# sudo bash install_opencv_arm64.sh

set -e

REPO="renesas-rdk/rzv2h_opencv_accelerated_debs"
VERSION="v4.6.0"
TARBALL="rzv2h_opencv_accelerated_debs.tar.gz"
URL="https://github.com/$REPO/releases/download/$VERSION/$TARBALL"
TMPDIR=$(mktemp -d)

echo "============================================="
echo " DRP-Accelerated OpenCV Installer for RZ/V2H"
echo " Ubuntu 24.04 ARM64"
echo "============================================="

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run with sudo"
    exit 1
fi

# Check architecture
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" != "arm64" ]; then
    echo "Error: This package is for ARM64, detected: $ARCH"
    exit 1
fi

# Install wget if needed
echo "[1/5] Checking dependencies..."
if ! command -v wget &>/dev/null; then
    apt update -qq
    apt install -y -qq wget
fi

# Download release
echo "[2/5] Downloading packages..."
wget -q --show-progress -O "$TMPDIR/$TARBALL" "$URL"
tar xzf "$TMPDIR/$TARBALL" -C "$TMPDIR"

# Install .deb packages
echo "[3/5] Installing OpenCV packages..."
dpkg -i "$TMPDIR"/binaries/*.deb || true

# Fix dependencies
echo "[4/5] Resolving dependencies..."
apt --fix-broken install -y

# Verify
echo "[5/5] Verifying installation..."
echo ""
echo "OpenCV version:"
pkg-config --modversion opencv4 2>/dev/null || echo "  opencv4 not found in pkg-config"
echo ""
echo "Libraries installed:"
ldconfig -p | grep opencv | head -10
echo ""

# Cleanup
echo "Cleaning up..."
rm -rf "$TMPDIR"

echo "============================================="
echo " Installation completed!"
echo "============================================="
