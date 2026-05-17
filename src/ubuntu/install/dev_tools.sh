#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install developer tools"
apt-get update
apt-get install -y --no-install-recommends \
    git \
    vim \
    nano \
    make \
    jq \
    unzip \
    zip \
    python3 \
    python3-pip \
    nodejs \
    npm
apt-get clean -y
rm -rf /var/lib/apt/lists/*
