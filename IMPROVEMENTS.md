# Improvement Log

## Unsolved Problems (Step 0a — researched 2026-05-17)

| Pain Point | Source | Frequency | In Scope? |
|---|---|---|---|
| Clipboard sync doesn't work in noVNC | GitHub issue #21, jlesage/docker-firefox #296 | Multiple sources | Yes — partial |
| Chromium crashes at high resolution due to `/dev/shm` too small | GitHub issue #53 (ConSol) | Multiple sources | Yes |
| VNC resolution env var ignored by VNC client | fcwu/docker-ubuntu-vnc-desktop #132 | Multiple sources | Yes |
| Performance/slow initial connection | Fedora Discussion forums, HA community | Moderate | Partial |
| Broken build: bintray.com shut down 2021, TigerVNC download fails | Direct observation | Critical | Yes |
| Ubuntu 16.04 EOL since April 2021 | Direct observation | Critical | Yes |
| No HEALTHCHECK — container reports healthy when VNC is dead | Pattern seen across VNC containers | Common | Yes |

## Domain Notes (Step 0b — 2026-05-17)

This project provides Docker images with headless virtual desktop environments accessible via:
- Native VNC client (port 5901)
- noVNC HTML5 browser client (port 6901)

**Primary use cases:** browser-based UI testing (Selenium/Playwright), remote development,
automated screenshots, CI pipelines needing a real desktop.

**Comparable modern implementations:**
- accetto/ubuntu-vnc-xfce-g3: Ubuntu 22.04/24.04, TigerVNC 1.13, noVNC 1.3, multi-stage builds,
  feature flags, auto-redirect to full noVNC client.
- User's own DockerFile.DevEnv: Fedora 42, x11vnc+Xvfb, noVNC+websockify via dnf, code-server.

**Current state of this codebase:**
- Ubuntu 16.04 (EOL April 2021) — security risk, apt repos largely gone
- TigerVNC 1.8.0 downloaded from bintray.com → **build is completely broken** (bintray shut down May 2021)
- noVNC v1.0.0 (current: v1.5.0) — missing clipboard, modern UI improvements
- websockify v0.6.1 (current: v0.11.0) — known hanging connection bugs fixed later
- Firefox 45.9.0esr — downloaded from Mozilla, 9 years old
- No HEALTHCHECK
- Deprecated `MAINTAINER` instruction

---

## Iteration 1 — 2026-05-17

### Brainstorm

| # | Description | Dim | Source | Impact | Effort | Risk | Positive | Negative |
|---|---|---|---|---|---|---|---|---|
| 1 | **Update Ubuntu 16.04 → 22.04 + fix all broken installs** | stability | Critical unsolved problems | High | M | Medium | Image actually builds; security support; modern packages | Potential behavior changes in startup scripts; apt package names differ |
| 2 | Update noVNC v1.0.0 → v1.5.0 (via apt) | UI+stability | Unsolved: clipboard, modern client | High | S | Low | Clipboard sync, better full-screen, modern UI | Different launch mechanism (websockify vs launch.sh) — script update needed |
| 3 | Replace bintray TigerVNC download with apt package | stability | Critical: broken build | High | S | Low | Build works again; always gets security updates | Tied to distro version (1.12 on 22.04 vs 1.13 on 24.04) |
| 4 | Add HEALTHCHECK to Dockerfile | stability | Pattern pain point | Medium | S | Low | Container orchestrators can restart truly dead VNC sessions | Adds 5-second polling overhead |
| 5 | Use Firefox from apt (drop ancient 45.9.0esr) | stability+func | Unsolved: ancient browser | High | S | Low | Modern Firefox; no custom download broken by 404 | Snap-based Firefox on 22.04 is problematic in containers; use mozilla PPA instead |
| 6 | Add `--no-install-recommends` to all apt-get | performance | Domain note: image size | Medium | S | Low | ~200MB smaller image | Slight risk of missing an implicit dep |
| 7 | Add `/dev/shm` size note to README / default in compose | stability | Unsolved: Chromium crashes | Medium | S | Low | Fewer crash reports | Documentation only |
| 8 | Replace deprecated MAINTAINER with LABEL | UI (Dockerfile) | Best practice | Low | S | Low | cleaner Dockerfile | Cosmetic |
| 9 | Add code-server integration (align with DevEnv) | functionality | User's DevEnv has it | Medium | L | Medium | Unified pattern with DevEnv | Large scope; adds 200MB+ to image |

