//! Slint presentation adapter.
//!
//! Depends only on `hub-application`: it calls use cases and maps their DTOs
//! to Slint view types (see [`presenter`]). It never sees domain aggregates.

mod presenter;

use std::rc::Rc;

use hub_application::{ListPackages, PreferencesService, RegisterPackage};
use slint::{ComponentHandle, ModelRc, SharedString, VecModel};

#[allow(
    clippy::all,
    clippy::pedantic,
    missing_debug_implementations,
    unused_qualifications
)]
mod generated {
    slint::include_modules!();
}

pub use generated::{AppWindow, PackageRow, PackageStatus, ThemePreference};

/// Use cases the UI needs, wired by the platform app (composition root).
#[derive(Debug, Clone)]
pub struct Services {
    pub register_package: RegisterPackage,
    pub list_packages: ListPackages,
    pub preferences: PreferencesService,
}

/// Creates the main window, wires callbacks and runs the event loop.
pub fn run(services: Services, version: &str) -> Result<(), slint::PlatformError> {
    let ui = AppWindow::new()?;
    ui.set_version(version.into());

    match services.preferences.load() {
        Ok(prefs) => ui.set_theme(presenter::theme_from(prefs.color_scheme)),
        Err(e) => eprintln!("[preferences] using defaults: {e}"),
    }

    refresh(&services, &ui);

    let weak = ui.as_weak();
    let s = services.clone();
    ui.on_register_package(move |name| {
        let Some(ui) = weak.upgrade() else {
            return false;
        };
        match s.register_package.execute(&name) {
            Ok(_) => {
                refresh(&s, &ui);
                true
            }
            Err(e) => {
                ui.set_error_message(e.to_string().into());
                false
            }
        }
    });

    let weak = ui.as_weak();
    let s = services.clone();
    ui.on_refresh_packages(move || {
        if let Some(ui) = weak.upgrade() {
            refresh(&s, &ui);
        }
    });

    let weak = ui.as_weak();
    let s = services;
    ui.on_theme_selected(move |theme| {
        let Some(ui) = weak.upgrade() else { return };
        if let Err(e) = s
            .preferences
            .set_color_scheme(presenter::color_scheme_from(theme))
        {
            ui.set_error_message(e.to_string().into());
        }
    });

    ui.run()
}

fn refresh(services: &Services, ui: &AppWindow) {
    match services.list_packages.execute() {
        Ok(views) => {
            let rows: Vec<PackageRow> = views.iter().map(presenter::row_from).collect();
            ui.set_packages(ModelRc::from(Rc::new(VecModel::from(rows))));
            ui.set_error_message(SharedString::new());
        }
        Err(e) => ui.set_error_message(e.to_string().into()),
    }
}
