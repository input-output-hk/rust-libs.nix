final: prev:
let sources = import ./nix/sources.nix { pkgs = final; }; in
let naersk  = final.callPackage (import sources.naersk) {}; in
# rust packages we built by default contain all binaries and lirbaries
# to be consumed downstream.
let rustPkg = { src, ... }@args:
    naersk.buildPackage ({ copyBins = true; copyTarget = false; copyLibs = true; } // args);
in {
    # the KES rust library
    kes_mmm_sumed25519_c = rustPkg { src = sources.kes-mmm-sumed25519; };
}