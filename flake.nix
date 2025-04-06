{
  description = "Reusable substituteVars library flake with sandbox-safe permissions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    # Limit to Linux systems. We don't support Darwin right now.
    systems.url = "github:nix-systems/default-linux";
    flake-utils.inputs.systems.follows = "systems";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@args: let
      secretsDirectory = "/run/substituteVars";
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        substituteVars = import ./lib/substituteVars.nix {
          inherit secretsDirectory;
          lib = nixpkgs.lib;
          runCommand = pkgs.runCommand;
        };

        module = import ./service.nix ({
          inherit pkgs secretsDirectory substituteVars;
          lib = nixpkgs.lib;
        } // args);

        tests = import ./tests/test.nix {
          inherit module pkgs substituteVars;
        };
      in
      {
        # Export our service
        nixosModules.substituteVars = module;

        # Export our function
        lib.substituteVars = substituteVars;

        # Tests
        checks = builtins.mapAttrs (_: v: v) tests;
        # checks.substitutionTest = tests.substitutionTest;

        apps = builtins.mapAttrs (_: v: {
          type = "app";
          program = "${v}";
        }) tests;

        # For flake-check command
        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
