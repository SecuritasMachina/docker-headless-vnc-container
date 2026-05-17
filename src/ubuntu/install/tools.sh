#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install common tools"
apt-get update
apt-get install -y --no-install-recommends \
    curl \
    wget \
    net-tools \
    locales \
    vim \
    gettext \
    ca-certificates \
    gnupg \
    lsb-release \
    xdotool \
    xdpyinfo \
    autocutsel
apt-get clean -y
rm -rf /var/lib/apt/lists/*

echo "Generate locale en_US.UTF-8"
locale-gen en_US.UTF-8
