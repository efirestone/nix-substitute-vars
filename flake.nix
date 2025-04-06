# {
#   description = "Reusable substituteVars library flake with sandbox-safe permissions";

#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs";
#     flake-utils.url = "github:numtide/flake-utils";

#     # Limit to Linux systems. We don't support Darwin right now.
#     systems.url = "github:nix-systems/default-linux";
#     flake-utils.inputs.systems.follows = "systems";
#   };

# #   outputs =
# #     {
# #       self,
# #       nixpkgs,
# #       flake-utils,
# #       ...
# #     }: let
# #       secretsDirectory = "/run/substituteVars";
# #     in
# #     flake-utils.lib.eachDefaultSystem (
# #       system:
# #       let
# #         pkgs = nixpkgs.legacyPackages.${system};

# #         module = import ./service.nix;

# #         substituteVars = import ./lib/substituteVars.nix {
# #           inherit pkgs secretsDirectory;
# #           lib = nixpkgs.lib;
# #         };


# #         tests = import ./tests/test.nix {
# #           inherit module pkgs substituteVars;
# #         };
# #       in
# #       {
# #         # Export our service
# #         nixosModules.substituteVars = module;

# #         # Export our function
# #         lib.substituteVars = substituteVars;

# #         # Tests
# #         checks = builtins.mapAttrs (_: v: v) tests;
# #         # checks.substitutionTest = tests.substitutionTest;

# #         apps = builtins.mapAttrs (_: v: {
# #           type = "app";
# #           program = "${v}";
# #         }) tests;

# #         # For flake-check command
# #         formatter = pkgs.nixfmt-rfc-style;
# #       }
# #     );
# # }


# # A self-contained library flake that:
# # - Exposes a `lib.addActivationScript` function
# # - Automatically registers a NixOS module to run all added scripts
# # - Requires no manual `imports`, only calling the function from user config

# # {
# #   description = "Reusable activation script collector and runner";

#   # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

#   outputs = { self, nixpkgs, flake-utils, systems }: flake-utils.lib.eachDefaultSystem (system: let
#     secretsDirectory = "/run/substituteVars";
    
#     pkgs = import nixpkgs { inherit system; };
    
#     substituteVars = import ./lib/substituteVars.nix {
#       inherit pkgs secretsDirectory;
#     };

#     module = { lib, config, pkgs, ... }:
#       with lib;
#       let
#         collectedScripts = config._activationScriptLib.collectedScripts;

#         scriptsDir = pkgs.runCommand "activation-scripts-dir" {} ''
#           mkdir -p $out
#           ${concatStringsSep "\n" (imap1 (i: script:
#             "ln -s ${script} $out/script-${toString i}"
#           ) collectedScripts)}
#         '';
#       in {
#         options._activationScriptLib.collectedScripts = mkOption {
#           type = with types; listOf package;
#           default = [];
#           internal = true;
#         };

#         config = {
#           system.activationScripts.runCollectedActivationScripts.text = ''
#             echo "Config: ${builtins.toJSON config._activationScriptLib}" >> /tmp/activation-scripts.log
#             for script in ${scriptsDir}/*; do
#               echo "[activation] Running $script"
#               $script
#             done
#           '';
#         };
#       };
#   in {

#     lib.substituteVars = substituteVars;
#     # lib.addActivationScript = { name, scriptText, pkgsOverride ? null }: {
#     #   _module.args._activationScriptLibScript =
#     #     (if pkgsOverride != null then pkgsOverride else pkgs).writeShellScript name scriptText;
#     # };

#     nixosModules.default = module;

#     checks = let
#       tests = import ./tests/test.nix {
#         inherit module pkgs substituteVars;
#       };
#     in
#       tests; #builtins.mapAttrs (_: v: v) tests;

#     # Optional: example configuration for testing
#     # nixosConfigurations.example = nixpkgs.lib.nixosSystem {
#     #   inherit system;
#     #   modules = [
#     #     self.nixosModules.default
#     #   ];
#     # };

#   });
# }


# #   outputs = { self, nixpkgs }: let
# #     substituteVars = import ./lib/substituteVars.nix;
# #   in {

# #     lib.substituteVars = substituteVars;
# #     # lib.addActivationScript = { name, scriptText, pkgs ? null }: {
# #     #   _module.args._activationScriptLibScript =
# #     #     (if pkgs != null then pkgs else import nixpkgs { system = builtins.currentSystem; }).writeShellScript name scriptText;
# #     # };

