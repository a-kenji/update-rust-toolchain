use clap::Parser;
use serde_derive::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::File;
use std::io::{Read, Write};
use std::path::PathBuf;

use thiserror::Error;

#[derive(Debug, Error)]
enum RustToolchainError {
    /// Io Error
    #[error("IoError: {0}")]
    Io(#[from] std::io::Error),
    /// Io Path Error
    #[error("IoError: {0}, {1}")]
    IoPath(std::io::Error, String),
    /// Deserialization Error
    #[error("Deserialization Error: {0}")]
    Serde(#[from] serde_json::Error),
    /// Deserialization Toml Error
    #[error("Deserialization Toml Error: {0}")]
    SerdeToml(#[from] toml::de::Error),
    #[error("Utf8 Conversion Error")]
    Utf8(#[from] std::str::Utf8Error),
    /// Reqwest Error
    #[error("Reqwest Error")]
    Reqwest(#[from] reqwest::Error),
    /// Reqwest Error
    #[error("Incorrect Channel")]
    IncorrectChannel(String),
}

#[derive(Debug, Clone, Deserialize)]
struct PreRelease {
    date: String,
    pkg: HashMap<String, Component>,
    renames: Option<HashMap<String, Rename>>,
    profiles: Option<HashMap<String, Vec<String>>>,
}

#[derive(Debug, Clone, Deserialize)]
struct Component {
    version: String,
    git_commit_hash: Option<String>,
    target: HashMap<String, Target>,
}

#[derive(Debug, Clone, Deserialize)]
struct Target {
    available: bool,
    url: Option<String>,
    hash: Option<String>,
    xz_url: Option<String>,
    xz_hash: Option<String>,
}
#[derive(Debug, Clone, Deserialize)]
struct Rename {
    to: String,
}

#[derive(Debug, Deserialize, Serialize)]
struct PreReleaseOutputs {
    date: String,
    version: String,
    components: HashMap<String, Vec<usize>>,
}

#[derive(Debug, Deserialize, Serialize, PartialEq)]
struct TargetMap {
    #[serde(flatten)]
    components: HashMap<String, Vec<String>>,
}

#[derive(Debug, Deserialize, Serialize)]
struct MetaData {
    latest_version: semver::Version,
}

impl MetaData {
    fn new(latest_version: semver::Version) -> Self {
        Self { latest_version }
    }
}

#[derive(Debug)]
enum Channel {
    Nightly,
    Beta,
    Stable,
}

impl std::str::FromStr for Channel {
    type Err = RustToolchainError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "nightly" => Ok(Self::Nightly),
            "beta" => Ok(Self::Beta),
            "stable" => Ok(Self::Stable),
            _ => Err(RustToolchainError::IncorrectChannel(
                "Please use one of 'nightly', 'beta', or 'stable'".to_owned(),
            )),
        }
    }
}

#[derive(Parser)]
struct CliArgs {
    channel: Channel,
    #[clap(long, value_parser)]
    output: Option<PathBuf>,
}

impl From<PreRelease> for PreReleaseOutputs {
    fn from(input: PreRelease) -> Self {
        let date = input.date;
        let version = input
            .pkg
            .get("rust")
            .unwrap()
            .version
            .to_owned()
            .split_once(' ')
            .unwrap()
            .0
            .to_owned();
        let mut components = HashMap::new();
        for (k, component) in input.pkg {
            let mut targets = Vec::new();
            let mut keys: Vec<String> = component.target.keys().map(|k| k.to_owned()).collect();
            keys.sort();
            for (i, v) in keys.into_iter().enumerate() {
                if let Some(target) = component.target.get(&v) {
                    if target.available {
                        targets.push(i);
                    }
                }
            }
            components.insert(k, targets);
        }
        Self {
            date,
            version,
            components,
        }
    }
}
impl From<PreRelease> for TargetMap {
    fn from(input: PreRelease) -> Self {
        let mut components = HashMap::new();
        for (k, component) in input.pkg {
            let mut keys: Vec<String> = component.target.keys().map(|k| k.to_owned()).collect();
            keys.sort();
            components.insert(k, keys);
        }
        Self { components }
    }
}
const RUST_RELEASES: &str = "https://api.github.com/repos/rust-lang/rust/tags";
const RUST_BETA_PRE_RELEASE: &str = "https://static.rust-lang.org/dist/channel-rust-beta.toml";
const RUST_NIGHTLY_PRE_RELEASE: &str =
    "https://static.rust-lang.org/dist/channel-rust-nightly.toml";

fn main() -> Result<(), RustToolchainError> {
    let opts = CliArgs::parse();
    let location = opts
        .output
        .unwrap_or_else(|| std::path::PathBuf::from("outputs"))
        .into_os_string()
        .into_string()
        .unwrap();
    match opts.channel {
        Channel::Nightly => {
            let resp = reqwest::blocking::get(RUST_NIGHTLY_PRE_RELEASE)?.text()?;
            let serialized: PreRelease = toml::from_str(&resp)?;
            std::fs::create_dir_all(format!("{location}/nightly"))?;
            let version = <PreRelease as Into<PreReleaseOutputs>>::into(serialized.clone()).version;
            let mut file = File::create(format!("{location}/nightly/{version}.json"))?;
            let outputs = serde_json::to_string::<PreReleaseOutputs>(&serialized.clone().into())?;
            file.write_all(outputs.as_bytes())?;

            let mut map = File::create(format!("outputs/nightly/since-{version}-map.json"))?;
            let outputs = serde_json::to_string::<TargetMap>(&serialized.into())?;
            map.write_all(outputs.as_bytes())?;
        }
        Channel::Beta => {
            let resp = reqwest::blocking::get(RUST_BETA_PRE_RELEASE)?.text()?;
            let serialized: PreRelease = toml::from_str(&resp)?;
            std::fs::create_dir_all(format!("{location}/beta"))?;
            let version = <PreRelease as Into<PreReleaseOutputs>>::into(serialized.clone()).version;

            let mut file = File::create(format!("{location}/beta/{version}.json"))?;
            let outputs = serde_json::to_string::<PreReleaseOutputs>(&serialized.clone().into())?;
            file.write_all(outputs.as_bytes())?;

            let mut map = File::create(format!("{location}/beta/since-{version}-map.json"))?;
            let outputs = serde_json::to_string::<TargetMap>(&serialized.into())?;
            map.write_all(outputs.as_bytes())?;
        }
        Channel::Stable => {}
    }
    Ok(())
}

pub(crate) fn write_meta_data(
    path: &str,
    version: semver::Version,
) -> Result<(), RustToolchainError> {
    let mut map = File::create(path)?;
    let outputs = serde_json::to_string::<MetaData>(&MetaData::new(version))?;
    map.write_all(outputs.as_bytes())?;
    Ok(())
}

pub(crate) fn read_meta_data(path: &str) -> Result<MetaData, RustToolchainError> {
    let mut file = File::open(path)?;
    let mut data = String::new();
    file.read_to_string(&mut data)?;
    serde_json::from_str::<MetaData>(&data).map_err(|e| e.into())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn rename_input() -> &'static str {
        r#"
        [rust-analyzer]
        to = "rust-analyzer-preview"
        [rust-docs-json]
        to = "rust-docs-json-preview"
        "#
    }
    fn target_input() -> &'static str {
        r#"
        [aarch64-pc-windows-msvc]
        available = true
        url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-aarch64-pc-windows-msvc.tar.gz"
        hash = "29445be91e4c1efc6cf2a7444aecafd930d64b5f9d94986bea58cec3b7f2497b"
        xz_url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-aarch64-pc-windows-msvc.tar.xz"
        xz_hash = "a7ef27e516d802c9427c2596149ef44d5ac876f97d57bdb063123011a01964a5"
        "#
    }
    fn target_inputs() -> &'static str {
        r#"
        [aarch64-pc-windows-msvc]
        available = true
        url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-aarch64-pc-windows-msvc.tar.gz"
        hash = "29445be91e4c1efc6cf2a7444aecafd930d64b5f9d94986bea58cec3b7f2497b"
        xz_url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-aarch64-pc-windows-msvc.tar.xz"
        xz_hash = "a7ef27e516d802c9427c2596149ef44d5ac876f97d57bdb063123011a01964a5"
        [mipsisa64r6el-unknown-linux-gnuabi64]
        available = false
        "#
    }
    fn component_inputs() -> &'static str {
        r#"
        [cargo]
        version = "0.66.0-nightly (73ba3f35e 2022-09-18)"
        git_commit_hash = "3f83906b30798bf61513fa340524cebf6676f9db"

