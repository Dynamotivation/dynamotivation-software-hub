//! Enforces the layered / hexagonal dependency rules between workspace crates.
//!
//! ```text
//! desktop app ──► hub-ui ──► hub-application ──► hub-domain
//!      │                          ▲                 ▲
//!      └──► hub-infrastructure ───┴─────────────────┘
//! ```
//!
//! Every workspace member must have a rule; adding a crate without one fails.

use cargo_metadata::{DependencyKind, MetadataCommand};

use crate::Result;

enum External {
    /// No third-party crates at all (pure layers).
    None,
    /// Any third-party crate except the listed ones.
    AnyExcept(&'static [&'static str]),
}

struct Rule {
    krate: &'static str,
    internal: &'static [&'static str],
    external: External,
}

const UI_CRATES: &[&str] = &["slint", "slint-build"];

const RULES: &[Rule] = &[
    Rule {
        krate: "hub-domain",
        internal: &[],
        external: External::None,
    },
    Rule {
        krate: "hub-application",
        internal: &["hub-domain"],
        external: External::None,
    },
    Rule {
        krate: "hub-infrastructure",
        internal: &["hub-domain", "hub-application"],
        external: External::AnyExcept(UI_CRATES),
    },
    Rule {
        krate: "hub-ui",
        internal: &["hub-application"],
        external: External::AnyExcept(&[]),
    },
    Rule {
        krate: "dynamotivation-software-hub",
        internal: &["hub-application", "hub-infrastructure", "hub-ui"],
        external: External::AnyExcept(&[]),
    },
    Rule {
        krate: "xtask",
        internal: &[],
        external: External::AnyExcept(UI_CRATES),
    },
];

/// (crate name, [(dependency name, is workspace member)])
type Graph = Vec<(String, Vec<(String, bool)>)>;

pub fn check() -> Result {
    let violations = violations(&workspace_graph()?);
    if violations.is_empty() {
        eprintln!("architecture: OK");
        Ok(())
    } else {
        for v in &violations {
            eprintln!("architecture violation: {v}");
        }
        Err(format!("{} architecture violation(s)", violations.len()))
    }
}

fn workspace_graph() -> Result<Graph> {
    let metadata = MetadataCommand::new()
        .manifest_path(crate::workspace_root().join("Cargo.toml"))
        .no_deps()
        .exec()
        .map_err(|e| format!("cargo metadata failed: {e}"))?;
    let members: Vec<&str> = metadata
        .workspace_packages()
        .iter()
        .map(|p| p.name.as_str())
        .collect();
    Ok(metadata
        .workspace_packages()
        .iter()
        .map(|p| {
            let deps = p
                .dependencies
                .iter()
                // Dev-dependencies (test doubles etc.) are exempt.
                .filter(|d| d.kind != DependencyKind::Development)
                .map(|d| (d.name.clone(), members.contains(&d.name.as_str())))
                .collect();
            (p.name.to_string(), deps)
        })
        .collect())
}

fn violations(graph: &Graph) -> Vec<String> {
    let mut out = Vec::new();
    for (krate, deps) in graph {
        let Some(rule) = RULES.iter().find(|r| r.krate == krate) else {
            out.push(format!("crate `{krate}` has no rule in xtask/src/arch.rs"));
            continue;
        };
        for (dep, internal) in deps {
            let allowed = if *internal {
                rule.internal.contains(&dep.as_str())
            } else {
                match rule.external {
                    External::None => false,
                    External::AnyExcept(banned) => !banned.contains(&dep.as_str()),
                }
            };
            if !allowed {
                out.push(format!("`{krate}` must not depend on `{dep}`"));
            }
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn graph(entries: &[(&str, &[(&str, bool)])]) -> Graph {
        entries
            .iter()
            .map(|(k, deps)| {
                (
                    (*k).to_string(),
                    deps.iter().map(|(d, i)| ((*d).to_string(), *i)).collect(),
                )
            })
            .collect()
    }

    #[test]
    fn current_workspace_respects_architecture() {
        let g = workspace_graph().expect("cargo metadata");
        assert_eq!(violations(&g), Vec::<String>::new());
    }

    #[test]
    fn detects_forbidden_edges() {
        let g = graph(&[
            ("hub-domain", &[("serde", false)]),
            ("hub-application", &[("hub-infrastructure", true)]),
            ("hub-ui", &[("hub-domain", true)]),
            ("hub-infrastructure", &[("slint", false)]),
            ("new-crate", &[]),
        ]);
        assert_eq!(violations(&g).len(), 5);
    }
}
