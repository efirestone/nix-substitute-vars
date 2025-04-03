{ pkgs, lib, substituteVars }:

let
  runTest = pkgs.testers.runNixOSTest;

  # Read the test fixtures into memory within this "host", where the paths
  # are valid, then write the in-memory string back within the context of each VM.
  templateFile = builtins.readFile ./template.txt;
in {
  # To run the tests: nix flake check --all-systems
  # You may also want the -L and --verbose flags for additional debugging.
  substitutionTest = runTest {
      name = "substitutionTest";
      nodes.machine = {
        users.users.testuser = {
          isSystemUser = true;
          group = "testgroup";
        };
        users.groups.testgroup = {};
        # imports = [ module ];

        # # Create a fake Docker image that we can "run"
        # systemd.services.create-fake-docker-image = {
        #   description = "Create fake Docker image";
        #   before = [ "managed-docker-compose.service" ];
        #   requiredBy = [ "managed-docker-compose.service" ];
        #   serviceConfig = {
        #     Type = "oneshot";
        #     ExecStart = "/bin/sh -c '${pkgs.gnutar}/bin/tar cv --files-from /dev/null | ${pkgs.docker}/bin/docker import - testimg'";
        #     TimeoutSec = 90;
        #   };
        # };
      };
      testScript = let
        substitutions = {
          name = "Marie";
          city = "Zurich";
        };

        scriptDrv = substituteVars {
          src = ./template.txt;
          inherit substitutions;
          mode = "0400";
          owner = "testuser";
          group = "testgroup";
        };

        script = builtins.toString scriptDrv;
      in ''
        expected_contents = "Hello Marie\nWelcome to Zurich!\n";
        actual_contents = machine.execute("cat ${script}")[1]
        print(f"Actual: {actual_contents}")
        assert expected_contents == actual_contents, "Resolved template contents don't match."

        # expected_perms = "400";
        # actual_perms = machine.execute("stat -c '%a' ${script}")[1]
        # print(f"Actual: {actual_perms}")
        # assert expected_perms == actual_perms, "Resolved template permissions don't match."

        expected_user = "testuser";
        actual_user = machine.execute("stat -c '%U' ${script}")[1]
        print(f"Actual: {actual_user}")
        assert expected_user == actual_user, "Resolved template user doesn't match."

        expected_group = "testgroup";
        actual_group = machine.execute("stat -c '%G' ${script}")[1]
        print(f"Actual: {actual_group}")
        assert expected_group == actual_group, "Resolved template group doesn't match."
      '';
  };
}

# let
#   substitutions = {
#     name = "Marie";
#     city = "Zurich";
#   };

#   scriptDrv = substituteVars {
#     src = ./template.txt;
#     inherit substitutions;
#     mode = "0400";
#     owner = "root";
#     group = "wheel";
#   };

#   script = builtins.toString scriptDrv;
#   expected = "Hello Marie\nWelcome to Zurich!\n";

# in
# pkgs.runCommand "substituteVars-test" { } ''
#   # Use this trick to avoid stripping newlines off the end of the output.
#   # This lets us verify that trailing newlines are not stripped during the substitution.
#   output=$(cat ${script}; ret=$?; echo .; exit "$ret")
#   ret=$?
#   actual=''${output%.}

#   if [ "$actual" != "${expected}" ]; then
#     echo "Substitution test failed!"
#     echo "Expected: '${expected}'"
#     echo "Got:      '$actual'"
#     exit 1
#   fi

#   # This test doesn't currently work due to sandboxing
#   #perms=$(stat -c "%a" ${script})
#   #if [ "$perms" != "644" ]; then
#   #  echo "Permissions test failed!"
#   #  echo "Expected mode: 644"
#   #  echo "Got:           $perms"
#   #  exit 1
#   #fi

#   user=$(stat -c "%U" ${script})
#   if [ "$user" != "root" ]; then
#     echo "Owner test failed!"
#     echo "Expected owner: root"
#     echo "Got:            $user"
#     exit 1
#   fi

#   group=$(stat -c "%G" ${script})
#   if [ "$group" != "wheel" ]; then
#     echo "Group test failed!"
#     echo "Expected mode: wheel"
#     echo "Got:           $group"
#     exit 1
#   fi

#   echo "All tests passed." > $out
# ''
