# Bitnami Artifact Replacement with Nix

## Mapping of Artifacts

*Versions correspond to packages in `nixos-24.05` at commit `b134951a4c9f3c995fd7be05f3243f8ecd65d798`.*

| Bitnami component | Source URL / tag | nixpkgs attribute | Version | Notes |
|------------------|-----------------|-------------------|---------|------|
| Bash | downloads.bitnami.com/files/stacksmith/bash-5.2.26-0-linux-amd64-debian-12.tar.gz | `pkgs.bash` | 5.2p32 | Same major/minor; Nix includes upstream patches. |
| Coreutils | downloads.bitnami.com/files/stacksmith/coreutils-9.4-0-linux-amd64-debian-12.tar.gz | `pkgs.coreutils` | 9.5 | Provides `/bin/env` and other GNU tools. |
| glibc runtime | included in Bitnami base | `pkgs.glibc` | 2.39-52 | Supplies dynamic loader and libc for binaries. |
| CA certificates | Bitnami `ca-certificates` package | `pkgs.cacert` | 3.107 | Populates `/etc/ssl/certs/ca-certificates.crt`. |
| (example app) Nginx | downloads.bitnami.com/files/stacksmith/nginx-1.25.5-0-linux-amd64-debian-12.tar.gz | `pkgs.nginx` | 1.24.0* | Build-time modules mirrored; pin exact commit for ABI compatibility. |

\*Nixpkgs 24.05 ships Nginx 1.24.0; override to 1.25.x when available.

## Building a Nix Closure Without `/nix`

1. **Derive components** with `flake.nix`:
   ```nix
   pkgs.runCommand "bash-rootfs" { buildInputs = [ pkgs.patchelf ]; } ''
     mkdir -p $out
     cp ${pkgs.bash}/bin/bash $out/bin/
     ...
   ''
   ```
2. **Flatten** outputs via `copyToRoot`/`runCommand`, removing `/nix/store` paths and relocating files into FHS locations (`/bin`, `/lib`, `/opt/bitnami`).
3. **Patch ELF** binaries using `patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 --set-rpath /lib` so they execute without Nix.
4. **Tarball** the result:
   ```bash
   nix build .#bash-rootfs-tarball
   cp result/bash-rootfs.tar.gz app-rootfs.tar.gz
   ```
5. **Dockerfile integration**:
   ```dockerfile
   ARG BASE_SOURCE=bitnami
   FROM debian:bookworm-slim AS bitnami
   # existing curl from downloads.bitnami.com ...

   FROM debian:bookworm-slim AS nix
   ADD app-rootfs.tar.gz /

   FROM ${BASE_SOURCE}
   RUN groupadd --system --gid 1001 bitnami \
       && useradd --system --uid 1001 --gid bitnami --shell /bin/bash bitnami
   ```

### Alternative tooling
- `nixpkgs.dockerTools`: use `copyToRoot` and `buildLayeredImage` to generate layers; export with `dockerTools.streamLayeredImage`.
- `nix2container`: `copyToRoot` + `extraCommands` to run `patchelf` and drop `/nix` before emitting a layer tarball.

## Validation Plan

1. **ABI parity** – run `ldd` on copied binaries; compare against Bitnami artifacts.
2. **Executable set** – ensure `/bin/bash`, `/bin/env`, application binaries under `/opt/bitnami`.
3. **Locale & timezone** – verify `locale -a` includes `C.UTF-8`; `/usr/share/zoneinfo` populated.
4. **Certificates** – check `/etc/ssl/certs/ca-certificates.crt` hash matches upstream.
5. **Users** – `/etc/passwd` contains UID 1001 bitnami user.
6. **NSS** – `getent hosts localhost` works; `/etc/nsswitch.conf` copied.
7. **Smoke test** – run container with `ENTRYPOINT` unchanged and ensure service starts.

## Risk Matrix

| Risk | Description | Mitigation |
|------|-------------|------------|
| Size growth | Nix closures may include unneeded runtime deps. | Use `nix why-depends`, prune paths, strip binaries. |
| CVE surface | Different build flags from Bitnami may expose new CVEs. | Track advisories via `nixpkgs` channel updates and Trivy/Grype scans. |
| Update cadence | Nixpkgs updates weekly; pin flake to commit and bump with automation. | Use Renovate/bot to open PRs with new hashes. |
| CI complexity | Requires Nix tooling on CI runners. | Provide flake‑based build in workflow; cache `/nix/store` between jobs. |
| Portability | Non‑glibc platforms need per‑arch builds. | Extend flake outputs for `aarch64-linux` etc. |

## Rollback Plan

- Introduce `ARG BASE_SOURCE=nix` in Dockerfiles with default `bitnami`.
- Provide CI job that builds both variants; promote Nix-based build after parity.
- Roll back by setting `BASE_SOURCE=bitnami` or reverting to previous tarball.
- Maintain archived Bitnami tarballs for older releases during transition.

