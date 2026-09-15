{
  stdenv,
  src,
  php,
}:
stdenv.mkDerivation {
  name = "pmp";
  inherit src;

  buildInputs = [ php ];
  postPatch = ''
    patchShebangs .
  '';

  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 main.php $out/bin/pmp
  '';

  meta = {
    mainProgram = "pmp";
  };
}
