{ pkgs, lib, substituteVars }:

let
  scriptDrv = substituteVars {
    src = ./template.txt;
    substitutions = {
      name = "Marie";
      city = "Zurich";
    };
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

  echo "All tests passed." > $out
''
