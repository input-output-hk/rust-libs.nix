final: prev:
let
  sources = import ./nix/sources.nix { pkgs = final; };
  # Inject `files` into `src`. E.g. Cargo.lock files into src repositories that
  # do not have any.  Without them reproducable builds are impossible.  However
  # rust's documentation suggests only to add them to executables and does not
  # explicitly consider the use of libraries as final products.
  augmentSrc = { name, src, files }: final.stdenv.mkDerivation {
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
  };
  # rust packages we built by default contain all binaries and lirbaries
  # to be consumed downstream.
  rustPkg = { src, ... }@args:
    let defaultArgs = {
      copyBins = true; copyTarget = false; copyLibs = true;
      # So for windows we'll need to do some threading hand stands.
      # We need mingw_w64_pthreads, as rust will forcably link -lpthread
      # but we'll also need to always link mcfgthread, as that's baked into
      # gcc.
      NIX_x86_64_w64_mingw32_LDFLAGS = final.lib.optionals final.stdenv.targetPlatform.isWindows [
          "-L${final.pkgsBuildTarget.targetPackages.windows.mingw_w64_pthreads.overrideDerivation (_ : { dontDisableStatic = true; })}/lib"
          "-L${final.pkgsBuildTarget.targetPackages.windows.mcfgthreads}/lib"
          "-lmcfgthread"
      ];
    };
    in final.naersk.buildPackage (defaultArgs // args);

  # a helper for injecting lock files based on names.
  namedSrc = name: augmentSrc {
    inherit name; src = sources.${name};
    files = { "Cargo.lock" = ./locks + "/${name}.lock"; };
  };
in {
    # this way we can override it in a different overlay if we need to.
    naersk  = final.callPackage (import sources."rust.nix") {};
    # the KES rust library
    kes_mmm_sumed25519_c = rustPkg {
        # cargoOptions = (opts: opts ++ [ "--verbose" ]);
        src = sources.kes-mmm-sumed25519;
    };
    rust-test = rustPkg {
        # cargoOptions = (opts: opts ++ [ "--verbose" ]);
        src = ./rust-test;
    };
}