#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix >/dev/null 2>&1; then
  echo "nix is required" >&2
  exit 1
fi

nix --extra-experimental-features 'nix-command flakes' build .#bash-rootfs-tarball
cp result/bash-rootfs.tar.gz app-rootfs.tar.gz
