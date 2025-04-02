{
  description = "Reusable substituteVars library flake with sandbox-safe permissions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = {
          substituteVars = import ./lib/substituteVars.nix { inherit pkgs; };
        };
      in {
        packages.default = pkgs.writeText "substitute-lib-placeholder" "Use this as a lib flake";
        inherit lib;

        checks.default = pkgs.callPackage ./tests/test.nix {
          inherit pkgs lib;
          substituteVars = lib.substituteVars;
        };
      }
    );
}
