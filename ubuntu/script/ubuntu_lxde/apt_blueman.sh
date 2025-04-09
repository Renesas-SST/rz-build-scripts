#!/bin/bash
##############################################################################
# Install bluetooth application to run the bluetooth. (only for 20.04 and above)
##############################################################################

# Set DEBIAN_FRONTEND globally
export DEBIAN_FRONTEND=noninteractive

# Install bluetooth application
DEBIAN_FRONTEND=noninteractive apt install -y --allow-unauthenticated -o Dpkg::Options::="--force-confold" -f blueman
