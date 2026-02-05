#!/bin/bash
#===============================================================================
# title           : v4l2-init.sh
# description     : Initialise media pipeline for cameras for RZ Common System
# usage           : bash v4l2-init.sh --device 0 --width 1280 --height 720
#===============================================================================

# Supported camera models
SUPPORTED_MODELS=("ov5640" "ov5645" "ap1302" "ar1335")

# Default values
DEFAULT_DEVICE_ID=0
DEFAULT_CAPTURE_WIDTH="1920"
DEFAULT_CAPTURE_HEIGHT="1080"

# Valid resolutions per camera model
declare -A CAMERA_VALID_RESOLUTIONS
CAMERA_VALID_RESOLUTIONS["ov5640"]="720x480 720x576 1024x768 1280x720 1920x1080 2592x1944"
CAMERA_VALID_RESOLUTIONS["ov5645"]="1280x960 1920x1080 2592x1944"
CAMERA_VALID_RESOLUTIONS["ap1302"]="1280x720 1920x1080"
CAMERA_VALID_RESOLUTIONS["ar1335"]="1280x720 1920x1080"

declare -A CAMERA_DEFAULT_FORMAT
CAMERA_DEFAULT_FORMAT["ov5640"]="UYVY8_1X16"
CAMERA_DEFAULT_FORMAT["ov5645"]="UYVY8_1X16"
CAMERA_DEFAULT_FORMAT["ap1302"]="YUYV8_1X16"
CAMERA_DEFAULT_FORMAT["ar1335"]="SRGGB10_1X10"

declare -A CAMERA_V4L2_PIXFMT
CAMERA_V4L2_PIXFMT["UYVY8_1X16"]="UYVY"
CAMERA_V4L2_PIXFMT["YUYV8_1X16"]="YUYV"
CAMERA_V4L2_PIXFMT["SRGGB10_1X10"]="SRGGB10"

# Detect subdevs
mapfile -t subdevs < <(
  grep '-' /sys/class/video4linux/v4l-subdev*/name 2>/dev/null \
    | sed 's/.*://' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u
)

# Get camera model
get_cam_model() {
    local cam="$1"
    # Strip everything after first space or dot
    echo "$cam" | sed -E 's/[ .].*//'
}

# Filter supported cameras
cameras=()
for s in "${subdevs[@]}"; do
  for m in "${SUPPORTED_MODELS[@]}"; do
    if [[ "$s" == "$m"* ]]; then
        cameras+=("$s")
        break
    fi
  done
done

# Detect CSI2 and CRU (entity names only)
mapfile -t csi2 < <(grep 'csi2' /sys/class/video4linux/v4l-subdev*/name 2>/dev/null | sed 's|.*/name:||')
mapfile -t cru  < <(grep 'cru-ip' /sys/class/video4linux/v4l-subdev*/name 2>/dev/null | sed 's|.*/name:||')

# Set defaults
default_camera=${cameras[0]:-"<none>"}
default_csi2=${csi2[0]:-"<none>"}
default_cru=${cru[0]:-"<none>"}
cru_output="CRU output"

# Usage
function print_usage {
    local -A seen_models
    local resolution_info=""

    for cam in "${cameras[@]}"; do
        local model=$(get_cam_model "$cam")
        # Only add if not already processed
        if [[ -z "${seen_models[$model]}" ]]; then
            seen_models[$model]=1
            resolution_info+="  ${model}: ${CAMERA_VALID_RESOLUTIONS[$model]}"$'\n'
        fi
    done

cat << EOF
Usage: v4l2-init [options]
Options:
  --help                    show this help message and exit
  --device DEVICE_ID        The id of the media device, where 0 corresponds to /dev/media0
  --width WIDTH             Width of capture image
  --height HEIGHT           Height of capture image

Detected cameras: ${cameras[*]}

Available resolutions:
${resolution_info}
Example: $0 --device 0 --width 1920 --height 1080
EOF
}

# Validate resolution against camera model
check_resolution() {
    local cam_model="$1"
    local width="$2"
    local height="$3"
    local target="${width}x${height}"
    for res in ${CAMERA_VALID_RESOLUTIONS[$cam_model]}; do
        if [[ "$res" == "$target" ]]; then
            echo "$target"
            return
        fi
    done

    # Fallback to first listed resolution if the input is invalid
    local fallback=$(echo ${CAMERA_VALID_RESOLUTIONS[$cam_model]} | awk '{print $1}')
    echo "WARNING: Requested resolution '${target}' is invalid for '${cam_model}', falling back to '${fallback}'." >&2
    echo "$fallback"
}

# Validate requested media device exists and contains a supported camera.
validate_device_index() {
    local device_id="$1"

    # numeric check
    if ! [[ "$device_id" =~ ^[0-9]+$ ]]; then
        echo "ERROR: --device must be a non-negative integer."
        exit 2
    fi

    # Check media device node exists
    if [[ ! -e "/dev/media${device_id}" ]]; then
        echo "ERROR: Media device /dev/media${device_id} not found."
        echo "Available media devices:"
        for m in /dev/media*; do
            [[ -e "$m" ]] || continue
            echo "  - $m"
        done
        exit 2
    fi

    # Ensure this media device has at least one supported camera entity
    if ! media-ctl -d "/dev/media${device_id}" -p 2>/dev/null | grep -E -q "$(printf '%s|' "${SUPPORTED_MODELS[@]}" | sed 's/|$//')"; then
        echo "ERROR: /dev/media${device_id} does not appear to contain any supported cameras (${SUPPORTED_MODELS[*]})."
        echo "Inspect topology with:"
        echo "  media-ctl -d /dev/media${device_id} -p"
        exit 3
    fi
}


