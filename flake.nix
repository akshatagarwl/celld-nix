{
  description = "Nix flake for celld, self-hosted distributed Durable Objects (prebuilt release binaries)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = final: _prev: {
        celld = final.callPackage ./pkgs/celld.nix { };
      };

      packages = forAllSystems (pkgs: rec {
        celld = pkgs.callPackage ./pkgs/celld.nix { };
        default = celld;
      });

      apps = forAllSystems (pkgs: {
        update = {
          type = "app";
          meta.description = "Bump celld to the latest release and refresh hashes";
          program = nixpkgs.lib.getExe (
            pkgs.writeShellApplication {
              name = "celld-update";
              runtimeInputs = [
                pkgs.curl
                pkgs.jq
              ];
              text = builtins.readFile ./pkgs/update.sh;
            }
          );
        };
      });

      checks = forAllSystems (pkgs: {
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) celld;
        overlay = (pkgs.extend self.overlays.default).celld;
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
