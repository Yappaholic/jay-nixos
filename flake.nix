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
          rev = "v1.7.0";
          sha256 = "0c6m3vsb2gfr3b4bmaysa90flfifzbdmczs8rr4wipw837v3j22l";
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
          cairo
          udev
          libinput
          shaderc
        ];

        runtimeDependencies = with pkgs;[
          libglvnd
          wayland
          xwayland
          libGL
          mesa
          vulkan-loader
        ];      
    };
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
