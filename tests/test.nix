{ pkgs, module, substituteVars, ... }:

let
  resolvedFile = substituteVars {
    src = "/tmp/template.txt";
    substitutions = {
      name = "Marie";
      city = "Zurich";
    };
    mode = "0644";
    owner = "test";
    group = "test";
  };
  baseName = baseNameOf (toString resolvedFile);
in {
  substitutionTest = pkgs.nixosTest {
    name = "substituteVarsTest";
    
    # Some parts of the test are dynamic and include hashes that can trigger the type checker.
    skipTypeCheck = true;

    nodes.machine = { config, pkgs, ... }: {
      imports = [ module ];

      environment.systemPackages = with pkgs; [ coreutils gnused ];

      networking.interfaces = {};

      users.groups.${baseName} = {};
      users.groups.test = {};
      users.users.test = {
        isNormalUser = true;
        extraGroups = [ "test" baseName ];
      };
    };

    testScript = ''
      print("Copying template")
      machine.copy_from_host("${./template.txt}", "/tmp/template.txt")

      result2 = machine.execute("ls -lah /run/substituteVars")[1]
      print(f"ls result: {result2}")

      result3 = machine.execute("cat '${resolvedFile}'")[1]
      print(f"Resolved file: {result3}")
      #machine.succeed("bash /tmp/substitute.sh")

      print(f"Log: {machine.execute("cat /run/substituteVars/scripts.log")[1]}")

      print(f"Addscript Log: {machine.execute("cat /tmp/addscript.log")[1]}")

      print(f"Activation Scripts Log: {machine.execute("cat /tmp/activation-scripts.log")[1]}")
    '';
  };
}
