//! Desktop entry point and composition root: wires adapters into use cases.
//! No business logic belongs here.

// Never attach a console window on Windows.
#![windows_subsystem = "windows"]

use std::sync::Arc;

use hub_application::{
    InstallationChange, ListPackages, PreferencesService, RecordInstallationChange, RegisterPackage,
};
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

    let record_change = RecordInstallationChange::new(repo.clone(), events.clone());
    let services = Services {
        register_package: RegisterPackage::new(repo.clone(), events),
        list_packages: ListPackages::new(repo),
        preferences: PreferencesService::new(preferences),
    };

    #[cfg(debug_assertions)]
    seed_dev_data(&services, &record_change);

    #[cfg(not(debug_assertions))]
    let _ = record_change;

    hub_ui::run(services, env!("CARGO_PKG_VERSION"))
}

/// Sample Dynamotivation packages for local development; never shipped in release builds.
#[cfg(debug_assertions)]
fn seed_dev_data(services: &Services, record_change: &RecordInstallationChange) {
    let installed = [
        ("Joins the Battle Meme Generator", false),
        ("Geo Background Generator", true),
        ("Stellenwerttafel Plus", false),
    ];

    for (name, has_update) in installed {
        match services.register_package.execute(name) {
            Ok(view) => {
                if let Err(e) = record_change.execute(&view.id, InstallationChange::Installed) {
                    eprintln!("[seed] install {name}: {e}");
                } else if has_update
                    && let Err(e) =
                        record_change.execute(&view.id, InstallationChange::UpdateAvailable)
                {
                    eprintln!("[seed] flag update {name}: {e}");
                }
            }
            Err(e) => eprintln!("[seed] {name}: {e}"),
        }
    }

    let available = [
        "Unofficial Super Mario Bros. Misfit Pack",
        "OSS Space Adventure",
        "BenPlaysGames Soundboard",
        "Unofficial Sonic Mania Mobile Prototype",
        "Project Tortuga",
        "GerMemz",
    ];

    for name in available {
        if let Err(e) = services.register_package.execute(name) {
            eprintln!("[seed] {name}: {e}");
        }
    }
}
