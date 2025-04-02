{ pkgs }:

{ src, substitutions, mode ? "0644", owner ? null, group ? null }:

let
  name = "substituted-${builtins.baseNameOf (toString src)}";

  # Properly escape ${var} as \${var} in sed command
  sedCommands = pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (k: v:
      "sed -i 's|\\$\{" + k + "}|"+ v +"|g' \"$out\""
    ) substitutions
  );

  installFlags =
    "-m ${mode}"
    + (if owner != null then " -o ${owner}" else "")
    + (if group != null then " -g ${group}" else "");

  fallbackMode = if mode != null then "chmod ${mode} $out" else "";

in

pkgs.stdenv.mkDerivation {
  inherit name;

  phases = [ "installPhase" ];
  installPhase = ''
    echo "fallback mode: ${fallbackMode}"
    install ${installFlags} ${src} $out || (
      echo "⚠️  'install' failed; falling back to 'cp' and chmod"
      cp ${src} $out
      ${fallbackMode}
    )
    ${sedCommands}
  '';
}
