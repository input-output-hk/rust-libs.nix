{
  description = "Flake for vit-servicing-station";
  inputs = {
    utils.url = "github:numtide/flake-utils";

    rust-nix = {
      url = "github:input-output-hk/rust.nix";
      flake = false;
    };

    kes-mmm-sumed25519 = {
      url = "github:input-output-hk/kes-mmm-sumed25519";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rust-nix, utils, ... }@inputs:
    (utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-nix) (import ./overlay.nix inputs) ];
        };
      in {
        legacyPackages = pkgs;
        defaultPackage = pkgs.vit-servicing-station;
      }));
}
