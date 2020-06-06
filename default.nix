{ sources ? import ./nix/sources.nix { }
, nixpkgs ? sources.nixpkgs
}:
# Add rust packages to nixpkgs via the overlay in overlay.nix
import nixpkgs { overlays = [
    (final: prev: {
        rust = final.rust_1_41_0;
        rustPackages = final.rust.packages.stable;
        cargo = prev.cargo.override { rustc = final.rustc; };
        inherit (final.rustPackages) rustPlatform;
    })
    # rust needs some platform rewrite.
    (final: prev: prev.lib.optionalAttrs prev.targetPlatform.isWindows {
        targetPlatform = prev.targetPlatform // { rustc.config = "x86_64-pc-windows-gnu"; };
        stdenv = prev.stdenv // {
            targetPlatform = prev.stdenv.targetPlatform // { rustc.config = "x86_64-pc-windows-gnu"; };
        };
    })
    (final: prev: prev.lib.optionalAttrs prev.targetPlatform.isMusl {
        rustc = final.rustPackages.rustc.overrideDerivation  (drv: {
            configureFlags =
                # We need to pull musl from the targetPackages set. We want musl
                # *for* the target platform. rustc is being pulled from the
                # buildPackages (build -> target compiler), but we link against
                # musl, thus musl needs to be compiled for the target, not the
                # build system (which final.musl would be).
                (drv.configureFlags ++ [ "--set=rust.musl-root=${final.targetPackages.musl}" ]);
        });
    })
    # rust will pass -lpthread, however nix has libpthread split into a separate
    # package.  Thus to prevent rustc from failing to build due to
    #
    #    cannot find -lpthread
    #
    # We need to inject the -L flags into NIX_LDFLAGS while building rustc.
    # Notably rust will try to statically link it and nixpkgs by default
    # disables static products m(.
    (final: prev: prev.lib.optionalAttrs prev.targetPlatform.isWindows {
        rustc = final.rustPackages.rustc.overrideDerivation (drv: {
            NIX_DEBUG = 3;
            NIX_x86_64_w64_mingw32_LDFLAGS = final.lib.optionals final.stdenv.targetPlatform.isWindows [
                "-L${final.targetPackages.windows.mingw_w64_pthreads.overrideDerivation (_ : { dontDisableStatic = true; })}/lib"
                "-L${final.targetPackages.windows.mcfgthreads}/lib"
                "-lmcfgthread"
            ];
        });
    })
    (import ./overlay.nix)
    # For debugging with a local rust.nix checkout.
    # (final: prev: {
    #     naersk = final.callPackage (import ../rust.nix) {};
    # })
]; }