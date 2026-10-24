# AGENTS.md

**Dynamotivation Software Hub**: a desktop launcher/toolbox for managing the software packages from the same author (Dynamotivation) that are installed on the user's device. Rust + Slint. Desktop releases (Windows, macOS, Linux) are built locally; there's no CI.

## Layout (enforced by `cargo xtask check-arch`)
```
crates/domain          pure model (SoftwarePackage aggregate). No dependencies, no I/O, no clock.
crates/application     use cases, DTOs, ports. Depends on domain only.
crates/infrastructure  port adapters (in-memory repo, INI preferences). No UI crates.
crates/ui              Slint UI + presenter. Depends on application only.
apps/desktop           composition root + desktop Slint backend. No logic.
xtask                  check / dist automation
```

## Rules
- Change state only through aggregate commands (`install`, `update`, …). They enforce the lifecycle and record `PackageEvent`s.
- Use cases return DTOs, never aggregates. Errors are typed enums; never discard them, show them in the UI.
- UI colours must come from `Palette` or `Theme` (`ui/theme.slint`). All user-facing text uses `@tr()`.
- Preferences are the launcher's own settings only, stored in `preferences.ini` (per-user config dir).
- A new crate needs a rule in `xtask/src/arch.rs`.

## Commands
- `cargo run` runs the app (debug builds seed sample data).
- `cargo xtask check` runs fmt, clippy (`-D warnings`), tests and the architecture check. It must pass before you finish.
- `cargo xtask dist [--target <triple>]` creates the release archive and SHA-256 in `dist/`.

## Open decisions (ask the owner, don't assume)
- Licence. Slint is used under one of GPLv3, its royalty-free licence or a commercial licence. An `AboutSlint` attribution is shown in the app's About popup.
- How packages are discovered and installed. No installer adapter exists yet.
- Installer formats, code signing, app icons.
