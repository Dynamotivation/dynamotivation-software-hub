use std::fs;
use std::path::{Path, PathBuf};

use hub_application::{ColorScheme, Preferences, PreferencesError, PreferencesStore};
use ini::Ini;

const SECTION_APPEARANCE: &str = "appearance";
const KEY_COLOR_SCHEME: &str = "color_scheme";

const SECTION_GENERAL: &str = "general";
const KEY_AUTOSTART_IN_BACKGROUND: &str = "autostart_in_background";
const KEY_AUTO_CHECK_UPDATES: &str = "auto_check_updates";
const KEY_SHOW_NOTIFICATIONS: &str = "show_notifications";
const KEY_KEEP_RUNNING_IN_BACKGROUND: &str = "keep_running_in_background";

/// Stores [`Preferences`] in an INI file:
///
/// ```ini
/// [appearance]
/// color_scheme=system
///
/// [general]
/// autostart_in_background=false
/// auto_check_updates=true
/// show_notifications=true
/// keep_running_in_background=true
/// ```
#[derive(Debug, Clone)]
pub struct IniPreferencesStore {
    path: PathBuf,
}

impl IniPreferencesStore {
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self { path: path.into() }
    }

    pub fn path(&self) -> &Path {
        &self.path
    }
}

fn parse_bool(raw: Option<&str>, default: bool) -> bool {
    match raw.map(|s| s.trim().to_ascii_lowercase()) {
        Some(s) if s == "true" || s == "1" || s == "yes" => true,
        Some(s) if s == "false" || s == "0" || s == "no" => false,
        _ => default,
    }
}

impl PreferencesStore for IniPreferencesStore {
    fn load(&self) -> Result<Preferences, PreferencesError> {
        if !self.path.exists() {
            return Ok(Preferences::default());
        }
        let ini = Ini::load_from_file(&self.path)
            .map_err(|e| PreferencesError::new(format!("{}: {e}", self.path.display())))?;
        let color_scheme = ini
            .get_from(Some(SECTION_APPEARANCE), KEY_COLOR_SCHEME)
            .and_then(ColorScheme::parse)
            .unwrap_or_default();

        let defaults = Preferences::default();
        let autostart_in_background = parse_bool(
            ini.get_from(Some(SECTION_GENERAL), KEY_AUTOSTART_IN_BACKGROUND),
            defaults.autostart_in_background,
        );
        let auto_check_updates = parse_bool(
            ini.get_from(Some(SECTION_GENERAL), KEY_AUTO_CHECK_UPDATES),
            defaults.auto_check_updates,
        );
        let show_notifications = parse_bool(
            ini.get_from(Some(SECTION_GENERAL), KEY_SHOW_NOTIFICATIONS),
            defaults.show_notifications,
        );
        let keep_running_in_background = parse_bool(
            ini.get_from(Some(SECTION_GENERAL), KEY_KEEP_RUNNING_IN_BACKGROUND),
            defaults.keep_running_in_background,
        );

        Ok(Preferences {
            color_scheme,
            autostart_in_background,
            auto_check_updates,
            show_notifications,
            keep_running_in_background,
        })
    }

    fn save(&self, preferences: &Preferences) -> Result<(), PreferencesError> {
        let err = |e: &dyn std::fmt::Display| {
            PreferencesError::new(format!("{}: {e}", self.path.display()))
        };
        if let Some(dir) = self.path.parent() {
            fs::create_dir_all(dir).map_err(|e| err(&e))?;
        }
        // Keep unknown keys written by newer versions.
        let mut ini = Ini::load_from_file(&self.path).unwrap_or_default();
        ini.with_section(Some(SECTION_APPEARANCE))
            .set(KEY_COLOR_SCHEME, preferences.color_scheme.as_str());
        ini.with_section(Some(SECTION_GENERAL))
            .set(
                KEY_AUTOSTART_IN_BACKGROUND,
                preferences.autostart_in_background.to_string(),
            )
            .set(
                KEY_AUTO_CHECK_UPDATES,
                preferences.auto_check_updates.to_string(),
            )
            .set(
                KEY_SHOW_NOTIFICATIONS,
                preferences.show_notifications.to_string(),
            )
            .set(
                KEY_KEEP_RUNNING_IN_BACKGROUND,
                preferences.keep_running_in_background.to_string(),
            );
        // Write-then-rename so a crash never leaves a half-written file.
        let tmp = self.path.with_extension("ini.tmp");
        ini.write_to_file(&tmp).map_err(|e| err(&e))?;
        fs::rename(&tmp, &self.path).map_err(|e| err(&e))
    }
}

#[cfg(test)]
mod tests {
    #![allow(clippy::unwrap_used)]
    use super::*;

    fn temp_file(name: &str) -> PathBuf {
        let dir =
            std::env::temp_dir().join(format!("hub-prefs-test-{}-{name}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        dir.join("nested").join("preferences.ini")
    }

    #[test]
    fn missing_file_yields_defaults() {
        let store = IniPreferencesStore::new(temp_file("missing"));
        assert_eq!(store.load().unwrap(), Preferences::default());
    }

    #[test]
    fn round_trips_and_keeps_unknown_keys() {
        let path = temp_file("roundtrip");
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(&path, "[future]\nkey=value\n").unwrap();
        let store = IniPreferencesStore::new(&path);
        let custom = Preferences {
            color_scheme: ColorScheme::Dark,
            autostart_in_background: true,
            auto_check_updates: false,
            show_notifications: false,
            keep_running_in_background: false,
        };
        store.save(&custom).unwrap();
        assert_eq!(store.load().unwrap(), custom);
        assert!(fs::read_to_string(&path).unwrap().contains("key=value"));
    }

    #[test]
    fn invalid_value_falls_back_to_default() {
        let path = temp_file("invalid");
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(
            &path,
            "[appearance]\ncolor_scheme=neon\n[general]\nautostart_in_background=maybe\n",
        )
        .unwrap();
        let loaded = IniPreferencesStore::new(&path).load().unwrap();
        assert_eq!(loaded.color_scheme, ColorScheme::System);
        assert_eq!(
            loaded.autostart_in_background,
            Preferences::default().autostart_in_background
        );
    }
}
