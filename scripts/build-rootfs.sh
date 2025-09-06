#!/usr/bin/env bash
set -euo pipefail

if ! command -v nix >/dev/null 2>&1; then
  echo "Error: 'nix' is required but not installed." >&2
  echo "Please install Nix by following the instructions at:" >&2
  echo "  https://nixos.org/download.html" >&2
  exit 1
fi

nix --extra-experimental-features 'nix-command flakes' build .#bash-rootfs-tarball
cp result/bash-rootfs.tar.gz app-rootfs.tar.gz
