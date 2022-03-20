# update-rust-toolchain

This is a GitHub Action that will update your `rust-toolchain` / `rust-toolchain.toml` file, when it is run.

Keep a shared rust version for your project,
while also keeping it up to date.

Update patch versions as soon as they release,
or even update your minor versions.


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


## Currently supports:

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

Channels with the `Beta`, or `Nigthly` prefix are not yet supported.
