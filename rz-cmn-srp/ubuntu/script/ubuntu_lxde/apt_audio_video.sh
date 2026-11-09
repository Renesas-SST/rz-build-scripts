#!/bin/bash
##############################################################################
# Install packages to run audio and video features on ubuntu.
##############################################################################

# Install video for linux utils
DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated -o Dpkg::Options::="--force-confold" -f v4l-utils

# Install video codec:
DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated -o Dpkg::Options::="--force-confold" -f ubuntu-restricted-extras

# Install audacity application to record and play audio
apt install audacity -y

# Install VLC application to play video, stream video and record video
apt install vlc -y

# Remove clipit application
apt remove clipit --purge -y

# Camera userspace (libcamera): GStreamer tools and plugins used with the
# libcamerasrc plugin copied from Yocto, and the libraries needed by cam
DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated -o Dpkg::Options::="--force-confold" -f \
	gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-x \
	libevent-2.1-7t64 libevent-pthreads-2.1-7t64
