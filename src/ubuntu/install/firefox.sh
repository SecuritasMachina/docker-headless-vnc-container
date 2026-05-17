#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install Firefox via Mozilla PPA (avoids Ubuntu's snap wrapper)"
apt-get update
apt-get install -y --no-install-recommends software-properties-common
add-apt-repository -y ppa:mozillateam/ppa
# Prefer PPA version over snap stub
printf '%s\n' \
    'Package: *' \
    'Pin: release o=LP-PPA-mozillateam' \
    'Pin-Priority: 1001' \
    > /etc/apt/preferences.d/mozilla-firefox
apt-get update
apt-get install -y --no-install-recommends firefox
apt-get clean -y
rm -rf /var/lib/apt/lists/*
