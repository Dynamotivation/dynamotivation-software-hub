//! Slint presentation adapter.
//!
//! Depends only on `hub-application`: it calls use cases and maps their DTOs
//! to Slint view types (see [`presenter`]). It never sees domain aggregates.

mod presenter;

use std::rc::Rc;

use hub_application::{ListPackages, PreferencesService, RegisterPackage};
use slint::{ComponentHandle, LogicalPosition, LogicalSize, ModelRc, SharedString, VecModel};

#[allow(
    unsafe_code,
    clippy::all,
    clippy::pedantic,
    clippy::restriction,
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
    ui.show()?;
    ui.set_version(version.into());

    match services.preferences.load() {
        Ok(prefs) => ui.set_theme(presenter::theme_from(prefs.color_scheme)),
        Err(e) => eprintln!("[preferences] using defaults: {e}"),
    }

    refresh(&services, &ui);
    wire_window_chrome(&ui);

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
    let s = services.clone();
    ui.on_search_edited(move |_query| {
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

fn wire_window_chrome(ui: &AppWindow) {
    let weak = ui.as_weak();
    ui.on_move_window(move |dx, dy| {
        if let Some(ui) = weak.upgrade() {
            let scale = ui.window().scale_factor();
            let pos = ui.window().position().to_logical(scale);
            ui.window()
                .set_position(LogicalPosition::new(pos.x + dx, pos.y + dy));
        }
    });

    let weak = ui.as_weak();
    ui.on_minimize_window(move || {
        if let Some(ui) = weak.upgrade() {
            ui.window().set_minimized(true);
        }
    });

    let weak = ui.as_weak();
    ui.on_toggle_maximize_window(move || {
        if let Some(ui) = weak.upgrade() {
            let maximized = ui.window().is_maximized();
            ui.window().set_maximized(!maximized);
        }
    });

    let weak = ui.as_weak();
    ui.on_close_window(move || {
        if let Some(ui) = weak.upgrade() {
            let _ = ui.hide();
        }
        let _ = slint::quit_event_loop();
    });

    let weak = ui.as_weak();
    ui.on_resize_window_east(move |dx| {
        if let Some(ui) = weak.upgrade() {
            let scale = ui.window().scale_factor();
            let size = ui.window().size().to_logical(scale);
            let new_w = (size.width + dx).max(440.0);
            ui.window().set_size(LogicalSize::new(new_w, size.height));
        }
    });

    let weak = ui.as_weak();
    ui.on_resize_window_south(move |dy| {
        if let Some(ui) = weak.upgrade() {
            let scale = ui.window().scale_factor();
            let size = ui.window().size().to_logical(scale);
            let new_h = (size.height + dy).max(520.0);
            ui.window().set_size(LogicalSize::new(size.width, new_h));
        }
    });

    let weak = ui.as_weak();
    ui.on_resize_window_southeast(move |dx, dy| {
        if let Some(ui) = weak.upgrade() {
            let scale = ui.window().scale_factor();
            let size = ui.window().size().to_logical(scale);
            let new_w = (size.width + dx).max(440.0);
            let new_h = (size.height + dy).max(520.0);
            ui.window().set_size(LogicalSize::new(new_w, new_h));
        }
    });
}

fn refresh(services: &Services, ui: &AppWindow) {
    match services.list_packages.execute() {
        Ok(views) => {
            let query = ui.get_search_query();
            let rows: Vec<PackageRow> = views.iter().map(presenter::row_from).collect();
            let (installed, available, updates_count) =
                presenter::partition_rows_filtered(&views, query.as_str());
            let current_selected_id = ui.get_selected_package().id;
            if let Some(updated_sel) = installed
                .iter()
                .chain(available.iter())
                .find(|r| r.id == current_selected_id)
            {
                ui.set_selected_package(updated_sel.clone());
            } else if let Some(first) = installed.first().or_else(|| available.first()) {
                ui.set_selected_package(first.clone());
            }
            ui.set_packages(ModelRc::from(Rc::new(VecModel::from(rows))));
            ui.set_installed_packages(ModelRc::from(Rc::new(VecModel::from(installed))));
            ui.set_available_packages(ModelRc::from(Rc::new(VecModel::from(available))));
            ui.set_updates_count(updates_count);
            ui.set_error_message(SharedString::new());
        }
        Err(e) => ui.set_error_message(e.to_string().into()),
    }
}
