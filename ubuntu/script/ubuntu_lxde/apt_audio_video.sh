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
