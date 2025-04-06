{
  lib,
  runCommand,
  secretsDirectory
}:

{
  src,
  substitutions ? {},
  secrets ? {},
  mode ? "0440",
  owner ? null,
  group ? null
}:

let
  inherit (lib)
    concatStringsSep
    escapeShellArg
    fileContents
    hashString
    attrNames
    mapAttrsToList
    optionalString
    ;

  # Get contents of secrets as a list of sed replacement commands
  secretReplacements = mapAttrsToList (
    key: path: "s|\$\{" + key + "\}|\$(<\\$\{escapeShellArg path\})|g"
  ) secrets;

  # Normal substitutions as sed expressions
  substitutionReplacements = mapAttrsToList (
    key: val: "s|\$\{" + key + "\}|" + val + "|g"
  ) substitutions;

  sedScript = concatStringsSep " \n  " (substitutionReplacements ++ secretReplacements);

  # Calculate a hash of all inputs to use in output file name
  hashInput = builtins.toJSON {
    srcName = builtins.baseNameOf (toString src);
    substitutions = substitutions;
    secrets = mapAttrsToList (_: path: builtins.hashFile "sha256" path) secrets;
    mode = mode;
    owner = owner;
    group = group;
  };
  hash = builtins.hashString "sha256" hashInput;
  outFileName = "${lib.substring 0 8 hash}-${lib.strings.removeSuffix ".in" (builtins.baseNameOf (toString src))}";

in runCommand outFileName {
  inherit secretsDirectory sedScript;
  nativeBuildInputs = [ ];
  passAsFile = [ "sedScript" ]; # pass sedScript as a file, keeps secrets (and secrets file paths) out of the Nix store
} ''
  dstfile=$secretsDirectory/${outFileName}
  echo "$(ls -lah $secretsDirectory)"
  echo "Dst file"
  echo "$dstfile"
  sed -f "$sedScriptPath" "${escapeShellArg (toString src)}" > "$dstfile"
  ${optionalString (owner != null || group != null) ''
    chown ${if owner != null then owner else ""}${if owner != null && group != null then ":" else ""}${if group != null then group else ""} "$dstfile"
  ''}
  chmod ${mode} "$dstfile"
  ln -s "$dstfile" "$out"
''


# { pkgs }:

# { src, substitutions, mode ? "0644", owner ? null, group ? null }:

# let
#   name = "substituted-${builtins.baseNameOf (toString src)}-${builtins.hashString "sha1" (builtins.toJSON substitutions)}";

#   # Properly escape ${var} as \${var} in sed command
#   sedCommands = pkgs.lib.concatStringsSep "\n" (
#     pkgs.lib.mapAttrsToList (k: v: "sed -i 's|\\$\{" + k + "}|" + v + "|g' \"$out\"") substitutions
#   );

#   installFlags =
#     "-m ${mode}"
#     + (if owner != null then " -o ${owner}" else "")
#     + (if group != null then " -g ${group}" else "");

#   fallbackMode = if mode != null then "chmod ${mode} $out" else "";

# in

# pkgs.stdenv.mkDerivation {
#   inherit name;

#   phases = [ "installPhase" ];
#   installPhase = ''
#     echo "fallback mode: ${fallbackMode}"
#     install ${installFlags} ${src} $out || (
#       echo "⚠️  'install' failed; falling back to 'cp' and chmod"
#       cp ${src} $out
#       ${fallbackMode}
#     )
#     ${sedCommands}
#   '';
# }
