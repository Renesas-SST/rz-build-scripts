#!/bin/bash
# --------------------------------------------------------------------------#
# Description:
# Enable some custom services
# --------------------------------------------------------------------------#

# Enable xorg display to force Display Unit handle xorg initalization
chmod +x /usr/local/bin/force-display-xorg.sh
systemctl enable force-xorg-display.service