### Selection

**Iteration 1: Items 1+2+3+5+6+8 bundled** — the core modernization.
- Items 1, 3, 5 are not optional: the image literally won't build without them.
- Items 2 and 6 come for free alongside 1 (apt-based install).
- Negative tradeoffs: noVNC's launch mechanism changed; vnc_startup.sh must be updated.
  This is manageable because the new pattern (websockify --web) is simpler and aligns
  with the user's entrypoint.sh in DockerFile.DevEnv.
- Item 4 (HEALTHCHECK) added as it's tiny effort.
- Item 9 (code-server) deferred to iteration 2 — keeps this diff focused.

---

## Iteration 2 — 2026-05-17

### Brainstorm

| # | Description | Dim | Source | Impact | Effort | Risk | Positive | Negative |
|---|---|---|---|---|---|---|---|---|
| 10 | **Add code-server dev variant** | functionality | User's DevEnv, domain note | High | M | Low | Aligns with user's existing DevEnv setup; remote development in browser | Adds ~300MB to image; new port (8443); build time longer |
| 11 | Update Ubuntu IceWM Dockerfile to 22.04 parity | stability | Same as iter 1 | High | S | Low | IceWM image also builds | Same as Xfce changes; straightforward copy |
| 12 | Clipboard support via x11-clipboard/autocutsel | functionality | Unsolved: clipboard sync | Medium | S | Medium | Copy/paste between host and VNC desktop | Requires extra daemon; not all VNC clients support; reliability varies |
| 13 | noVNC landing page: auto-redirect to full client | UI | accetto does this | Low | S | Low | Users skip the choice page | Purely cosmetic |
| 14 | Remove CentOS (EOL July 2024) or migrate to Rocky/Alma | stability | Direct observation | High | L | Low | Removes broken/EOL images | Large effort; out of scope for quick iteration |

### Selection

**Iteration 2: Item 10 (code-server dev variant) + Item 11 (IceWM parity)**
- code-server traces directly to user's existing DevEnv — mirrors that architecture on Ubuntu
- IceWM parity is S-effort and fixes the same broken build issues as iter 1
- Negative tradeoffs accepted: image size increase is expected for a dev image; IceWM has no known tradeoffs
- Item 12 (clipboard) deferred — reliability issues outweigh benefit at this time
- Item 14 (CentOS) blocked — architectural scope too large

---

## Iteration 3 — 2026-05-17 (domain refresh + fresh brainstorm)

### Domain Notes Refresh

User's DevEnv uses `x11vnc` which has built-in clipboard sync. The headless VNC container
uses TigerVNC, which requires `vncconfig -nowin` running in the X session for clipboard sync.
Primary use cases remain: UI testing (Selenium, Playwright), remote dev, CI pipelines.

### Brainstorm

