#!/bin/sh

gpu_dev=$(find /sys/bus/platform/devices -name '*gpu' | head -n1)
display_dev=$(find /sys/bus/platform/devices -name '*display' | head -n1)

if [ -z "$gpu_dev" ] || [ -z "$display_dev" ]; then
    echo "Missing gpu or display, skipping Xorg config override."
    exit 0
fi

display_drm_card=""

for card in /sys/class/drm/card*; do
    if [ -e "$card/device" ] && [ "$(readlink -f "$card/device")" = "$(readlink -f "$display_dev")" ]; then
        display_drm_card="/dev/dri/$(basename "$card")"
        break
    fi
done

if [ -z "$display_drm_card" ]; then
    echo "Could not find DRM card for display."
    exit 1
fi

mkdir -p /etc/X11/xorg.conf.d

cat <<EOF > /etc/X11/xorg.conf.d/10-force-display.conf
Section "Device"
    Identifier  "DisplayController"
    Driver      "modesetting"
    Option      "kmsdev" "$display_drm_card"
    Option      "AccelMethod" "glamor"
EndSection
EOF

echo "Created Xorg config forcing $display_drm_card"
