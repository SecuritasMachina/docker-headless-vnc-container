#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install CJK fonts (wqy-zenhei)"
apt-get update
apt-get install -y --no-install-recommends fonts-wqy-zenhei
apt-get clean -y
rm -rf /var/lib/apt/lists/*
