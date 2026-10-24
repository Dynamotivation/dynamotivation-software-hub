//! Application layer: use cases, read models (DTOs) and outbound ports.
//!
//! Adapters (UI, infrastructure) talk to the domain only through this crate.
//! Use cases return DTOs, never domain aggregates.

pub mod dto;
pub mod error;
pub mod packages;
pub mod ports;
pub mod preferences;

pub use dto::{PackageStatusView, PackageView};
pub use error::ApplicationError;
pub use packages::{InstallationChange, ListPackages, RecordInstallationChange, RegisterPackage};
pub use ports::{EventPublisher, PreferencesError, PreferencesStore};
pub use preferences::{ColorScheme, Preferences, PreferencesService};

#[cfg(test)]
pub(crate) mod test_support;
