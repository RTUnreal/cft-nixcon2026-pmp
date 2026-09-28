# NixCon 2026 pmp ctf challenge

The solution can be found in `input-derivation.nix`

The challenge bot would first run `nix flake check .` then output `nix run .#output-flag -- -c config.xml`
