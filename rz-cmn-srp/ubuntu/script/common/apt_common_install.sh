#!/bin/bash
# ------------------------------------------------------------------------------------------#
# This script is intended to be run inside a chroot environment to install essential packages
# and perform system updates. It first checks if the script is executed as root, updates the
# package list, and installs various required utilities and packages.
# ------------------------------------------------------------------------------------------#

export LC_ALL=C

# Set DEBIAN_FRONTEND globally
export DEBIAN_FRONTEND=noninteractive

# time zone data turn to default if not defined
TIME_ZONE_AREA="${TIME_ZONE_AREA:=Asia}"
TIME_ZONE_CITY="${TIME_ZONE_CITY:=Ho_Chi_Minh}"
echo "tzdata tzdata/Areas select $TIME_ZONE_AREA" | sudo debconf-set-selections
echo "tzdata tzdata/Zones/$TIME_ZONE_AREA select $TIME_ZONE_CITY" | sudo debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure tzdata

apt install -y libglapi-mesa libturbojpeg libgoogle-glog-dev
