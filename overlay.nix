final: prev:
let
  sources = import ./nix/sources.nix { pkgs = final; };
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

  # a helper for injecting lock files based on names.
  namedSrc = name: augmentSrc {
    inherit name; src = sources.${name};
    files = { "Cargo.lock" = ./locks + "/${name}.lock"; };
  };
in {

    rust_1_43 = final.callPackage ./rust-versions/1_43.nix {
      inherit (final.darwin.apple_sdk.frameworks) CoreFoundation Security;
    };

    rust = final.rust_1_43;

    # the KES rust library
    kes_mmm_sumed25519_c = rustPkg {
        # cargoOptions = (opts: opts ++ [ "--verbose" ]);
        src = sources.kes-mmm-sumed25519;
    };

    rust-test = rustPkg {
        # cargoOptions = (opts: opts ++ [ "--verbose" ]);
        src = ./rust-test;
    };

    vit-servicing-station = rustPkg {
      src = sources.vit-servicing-station;
    };
}
