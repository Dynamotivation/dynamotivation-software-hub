//! Pure mapping between application DTOs and Slint view types.

use hub_application::{ColorScheme, PackageStatusView, PackageView};

use crate::generated::{PackageRow, PackageStatus, ThemePreference};

pub fn row_from(view: &PackageView) -> PackageRow {
    PackageRow {
        id: view.id.as_str().into(),
        name: view.name.as_str().into(),
        status: status_from(view.status),
    }
}

pub fn status_from(status: PackageStatusView) -> PackageStatus {
    match status {
        PackageStatusView::NotInstalled => PackageStatus::NotInstalled,
        PackageStatusView::Installed => PackageStatus::Installed,
        PackageStatusView::UpdateAvailable => PackageStatus::UpdateAvailable,
    }
}

pub fn theme_from(scheme: ColorScheme) -> ThemePreference {
    match scheme {
        ColorScheme::System => ThemePreference::System,
        ColorScheme::Light => ThemePreference::Light,
        ColorScheme::Dark => ThemePreference::Dark,
    }
}

pub fn color_scheme_from(theme: ThemePreference) -> ColorScheme {
    match theme {
        ThemePreference::Light => ColorScheme::Light,
        ThemePreference::Dark => ColorScheme::Dark,
        // Slint enums are non-exhaustive across versions; default to System.
        _ => ColorScheme::System,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_rows() {
        let row = row_from(&PackageView {
            id: "hub".into(),
            name: "Hub".into(),
            status: PackageStatusView::UpdateAvailable,
        });
        assert_eq!(row.id, "hub");
        assert_eq!(row.status, PackageStatus::UpdateAvailable);
    }

    #[test]
    fn theme_round_trips() {
        for s in [ColorScheme::System, ColorScheme::Light, ColorScheme::Dark] {
            assert_eq!(color_scheme_from(theme_from(s)), s);
        }
    }
}
