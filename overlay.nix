final: prev:
let sources = import ./nix/sources.nix { pkgs = final; }; in
let naersk  = final.callPackage (import sources.naersk) {}; in
let augmentSrc = { name, src, files }: final.stdenv.mkDerivation {
    name = "${name}-augmented-src";
    inherit src;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = (''
    mkdir $out
    cd "$src"
    cp -r . $out/
    cd "$out"
    ''
    + (__concatStringsSep "\n"
        (__attrValues (__mapAttrs (k: v: ''
          if [[ ! -z "$(dirname "${k}")" ]]; then
              mkdir -p "$(dirname "${k}")"
          fi
          cp "${v}" "${k}"
          '')
        files))));
}; in
# rust packages we built by default contain all binaries and lirbaries
# to be consumed downstream.
let rustPkg = { src, ... }@args:
    naersk.buildPackage ({ copyBins = true; copyTarget = false; copyLibs = true; } // args);
in {
    # the KES rust library
    kes_mmm_sumed25519_c = rustPkg {
        src = augmentSrc {
            name = "kes-mmm-sumed25519";
            src = sources.kes-mmm-sumed25519;
            files = { "Cargo.lock" = ./locks/kes-mmm-sumed25519.lock; };
        };
    };
}