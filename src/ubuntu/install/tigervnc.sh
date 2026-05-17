#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install TigerVNC via apt"
apt-get update
apt-get install -y --no-install-recommends \
    tigervnc-standalone-server \
    tigervnc-common
apt-get clean -y
rm -rf /var/lib/apt/lists/*
