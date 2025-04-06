{ lib, pkgs, secretsDirectory, substituteVars, ... }:

with lib;

{
  config = {
    # Create the secrets directory as an activation script. We can't do it later
    # as we won't be running as root.
    system.activationScripts.agenixNewGeneration = {
      text = ''
        echo "Running activation script"

        # Delete the old secrets. We'll recreate them if they're still valid.
        rm -rf "${secretsDirectory}"

        mkdir -p "${secretsDirectory}
        chmod 0751 "${secretsDirectory}"

        # Create a RAM disk to ensure the secrets don't survive a reboot and aren't
        # available to someone sniffing the hard drive.
        # If the substituteVars module is still included then we'll recreate them.
        grep -q "${secretsDirectory} ramfs" /proc/mounts ||
          mount -t ramfs none "${secretsDirectory}" -o nodev,nosuid,mode=0751
      '';
      deps = [
        "specialfs"
      ];
    };
  };
}