# #     nixosModules.default = { lib, config, pkgs, ... }:
# #       with lib;
# #       let
# #         collectedScripts = config._activationScriptLib.collectedScripts;

# #         scriptsDir = pkgs.runCommand "activation-scripts-dir" {} ''
# #           mkdir -p $out
# #           ${concatStringsSep "\n" (imap1 (i: script:
# #             "ln -s ${script} $out/script-${toString i}"
# #           ) collectedScripts)}
# #         '';
# #       in {
# #         options._activationScriptLib.collectedScripts = mkOption {
# #           type = with types; listOf package;
# #           default = [];
# #           internal = true;
# #         };

# #         config = {
# #           system.activationScripts.runCollectedActivationScripts.text = ''
# #             for script in ${scriptsDir}/*; do
# #               echo "[activation] Running $script"
# #               $script
# #             done
# #           '';
# #         };
# #       };

# #     # flake-utils.lib.eachDefaultSystem (
# #     #   system:
# #     #   let
# #     #     pkgs = nixpkgs.legacyPackages.${system};

# #     #     module = import ./service.nix;

# #     #     substituteVars = import ./lib/substituteVars.nix {
# #     #       inherit pkgs secretsDirectory;
# #     #       lib = nixpkgs.lib;
# #     #     };


# #     #     tests = import ./tests/test.nix {
# #     #       inherit module pkgs substituteVars;
# #     #     };
# #     #   in
# #     #   {
# #     #     # Export our service
# #     #     nixosModules.substituteVars = module;

# #     #     # Export our function
# #     #     lib.substituteVars = substituteVars;

# #     #     # Tests
# #     #     checks = builtins.mapAttrs (_: v: v) tests;
# #     #     # checks.substitutionTest = tests.substitutionTest;

# #     #     apps = builtins.mapAttrs (_: v: {
# #     #       type = "app";
# #     #       program = "${v}";
# #     #     }) tests;

# #     #     # For flake-check command
# #     #     formatter = pkgs.nixfmt-rfc-style;
# #     #   }
# #     # );

# #     checks."x86_64-linux" = let
# #       module = self.nixosModules.default;
# #       pkgs = import nixpkgs { system = builtins.currentSystem; };
# #       tests = import ./tests/test.nix {
# #         inherit module pkgs substituteVars;
# #       };
# #     in
# #       tests; #builtins.mapAttrs (_: v: v) tests;

# #     # Example system for testing only
# #     nixosConfigurations = {
# #       example = nixpkgs.lib.nixosSystem {
# #         system = "x86_64-linux";

# #         modules = [
# #           {
# #             boot.loader.grub.device = "/dev/sda";
# #             fileSystems."/" = {
# #               device = "/dev/disk/by-uuid/some-uuid";
# #               fsType = "ext4";
# #             };

# #             system.stateVersion = "24.11";
# #           }
# #           self.nixosModules.default
# #         ];
# #       };
# #     };
# #   };
# # }







{
  description = "Reusable activation script collector and runner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: let
    systems = flake-utils.lib.defaultSystems;
    registry = builtins.trace "[activation-script-lib] initializing registry" (builtins.listToAttrs []);
  in flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };

    _registeredScripts = ref: script:
      let name = script.name;
          text = script.scriptText;
          realPkgs = script.pkgsOverride or pkgs;
      in ref ++ [ realPkgs.writeShellScript name text ];

    scriptRegistry = builtins.foldl' _registeredScripts [] self.lib._activationScriptEntries;
  in {

    lib._activationScriptEntries = [];

    lib.addActivationScript = { name, scriptText, pkgsOverride ? null }:
      self.lib._activationScriptEntries := self.lib._activationScriptEntries ++ [
        { inherit name scriptText pkgsOverride; }
      ];

    nixosModules.default = { config, pkgs, lib, ... }:
      let
        scriptsDir = pkgs.runCommand "activation-scripts-dir" {} ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (lib.imap1 (i: script:
            "ln -s ${script} $out/script-${toString i}"
          ) scriptRegistry)}
        '';
      in {
        config.system.activationScripts.runCollectedActivationScripts.text = ''
          for script in ${scriptsDir}/*; do
            echo "[activation] Running $script"
            $script
          done
        '';
      };
  }) // {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.default
      ];
    };

    # Example use: just call the function
    _ = self.lib.addActivationScript {
      name = "hello";
      scriptText = "echo Hello from activation!";
    };
  };
}
