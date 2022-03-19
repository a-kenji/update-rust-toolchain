# update-rust-toolchain

Keep a shared rust version for your project,
while also keeping it up to date.

Update patch versions as soon as they release,
or even update your minor versions.


## usage:

Creates a pr with an update to the patch version
```
jobs:
  rust-toolchain:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
      - name: Update rust-toolchain
        uses: a-kenji/update-rust-toolchain
      - name: Create Pull Request
        id: cpr
        uses: peter-evans/create-pull-request@v3
        with:
          commit-message: Update `rust-toolchain`
          committer: GitHub <noreply@github.com>
          author: ${{ github.actor }} <${{ github.actor }}@users.noreply.github.com>
          labels: |
            dependencies
            automated
            rust
```
