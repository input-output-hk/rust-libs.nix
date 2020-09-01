inputs:
final: prev:
let
  # Inject `files` into `src`. E.g. Cargo.lock files into src repositories that
  # do not have any.  Without them reproducable builds are impossible.  However
  # rust's documentation suggests only to add them to executables and does not
  # explicitly consider the use of libraries as final products.
  augmentSrc = final.callPackage ./augemented-src.nix {};
  # rust packages we built by default contain all binaries and lirbaries
  # to be consumed downstream.
  rustPkg = { src, ... }@args:
    let defaultArgs = { copyBins = true; copyTarget = false; copyLibs = true;
                        enableShared = false;
                      };
    in final.rust-nix.buildPackage (defaultArgs // args);
in {

    rust_1_43 = final.callPackage ./rust/1_43.nix {
      inherit (final.darwin.apple_sdk.frameworks) CoreFoundation Security;
    };

    rust = final.rust_1_43;

    # the KES rust library
    kes_mmm_sumed25519_c = rustPkg {
        # cargoOptions = (opts: opts ++ [ "--verbose" ]);
        src = inputs.kes-mmm-sumed25519;
    };

    rust-test = rustPkg {
        # cargoOptions = (opts: opts ++ [ "--verbose" ]);
        src = ./rust-test;
    };

    vit-servicing-station = rustPkg {
      src = inputs.vit-servicing-station;
    };
}
