alias uf := update-flake-dependencies
alias f := fmt

actionlint:
	nix develop --command actionlint --ignore 'SC2046'

fmt:
	nix develop .#fmtShell --command treefmt --config-file ./.treefmt.toml --tree-root ./.

update-flake-dependencies:
	nix flake update --commit-lock-file
