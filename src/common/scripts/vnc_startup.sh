#!/bin/bash

## print out help
help (){
echo "
USAGE:
docker run -it -p 6901:6901 -p 5901:5901 consol/<image>:<tag> <option>

IMAGES:
consol/ubuntu-xfce-vnc
consol/centos-xfce-vnc
consol/ubuntu-icewm-vnc
consol/centos-icewm-vnc

TAGS:
latest  stable version of branch 'master'
dev     current development version of branch 'dev'

OPTIONS:
-w, --wait      (default) keeps the UI and the vncserver up until SIGINT or SIGTERM will received
-s, --skip      skip the vnc startup and just execute the assigned command.
                example: docker run consol/centos-xfce-vnc --skip bash
-d, --debug     enables more detailed startup output
                e.g. 'docker run consol/centos-xfce-vnc --debug bash'
-h, --help      print out this help

Fore more information see: https://github.com/ConSol/docker-headless-vnc-container
"
}
if [[ ${1:-} =~ -h|--help ]]; then
    help
    exit 0
fi

# source $STARTUPDIR/generate_container_user for non-root user support
source $HOME/.bashrc

# add `--skip` to startup args, to skip the VNC startup procedure
if [[ ${1:-} =~ -s|--skip ]]; then
    echo -e "\n\n------------------ SKIP VNC STARTUP -----------------"
    echo -e "\n\n------------------ EXECUTE COMMAND ------------------"
    echo "Executing command: '${@:2}'"
    exec "${@:2}"
fi
if [[ ${1:-} =~ -d|--debug ]]; then
    echo -e "\n\n------------------ DEBUG VNC STARTUP -----------------"
    export DEBUG=true
fi

## correct forwarding of shutdown signal
cleanup () {
    kill -s SIGTERM $!
    exit 0
}
trap cleanup SIGINT SIGTERM

## validate VNC_RESOLUTION format
if ! echo "${VNC_RESOLUTION:-}" | grep -qE '^[0-9]+x[0-9]+$'; then
    echo -e "\e[1;31m[ERROR] VNC_RESOLUTION='${VNC_RESOLUTION:-}' is invalid. Expected format: WxH (e.g. 1280x1024)\e[0m"
    exit 1
fi

## write correct window size to chrome properties
$STARTUPDIR/chrome-init.sh

## resolve VNC IP
VNC_IP=$(hostname -i)

## change VNC password
echo -e "\n------------------ change VNC password  ------------------"
mkdir -p "$HOME/.vnc"
PASSWD_PATH="$HOME/.vnc/passwd"

if [[ -f $PASSWD_PATH ]]; then
    echo -e "\n---------  purging existing VNC password settings  ---------"
    rm -f $PASSWD_PATH
fi

if [[ ${VNC_VIEW_ONLY:-false} == "true" ]]; then
    echo "start VNC server in VIEW ONLY mode!"
    echo $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20) | vncpasswd -f > $PASSWD_PATH
fi
echo "$VNC_PW" | vncpasswd -f >> $PASSWD_PATH
chmod 600 $PASSWD_PATH

if [[ "$VNC_PW" == "vncpassword" ]]; then
    echo -e "\e[1;33m[WARN] Using default VNC password 'vncpassword' — set VNC_PW env var to change it\e[0m"
fi

## Create xstartup for the window manager (required by TigerVNC 1.12+)
## vncconfig -nowin enables clipboard sync between VNC client and X session
cat > "$HOME/.vnc/xstartup" << 'XSTARTUP_EOF'
#!/bin/bash
vncconfig -nowin &
exec $HOME/wm_startup.sh
XSTARTUP_EOF
chmod +x "$HOME/.vnc/xstartup"

## start VNC server
echo -e "\n------------------ start VNC server ------------------------"
echo "removing stale VNC locks if any"
vncserver -kill $DISPLAY &> $STARTUPDIR/vnc_startup.log \
    || rm -rfv /tmp/.X*-lock /tmp/.X11-unix &> $STARTUPDIR/vnc_startup.log \
    || echo "no locks present"

echo -e "starting vncserver: VNC_COL_DEPTH=$VNC_COL_DEPTH  VNC_RESOLUTION=$VNC_RESOLUTION"
if [[ $DEBUG == true ]]; then
    echo "  cmd: vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION -localhost no"
fi
if ! vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION -localhost no \
        &> $STARTUPDIR/vnc_startup.log; then
    echo -e "\n\e[1;31m[ERROR] vncserver failed to start — see $STARTUPDIR/vnc_startup.log\e[0m"
    cat $STARTUPDIR/vnc_startup.log
    exit 1
fi

## start noVNC using websockify
echo -e "\n------------------ start noVNC  ----------------------------"
if [[ $DEBUG == true ]]; then
    echo "  cmd: websockify --web $NO_VNC_HOME $NO_VNC_PORT localhost:$VNC_PORT"
fi
websockify --web "$NO_VNC_HOME" "$NO_VNC_PORT" "localhost:$VNC_PORT" \
    &> $STARTUPDIR/no_vnc_startup.log &
PID_SUB=$!

## verify noVNC started
sleep 1
if ! kill -0 $PID_SUB 2>/dev/null; then
    echo -e "\n\e[1;31m[ERROR] noVNC/websockify failed — see $STARTUPDIR/no_vnc_startup.log\e[0m"
    cat $STARTUPDIR/no_vnc_startup.log
    exit 1
fi

## start code-server if installed and CODE_SERVER_PORT is configured
if command -v code-server &>/dev/null && [[ -n "${CODE_SERVER_PORT:-}" ]]; then
    echo -e "\n------------------ start code-server ------------------------"
    if [[ $DEBUG == true ]]; then
        echo "  cmd: code-server --bind-addr 0.0.0.0:${CODE_SERVER_PORT} --auth ${CODE_SERVER_AUTH:-none} /workspace"
    fi
    code-server \
        --bind-addr "0.0.0.0:${CODE_SERVER_PORT}" \
        --auth "${CODE_SERVER_AUTH:-none}" \
        /workspace &>> $STARTUPDIR/code_server_startup.log &
    PID_CODE=$!
    echo -e "\ncode-server started:\n\t=> connect via http://$VNC_IP:$CODE_SERVER_PORT\n"
fi

## log connect info
echo -e "\n\n========== VNC environment ready =========="
echo -e "  VNC viewer:       $VNC_IP:$VNC_PORT"
echo -e "  noVNC (full):     http://$VNC_IP:$NO_VNC_PORT/vnc.html?autoconnect=true"
echo -e "  noVNC (lite):     http://$VNC_IP:$NO_VNC_PORT/vnc_lite.html?password=..."
if [[ -n "${CODE_SERVER_PORT:-}" ]]; then
    echo -e "  code-server:      http://$VNC_IP:$CODE_SERVER_PORT"
fi
echo -e "  password:         set via VNC_PW env var (current: ${#VNC_PW} chars)"
echo -e "==========================================="

if [[ $DEBUG == true ]] || [[ ${1:-} =~ -t|--tail-log ]]; then
    echo -e "\n------------------ tailing logs ------------------"
    tail -f $STARTUPDIR/*.log $HOME/.vnc/*$DISPLAY.log
fi

if [ -z "${1:-}" ] || [[ ${1:-} =~ -w|--wait ]]; then
    wait $PID_SUB
else
    echo -e "\n\n------------------ EXECUTE COMMAND ------------------"
    echo "Executing command: '$@'"
    exec "$@"
fi
