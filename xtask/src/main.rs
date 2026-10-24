//! Repository automation. Run via the `cargo xtask` alias (see `.cargo/config.toml`).
//!
//! - `cargo xtask check`               fmt + clippy + tests + architecture rules
//! - `cargo xtask check-arch`          architecture (dependency direction) rules only
//! - `cargo xtask dist [--target T]`   release build + archive + SHA-256 into `dist/`

mod arch;
mod dist;

use std::process::{Command, ExitCode};

type Result<T = ()> = std::result::Result<T, String>;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let result = match args.first().map(String::as_str) {
        Some("check") => check(),
        Some("check-arch") => arch::check(),
        Some("dist") => dist::run(&args[1..]),
        _ => {
            eprintln!("usage: cargo xtask <check | check-arch | dist [--target <triple>]>");
            return ExitCode::from(2);
        }
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("error: {e}");
            ExitCode::FAILURE
        }
    }
}

fn check() -> Result {
    cargo(&["fmt", "--all", "--check"])?;
    cargo(&[
        "clippy",
        "--workspace",
        "--all-targets",
        "--locked",
        "--",
        "-D",
        "warnings",
    ])?;
    cargo(&["test", "--workspace", "--locked"])?;
    arch::check()
}

/// Runs `cargo <args>` from the workspace root, failing on non-zero exit.
pub(crate) fn cargo(args: &[&str]) -> Result {
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".into());
    eprintln!("> cargo {}", args.join(" "));
    let status = Command::new(cargo)
        .args(args)
        .current_dir(workspace_root())
        .status()
        .map_err(|e| format!("failed to run cargo: {e}"))?;
    if status.success() {
        Ok(())
    } else {
        Err(format!("`cargo {}` failed", args.join(" ")))
    }
}

pub(crate) fn workspace_root() -> std::path::PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .map_or_else(|| ".".into(), std::path::Path::to_path_buf)
}
