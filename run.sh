#!/bin/env/bash
# local testing
export RUST_TOOLCHAIN_FILE=./rust-toolchain
export MINOR_VERSION_DELTA=0
export BLURB="This is updated by: action/update-rust-toolchain"
export PATCH_VERSION=true


./update-toolchain.sh


