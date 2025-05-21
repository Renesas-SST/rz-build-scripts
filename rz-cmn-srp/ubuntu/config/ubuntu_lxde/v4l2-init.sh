#!/bin/sh
##############################################################################
# This script is used to setup the camera ov5640 configuration.
# The script uses the media-ctl tool to setup the camera configuration.
# The resolution is set to 1920x1080 with UYVY8_2X8 format.
##############################################################################
media-ctl -d /dev/media0 -l "'rzg2l_csi2 10830400.csi2':1 -> 'CRU output':0 [1]"
media-ctl -d /dev/media0 -V "'rzg2l_csi2 10830400.csi2':1 [fmt:UYVY8_2X8/1280x720 field:none]"
media-ctl -d /dev/media0 -V "'ov5640 1-003c':0 [fmt:UYVY8_2X8/1280x720 field:none]"
