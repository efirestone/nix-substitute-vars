{ config, lib, pkgs, substituteVars, ... }:

with lib;

let
  secretsDirectory = "/run/substituteVars";
  scriptsDir = pkgs.runCommand "activation-scripts-dir" {} ''
    mkdir -p $out
    ${concatStringsSep "\n" (imap1 (i: script:
      "echo \"Writing script ${script} to file\" >> /tmp/script-write.log"
      "ln -s ${script} $out/script-${toString i}"
    ) config.substituteVars.activationScripts)}
  '';
in {
  options.substituteVars.activationScripts = mkOption {
    type = with types; listOf path;
    default = [];
    description = "Scripts to run at activation time to do the substitutions.";
  };

  config = {
    _module.args = {
      substituteVars = substituteVars;

      __substitutionVars_register = file: let
        current = config.substitutionVars.activationScripts or [];
      in {
        config.substitutionVars.activationScripts = mkAfter current ++ [ file ];
      };
    };

    # Create the secrets directory as an activation script. We can't do it later
    # as we won't be running as root.
    system.activationScripts.substituteVarsResolveSubstitutions = {
      text = ''
        set -x
        echo "Running activation script"
        echo "Running activation script" > /tmp/subvarslog.txt

        # # Delete the old secrets. We'll recreate them if they're still valid.
        # rm -rf "${secretsDirectory}/*"

        # mkdir -p "${secretsDirectory}"
        # chmod 0751 "${secretsDirectory}"

        # # Create a RAM disk to ensure the secrets don't survive a reboot and aren't
        # # available to someone sniffing the hard drive.
        # # If the substituteVars module is still included then we'll recreate them.
        # grep -q "${secretsDirectory} ramfs" /proc/mounts ||
        #   mount -t ramfs none "${secretsDirectory}" -o nodev,nosuid,mode=0751

        # echo "Config: ${builtins.toJSON config.substituteVars}" >> /tmp/activation-scripts.log

        # Run the various scripts that are generated each time substituteVars is
        # generated. There is one per call, and executing it does the actual substitution.
        echo "Scripts dir: ${scriptsDir}" > "/run/substituteVars/scripts.log"
        for script in "${scriptsDir}/*"; do
          echo "Running $script" >> "/run/substituteVars/scripts.log"
          $script
        done
      '';
      deps = [
        "specialfs"
      ];
    };
  };
}
