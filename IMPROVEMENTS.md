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

## Changes Log

*(filled in after each iteration)*
