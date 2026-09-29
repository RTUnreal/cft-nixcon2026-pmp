# Pimp my PHP


This is your quest: write `input-derivation.nix` so that

```console
nix flake check
```

passes.

Read `pmp.patch` before you start. It is not a complete program, and
`main.php` has a `// TODO` where the missing behaviour goes.

## Submitting

```console
git add -A && git add -f input-derivation.nix
git diff HEAD > my.patch
curl --data-binary @my.patch http://<submission-desk>/submit
```
