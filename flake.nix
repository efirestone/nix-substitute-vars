{
  description = "Reusable substituteVars library flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        substituteVars = import ./lib/substituteVars.nix { inherit pkgs; };
      in
      {
        # Export our function
        lib.substituteVars = substituteVars;

        # Tests
        checks = {
          substitutionTest = import ./tests/test.nix {
            inherit pkgs substituteVars;
          };
        };

        # For flake-check command
        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
