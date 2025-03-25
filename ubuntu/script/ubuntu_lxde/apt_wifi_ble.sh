#!/bin/bash
##############################################################################
# Install packages and bluetooth application to run the bluetooth.
##############################################################################

# Set DEBIAN_FRONTEND globally
export DEBIAN_FRONTEND=noninteractive

# Install dbus-x11 and apt-utils
DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated -o Dpkg::Options::="--force-confold" -f dbus-x11

# Install apt-utils
DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated -o Dpkg::Options::="--force-confold" -f apt-utils

# Install libsss-dev
DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated -o Dpkg::Options::="--force-confold" -f libssl-dev

# Install bluetooth application
# DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated -o Dpkg::Options::="--force-confold" -f blueman
