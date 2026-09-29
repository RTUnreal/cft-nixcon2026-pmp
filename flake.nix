{
  description = "Pimp my PHP";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs =
    inputs:
    let
      forEach = f: builtins.mapAttrs f inputs.nixpkgs.legacyPackages;
    in
    {
      # the package you build and the source provided
      packages = forEach (
        system: pkgs: rec {
          src = pkgs.runCommand "package-src" { } ''
            cp -r ${./package-src} $out
          '';
          php = pkgs.php85;
          pmp_patch = pkgs.runCommand "package-src" { } ''
            cp -r ${./pmp.patch} $out
          '';

          buildPkg = pkgs.callPackage ./input-derivation.nix { inherit src php pmp_patch; };
        }
      );

      # the following checks must pass before the flag is output via `nix run .#output-flag`
      checks = forEach (
        system: pkgs:
        let
          selfpkgs = inputs.self.packages.${system};
          lib = pkgs.lib;

          phpExe = lib.getExe selfpkgs.php;
          buildPkgExe = lib.getExe selfpkgs.buildPkg;

          runSimpleTest = name: script: pkgs.runCommand name { } (script + "\ntouch $out");
        in
        builtins.mapAttrs runSimpleTest {
          t000-fileIsPHPScript = ''
            ${phpExe} -l "${buildPkgExe}"
          '';

          t001-correctlyParsesConfig = ''
            target=$(mktemp)
            ${phpExe} -r '
            $targetFile = $argv[1];

            $a = [
              "<lmao>wrong key</lmao>",
              "<targFile>/etc/your/files/have/beem/hacked</targFile>",
              "<meow>I have no .idea</meow>",
              "<nixos>github:nixos/nixpkgs</nixos>",
              "<german humor=\"\">Hier könnte Ihre Werbung stehen!</german>",
            ];
            function randomElements() {
              global $a;
              $count = random_int(3, min(5, count($a)));
              $keys = array_rand($a, $count);

              if (!is_array($keys)) {
                $keys = [$keys];
              }

              echo implode("\n\t", array_map(
                static fn($key) => $a[$key],
                $keys
              ));
            }
            echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
            echo "<config>\n\t";
            randomElements();
            echo "\n\t<targetFile>".$argv[1]."</targetFile>\n\t";
            randomElements();
            echo "\n</config>";
            ' "$target" > config.xml
            [[ "$(${buildPkgExe} --config config.xml --print-target)" == "$target" ]] || {
              ${buildPkgExe} --config config.xml --print-target
              exit 1
            }
          '';

          t002-correctlyFindsAndParsesTarget = ''
            cat <<EOF > config.xml
            <?xml version="1.0" encoding="UTF-8"?>
            <config>
              <targetFile>flag.txt</targetFile>
            </config>
            EOF
            cat <<EOF > flag.txt
            This is a test file, which tests
            the functionality of PmP to see
            if the NIXCON{FAKE_FLAG} is found
            in this file.
            EOF
            [[ "$(${buildPkgExe} -c config.xml)" == "NIXCON{FAKE_FLAG}" ]] || {
              echo '"'$(${buildPkgExe} -c config.xml)'"'
              exit 1
            }
          '';
        }
      );

      apps = forEach (
        system: pkgs: {
          output-flag = {
            type = "app";
            program = pkgs.lib.getExe inputs.self.packages.${system}.buildPkg;
            meta.description = "runs the flag outputter";
          };
        }
      );
    };
}
