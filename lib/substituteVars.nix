{
  pkgs,
  secretsDirectory,
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
  lib = pkgs.lib;
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
  # Unlike the normal substitutions below, these are each read from a file
  # and not substituted directly.
  secretReplacements = mapAttrsToList (
    key: path: "s|\$\{" + key + "\}|\$(<\\$\{escapeShellArg path\})|g"
  ) secrets;

  # Normal substitutions as sed expressions
  substitutionReplacements = mapAttrsToList (
    key: val: "s|\$\{" + key + "\}|" + val + "|g"
  ) substitutions;

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

  # Write the sed arguments to a file. This probably isn't necessary in most cases,
  # but it does mean we never have to worry about hitting the command length limit.
  sedScript = concatStringsSep "\n" (substitutionReplacements ++ secretReplacements);
  sedScriptPath = pkgs.writeText "${lib.substring 0 8 hash}-substitute.sed" sedScript;

  outFileName = "${lib.substring 0 8 hash}-${lib.strings.removeSuffix ".in" (builtins.baseNameOf (toString src))}";
  destinationFile = "${secretsDirectory}/${outFileName}";

  script = pkgs.writeShellApplication {
    name = "${lib.substring 0 8 hash}-substitute-vars.sh";
    text = ''
      echo "Running script ${lib.substring 0 8 hash}-substitute-vars.sh" > /tmp/activation.log
      dstfile=${destinationFile}
      sed -f "${sedScriptPath}" "${escapeShellArg (toString src)}" > "$dstfile"
      ${optionalString (owner != null || group != null) ''
        chown ${if owner != null then owner else ""}${if owner != null && group != null then ":" else ""}${if group != null then group else ""} "$dstfile"
      ''}
      chmod ${mode} "$dstfile"
    '';
  };

  config._activationScriptLib.collectedScripts = lib.mkAfter [ script ];

  system.activationScripts.debug.text = ''
    echo "Add script ${script}" >> /tmp/addscript.log
  '';

  # config = config;

  # Automatically register the script at evaluation time
  # Automatically add to config
  # _ = config._module.args.__substitutionVars_script_collector script;
  # trc = builtins.warn "Registering ${script}" script;

  # _ = builtins.trace "Registering ${file}" (
  #     config._module.args.__substitutionVars_script_collector file;
  #     file
  #   );
  # _ = config._module.args.__substitutionVars_register script;
  # config._activationScriptLib.collectedScripts = lib.mkAfter [ script ];
  # _module.args._activationScriptLibScript = script;

  # Add to activationScripts list
  # _ = lib.mkAfter (config.services.substitutionVars.activationScripts or []) ++ [ script ];
in
  destinationFile
