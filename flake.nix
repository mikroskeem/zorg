{
  description = "zorg";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
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
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
      in
      rec {
        devShell = pkgs.mkShell {
          buildInputs =
            let
              # Implies that https://openzfsonosx.org/ is installed on the system
              zfs-mac' = { stdenvNoCC, zfsPath ? "/usr/local/zfs" }: stdenvNoCC.mkDerivation rec {
                name = "mac-zfs-user";
                phases = [ "installPhase" ];

                installPhase = ''
                  runHook preInstall

                  mkdir -p $out
                  for output in bin include lib libexec share; do
                    ln -s "${zfsPath}/$output" $out/$output
                  done

                  runHook postInstall
                '';
              };
              zfs-mac = pkgs.callPackage zfs-mac' { };
            in
            with pkgs; [
              bindfs
              borgbackup
              gnupg
              rage
              shellcheck
              sops
            ] ++ lib.optionals stdenv.isDarwin [
              zfs-mac
              (sanoid.override {
                zfs = zfs-mac;
                mbuffer = null; # does not compile
              })
            ] ++ lib.optionals stdenv.isLinux [
              sanoid
            ];
        };
      });
}
