#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Write description to link ln -sf iptables legacy to iptables
# --------------------------------------------------------------------------#

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
	echo "Please run this script as root or using sudo."
	exit 1
fi

ln -sf /usr/sbin/iptables-legacy /usr/sbin/iptables
ln -sf /usr/sbin/ip6tables-legacy /usr/sbin/ip6tables

echo "Set default iptables to legacy"