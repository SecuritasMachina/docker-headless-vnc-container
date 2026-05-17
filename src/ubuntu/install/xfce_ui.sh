#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install Xfce4 UI components"
apt-get update
apt-get install -y --no-install-recommends \
    supervisor \
    xfce4 \
    xfce4-terminal \
    xterm \
    dbus-x11
# Remove screensaver to keep the desktop visible in VNC sessions
apt-get purge -y xscreensaver* || true
apt-get clean -y
rm -rf /var/lib/apt/lists/*