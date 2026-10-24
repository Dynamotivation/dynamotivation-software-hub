# Dynamotivation Software Hub

Desktop launcher and toolbox for Dynamotivation software installed on your device. Built with Rust and [Slint](https://slint.dev).

## Develop
```sh
cargo run              # run the desktop app (debug builds include sample data)
cargo xtask check      # fmt + clippy + tests + architecture rules
```
Requires Rust ≥ 1.92. On Linux, install the winit/OpenGL system libraries first (e.g. `libfontconfig1-dev libxkbcommon-dev libwayland-dev libgl1-mesa-dev`).

## Release (local)
```sh
rustup target add <triple>
cargo xtask dist --target <triple>
```
This writes `dist/dynamotivation-software-hub-<version>-<triple>.{zip|tar.gz}` plus a `.sha256` file.

| OS | Targets | Build on |
|---|---|---|
| Windows | `x86_64-pc-windows-msvc`, `aarch64-pc-windows-msvc` (or `x86_64-pc-windows-gnu`) | Windows |
| macOS | `x86_64-apple-darwin`, `aarch64-apple-darwin` | macOS |
| Linux | `x86_64-unknown-linux-gnu`, `aarch64-unknown-linux-gnu` | Linux |

Preferences are stored in `preferences.ini` in the per-user config directory (`%APPDATA%\Dynamotivation\SoftwareHub\config` on Windows).

See [AGENTS.md](AGENTS.md) for the architecture rules.
