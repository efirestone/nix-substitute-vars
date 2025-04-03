# substitute-vars

A reusable Nix flake that provides a `substituteVars` function for `${var}`-style template substitution, similar to `pkgs.substituteAll`. Unlike `substituteAll`, it uses the varible-replacement format of `${var}` rather than `@var@`.

## How to Import

Add to your flake:

```nix
inputs.substitute-vars.url = "github:efirestone/nix-substitute-vars";
```

Then use it like:

```nix
let
  substituteVars = substitute-vars.lib.substituteVars;
in

substituteVars {
  src = ./template.txt;
  substitutions = {
    name = "Ada";
    city = "Paris";
  };
}
```

## Tests

Run tests with:

```bash
nix flake check
```

## License

MIT
