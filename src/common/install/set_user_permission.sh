#!/usr/bin/env bash
### every exit != 0 fails the script
set -e
if [[ -n $DEBUG ]]; then
    verbose="-v"
fi

for var in "$@"
do
    echo "fix permissions for: $var"
    chgrp -R 0 "$var" && chmod -R $verbose a+rw "$var" && find "$var" -type d -exec chmod $verbose a+x {} +
    # Make shell scripts executable
    find "$var"/ -name '*.sh' -exec chmod $verbose a+x {} +
    find "$var"/ -name '*.desktop' -exec chmod $verbose a+x {} +
    # Make wrapper scripts without extension executable (e.g. google-chrome-docker)
    find "$var"/ -maxdepth 1 -type f -not -name '*.*' -exec chmod $verbose a+x {} +
done