use std::fs;
use std::path::{Path, PathBuf};

use hub_application::{ColorScheme, Preferences, PreferencesError, PreferencesStore};
use ini::Ini;

const SECTION_APPEARANCE: &str = "appearance";
const KEY_COLOR_SCHEME: &str = "color_scheme";

/// Stores [`Preferences`] in an INI file:
///
/// ```ini
/// [appearance]
/// color_scheme=system
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
        Ok(Preferences { color_scheme })
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
        store
            .save(&Preferences {
                color_scheme: ColorScheme::Dark,
            })
            .unwrap();
        assert_eq!(store.load().unwrap().color_scheme, ColorScheme::Dark);
        assert!(fs::read_to_string(&path).unwrap().contains("key=value"));
    }

    #[test]
    fn invalid_value_falls_back_to_default() {
        let path = temp_file("invalid");
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(&path, "[appearance]\ncolor_scheme=neon\n").unwrap();
        assert_eq!(
            IniPreferencesStore::new(&path).load().unwrap().color_scheme,
            ColorScheme::System
        );
    }
}
