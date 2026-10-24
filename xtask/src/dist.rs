//! Local release packaging for desktop targets.
//!
//! Produces `dist/<binary>-<version>-<target>.{zip|tar.gz}` plus a `.sha256`.
//! Supported targets (install with `rustup target add <triple>`):
//! `x86_64-pc-windows-msvc`, `aarch64-pc-windows-msvc`, `x86_64-pc-windows-gnu`,
//! `x86_64-apple-darwin`, `aarch64-apple-darwin`,
//! `x86_64-unknown-linux-gnu`, `aarch64-unknown-linux-gnu`.
//! Cross-OS builds generally need that OS's SDK/linker; build on the target OS.

use std::fs;
use std::path::Path;
use std::process::Command;

use cargo_metadata::MetadataCommand;
use sha2::{Digest, Sha256};

use crate::{Result, cargo, workspace_root};

const APP_PACKAGE: &str = "dynamotivation-software-hub";

const SUPPORTED_TARGETS: &[&str] = &[
    "x86_64-pc-windows-msvc",
    "aarch64-pc-windows-msvc",
    "x86_64-pc-windows-gnu",
    "x86_64-apple-darwin",
    "aarch64-apple-darwin",
    "x86_64-unknown-linux-gnu",
    "aarch64-unknown-linux-gnu",
];

pub fn run(args: &[String]) -> Result {
    let target = match args {
        [] => host_target()?,
        [flag, t] if flag == "--target" => t.clone(),
        _ => return Err("usage: cargo xtask dist [--target <triple>]".into()),
    };
    if !SUPPORTED_TARGETS.contains(&target.as_str()) {
        return Err(format!(
            "unsupported target `{target}`; supported: {}",
            SUPPORTED_TARGETS.join(", ")
        ));
    }

    let root = workspace_root();
    let version = app_version()?;
    let windows = target.contains("windows");
    let exe = if windows {
        format!("{APP_PACKAGE}.exe")
    } else {
        APP_PACKAGE.to_owned()
    };

    cargo(&[
        "build",
        "--release",
        "--locked",
        "-p",
        APP_PACKAGE,
        "--target",
        &target,
    ])
    .map_err(|e| {
        format!(
            "{e}\nhint: `rustup target add {target}`; cross-OS builds need the target SDK/linker"
        )
    })?;

    let name = format!("{APP_PACKAGE}-{version}-{target}");
    let dist = root.join("dist");
    let stage = dist.join(&name);
    let _ = fs::remove_dir_all(&stage);
    fs::create_dir_all(&stage).map_err(io)?;

    let built = root.join("target").join(&target).join("release").join(&exe);
    fs::copy(&built, stage.join(&exe)).map_err(|e| format!("{}: {e}", built.display()))?;
    for extra in [
        "README.md",
        "LICENSE",
        "LICENSE.md",
        "THIRD_PARTY_LICENSES.md",
    ] {
        let src = root.join(extra);
        if src.exists() {
            fs::copy(&src, stage.join(extra)).map_err(io)?;
        }
    }

    let archive = if windows && cfg!(windows) {
        // bsdtar ships with Windows 10+ and can write zip.
        let file = format!("{name}.zip");
        tar(&dist, &["-a", "-c", "-f", &file, &name])?;
        file
    } else {
        let file = format!("{name}.tar.gz");
        tar(&dist, &["-c", "-z", "-f", &file, &name])?;
        file
    };

    let bytes = fs::read(dist.join(&archive)).map_err(io)?;
    let digest: String =
        Sha256::digest(&bytes)
            .iter()
            .fold(String::with_capacity(64), |mut acc, b| {
                use std::fmt::Write;
                let _ = write!(acc, "{b:02x}");
                acc
            });
    fs::write(
        dist.join(format!("{archive}.sha256")),
        format!("{digest}  {archive}\n"),
    )
    .map_err(io)?;

    eprintln!("dist: {}", dist.join(&archive).display());
    Ok(())
}

fn tar(cwd: &Path, args: &[&str]) -> Result {
    let status = Command::new("tar")
        .args(args)
        .current_dir(cwd)
        .status()
        .map_err(|e| format!("failed to run tar: {e}"))?;
    if status.success() {
        Ok(())
    } else {
        Err("tar failed".into())
    }
}

fn host_target() -> Result<String> {
    let out = Command::new("rustc")
        .arg("-vV")
        .output()
        .map_err(|e| format!("failed to run rustc: {e}"))?;
    String::from_utf8_lossy(&out.stdout)
        .lines()
        .find_map(|l| l.strip_prefix("host: ").map(str::to_owned))
        .ok_or_else(|| "could not determine host target".into())
}

fn app_version() -> Result<String> {
    let metadata = MetadataCommand::new()
        .manifest_path(workspace_root().join("Cargo.toml"))
        .no_deps()
        .exec()
        .map_err(|e| format!("cargo metadata failed: {e}"))?;
    metadata
        .workspace_packages()
        .iter()
        .find(|p| p.name.as_str() == APP_PACKAGE)
        .map(|p| p.version.to_string())
        .ok_or_else(|| format!("package `{APP_PACKAGE}` not found"))
}

#[allow(clippy::needless_pass_by_value)]
fn io(e: std::io::Error) -> String {
    e.to_string()
}
