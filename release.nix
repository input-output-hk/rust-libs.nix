{ sources ? import ./nix/sources.nix { }
, nixpkgs ? sources.nixpkgs
, sourcesOverride ? {}
, ...
}@args:
# The idea is to have rustPkgs listed (or we'd somehow have to extract the names
# somehow out of the overlay.nix). And the targets we want, and then just
# produce the products (rustPkgs x targets) we want hydra to build.
let nativePkgs = import ./. args;
    rustPkgs = [ "kes_mmm_sumed25519_c" "rust-test" "vit-servicing-station" ];
    targets = with nativePkgs.pkgsCross; {
        "${builtins.currentSystem}" = nativePkgs;
        x86-musl64 = musl64;
        x86-win64 = mingwW64;

        # arm builds for good measure.
        rpi32-gnu = armv7l-hf-multiplatform;
        # sadly this one is missing from the nixpkgs system examples
        # This is a mess, we have no way to access nixpkgsFun or the
        # original arguments nixpkgs was called with.
        rpi32-musl = import nativePkgs.path {
            inherit (nativePkgs) overlays config;
            crossSystem = nativePkgs.lib.systems.examples.armv7l-hf-multiplatform
              // { config = "armv7l-unknown-linux-musleabihf"; };
            };
        rpi64-gnu = aarch64-multiplatform;
        rpi64-musl = aarch64-multiplatform-musl;
    };
in with nativePkgs.lib;
flip mapAttrs targets (_: pkgs:
    __listToAttrs (flip map rustPkgs (pkg:
        { name = pkg; value = pkgs.${pkg}; }
    ))
)