# Create media pipeline
create_pipeline() {
    local device_id="$1"
    local capture_width="$2"
    local capture_height="$3"
    local media_device="/dev/media${device_id}"

    # Find which camera is actually on this media device
    local selected_camera=""
    for cam in "${cameras[@]}"; do
        if media-ctl -d "$media_device" -p 2>/dev/null | grep -q "$cam"; then
            selected_camera="$cam"
            break
        fi
    done

    if [[ -z "$selected_camera" ]]; then
        echo "ERROR: No supported camera found on $media_device"
        exit 1
    fi

    # Extract entity names from media-ctl -p output
    local device_csi2=$(media-ctl -d "$media_device" -p | grep -E "^- entity.*csi" | sed 's/.*: \([^ ]*\) .*/\1/')
    local device_cru=$(media-ctl -d "$media_device" -p | grep -E "^- entity.*cru-ip" | sed 's/.*: \([^ ]*\) .*/\1/')
    local cru_output="CRU output"

    echo "Using camera: $selected_camera"
    echo "Using CSI2: $device_csi2"
    echo "Using CRU: $device_cru"

    if [[ -z "$device_csi2" || -z "$device_cru" ]]; then
        echo "ERROR: Could not find CSI2 or CRU entities on $media_device"
        echo "Available entities:"
        media-ctl -d "$media_device" -p | grep -E "^- entity"
        exit 1
    fi

    # Get camera model for format lookup
    local cam_model=$(get_cam_model "$selected_camera")
    local pixfmt=${CAMERA_DEFAULT_FORMAT[$cam_model]}
    local resolution=$(check_resolution "$cam_model" "$capture_width" "$capture_height")
    local v4l2_pixfmt="${CAMERA_V4L2_PIXFMT[$pixfmt]}"
    local width=${resolution%x*}
    local height=${resolution#*x}

    echo "Using format: $pixfmt"
    echo "Using resolution: ${width}x${height}"

    MEDIA_DEV="$media_device"

    # Clear previous links
    media-ctl -d "$MEDIA_DEV" -r

    # Link pads
    echo "Setting up links..."
    media-ctl -d "$MEDIA_DEV" -l "'$selected_camera':0 -> '$device_csi2':0 [1]"
    media-ctl -d "$MEDIA_DEV" -l "'$device_csi2':1 -> '$device_cru':0 [1]"
    media-ctl -d "$MEDIA_DEV" -l "'$device_cru':1 -> '$cru_output':0 [1]"

    # Set formats
    echo "Setting up formats..."
    media-ctl -d "$MEDIA_DEV" -V "\"$selected_camera\":0 [fmt:${pixfmt}/${width}x${height} field:none colorspace:srgb]"
    media-ctl -d "$MEDIA_DEV" -V "\"$device_csi2\":0 [fmt:${pixfmt}/${width}x${height} field:none colorspace:srgb]"
    media-ctl -d "$MEDIA_DEV" -V "\"$device_csi2\":1 [fmt:${pixfmt}/${width}x${height} field:none colorspace:srgb]"
    media-ctl -d "$MEDIA_DEV" -V "\"$device_cru\":0 [fmt:${pixfmt}/${width}x${height} field:none colorspace:srgb]"
    media-ctl -d "$MEDIA_DEV" -V "\"$device_cru\":1 [fmt:${pixfmt}/${width}x${height} field:none colorspace:srgb]"

    v4l2-ctl -d "/dev/video${device_id}" --set-fmt-video=width=${width},height=${height},pixelformat=${v4l2_pixfmt}

    echo "Pipeline successfully configured for ${width}x${height}"
}

# Parse arguments
parse_shell_args() {
    local device_id=${DEFAULT_DEVICE_ID}
    local capture_width=${DEFAULT_CAPTURE_WIDTH}
    local capture_height=${DEFAULT_CAPTURE_HEIGHT}

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --device)
                if [[ -z "${2:-}" ]]; then
                    echo "ERROR: --device requires a value."
                    print_usage
                    exit 1
                fi
                device_id="$2"
                shift 2
                ;;
            --width)
                if [[ -z "${2:-}" ]]; then
                    echo "ERROR: --width requires a value."
                    print_usage
                    exit 1
                fi
                capture_width="$2"
                shift 2
                ;;
            --height)
                if [[ -z "${2:-}" ]]; then
                    echo "ERROR: --height requires a value."
                    print_usage
                    exit 1
                fi
                capture_height="$2"
                shift 2
                ;;
            --help)    print_usage; exit 0;;
            *)         echo "ERROR: Unknown parameter: $1"; print_usage; exit 1;;
        esac
    done

    validate_device_index "$device_id"
    create_pipeline "$device_id" "$capture_width" "$capture_height"
}

# Main
parse_shell_args "$@"

