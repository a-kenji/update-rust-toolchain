{
  description = "update-rust-action";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      shellInputs = [
        pkgs.shellcheck
        pkgs.actionlint
      ];
      fmtInputs = [
        pkgs.alejandra
        pkgs.treefmt
      ];
    in rec {
      devShell = pkgs.mkShell {
        name = "update-rust-action-env";
        nativeBuildInputs = shellInputs ++ fmtInputs;
        buildInputs = shellInputs ++ fmtInputs;
      };
      formatter = pkgs.alejandra;
    });
}
