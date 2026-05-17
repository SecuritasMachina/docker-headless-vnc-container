#!/bin/bash
# Change VNC resolution at runtime without restarting the container.
#
# Usage:
#   /dockerstartup/vnc_set_resolution.sh 1920x1080
#   VNC_RESOLUTION=1920x1080 /dockerstartup/vnc_set_resolution.sh
#
# Also works as: docker exec <container> /dockerstartup/vnc_set_resolution.sh 1920x1080

set -e

TARGET_RES="${1:-${VNC_RESOLUTION:-1280x1024}}"
DISPLAY="${DISPLAY:-:1}"

if [[ -z "$TARGET_RES" ]]; then
    echo "Usage: vnc_set_resolution.sh <WxH>  (e.g. 1920x1080)"
    exit 1
fi

W=${TARGET_RES%x*}
H=${TARGET_RES#*x}

if ! [[ "$W" =~ ^[0-9]+$ && "$H" =~ ^[0-9]+$ ]]; then
    echo "[ERROR] Invalid resolution: '$TARGET_RES'. Expected format: WxH (e.g. 1280x1024)"
    exit 1
fi

echo "Setting display $DISPLAY resolution to ${W}x${H}"

# Check if the modeline already exists
if ! xrandr --display "$DISPLAY" | grep -q "${W}x${H}"; then
    MODELINE=$(cvt "$W" "$H" 60 | grep Modeline | sed 's/Modeline //')
    MODE_NAME=$(echo "$MODELINE" | awk '{print $1}' | tr -d '"')
    xrandr --display "$DISPLAY" --newmode $MODELINE
    xrandr --display "$DISPLAY" --addmode VNC-0 "$MODE_NAME" 2>/dev/null \
        || xrandr --display "$DISPLAY" --addmode Screen0 "$MODE_NAME" 2>/dev/null \
        || true
fi

xrandr --display "$DISPLAY" -s "${W}x${H}" 2>/dev/null \
    || xrandr --display "$DISPLAY" --output VNC-0 --mode "${W}x${H}" 2>/dev/null \
    || xrandr --display "$DISPLAY" --output Screen0 --mode "${W}x${H}" 2>/dev/null \
    || true

echo "Done. Current display info:"
xrandr --display "$DISPLAY" | head -5
