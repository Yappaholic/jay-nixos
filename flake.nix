{
  description = "Flake of jay compositor";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    fenix.url = "github:nix-community/fenix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = 
  { nixpkgs
  , fenix
  , flake-utils
  , ... }:
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [fenix.overlays.default];
    };

    jay-compositor =
      { rustPlatform
      , git
      ,
      }:
      rustPlatform.buildRustPackage rec {
        version = (builtins.fromTOML (builtins.readFile "${src}/jay/Cargo.toml")).package.version;
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
        BuildInputs = with pkgs; [wayland xwayland];
        nativeBuildInputs = with pkgs;[git pkg-config libinput mesa libxkbcommon systemd pango shaderc];
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
    }
  );
}
