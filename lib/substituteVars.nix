{ pkgs }:

{ src, substitutions }:

let
  name = "substituted-${builtins.baseNameOf (toString src)}";

  # Properly escape ${var} as \${var} in sed command
  sedCommands = pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (k: v:
      "sed -i 's|\\$\{" + k + "}|"+ v +"|g' \"$out\""
    ) substitutions
  );
in
pkgs.stdenv.mkDerivation {
  inherit name;

  phases = [ "installPhase" ];
  installPhase = ''
    cp ${src} $out
    ${sedCommands}
  '';
}
