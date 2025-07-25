#!/bin/bash

##############################################################################
# This script is used to setup the camera ov564x configuration.
# The script uses the media-ctl tool to setup the camera configuration.
# ov5640: The resolution is set to 1280x720 with UYVY8_1X16 format.
# ov5645: The resolution is set to 1280x960 with UYVY8_1X16 format.
##############################################################################

cru=$(cat /sys/class/video4linux/v4l-subdev*/name | grep "cru-ip")
csi2=$(cat /sys/class/video4linux/v4l-subdev*/name | grep "csi2")
ov=$(cat /sys/class/video4linux/v4l-subdev*/name | grep "ov")
default_camera=$(echo "$ov" | awk '{print $1}')

declare -A camera_default_resolution
camera_default_resolution["ov5640"]="1280x720"
camera_default_resolution["ov5645"]="1280x960"

# Check for no input
ov564x_res="${camera_default_resolution[$default_camera]}"

media-ctl -d /dev/media0 -V "'$csi2':0 [fmt:UYVY8_1X16/$ov564x_res field:none]"
media-ctl -d /dev/media0 -V "'$csi2':1 [fmt:UYVY8_1X16/$ov564x_res field:none]"
media-ctl -d /dev/media0 -V "'$ov':0 [fmt:UYVY8_1X16/$ov564x_res field:none]"
media-ctl -d /dev/media0 -V "'$cru':0 [fmt:UYVY8_1X16/$ov564x_res field:none]"
media-ctl -d /dev/media0 -V "'$cru':1 [fmt:UYVY8_1X16/$ov564x_res field:none]"

width=${ov564x_res%x*}
height=${ov564x_res#*x}
v4l2-ctl -d /dev/video0 --set-fmt-video=width=${width},height=${height},pixelformat=UYVY
