#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install code-server (VS Code in browser)"
curl -fsSL https://code-server.dev/install.sh | sh
echo "code-server installed: $(code-server --version)"
