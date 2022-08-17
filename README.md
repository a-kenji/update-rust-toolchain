# update-rust-toolchain

This is a GitHub Action that will update your `rust-toolchain` / `rust-toolchain.toml` file, when it is run.

Keep a shared rust version for your project,
while also keeping it up to date.

Update patch versions as soon as they release,
or even update your minor versions.

Will usually take between 3-6 seconds to execute.

# Usage:

Creates a pr with an update to the latest rust-version.
```
jobs:
  rust-toolchain:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
      - name: Update rust-toolchain
        uses: a-kenji/update-rust-toolchain
```
Creates a pr with an update to the latest patch of your selected rust-version.
```
jobs:
  rust-toolchain:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
      - name: Update rust-toolchain
        uses: a-kenji/update-rust-toolchain
        with:
          update-minor: false
```

# Running GitHub Actions on the Action
GitHub Actions will not run workflows by a PR that is itself opened by a GitHub Action. There are two ways to have GitHub Actions CI run on a PR submitted by this action.

## Manually
You can manually run the following commands, in order to force a CI run of the PR.
```
git branch -D update_rust_toolchain_action
git fetch origin
git checkout update_rust_toolchain_action
git commit --amend --no-edit
git push origin update_rust_toolchain_action --force
```

## With a Personal Authentication Token

By providing a Personal Authentication Token, the PR will be submitted in a way that bypasses this limitation (GitHub will essentially think it is the owner of the PAT submitting the PR, and not an Action).
You can create a token by visiting https://github.com/settings/tokens and select at least the `repo` scope. Then, store this token in your repository secrets (i.e. `https://github.com/<USER>/<REPO>/settings/secrets/actions`) as `GH_TOKEN_FOR_UPDATES` and set up your workflow file like the following:

```
name: update-rust-toolchain
on:
  workflow_dispatch: # allows manual triggering
  schedule:
    - cron: '0 9 * * sun' # runs at 9 am on every sunday

jobs:
  update-rust-toolchain:
    name: "Update rust-toolchain"
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
      - name: update rust toolchain
        uses: a-kenji/update-rust-toolchain@v1
        with:
          token: ${{ secrets.GH_TOKEN_FOR_UPDATES }}
```
It is additionally recommended to scope the environment variable in an environment, if possible.


### Currently supports:

* Toolchain files in the following format:

`rust-toolchain`
```
1.45.0
```

`rust-toolchain.toml`
```
[toolchain]
channel = "1.45.0"
components = ["rustfmt", "clippy", "rust-analysis"]
targets = ["wasm32-wasi"]
```

Channels with the `Beta`, or `Nightly` prefix are not yet supported.