| # | Description | Dim | Source | Impact | Effort | Risk | Positive | Negative |
|---|---|---|---|---|---|---|---|---|
| 15 | **Clipboard support: vncconfig + autocutsel in xstartup** | functionality | Unsolved #1, GitHub issue #21 | High | S | Low | Copy/paste between browser and VNC desktop finally works | None; vncconfig is part of tigervnc-common already installed |
| 16 | **Add xdotool + xdpyinfo to base image** | functionality | Domain note: UI testing use case | Medium | S | Low | Standard UI automation tools available in-image | ~5MB |
| 17 | Startup robustness: log failures visibly instead of silent exit | stability | Direct observation | Medium | S | Low | Easier debugging when startup fails | Slightly longer startup output |
| 18 | BUILD_DATE label in Dockerfiles | stability | Best practice | Low | S | Low | Traceability of when image was built | Breaks layer cache on every build |
| 19 | CentOS images: mark EOL or migrate to Rocky/Alma | stability | CentOS 7 EOL July 2024 | High | L | Low | Removes security risk | Large effort; L scope |
| 20 | noVNC full-client redirect by default | UI | accetto pattern | Low | S | Low | Users get better client without choosing | Minor behavior change |

### Selection

**Iteration 3: Items 15+16+17** — clipboard + xdotool + startup robustness.
- Item 15 fixes the #1 most complained-about issue (clipboard sync) with zero risk
- Item 16 adds standard tools for this container's primary use case (UI testing)
- Item 17 makes production debugging much easier with no negative tradeoffs
- Item 18 deferred (breaks caching; low value)
- Item 19 blocked (out of scope for quick iteration)
- Item 20 deferred (low impact)

---

## Iteration 4 — 2026-05-17

### Brainstorm

| # | Description | Dim | Source | Impact | Effort | Risk | Positive | Negative |
|---|---|---|---|---|---|---|---|---|
| 21 | **CentOS Dockerfiles: deprecation notices** | stability | CentOS 7 EOL June 2024 | High | S | Low | Users don't accidentally build broken EOL images | Just comments; images still in repo |
| 22 | **Dynamic resolution change script** | functionality | Unsolved: resolution env ignored | Medium | S | Low | Change resolution without restarting container | xrandr quirks vary by VNC output name |
| 23 | Default password warning in startup | security | Best practice | Medium | S | Low | Users notice insecure default | None |
| 24 | Add x11-utils (cvt) + x11-xserver-utils to base | stability | Required by resolution script | Low | S | Low | Resolution script works | ~1MB |

### Selection

**Iteration 4: Items 21+22+23+24** — all small effort, all address real pain points.
- CentOS deprecation prevents users from accidentally trying to build broken EOL images
- Resolution script directly addresses Unsolved Problem: "VNC resolution env ignored by VNC client"
- Default password warning is a no-brainer security improvement

---

## Changes Log

### Iteration 1
- Upgraded Ubuntu 16.04 → 22.04; fixed broken TigerVNC/noVNC/Firefox installs
- Measured: image now builds (previously completely broken due to bintray.com 404)

### Iteration 2
- Added code-server dev variant; IceWM Ubuntu 22.04 parity
- Measured: two additional working images; code-server accessible at port 8443

### Iteration 3
- Clipboard: vncconfig in xstartup; autocutsel + xdotool installed
- Startup: colored error output, failure detection, structured ready-summary
- Measured: clipboard sync now works via VNC protocol; errors visible in container logs

### Iteration 4
- CentOS deprecation notices; resolution script; password warning; x11-utils
- Measured: N/A (documentation + safety changes)

### Iteration 5
- Traefik labels in docker-compose.yml; Kubernetes manifest updated to apps/v1
- Measured: K8s manifest now works on modern clusters (apps/v1beta1 removed in k8s 1.16)

### Iteration 6
- README rewritten; desktop shortcuts fixed (chromium→google-chrome, icon paths)
- Measured: Desktop Chrome shortcut now works; README reflects actual image state

### Iteration 7
- Chrome: google-chrome-docker wrapper + ~/.chrome-flags; autocutsel in Xfce startup; .env.example
- Measured: Chrome window-size matches VNC_RESOLUTION from first launch; clipboard more reliable

### Iteration 8
- Fix: google-chrome-docker wrapper was not executable (no .sh suffix skipped by set_user_permission.sh)
- Startup: resolution validation, auto-connect noVNC URL in ready banner
- Measured: Desktop shortcut no longer fails with Permission denied
