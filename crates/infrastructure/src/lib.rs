//! Infrastructure adapters for the outbound ports.

pub mod event_log;
pub mod in_memory_repo;
pub mod ini_preferences;
pub mod paths;

pub use event_log::{FileEventPublisher, NoopEventPublisher, StderrEventPublisher};
pub use in_memory_repo::InMemorySoftwarePackageRepository;
pub use ini_preferences::IniPreferencesStore;
