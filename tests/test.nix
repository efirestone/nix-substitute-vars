{ pkgs, lib, substituteVars }:

let
  substitutions = {
    name = "Marie";
    city = "Zurich";
  };

  scriptDrv = substituteVars {
    src = ./template.txt;
    inherit substitutions;
    mode = "0400";
    owner = "root";
    group = "wheel";
  };

  script = builtins.toString scriptDrv;
  expected = "Hello Marie\nWelcome to Zurich!\n";

in
pkgs.runCommand "substituteVars-test" { } ''
  # Use this trick to avoid stripping newlines off the end of the output.
  # This lets us verify that trailing newlines are not stripped during the substitution.
  output=$(cat ${script}; ret=$?; echo .; exit "$ret")
  ret=$?
  actual=''${output%.}

  if [ "$actual" != "${expected}" ]; then
    echo "Substitution test failed!"
    echo "Expected: '${expected}'"
    echo "Got:      '$actual'"
    exit 1
  fi

  # This test doesn't currently work due to sandboxing
  #perms=$(stat -c "%a" ${script})
  #if [ "$perms" != "644" ]; then
  #  echo "Permissions test failed!"
  #  echo "Expected mode: 644"
  #  echo "Got:           $perms"
  #  exit 1
  #fi

  user=$(stat -c "%U" ${script})
  if [ "$user" != "root" ]; then
    echo "Owner test failed!"
    echo "Expected owner: root"
    echo "Got:            $user"
    exit 1
  fi

  group=$(stat -c "%G" ${script})
  if [ "$group" != "wheel" ]; then
    echo "Group test failed!"
    echo "Expected mode: wheel"
    echo "Got:           $group"
    exit 1
  fi

  echo "All tests passed." > $out
''
