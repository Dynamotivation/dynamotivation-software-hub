//! Desktop entry point and composition root: wires adapters into use cases.
//! No business logic belongs here.

// No console window for release builds on Windows.
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::sync::Arc;

use hub_application::{ListPackages, PreferencesService, RegisterPackage};
use hub_infrastructure::{
    InMemorySoftwarePackageRepository, IniPreferencesStore, StderrEventPublisher, paths,
};
use hub_ui::Services;

fn main() -> Result<(), slint::PlatformError> {
    let repo = Arc::new(InMemorySoftwarePackageRepository::new());
    let events = Arc::new(StderrEventPublisher);
    let preferences_path = paths::preferences_file().unwrap_or_else(|| {
        eprintln!("[preferences] no home directory found; using temp directory");
        std::env::temp_dir().join("softwarehub-preferences.ini")
    });
    let preferences = Arc::new(IniPreferencesStore::new(preferences_path));

    let services = Services {
        register_package: RegisterPackage::new(repo.clone(), events),
        list_packages: ListPackages::new(repo),
        preferences: PreferencesService::new(preferences),
    };

    #[cfg(debug_assertions)]
    seed_dev_data(&services);

    hub_ui::run(services, env!("CARGO_PKG_VERSION"))
}

/// Sample packages for local development only; never shipped in release builds.
#[cfg(debug_assertions)]
fn seed_dev_data(services: &Services) {
    for name in ["Jumpmaster Engine Core", "Cross-Platform Asset Pipeline"] {
        if let Err(e) = services.register_package.execute(name) {
            eprintln!("[seed] {name}: {e}");
        }
    }
}
