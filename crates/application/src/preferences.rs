use std::sync::Arc;

use crate::error::ApplicationError;
use crate::ports::PreferencesStore;

/// Launcher preferences (generic subdomain, not part of the core domain).
#[allow(clippy::struct_excessive_bools)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Preferences {
    pub color_scheme: ColorScheme,
    pub autostart_in_background: bool,
    pub auto_check_updates: bool,
    pub show_notifications: bool,
    pub keep_running_in_background: bool,
}

impl Default for Preferences {
    fn default() -> Self {
        Self {
            color_scheme: ColorScheme::System,
            autostart_in_background: false,
            auto_check_updates: true,
            show_notifications: true,
            keep_running_in_background: true,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ColorScheme {
    #[default]
    System,
    Light,
    Dark,
}

impl ColorScheme {
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::System => "system",
            Self::Light => "light",
            Self::Dark => "dark",
        }
    }

    /// Lenient parse: unknown values fall back to `None` so callers can default.
    pub fn parse(raw: &str) -> Option<Self> {
        match raw.trim().to_ascii_lowercase().as_str() {
            "system" => Some(Self::System),
            "light" => Some(Self::Light),
            "dark" => Some(Self::Dark),
            _ => None,
        }
    }
}

#[derive(Clone)]
pub struct PreferencesService {
    store: Arc<dyn PreferencesStore>,
}

impl std::fmt::Debug for PreferencesService {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("PreferencesService").finish_non_exhaustive()
    }
}

impl PreferencesService {
    pub fn new(store: Arc<dyn PreferencesStore>) -> Self {
        Self { store }
    }

    pub fn load(&self) -> Result<Preferences, ApplicationError> {
        Ok(self.store.load()?)
    }

    pub fn set_color_scheme(
        &self,
        color_scheme: ColorScheme,
    ) -> Result<Preferences, ApplicationError> {
        let mut prefs = self.store.load().unwrap_or_default();
        prefs.color_scheme = color_scheme;
        self.store.save(&prefs)?;
        Ok(prefs)
    }

    pub fn set_autostart_in_background(
        &self,
        autostart: bool,
    ) -> Result<Preferences, ApplicationError> {
        let mut prefs = self.store.load().unwrap_or_default();
        prefs.autostart_in_background = autostart;
        self.store.save(&prefs)?;
        Ok(prefs)
    }

    pub fn set_auto_check_updates(
        &self,
        auto_check: bool,
    ) -> Result<Preferences, ApplicationError> {
        let mut prefs = self.store.load().unwrap_or_default();
        prefs.auto_check_updates = auto_check;
        self.store.save(&prefs)?;
        Ok(prefs)
    }

    pub fn set_show_notifications(&self, show: bool) -> Result<Preferences, ApplicationError> {
        let mut prefs = self.store.load().unwrap_or_default();
        prefs.show_notifications = show;
        self.store.save(&prefs)?;
        Ok(prefs)
    }

    pub fn set_keep_running_in_background(
        &self,
        keep_running: bool,
    ) -> Result<Preferences, ApplicationError> {
        let mut prefs = self.store.load().unwrap_or_default();
        prefs.keep_running_in_background = keep_running;
        self.store.save(&prefs)?;
        Ok(prefs)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::MemoryPreferences;

    #[test]
    fn color_scheme_round_trips() {
        for s in [ColorScheme::System, ColorScheme::Light, ColorScheme::Dark] {
            assert_eq!(ColorScheme::parse(s.as_str()), Some(s));
        }
        assert_eq!(ColorScheme::parse(" DARK "), Some(ColorScheme::Dark));
        assert_eq!(ColorScheme::parse("purple"), None);
    }

    #[test]
    fn set_color_scheme_persists() {
        let store = Arc::new(MemoryPreferences::default());
        let service = PreferencesService::new(store);
        service.set_color_scheme(ColorScheme::Dark).unwrap();
        assert_eq!(service.load().unwrap().color_scheme, ColorScheme::Dark);
    }

    #[test]
    fn general_settings_persist() {
        let store = Arc::new(MemoryPreferences::default());
        let service = PreferencesService::new(store);
        service.set_autostart_in_background(true).unwrap();
        service.set_auto_check_updates(false).unwrap();
        service.set_show_notifications(false).unwrap();
        service.set_keep_running_in_background(false).unwrap();

        let loaded = service.load().unwrap();
        assert!(loaded.autostart_in_background);
        assert!(!loaded.auto_check_updates);
        assert!(!loaded.show_notifications);
        assert!(!loaded.keep_running_in_background);
    }
}
