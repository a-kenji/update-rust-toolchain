{
  description = "update-rust-action";

  inputs.rust-overlay = {
    url = "github:oxalica/rust-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      overlays = [(import rust-overlay)];
      rustPkgs = import nixpkgs {
        inherit system overlays;
      };
      CARGO_LOCK = "${./.}/Cargo.lock";
      CARGO_TOML = "${./.}/Cargo.toml";
      RUST_TOOLCHAIN = "${./.}/rust-toolchain.toml";
      rustToolchainToml = rustPkgs.rust-bin.fromRustupToolchainFile "${RUST_TOOLCHAIN}";
      rustc = rustToolchainToml;
      cargo = rustToolchainToml;

      buildInputs = [
        pkgs.openssl
      ];
      nativeBuildInputs = [
        pkgs.pkg-config
      ];
      devInputs = [
        rustc
        cargo
      ];
      shellInputs = [
        pkgs.shellcheck
        pkgs.actionlint
      ];
      fmtInputs = [
        pkgs.alejandra
        pkgs.treefmt
      ];
      update-channel = channel:
        pkgs.writeScriptBin "update-${channel}" ''
          set -x
           git config --local user.name "github-actions[bot]"
           # create temporary directory for downloads
           export TMP_DIR=./tmplocal
           mkdir $TMP_DIR
           # export WORKERS=5
           nix run -L github:$GITHUB_REPOSITORY \
             --no-write-lock-file \
             -- \
             --output ./outputs \
             ${channel}
           git add .
           git commit -m "$(date)"
           git push
        '';
    in {
      devShells.default = pkgs.mkShell {
        name = "update-rust-action-env";
        buildInputs = shellInputs ++ fmtInputs ++ devInputs ++ buildInputs ++ nativeBuildInputs;
      };
      packages = {
        default =
          (
            pkgs.makeRustPlatform {
              inherit cargo rustc;
            }
          )
          .buildRustPackage {
            cargoDepsName = "update-rust-toolchain";
            name = "update-rust-toolchain";
            version = "0.1.0";
            src = ./.;
            cargoLock = {
              lockFile = builtins.path {
                path = ./. + "/Cargo.lock";
                name = "Cargo.lock";
              };
            };
            inherit nativeBuildInputs buildInputs;
          };
        ci = {
          update-nightly = update-channel "nightly";
          update-beta = update-channel "beta";
        };
      };

      formatter = pkgs.alejandra;

      checks = {
        packages = {
          inherit (self.outputs.packages.${system}) default;
        };
        devShells = {
          inherit (self.outputs.devShells.${system}) default;
        };
      };
    });
}
