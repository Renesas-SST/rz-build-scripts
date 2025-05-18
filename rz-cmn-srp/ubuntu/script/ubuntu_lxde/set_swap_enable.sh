#!/bin/bash
##############################################################################
# This script to config the swap partiton auto enable on boot.
# Add this line to /etc/fstab: /swapfile none swap sw 0 0
##############################################################################

# Make the swap file auto enable on boot
echo '/swapfile none swap sw 0 0' > /etc/fstab
if [ $? -ne 0 ]; then
	echo "Failed to add swap file to /etc/fstab."
	exit 1
fi
