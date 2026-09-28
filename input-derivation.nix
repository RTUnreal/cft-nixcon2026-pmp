# this is a sample solution :3
{
  stdenv,
  src,
  php,
  pmp_patch,
}:
stdenv.mkDerivation {
  name = "pmp";
  inherit src;

  patches = [ pmp_patch ];

  buildInputs = [ php ];
  postPatch = ''
    patchShebangs .
    substituteInPlace ./main.php \
      --replace-fail '// TODO' 'if ($print_target) { echo $targetFile; exit(0); }'
  '';

  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 main.php $out/bin/pmp
  '';

  meta = {
    mainProgram = "pmp";
  };
}
