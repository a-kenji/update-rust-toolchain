alias uf := update-flake-dependencies
alias uc := update-cargo-dependencies
alias f := fmt

actionlint:
	nix develop --command actionlint --ignore 'SC2046'

fmt:
	nix develop .#fmtShell --command treefmt --config-file ./.treefmt.toml --tree-root ./.

# Update and then commit the `Cargo.lock` file
update-cargo-dependencies:
	cargo update
	git add Cargo.lock
	git commit Cargo.lock -m "update(cargo): `Cargo.lock`"

update-flake-dependencies:
	nix flake update --commit-lock-file
