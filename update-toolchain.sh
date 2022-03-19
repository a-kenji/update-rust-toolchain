#!/usr/bin/env bash
set -euo pipefail
# dependencies: bash, curl, jq
#
# Updates a rust-toolchain file in relation to the official rust releases.


function _current_toolchain_version() {
local RUST_TOOLCHAIN_FILE="$1"
RUST_TOOLCHAIN_VERSION=$(grep -oP 'channel = "\K[^"]+' "${RUST_TOOLCHAIN_FILE}")
echo "$RUST_TOOLCHAIN_VERSION"
}

# update with new version number
function _update_channel(){
local RUST_TOOLCHAIN_VERSION="$1"
sed -e "/channel/s/\".*\"/\"${RUST_TOOLCHAIN_VERSION}\"/" "${RUST_TOOLCHAIN_FILE}"
}

function _get_last_no_releases() {
    curl --silent "https://api.github.com/repos/rust-lang/rust/releases" | \
        jq '.[range(50)].tag_name' | sed -e 's/\"//g'
}

function _parse_semver() {
    local token="$1"
    local major=0
    local minor=0
    local patch=0

    if grep -E '^[0-9]+\.[0-9]+\.[0-9]+' <<<"$token" >/dev/null 2>&1 ; then
        local n=${token//[!0-9]/ }
        local a=(${n//\./ })
        major=${a[0]}
        minor=${a[1]}
        patch=${a[2]}
    fi

    echo "$major $minor $patch"
}
function _get_string_arrary() {
    IFS=' ' read  -r -a array <<< "$1";
    echo "${array["${2}"]}"
}


function _find_minor_version() {
local MINOR_DELTA="$1"
local RELEASES="$2"
local LATEST=0
for i in $RELEASES;do
    SEMVER=($(_parse_semver "$i"))
    if [ "$LATEST" != "${SEMVER[1]}" ];then
        MINOR_DELTA=$((MINOR_DELTA - 1))
    fi
    LATEST="${SEMVER[1]}"
    if [ -1 == "${MINOR_DELTA}" ];then
        echo "$i"
    fi
done
}

function _find_patch_version() {
local MINOR_VERSION="$1"
local RELEASES="$2"
for i in $RELEASES;do
    SEMVER=($(_parse_semver "$i"))
    if [ "$MINOR_VERSION" == "${SEMVER[1]}" ];then
        echo "$i"
    fi
done
}

_main() {
# Path to the rust-toolchain file
RUST_TOOLCHAIN_FILE="$TOOLCHAIN_FILE"
echo RUST_TOOLCHAIN_FILE "$TOOLCHAIN_FILE"
#RUST_TOOLCHAIN_FILE=$(echo "$TOOLCHAIN_FILE" | awk -F/ '{print $3}')
# How many minor versions delta there should be,
# will automatically advance patch versions.
MINOR_DELTA="$MINOR_VERSION_DELTA"
echo MINOR_DELTA "$MINOR_DELTA"
UPDATE_PATCH="$INPUTS_UPDATE_PATCH"
echo UPDATE_PATCH "$UPDATE_PATCH"
UPDATE_MINOR="$INPUTS_UPDATE_MINOR"
echo UPDATE_MINOR "$UPDATE_MINOR"
#MINOR_DELTA=$(echo "$MINOR_VERSION_DELTA" | awk -F/ '{print $3}')

RUST_TOOLCHAIN_VERSION="$(_current_toolchain_version "$RUST_TOOLCHAIN_FILE")"
echo CURRENT_RUST_TOOLCHAIN_VERSION "$RUST_TOOLCHAIN_VERSION"
RUST_TOOLCHAIN_VERSION=($(_parse_semver $(echo "$RUST_TOOLCHAIN_VERSION")))
echo RUST_TOOLCHAIN_VERSION_SEMVER "${RUST_TOOLCHAIN_VERSION[@]}"


RELEASES="$(_get_last_no_releases)"

if [[ $UPDATE_PATCH == "true" ]]; then
    VERSION=$(_find_patch_version "${RUST_TOOLCHAIN_VERSION[1]}" "$RELEASES")
fi

if [[ $UPDATE_MINOR == "true" ]]; then
    VERSION=$(_find_minor_version "${MINOR_DELTA}" "$RELEASES")
fi

echo "$(_update_channel $VERSION)" > "${RUST_TOOLCHAIN_FILE}"
cat "${RUST_TOOLCHAIN_FILE}"

}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _main "$@"
fi
