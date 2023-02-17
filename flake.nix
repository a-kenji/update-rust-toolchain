{
  description = "update-rust-action";

  inputs = {
    toolchain-manifest.url = "github:a-kenji/rust-toolchain-manifest";
    toolchain-manifest.inputs.nixpkgs.follows = "nixpkgs";
    toolchain-manifest.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    toolchain-manifest,
  }:
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      devInputs = [
        pkgs.python311
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
           nix run -L github:$GITHUB_REPOSITORY \
             --no-write-lock-file \
             -- \
             --version
           nix run -L github:$GITHUB_REPOSITORY \
             --no-write-lock-file \
             -- \
             --output ./. \
             ${channel}
           git add .
           git commit -m "$(date)"
           git push
        '';
    in {
      devShells = {
        default = pkgs.mkShell {
          name = "update-rust-action-env";
          buildInputs = shellInputs ++ fmtInputs ++ devInputs;
        };
        fmtShell = pkgs.mkShell {
          buildInputs = fmtInputs;
        };
      };
      packages.default = toolchain-manifest.outputs.packages.${system}.default;
      ci = {
        update-stable = update-channel "stable";
        update-beta = update-channel "beta";
        update-nightly = update-channel "nightly";
      };

      formatter = pkgs.alejandra;
    });
}
