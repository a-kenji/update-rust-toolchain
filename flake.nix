{
  description = "update-rust-action";

  inputs.rust-overlay = {
    url = "github:oxalica/rust-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-utils.follows = "flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , rust-overlay
    ,
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      overlays = [ (import rust-overlay) ];
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
    in
    {
      devShells.default = pkgs.mkShell {
        name = "update-rust-action-env";
        buildInputs = shellInputs ++ fmtInputs ++ devInputs ++ buildInputs ++ nativeBuildInputs;
      };
      packages.default =
        (
          pkgs.makeRustPlatform {
            inherit cargo rustc;
          }
        ).buildRustPackage {
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

      formatter = pkgs.alejandra;
    });
}
