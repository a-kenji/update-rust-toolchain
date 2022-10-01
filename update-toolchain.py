#!/usr/bin/env python
# Updates a rust-toolchain file in relation to the official rust releases
import json
from pathlib import Path
import glob

import tomllib as toml
# import requests
# import re

ROOT = "https://github.com/a-kenji/update-rust-toolchain/data"


def find_toolchains(channel):
    toolchains = glob.glob("rust-toolchain.toml", recursive=True)
    toolchains += glob.glob("rust-toolchain", recursive=True)
    # p = Path('outputs/nightly/')
    # toolchains = [x for x in p.iterdir() if x]
    return toolchains


# [toolchain]
#     channel = "1.61.0"
#     components = ["rustfmt", "clippy", "rust-analysis"]
#     targets = ["wasm32-wasi", "x86_64-unknown-linux-musl"]


def load_meta(path):
    pass


def load_channel(path):
    pass


def load_map(path):
    "Load the map that is used to map the"
    "components to their respective numbers."
    with open(path, "r") as file:
        map = json.load(file)
    return map


def component_targets(map, component, targets):
    # Every component here needs a corresponding target in it's target channel
    components = ["rustfmt", "clippy", "rust-analysis"]
    targets = ["wasm32-wasi", "x86_64-unknown-linux-musl"]
    pass


def match_map_components(map, component):
    pass


def load_toolchain(path):
    with open(path, 'rb') as file:
        toolchain = toml.load(file)
    return toolchain


def main():
    print(load_toolchain("./rust-toolchain.toml"))
    print(find_toolchains("test"))
    # print(load_map("./outputs/nightly/since-2022-09-30-map.json").get("rust-analysis"))


if __name__ == "__main__":
    main()
