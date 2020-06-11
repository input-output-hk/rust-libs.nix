{ sources ? import ./nix/sources.nix { }
, nixpkgs ? sources.nixpkgs
, sourcesOverride ? {}
}:
let sources' = sources // sourcesOverride; in
# Add rust packages to nixpkgs via the overlay in overlay.nix
import nixpkgs { overlays = [
    (import sources'."rust.nix")
    (import ./overlay.nix)
    # For debugging with a local rust.nix checkout.
    # (final: prev: {
    #     rust-nix = final.callPackage (import ../rust.nix) {};
    # })
    ];
}