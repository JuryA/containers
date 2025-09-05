# Base Image Evaluation

## Comparison

| Feature | bitnami/minideb:bookworm | debian:bookworm-slim |
|---------|-------------------------|----------------------|
| Size (compressed) | ~35 MB | ~69 MB |
| Package manager | `apt` with Bitnami hooks (`install_packages`) | plain `apt` |
| Locales | only `C.UTF-8` | `C.UTF-8` plus `en_US.UTF-8` minimal |
| CA certificates | bundled in `/etc/ssl/certs/ca-certificates.crt` | same path via `ca-certificates` package |
| Timezone data | `/usr/share/zoneinfo` trimmed | full `tzdata` |
| Shells | `/bin/bash` and `/bin/sh` | `/bin/bash` and `/bin/sh` |
| Init | `tini` preinstalled | none (install `tini` manually) |
| Default user | root (UID 0); Bitnami images later add UID 1001 | root (UID 0) |
| Docs/manpages | stripped | stripped |
| Security hardening | minimal; no `seccomp` profile | inherits Debian defaults |

## Differences and Considerations

- **Package names** – Debian uses the standard archive; Bitnami replaces packages with custom recompiles. Swapping bases may require adjusting package names or versions.
- **PATH/ENV** – Bitnami adds `/opt/bitnami` to `PATH` and sets `BITNAMI_APP_NAME`; Debian slim does not.
- **Init/tini** – Bitnami ships `/usr/bin/tini` as PID1. When switching, explicitly install `tini` and use `ENTRYPOINT ["/usr/bin/tini", "--"]`.
- **UID/GID** – ensure the `1001` user/group is created to match Bitnami conventions.
- **Locale & timezone** – install `locales` and `tzdata` packages to replicate Bitnami behavior.
- **SSL trust** – both place certificates at `/etc/ssl/certs/ca-certificates.crt`; confirm path for applications expecting Bitnami's `curl-ca-bundle.crt` symlink.

## Safe Swap Procedure

1. Replace base line in Dockerfile:
   ```diff
- FROM docker.io/bitnami/minideb:bookworm
+ FROM debian:bookworm-slim
   ```
2. Install required packages:
   ```Dockerfile
   RUN apt-get update && \
       apt-get install -y --no-install-recommends \
         ca-certificates tzdata locales tini && \
       rm -rf /var/lib/apt/lists/*
   ```
3. Create Bitnami-compatible user:
   ```Dockerfile
   RUN useradd -r -u 1001 -g 0 bitnami
   ```
4. Restore PATH and `TINI` entrypoint:
   ```Dockerfile
   ENV PATH="/opt/bitnami/common/bin:$PATH"
   ENTRYPOINT ["/usr/bin/tini", "--"]
   ```

## A/B Test Plan

1. Build images with `BASE_IMAGE=minideb` and `BASE_IMAGE=debian`.
2. Run compatibility tests (`tests/compat/run.sh`) against both.
3. Capture:
   - `docker image ls` size
   - CVE scan output (Trivy/Grype)
   - Start-up latency via `time docker run ...`
   - Peak RSS using `docker stats`
4. Promote Debian base once metrics are equivalent or improved.

