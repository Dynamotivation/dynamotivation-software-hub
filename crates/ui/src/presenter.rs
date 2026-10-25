//! Pure mapping between application DTOs and Slint view types.

use std::rc::Rc;

use hub_application::{ColorScheme, PackageStatusView, PackageView};
use slint::{ModelRc, SharedString, VecModel};

use crate::generated::{PackageRow, PackageStatus, ReleaseNote, ThemePreference};

struct ReleaseNoteData {
    version: &'static str,
    date: &'static str,
    highlights: &'static [&'static str],
}

struct CatalogMetadata {
    description: &'static str,
    version: &'static str,
    latest_version: &'static str,
    downloading: bool,
    latest_release: ReleaseNoteData,
    older_releases: &'static [ReleaseNoteData],
    versions: &'static [&'static str],
}

#[allow(clippy::too_many_lines)]
fn catalog_metadata(id: &str) -> CatalogMetadata {
    match id {
        "joins-the-battle-meme-generator" => CatalogMetadata {
            description: "Create authentic fighting game splash screens and memes",
            version: "2.4.1",
            latest_version: "2.4.1",
            downloading: false,
            latest_release: ReleaseNoteData {
                version: "2.4.1",
                date: "2026-08-14",
                highlights: &[
                    "Added custom font outline and drop shadow styling",
                    "New high-resolution PNG and animated GIF export options",
                    "Expanded template roster with 8 classic character poses",
                ],
            },
            older_releases: &[
                ReleaseNoteData {
                    version: "2.3.0",
                    date: "2026-03-22",
                    highlights: &[
                        "Drag-and-drop character artwork directly onto the canvas",
                        "Added alignment guidelines and snap-to-grid controls",
                    ],
                },
                ReleaseNoteData {
                    version: "2.0.0",
                    date: "2025-11-05",
                    highlights: &[
                        "Complete UI overhaul with native high-DPI scaling",
                        "Multi-layer editing support",
                    ],
                },
            ],
            versions: &["v2.4.1 (Latest)", "v2.3.0", "v2.0.0"],
        },
        "geo-background-generator" => CatalogMetadata {
            description: "Geometric pattern background generator with customizable gradients",
            version: "1.8.2",
            latest_version: "2.0.0",
            downloading: false,
            latest_release: ReleaseNoteData {
                version: "2.0.0",
                date: "2026-10-18",
                highlights: &[
                    "Major upgrade: brand-new procedural Delaunay triangulation engine",
                    "Added multi-stop gradient editor with real-time lighting simulation",
                    "Direct 4K, 5K, and ultrawide wallpaper export presets",
                ],
            },
            older_releases: &[
                ReleaseNoteData {
                    version: "1.8.2",
                    date: "2026-06-11",
                    highlights: &[
                        "Fixed color palette persistence when relaunching",
                        "Added one-click hex color code clipboard copying",
                    ],
                },
                ReleaseNoteData {
                    version: "1.8.0",
                    date: "2026-02-04",
                    highlights: &[
                        "Added 24 curated pastel and cyber-neon preset themes",
                        "Sub-pixel smoothing for high-refresh-rate displays",
                    ],
                },
            ],
            versions: &["v2.0.0 (Latest)", "v1.8.2 (Installed)", "v1.8.0", "v1.0.0"],
        },
        "stellenwerttafel-plus" => CatalogMetadata {
            description: "Interactive place value chart for binary, decimal, and hex",
            version: "1.3.0",
            latest_version: "1.3.0",
            downloading: false,
            latest_release: ReleaseNoteData {
                version: "1.3.0",
                date: "2026-07-29",
                highlights: &[
                    "Added hexadecimal numeral system support with interactive bundles",
                    "Keyboard shortcuts for rapid number entry and grouping",
                    "German and English curriculum-aligned exercises",
                ],
            },
            older_releases: &[ReleaseNoteData {
                version: "1.2.0",
                date: "2026-01-15",
                highlights: &[
                    "Binary bit-toggle mode with powers-of-two visualizer",
                    "Export exercise sheets as print-ready PDFs",
                ],
            }],
            versions: &["v1.3.0 (Latest)", "v1.2.0", "v1.0.0"],
        },
        "unofficial-super-mario-bros-misfit-pack" => CatalogMetadata {
            description: "Classic platformer collection with visual enhancements and widescreen",
            version: "0.9.0",
            latest_version: "0.9.0",
            downloading: false,
            latest_release: ReleaseNoteData {
                version: "0.9.0",
                date: "2026-09-02",
                highlights: &[
                    "Native 16:9 widescreen rendering with extended camera scroll",
                    "Remastered 8-bit sound effects and optional stereo music",
                    "Custom level selector and checkpoint system",
                ],
            },
            older_releases: &[ReleaseNoteData {
                version: "0.8.2",
                date: "2026-04-19",
                highlights: &[
                    "Fixed jump momentum collision glitch on moving platforms",
                    "Game controller rumble feedback support",
                ],
            }],
            versions: &["v0.9.0 (Latest)", "v0.8.2"],
        },
        "oss-space-adventure" => CatalogMetadata {
            description: "Retro arcade space shooter — protect your planet from asteroids",
            version: "1.2.4",
            latest_version: "1.2.4",
            // Demonstrates the requested filling wheel download indicator in action.
            downloading: true,
            latest_release: ReleaseNoteData {
                version: "1.2.4",
                date: "2026-09-30",
                highlights: &[
                    "Added three new boss battle phases and deep-space nebula arenas",
                    "Gamepad and joystick deadzone configuration",
                    "Global and local high-score leaderboards",
                ],
            },
            older_releases: &[ReleaseNoteData {
                version: "1.1.0",
                date: "2026-03-08",
                highlights: &[
                    "Weapon upgrade tree: laser spread, plasma burst, and homing missiles",
                    "Particle effects engine optimization",
                ],
            }],
            versions: &["v1.2.4 (Latest)", "v1.1.0", "v1.0.0"],
        },
        "benplaysgames-soundboard" => CatalogMetadata {
            description: "Soundboard app for YouTuber and Twitch streamer BenPlaysGames",
            version: "1.1.0",
            latest_version: "1.1.0",
            downloading: false,
            latest_release: ReleaseNoteData {
                version: "1.1.0",
                date: "2026-08-20",
                highlights: &[
                    "Added 28 new catchphrases and sound bites from recent livestreams",
                    "Global hotkey support to trigger sounds during gaming",
                    "Favorites bar with instant reordering",
                ],
            },
            older_releases: &[ReleaseNoteData {
                version: "1.0.0",
                date: "2025-12-10",
                highlights: &[
                    "Initial community soundboard release with 40 classic clips",
                    "Volume normalization across all recordings",
                ],
            }],
            versions: &["v1.1.0 (Latest)", "v1.0.0"],
        },
        "unofficial-sonic-mania-mobile-prototype" => CatalogMetadata {
            description: "Fan port prototype built with GameMaker: Studio and Sonic MAX",
            version: "0.4.2",
            latest_version: "0.4.2",
            downloading: false,
            latest_release: ReleaseNoteData {
                version: "0.4.2",
                date: "2026-05-18",
                highlights: &[
                    "Refined 360-degree loop physics and slope acceleration",
                    "On-screen virtual D-pad and Bluetooth controller mapping",
                    "Studiopolis Zone Act 1 performance improvements",
                ],
            },
            older_releases: &[ReleaseNoteData {
                version: "0.3.0",
                date: "2025-10-12",
                highlights: &[
                    "Initial public tech prototype with Green Hill Zone Act 1",
                    "Drop dash move support",
                ],
            }],
            versions: &["v0.4.2 (Latest)", "v0.3.0"],
        },
        "project-tortuga" => CatalogMetadata {
            description: "Custom Call of Duty: Black Ops 3 Zombies map and GSC/CSC scripts",
            version: "1.0.0",
            latest_version: "1.0.0",
            downloading: false,
            latest_release: ReleaseNoteData {
                version: "1.0.0",
                date: "2026-07-04",
                highlights: &[
                    "Full release of the pirate island Zombies survival experience",
                    "Custom cursed treasure Easter egg quest with cutscene",
                    "Four unique wonder weapons and custom perk-a-cola machines",
                ],
            },
            older_releases: &[],
            versions: &["v1.0.0 (Latest)"],
        },
        "germemz" => CatalogMetadata {
            description: "German TV commercial meme soundboard with 45 iconic quotes",
            version: "1.0.3",
            latest_version: "1.0.3",
            downloading: false,
            latest_release: ReleaseNoteData {
                version: "1.0.3",
                date: "2026-06-25",
                highlights: &[
                    "Added 12 iconic retro commercials from 90s and 2000s television",
                    "Search and tag filtering by decade and product category",
                    "Loop playback mode and sound pitching",
                ],
            },
            older_releases: &[ReleaseNoteData {
                version: "1.0.0",
                date: "2026-01-20",
                highlights: &["Initial release with 33 cult classic quotes"],
            }],
            versions: &["v1.0.3 (Latest)", "v1.0.0"],
        },
        _ => CatalogMetadata {
            description: "Dynamotivation software package managed on this device",
            version: "1.0.0",
            latest_version: "1.1.0",
            downloading: false,
            latest_release: ReleaseNoteData {
                version: "1.1.0",
                date: "2026-01-01",
                highlights: &["Performance and stability improvements"],
            },
            older_releases: &[],
            versions: &["v1.1.0 (Latest)", "v1.0.0"],
        },
    }
}

fn to_string_model(items: &[&str]) -> ModelRc<SharedString> {
    let strings: Vec<SharedString> = items.iter().map(|&s| SharedString::from(s)).collect();
    ModelRc::from(Rc::new(VecModel::from(strings)))
}

fn to_release_note(data: &ReleaseNoteData) -> ReleaseNote {
    ReleaseNote {
        version: data.version.into(),
        date: data.date.into(),
        highlights: to_string_model(data.highlights),
    }
}

pub fn row_from(view: &PackageView) -> PackageRow {
    let meta = catalog_metadata(&view.id);
    let older_notes: Vec<ReleaseNote> = meta.older_releases.iter().map(to_release_note).collect();
    PackageRow {
        id: view.id.as_str().into(),
        name: view.name.as_str().into(),
        description: meta.description.into(),
        version: meta.version.into(),
        latest_version: meta.latest_version.into(),
        status: status_from(view.status),
        downloading: meta.downloading,
        latest_release: to_release_note(&meta.latest_release),
        older_releases: ModelRc::from(Rc::new(VecModel::from(older_notes))),
        versions: to_string_model(meta.versions),
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
        assert!(!row.downloading);
        assert_eq!(row.latest_release.version, "2.0.0");
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
