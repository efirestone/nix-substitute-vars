{ pkgs, module, substituteVars, ... }:

{
  substitutionTest = pkgs.nixosTest {
    name = "substituteVarsTest";

    nodes.machine = { config, pkgs, ... }: {
      imports = [ module ];

      environment.systemPackages = with pkgs; [ coreutils gnused ];

      users.groups.test = {};
      users.users.test = {
        isNormalUser = true;
        extraGroups = [ "test" ];
      };

      # systemd.tmpfiles.rules = [
      #   "d /tmp/substitution-vars/substitutionTest 0755 root root"
      # ];
    };

    testScript = ''
      execute("id test")
      print("Copying template")

      machine.copy_from_host("${./template.txt}", "/tmp/template.txt")

      print("Installing template.in")

      machine.succeed('''
        install -m 600 /tmp/template.txt /tmp/template.in
      ''')

      print("Running substituteVars")

      machine.succeed("bash /tmp/substitute.sh")
    '';
  };
}