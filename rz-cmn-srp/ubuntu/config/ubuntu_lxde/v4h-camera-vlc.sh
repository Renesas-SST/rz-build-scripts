#!/bin/bash
#===============================================================================
# title       : v4h-camera-vlc.sh
# description : Show a Sparrow-Hawk (R-Car V4H) Pi Camera in VLC without a
#               virtual V4L2 device. libcamera (libcamerasrc) debayers the
#               frames, GStreamer writes raw video to a pipe and VLC reads it
#               through its rawvideo demuxer.
#
#   VLC cannot open /dev/video4 directly: the VIN node only delivers raw Bayer
#   and only libcamera configures the sensor -> CSI-2 -> ISP -> VIN graph.
#
# usage       : v4h-camera-vlc.sh [--camera imx219|imx708] [--width W] [--height H]
#               Run it as the desktop user (VLC refuses to run as root).
#               Stop other users of the same camera first (one client per camera).
#===============================================================================
set -u

CAMERA="imx219"
WIDTH=1920
HEIGHT=1080
FRAMERATE="30/1"

# Mode captured from the sensor (imx708 does not negotiate 1920x1080 directly,
# the picture is scaled to WIDTHxHEIGHT after the capture)
declare -A SOURCE_SIZE=( [imx219]="1920x1080" [imx708]="2304x1296" )

die() { echo "ERROR: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --camera) CAMERA="${2:-}"; shift 2 ;;
        --width)  WIDTH="${2:-}"; shift 2 ;;
        --height) HEIGHT="${2:-}"; shift 2 ;;
        -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
        *) die "unknown parameter: $1" ;;
    esac
done

[[ -n "${SOURCE_SIZE[$CAMERA]:-}" ]] || die "unsupported camera '$CAMERA' (use imx219 or imx708)"
[[ "$WIDTH" =~ ^[0-9]+$ && "$HEIGHT" =~ ^[0-9]+$ ]] || die "width and height must be integers"
for tool in cam gst-launch-1.0 vlc; do
    command -v "$tool" > /dev/null 2>&1 || die "$tool is not installed"
done

# Camera identifier from "cam -l" (the text between the last parentheses)
line="$(cam -l 2>&1 | grep -- "'$CAMERA'" | head -n1 || true)"
[[ -n "$line" ]] || die "camera $CAMERA not found in 'cam -l'"
NAME="$(sed -nE 's/.*\(([^()]*)\)[[:space:]]*$/\1/p' <<<"$line")"
[[ -n "$NAME" ]] || die "cannot read the camera name from: $line"

SRC_W="${SOURCE_SIZE[$CAMERA]%x*}"
SRC_H="${SOURCE_SIZE[$CAMERA]#*x}"

echo "Camera: $CAMERA ($NAME), ${SRC_W}x${SRC_H} -> ${WIDTH}x${HEIGHT}"

# BGRx bytes (B,G,R,x) are VLC "RV32". The pipe carries only video data, so
# gst-launch must stay quiet (-q) and must not print caps to stdout (no -v).
gst-launch-1.0 -q libcamerasrc camera-name="$NAME" ! \
    "video/x-raw,format=BGRx,width=${SRC_W},height=${SRC_H},framerate=${FRAMERATE}" ! \
    videoconvert ! videoscale ! \
    "video/x-raw,format=BGRx,width=${WIDTH},height=${HEIGHT}" ! \
    fdsink fd=1 \
| vlc --demux=rawvideo --rawvid-fps="${FRAMERATE%/*}" \
      --rawvid-width="$WIDTH" --rawvid-height="$HEIGHT" --rawvid-chroma=RV32 -
