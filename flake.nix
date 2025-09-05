{
  description = "PoC Nix build for Bitnami replacement";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    bashRoot = pkgs.runCommand "bash-rootfs" { buildInputs = [ pkgs.patchelf pkgs.findutils ]; } ''
      mkdir -p $out/bin $out/lib $out/lib64 $out/opt/bitnami
      cp ${pkgs.bash}/bin/bash $out/bin/
      cp ${pkgs.coreutils}/bin/env $out/bin/
      cp -r ${pkgs.coreutils}/share $out/share
      cp ${pkgs.ca-certificates}/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-certificates.crt
      cp -a ${pkgs.glibc.out}/lib/*.so* $out/lib/
      cp -a ${pkgs.glibc.out}/lib64/ld-linux-x86-64.so.2 $out/lib64/
      patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 --set-rpath /lib $out/bin/bash
      patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 --set-rpath /lib $out/bin/env
    '';
  in {
    packages.${system}.bash-rootfs = bashRoot;
    packages.${system}.bash-rootfs-tarball = pkgs.runCommand "bash-rootfs.tar.gz" {} ''
      mkdir -p $out
      tar -C ${bashRoot} -czf $out/bash-rootfs.tar.gz .
    '';
    apps.${system}.export-rootfs = {
      type = "app";
      program = pkgs.writeShellScript "export-rootfs" ''
        set -euo pipefail
        nix build .#bash-rootfs-tarball
        cp result/bash-rootfs.tar.gz ./app-rootfs.tar.gz
      '';
    };
  };
}
