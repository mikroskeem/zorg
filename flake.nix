{
  description = "zorg";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    openzfs-osx-shim-nix.url = "github:mikroskeem/openzfs-osx-shim-nix";

    openzfs-osx-shim-nix.inputs.nixpkgs.follows = "nixpkgs";
    openzfs-osx-shim-nix.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, openzfs-osx-shim-nix }:
    let
      supportedSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-linux"
        "x86_64-darwin"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            openzfs-osx-shim-nix.overlay
          ];
        };

        inherit (pkgs) lib;
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            bindfs
            borgbackup
            gnupg
            rage
            (sanoid.override (lib.optionalAttrs stdenv.isDarwin {
              mbuffer = null; # does not compile
            }))
            shellcheck
            sops
            zfs
          ];
        };
      });
}
