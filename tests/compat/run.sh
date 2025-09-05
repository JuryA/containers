#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build rootfs via Nix
if ! "$DIR/../../scripts/build-rootfs.sh"; then
  echo "rootfs build failed" >&2
  exit 1
fi

# Build Docker image using Nix rootfs
if command -v docker >/dev/null 2>&1; then
  docker build -t poc-nix --build-arg BASE_SOURCE=nix -f "$DIR/../../Dockerfile.nix" "$DIR/../.."
  docker run --rm poc-nix /bin/bash -lc 'echo smoke test'
else
  echo "docker is not available; skipping container smoke test" >&2
fi