        [cargo.target.armv7-unknown-linux-gnueabihf]
        available = true
        url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-armv7-unknown-linux-gnueabihf.tar.gz"
        hash = "a798ab508b69ee163382716d2c084dd9fcc90cd8078b3d79f29e3eead771f899"
        xz_url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-armv7-unknown-linux-gnueabihf.tar.xz"
        xz_hash = "dbc63ad7f20340a48e71efe7505709785bfaae382846e22eef8bf676353f5ad5"

        [cargo.target.i686-apple-darwin]
        available = false

        [cargo.target.i686-pc-windows-gnu]
        available = true
        url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-i686-pc-windows-gnu.tar.gz"
        hash = "970bd239c328795fd117e428c4e1dd1fa3c518beebc848807615413a7b28902d"
        xz_url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-i686-pc-windows-gnu.tar.xz"
        xz_hash = "31c0959dc715d99f4b1581b0168922cecb99c62775af2d07837f385df00e80ca"
        "#
    }
    fn release_inputs() -> &'static str {
        r#"
        manifest-version = "2"
        date = "2022-09-25"
        [pkg.cargo]
        version = "0.66.0-nightly (73ba3f35e 2022-09-18)"
        git_commit_hash = "3f83906b30798bf61513fa340524cebf6676f9db"
        [pkg.cargo.target.aarch64-apple-darwin]
        available = true
        url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-aarch64-apple-darwin.tar.gz"
        hash = "5dffd1d0a447f029c141bf8906e46c8f444847df802b5c92ddf8f3ed08268b86"
        xz_url = "https://static.rust-lang.org/dist/2022-09-25/cargo-nightly-aarch64-apple-darwin.tar.xz"
        xz_hash = "a870c680bc452c5fae498a4aba7a184d1e18fb6f46611ac68d790ae72c18adf9"
        [pkg.cargo.target.i686-apple-darwin]
        available = false
        [renames.rust-docs-json]
        to = "rust-docs-json-preview"

        [renames.rustfmt]
        to = "rustfmt-preview"
        "#
    }

    #[test]
    fn renames_parsed_is_ok() {
        let _serialised: HashMap<String, Rename> = toml::from_str(rename_input()).unwrap();
    }
    #[test]
    fn target_parsed_is_ok() {
        let _serialised: HashMap<String, Target> = toml::from_str(target_input()).unwrap();
    }
    #[test]
    fn targets_parsed_is_ok() {
        let _serialised: HashMap<String, Target> = toml::from_str(target_inputs()).unwrap();
    }
    #[test]
    fn components_parsed_is_ok() {
        let _serialised: HashMap<String, Component> = toml::from_str(component_inputs()).unwrap();
    }
    #[test]
    fn release_parsed_is_ok() {
        let _serialised: PreRelease = toml::from_str(release_inputs()).unwrap();
    }
}
