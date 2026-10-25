//! Pure mapping between application DTOs and Slint view types.

use hub_application::{ColorScheme, PackageStatusView, PackageView};

use crate::generated::{PackageRow, PackageStatus, ThemePreference};

struct CatalogMetadata {
    description: &'static str,
    version: &'static str,
    latest_version: &'static str,
}

fn catalog_metadata(id: &str) -> CatalogMetadata {
    match id {
        "joins-the-battle-meme-generator" => CatalogMetadata {
            description: "Create authentic fighting game splash screens and memes",
            version: "2.4.1",
            latest_version: "2.4.1",
        },
        "geo-background-generator" => CatalogMetadata {
            description: "Geometric pattern background generator with customizable gradients",
            version: "1.8.2",
            latest_version: "2.0.0",
        },
        "stellenwerttafel-plus" => CatalogMetadata {
            description: "Interactive place value chart for binary, decimal, and hex",
            version: "1.3.0",
            latest_version: "1.3.0",
        },
        "unofficial-super-mario-bros-misfit-pack" => CatalogMetadata {
            description: "Classic platformer collection with visual enhancements and widescreen",
            version: "0.9.0",
            latest_version: "0.9.0",
        },
        "oss-space-adventure" => CatalogMetadata {
            description: "Retro arcade space shooter — protect your planet from asteroids",
            version: "1.2.4",
            latest_version: "1.2.4",
        },
        "benplaysgames-soundboard" => CatalogMetadata {
            description: "Soundboard app for YouTuber and Twitch streamer BenPlaysGames",
            version: "1.1.0",
            latest_version: "1.1.0",
        },
        "unofficial-sonic-mania-mobile-prototype" => CatalogMetadata {
            description: "Fan port prototype built with GameMaker: Studio and Sonic MAX",
            version: "0.4.2",
            latest_version: "0.4.2",
        },
        "project-tortuga" => CatalogMetadata {
            description: "Custom Call of Duty: Black Ops 3 Zombies map and GSC/CSC scripts",
            version: "1.0.0",
            latest_version: "1.0.0",
        },
        "germemz" => CatalogMetadata {
            description: "German TV commercial meme soundboard with 45 iconic quotes",
            version: "1.0.3",
            latest_version: "1.0.3",
        },
        _ => CatalogMetadata {
            description: "Dynamotivation software package managed on this device",
            version: "1.0.0",
            latest_version: "1.1.0",
        },
    }
}

pub fn row_from(view: &PackageView) -> PackageRow {
    let meta = catalog_metadata(&view.id);
    PackageRow {
        id: view.id.as_str().into(),
        name: view.name.as_str().into(),
        description: meta.description.into(),
        version: meta.version.into(),
        latest_version: meta.latest_version.into(),
        status: status_from(view.status),
    }
}

fn matches_query(row: &PackageRow, query_lower: &str) -> bool {
    if query_lower.is_empty() {
        return true;
    }
    row.name.to_lowercase().contains(query_lower)
        || row.description.to_lowercase().contains(query_lower)
        || row.id.to_lowercase().contains(query_lower)
}

/// Splits package views into `(installed, available, updates_count)`, filtered by `query`.
pub fn partition_rows_filtered(
    views: &[PackageView],
    query: &str,
) -> (Vec<PackageRow>, Vec<PackageRow>, i32) {
    let query_lower = query.trim().to_lowercase();
    let mut installed = Vec::new();
    let mut available = Vec::new();
    let mut updates_count: i32 = 0;

    for view in views {
        let row = row_from(view);
        if !matches_query(&row, &query_lower) {
            continue;
        }
        match view.status {
            PackageStatusView::Installed => installed.push(row),
            PackageStatusView::UpdateAvailable => {
                updates_count = updates_count.saturating_add(1);
                installed.push(row);
            }
            PackageStatusView::NotInstalled => available.push(row),
        }
    }

    (installed, available, updates_count)
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
        ThemePreference::System => ColorScheme::System,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_rows() {
        let row = row_from(&PackageView {
            id: "geo-background-generator".into(),
            name: "Geo Background Generator".into(),
            status: PackageStatusView::UpdateAvailable,
        });
        assert_eq!(row.id, "geo-background-generator");
        assert_eq!(row.version, "1.8.2");
        assert_eq!(row.latest_version, "2.0.0");
        assert_eq!(row.status, PackageStatus::UpdateAvailable);
    }

    #[test]
    fn partitions_and_filters_installed_and_available_rows() {
        let views = vec![
            PackageView {
                id: "geo-background-generator".into(),
                name: "Geo Background Generator".into(),
                status: PackageStatusView::UpdateAvailable,
            },
            PackageView {
                id: "stellenwerttafel-plus".into(),
                name: "Stellenwerttafel Plus".into(),
                status: PackageStatusView::Installed,
            },
            PackageView {
                id: "oss-space-adventure".into(),
                name: "OSS Space Adventure".into(),
                status: PackageStatusView::NotInstalled,
            },
        ];
        let (installed, available, updates) = partition_rows_filtered(&views, "");
        assert_eq!(installed.len(), 2);
        assert_eq!(available.len(), 1);
        assert_eq!(updates, 1);

        let (installed_q, available_q, updates_q) = partition_rows_filtered(&views, "space");
        assert_eq!(installed_q.len(), 0);
        assert_eq!(available_q.len(), 1);
        assert_eq!(updates_q, 0);
    }

    #[test]
    fn theme_round_trips() {
        for s in [ColorScheme::System, ColorScheme::Light, ColorScheme::Dark] {
            assert_eq!(color_scheme_from(theme_from(s)), s);
        }
    }
}
