final: prev:
let
  sources = import ./nix/sources.nix { pkgs = final; };
  naersk  = final.callPackage (import sources.naersk) {};
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
    let defaultArgs = { copyBins = true; copyTarget = false; copyLibs = true; };
    in naersk.buildPackage (defaultArgs // args);
  # a helper for injecting lock files based on names.
  namedSrc = name: augmentSrc {
    inherit name; src = sources.${name};
    files = { "Cargo.lock" = ./locks + "/${name}.lock"; };
  };
in {
    # the KES rust library
    kes_mmm_sumed25519_c = rustPkg {
        src = namedSrc "kes-mmm-sumed25519";
    };
}