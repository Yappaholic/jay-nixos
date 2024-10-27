{
  description = "Flake of jay compositor";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = 
  { nixpkgs
  , rust-overlay
  , flake-utils
  , ... }:
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [(import rust-overlay)];
    };
    lib = nixpkgs.lib;

    jay-compositor =
      { rustPlatform
      }:
      rustPlatform.buildRustPackage rec {
        version = (builtins.fromTOML (builtins.readFile "${src}/Cargo.toml")).package.version;
        pname = "jay";
        src = pkgs.fetchFromGitHub {
          owner = "mahkoh";
          repo = "jay";
          rev = "163bb2c893ded86d405923cb19d539be8bbe0413";
          hash = "sha256-fzn9vu+6ccg2WrlQiC4XNQ0MKmTs6axhrN1Oek/OxaQ=";
        };
        cargoLock = {
          lockFile = "${src}/Cargo.lock";
        };
        cargoBuildFlags = ["--locked"];

        SHADERC_LIB_DIR = "${lib.getLib pkgs.shaderc}/lib";

        nativeBuildInputs = with pkgs;[
          autoPatchelfHook
           (
              rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {
                extensions = [ "rust-src" ];
                targets = [ "x86_64-unknown-linux-gnu" ];
              })
            )        
        ];

        buildInputs = with pkgs;[
          libGL
          libxkbcommon
          mesa
          pango
          udev
          libinput
          shaderc
        ];

        runtimeDependencies = with pkgs;[
          libglvnd
          vulkan-loader
        ];      };
    jay-package = pkgs.callPackage jay-compositor {};
    in
    {
      formatter = pkgs.alejandra;
      packages.default = jay-package;
      apps.default = {
        type = "app";
        program = "${jay-package}/bin/jay";
      };
      overlays.default = final: prev: {
        jay-git = jay-package.${system};
      };
    }

  );
}
