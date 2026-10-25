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

    #[cfg(windows)]
    {
        apply_windows_11_rounded_corners();
        ui.set_native_corners(true);
    }

    #[cfg(debug_assertions)]
    ui.set_hub_update_version("0.2.0".into());

    match services.preferences.load() {
        Ok(prefs) => {
            ui.set_theme(presenter::theme_from(prefs.color_scheme));
            ui.set_autostart_in_background(prefs.autostart_in_background);
            ui.set_auto_check_updates(prefs.auto_check_updates);
            ui.set_show_notifications(prefs.show_notifications);
            ui.set_keep_running_in_background(prefs.keep_running_in_background);
        }
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
    let s = services.clone();
    ui.on_theme_selected(move |theme| {
        let Some(ui) = weak.upgrade() else { return };
        if let Err(e) = s
            .preferences
            .set_color_scheme(presenter::color_scheme_from(theme))
        {
            ui.set_error_message(e.to_string().into());
        }
    });

    let weak = ui.as_weak();
    let s = services.clone();
    ui.on_autostart_toggled(move |val| {
        let Some(ui) = weak.upgrade() else { return };
        if let Err(e) = s.preferences.set_autostart_in_background(val) {
            ui.set_error_message(e.to_string().into());
        }
    });

    let weak = ui.as_weak();
    let s = services.clone();
    ui.on_auto_updates_toggled(move |val| {
        let Some(ui) = weak.upgrade() else { return };
        if let Err(e) = s.preferences.set_auto_check_updates(val) {
            ui.set_error_message(e.to_string().into());
        }
    });

    let weak = ui.as_weak();
    let s = services.clone();
    ui.on_notifications_toggled(move |val| {
        let Some(ui) = weak.upgrade() else { return };
        if let Err(e) = s.preferences.set_show_notifications(val) {
            ui.set_error_message(e.to_string().into());
        }
    });

    let weak = ui.as_weak();
    let s = services;
    ui.on_background_running_toggled(move |val| {
        let Some(ui) = weak.upgrade() else { return };
        if let Err(e) = s.preferences.set_keep_running_in_background(val) {
            ui.set_error_message(e.to_string().into());
        }
    });

    ui.run()
}

#[cfg(windows)]
fn apply_windows_11_rounded_corners() {
    #[allow(unsafe_code)]
    unsafe {
        use std::ffi::c_void;

        #[repr(C)]
        struct Margins {
            cx_left_width: i32,
            cx_right_width: i32,
            cy_top_height: i32,
            cy_bottom_height: i32,
        }

        unsafe extern "system" {
            fn GetCurrentProcessId() -> u32;
            fn EnumWindows(
                lpEnumFunc: unsafe extern "system" fn(isize, isize) -> i32,
                lParam: isize,
            ) -> i32;
            fn GetWindowThreadProcessId(hWnd: isize, lpdwProcessId: *mut u32) -> u32;
            fn IsWindowVisible(hWnd: isize) -> i32;
            fn DwmSetWindowAttribute(
                hwnd: isize,
                dwAttribute: u32,
                pvAttribute: *const c_void,
                cbAttribute: u32,
            ) -> i32;
            fn DwmExtendFrameIntoClientArea(hwnd: isize, pMarInset: *const Margins) -> i32;
            fn GetWindowLongW(hWnd: isize, nIndex: i32) -> i32;
            fn SetWindowLongW(hWnd: isize, nIndex: i32, dwNewLong: i32) -> i32;
            fn SetWindowPos(
                hWnd: isize,
                hWndInsertAfter: isize,
                X: i32,
                Y: i32,
                cx: i32,
                cy: i32,
                uFlags: u32,
            ) -> i32;
        }

        unsafe extern "system" fn enum_proc(hwnd: isize, _lparam: isize) -> i32 {
            unsafe {
                let mut proc_id = 0u32;
                GetWindowThreadProcessId(hwnd, std::ptr::addr_of_mut!(proc_id));
                if proc_id == GetCurrentProcessId() && IsWindowVisible(hwnd) != 0 {
                    // DWMWA_WINDOW_CORNER_PREFERENCE = 33
                    // DWMWCP_ROUND = 2 (Windows 11 standard rounded corners)
                    let preference: u32 = 2;
                    let _ = DwmSetWindowAttribute(
                        hwnd,
                        33,
                        std::ptr::addr_of!(preference).cast::<c_void>(),
                        4,
                    );

                    // Add WS_THICKFRAME (0x00040000), WS_MINIMIZEBOX (0x00020000), WS_MAXIMIZEBOX (0x00010000)
                    let style = GetWindowLongW(hwnd, -16);
                    let _ =
                        SetWindowLongW(hwnd, -16, style | 0x0004_0000 | 0x0002_0000 | 0x0001_0000);
                    // SWP_FRAMECHANGED (0x0020) | SWP_NOMOVE (0x0002) | SWP_NOSIZE (0x0001) | SWP_NOZORDER (0x0004)
                    let _ = SetWindowPos(hwnd, 0, 0, 0, 0, 0, 0x0027);

                    let margins = Margins {
                        cx_left_width: 0,
                        cx_right_width: 0,
                        cy_top_height: 0,
                        cy_bottom_height: 1,
                    };
                    let _ = DwmExtendFrameIntoClientArea(hwnd, std::ptr::addr_of!(margins));
                }
                1
            }
        }

        let _ = EnumWindows(enum_proc, 0);
    }
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
            ui.set_is_maximized(!maximized);
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
    ui.on_resize_window_west(move |dx| {
        if let Some(ui) = weak.upgrade() {
            let scale = ui.window().scale_factor();
            let size = ui.window().size().to_logical(scale);
            let pos = ui.window().position().to_logical(scale);
            let new_w = (size.width - dx).max(440.0);
            let actual_dx = size.width - new_w;
            ui.window().set_size(LogicalSize::new(new_w, size.height));
            ui.window()
                .set_position(LogicalPosition::new(pos.x + actual_dx, pos.y));
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

    let weak = ui.as_weak();
    ui.on_resize_window_southwest(move |dx, dy| {
        if let Some(ui) = weak.upgrade() {
            let scale = ui.window().scale_factor();
            let size = ui.window().size().to_logical(scale);
            let pos = ui.window().position().to_logical(scale);
            let new_w = (size.width - dx).max(440.0);
            let new_h = (size.height + dy).max(520.0);
            let actual_dx = size.width - new_w;
            ui.window().set_size(LogicalSize::new(new_w, new_h));
            ui.window()
                .set_position(LogicalPosition::new(pos.x + actual_dx, pos.y));
        }
    });

    let weak = ui.as_weak();
    ui.on_hub_update_requested(move || {
        if let Some(ui) = weak.upgrade() {
            ui.set_error_message("Software Hub update downloading in background…".into());
        }
    });
}

fn refresh(services: &Services, ui: &AppWindow) {
    match services.list_packages.execute() {
        Ok(views) => {
            let query = ui.get_search_query();
            let (installed, available, _updates_count) =
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
            ui.set_installed_packages(ModelRc::from(Rc::new(VecModel::from(installed))));
            ui.set_available_packages(ModelRc::from(Rc::new(VecModel::from(available))));
            ui.set_error_message(SharedString::new());
        }
        Err(e) => ui.set_error_message(e.to_string().into()),
    }
}
