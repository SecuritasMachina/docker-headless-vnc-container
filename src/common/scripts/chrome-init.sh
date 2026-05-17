#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

VNC_RES_W=${VNC_RESOLUTION%x*}
VNC_RES_H=${VNC_RESOLUTION#*x}

echo -e "\n------------------ configure Chrome/Chromium startup flags ------------------"
echo -e "... setting window size ${VNC_RES_W}x${VNC_RES_H}\n"

## Legacy Chromium init file (kept for images that still use chromium-browser)
echo "CHROMIUM_FLAGS='--no-sandbox --disable-gpu --user-data-dir --window-size=${VNC_RES_W},${VNC_RES_H} --window-position=0,0'" \
    > $HOME/.chromium-browser.init

## Google Chrome wrapper: write docker-compatible flags to ~/.chrome-flags
## The google-chrome-docker wrapper script reads this file at launch.
cat > $HOME/.chrome-flags << EOF
--no-sandbox
--disable-gpu
--window-size=${VNC_RES_W},${VNC_RES_H}
--window-position=0,0
EOF
