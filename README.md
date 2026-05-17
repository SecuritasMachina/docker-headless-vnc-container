# Docker container images with "headless" VNC session

Headless virtual desktop environments in Docker, accessible via browser or VNC viewer.

Each Docker image includes:

* Desktop environment [**Xfce4**](http://www.xfce.org) or [**IceWM**](http://www.icewm.org/)
* [**TigerVNC**](https://tigervnc.org/) server (port `5901`)
* [**noVNC**](https://github.com/novnc/noVNC) HTML5 VNC client (port `6901`)
* Browsers: **Mozilla Firefox** (current, via Mozilla PPA) and **Google Chrome** (stable)
* Clipboard sync between browser/VNC client and desktop (via `vncconfig`)
* Tools: `xdotool`, `xdpyinfo`, `autocutsel` for UI automation and testing

**Base OS:** Ubuntu 22.04 LTS

> **Note:** CentOS images are deprecated (CentOS 7 EOL June 2024). Use Ubuntu images.

---

## Available Images

| Dockerfile | Description | Ports |
|---|---|---|
| `Dockerfile.ubuntu.xfce.vnc` | Ubuntu 22.04 + Xfce4 (base) | 5901 (VNC), 6901 (noVNC) |
| `Dockerfile.ubuntu.xfce.dev.vnc` | + code-server (VS Code in browser) | + 8443 |
| `Dockerfile.ubuntu.icewm.vnc` | Ubuntu 22.04 + IceWM (lightweight) | 5901, 6901 |

---

## Quick Start

```bash
# Start base Xfce image
docker compose up --build

# Start dev image (with code-server)
docker compose --profile dev up --build

# Open in browser:
#   http://localhost:6901        — desktop (noVNC)
#   http://localhost:8443        — VS Code (dev image only)
```

## Usage

```bash
# Run with custom password and resolution (always use --shm-size!)
docker run -d \
  --shm-size=256m \
  -p 6901:6901 \
  -e VNC_PW=my-secret-pw \
  -e VNC_RESOLUTION=1440x900 \
  consol/ubuntu-xfce-vnc

# View-only mode (read-only VNC access)
docker run -d --shm-size=256m -p 6901:6901 -e VNC_VIEW_ONLY=true consol/ubuntu-xfce-vnc

# Interactive bash session
docker run -it --shm-size=256m -p 6901:6901 consol/ubuntu-xfce-vnc bash

# Change resolution at runtime (no restart needed)
docker exec <container-id> /dockerstartup/vnc_set_resolution.sh 1920x1080
```

## Connect & Control

| Method | URL / Address | Password |
|---|---|---|
| **noVNC (full client)** | `http://localhost:6901/vnc.html` | `vncpassword` |
| **noVNC (lite client)** | `http://localhost:6901/vnc_lite.html` | `vncpassword` |
| **VNC viewer** | `localhost:5901` | `vncpassword` |
| **code-server** (dev image) | `http://localhost:8443` | none |

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `VNC_PW` | `vncpassword` | VNC password (change this!) |
| `VNC_RESOLUTION` | `1280x1024` | Screen resolution (`WxH`) |
| `VNC_COL_DEPTH` | `24` | Color depth (bits) |
| `VNC_VIEW_ONLY` | `false` | Set `true` for read-only VNC |
| `CODE_SERVER_PORT` | `8443` | code-server port (dev image only) |
| `CODE_SERVER_AUTH` | `none` | code-server auth (`none` or `password`) |

---

## Hints

### 1) Extend the image with your own software

All images run as non-root user (`uid=1000`) by default. Switch to root to install:

```dockerfile
FROM consol/ubuntu-xfce-vnc

# Switch to root to install additional software
USER 0

RUN apt-get update && apt-get install -y gedit && apt-get clean

# Switch back to default user
USER 1000
```

### 2) Change the user ID

```bash
# Run as root
docker run -it --user 0 -p 6901:6901 consol/ubuntu-xfce-vnc

# Run as your host user
docker run -it -p 6901:6901 --user $(id -u):$(id -g) consol/ubuntu-xfce-vnc
```

### 3) Dynamic resolution change

Change the screen resolution at runtime without restarting:

```bash
docker exec <container-id> /dockerstartup/vnc_set_resolution.sh 1920x1080
```

### 4) Kubernetes / OpenShift

See [kubernetes/README.md](./kubernetes/README.md) and [openshift/README.md](./openshift/README.md).

The `kubernetes/kubernetes.headless-vnc.example.deployment.yaml` manifest includes proper
resource limits and the `/dev/shm` memory volume required to prevent browser crashes.

### 5) Traefik integration

Set environment variables before running `docker compose`:

```bash
TRAEFIK_ENABLE=true TRAEFIK_HOST=vnc.example.com docker compose up
```

### 6) Known Issues

#### 6.1) Browser crashes at high resolution

The default Docker `/dev/shm` (64MB) causes Chrome/Firefox to crash at high resolutions.
**Always use `--shm-size=256m`** (or `512m` for 1080p+):

```bash
docker run --shm-size=256m -p 6901:6901 -e VNC_RESOLUTION=1920x1080 consol/ubuntu-xfce-vnc
```

The `docker-compose.yml` already sets `shm_size: "256m"`.

#### 6.2) Clipboard not working

Clipboard sync requires:
1. Using the **noVNC full client** (`/vnc.html`) — the lite client has limited clipboard support
2. Clicking the clipboard icon in the noVNC toolbar and using the text box there

VNC viewer native clipboard sync is enabled automatically via `vncconfig`.

---

## Contributors

* [Tobias Schneck](https://github.com/toschneck) — Lead development
* [Robert Bohne](https://github.com/rbo) — IceWM images
* [Simon Hofmann](https://github.com/s1hofmann) — Maintainer

## Changelog

See [changelog.md](./changelog.md).
