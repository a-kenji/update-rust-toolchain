#!/usr/bin/env python
# Updates a rust-toolchain file in relation to the official rust releases
import json
import tomllib as toml
import requests
import re

ROOT = "https://github.com/a-kenji/update-rust-toolchain/data"


def find_toolchain():
    pass


def load_meta(path):
    pass


def load_channel(path):
    pass


def load_toolchain(path):
    with open(path) as file:
        toolchain = toml.loads(file)
    return toolchain


def main():
    print(load_toolchain("./rust-toolchain.toml"))


if __name__ == "__main__":
    main()
