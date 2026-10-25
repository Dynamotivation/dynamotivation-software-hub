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

/// Path of `softwarehub.log`, or `None` if no home directory can be determined.
pub fn log_file() -> Option<PathBuf> {
    ProjectDirs::from(QUALIFIER, ORGANIZATION, APPLICATION)
        .map(|dirs| dirs.data_dir().join("softwarehub.log"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preferences_file_has_correct_file_name() {
        if let Some(path) = preferences_file() {
            assert!(path.ends_with("preferences.ini"));
        }
    }

    #[test]
    fn log_file_has_correct_file_name() {
        if let Some(path) = log_file() {
            assert!(path.ends_with("softwarehub.log"));
        }
    }
}
