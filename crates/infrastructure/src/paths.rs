//! Per-user, per-OS locations for the launcher's own files.
//!
//! - Windows: `%APPDATA%\Dynamotivation\SoftwareHub\config`
//! - macOS:   `~/Library/Application Support/com.Dynamotivation.SoftwareHub`
//! - Linux:   `$XDG_CONFIG_HOME/softwarehub` (default `~/.config/softwarehub`)

use std::path::PathBuf;

use directories::ProjectDirs;

/// Matches the bundle identifier `com.dynamotivation.softwarehub`.
const QUALIFIER: &str = "com";
const ORGANIZATION: &str = "Dynamotivation";
const APPLICATION: &str = "SoftwareHub";

/// Path of `preferences.ini`, or `None` if no home directory can be determined.
pub fn preferences_file() -> Option<PathBuf> {
    ProjectDirs::from(QUALIFIER, ORGANIZATION, APPLICATION)
        .map(|dirs| dirs.config_dir().join("preferences.ini"))
}
