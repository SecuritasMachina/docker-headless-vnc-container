#!/usr/bin/env bash
### every exit != 0 fails the script
set -e
set -u

echo "Install noVNC and websockify via apt"
apt-get update
apt-get install -y --no-install-recommends \
    novnc \
    python3-websockify
apt-get clean -y
rm -rf /var/lib/apt/lists/*

## Ensure index.html exists (apt package includes it, but add symlink fallback)
if [ ! -f "$NO_VNC_HOME/index.html" ]; then
    ln -s "$NO_VNC_HOME/vnc_lite.html" "$NO_VNC_HOME/index.html"
fi