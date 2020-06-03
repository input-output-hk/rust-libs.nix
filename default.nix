{ sources ? import ./nix/sources.nix { }
, nixpkgs ? sources.nixpkgs
}:
# Add rust packages to nixpkgs via the overlay in overlay.nix
import nixpkgs { overlays = [ (import ./overlay.nix) ]; }