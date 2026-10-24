use std::sync::Arc;

use crate::error::ApplicationError;
use crate::ports::PreferencesStore;

/// Launcher preferences (generic subdomain, not part of the core domain).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Preferences {
    pub color_scheme: ColorScheme,
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
        let service = PreferencesService::new(store.clone());
        service.set_color_scheme(ColorScheme::Dark).unwrap();
        assert_eq!(service.load().unwrap().color_scheme, ColorScheme::Dark);
    }
}
