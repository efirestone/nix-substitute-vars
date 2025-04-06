# substitute-vars

A reusable Nix flake that provides a `substituteVars` function for `${var}`-style template substitution, similar to `pkgs.substituteAll`.

Unlike `substituteAll`, it allows the optional setting of file permissions, owner, and group, and also uses the varible-replacement format of `${var}` rather than `@var@`.

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
  mode = "0755";        # optional
  owner = "root";       # optional
  group = "wheel";      # optional
}
```

## Tests

Run tests with:

```bash
nix flake check
```

## Security

If custom permissions or ownership are used, a copy of the file will still also be present in the Nix store with world-readable permissions, so this should not be used as a way to limit visibility of the file. This is true for all Nix functions that allow setting permissions. For files that should be kept private try something like [agenix](https://github.com/ryantm/agenix) or [sops-nix](https://github.com/Mic92/sops-nix).

## Notes

- In sandboxed builds, `owner` and `group` will be skipped if they can't be applied.
- File `mode` is always respected.

## License

MIT
