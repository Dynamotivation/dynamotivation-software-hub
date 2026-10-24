use std::fmt;

use hub_domain::PackageEvent;

use crate::preferences::Preferences;

/// Outbound port: publishes domain events after they were persisted.
pub trait EventPublisher: Send + Sync {
    fn publish(&self, events: &[PackageEvent]);
}

/// Outbound port: persistence of the launcher's own preferences.
pub trait PreferencesStore: Send + Sync {
    /// Returns defaults when nothing has been stored yet.
    fn load(&self) -> Result<Preferences, PreferencesError>;
    fn save(&self, preferences: &Preferences) -> Result<(), PreferencesError>;
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PreferencesError(String);

impl PreferencesError {
    pub fn new(message: impl Into<String>) -> Self {
        Self(message.into())
    }
}

impl fmt::Display for PreferencesError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Preferences error: {}", self.0)
    }
}

impl std::error::Error for PreferencesError {}
