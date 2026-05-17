#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install IceWM UI components"
apt-get update
apt-get install -y --no-install-recommends \
    supervisor \
    icewm \
    xterm \
    xfonts-base \
    xauth \
    xinit \
    dbus-x11
apt-get purge -y xscreensaver* || true
apt-get clean -y
rm -rf /var/lib/apt/lists/*