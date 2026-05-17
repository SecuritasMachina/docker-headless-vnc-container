#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo -e "\n------------------ startup of Xfce4 window manager ------------------"

### Disable screensaver and power management (desktop remains visible)
xset -dpms &
xset s noblank &
xset s off &

### Start autocutsel to sync PRIMARY and CLIPBOARD X selections
### This ensures that middle-click paste and Ctrl+C/V both work
if command -v autocutsel &>/dev/null; then
    autocutsel -fork &
    autocutsel -selection PRIMARY -fork &
fi

/usr/bin/startxfce4 --replace > $HOME/wm.log &
sleep 1
cat $HOME/wm.log
