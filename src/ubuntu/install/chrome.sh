#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install Google Chrome (chromium-browser on Ubuntu 22.04 is a snap stub — not usable in containers)"
wget -q -O /tmp/google-chrome.gpg https://dl-ssl.google.com/linux/linux_signing_key.pub
gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg /tmp/google-chrome.gpg
rm /tmp/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list
apt-get update
apt-get install -y --no-install-recommends google-chrome-stable
apt-get clean -y
rm -rf /var/lib/apt/lists/*

### Fix Chrome to start in a Docker container — disable GPU and sandbox
echo "CHROMIUM_FLAGS='--no-sandbox --disable-gpu --start-maximized --user-data-dir'" > $HOME/.chromium-browser.init
