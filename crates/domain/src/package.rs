use std::fmt;

use crate::error::DomainError;
use crate::events::PackageEvent;

/// Stable identifier of a software package, e.g. `jumpmaster-engine-core`.
///
/// Lowercase letters/digits separated by single `-`. Derived deterministically
/// from the package name, so registering the same name twice is detectable and
/// no clock or random source is needed (keeps the domain pure and portable).
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct PackageId(String);

impl PackageId {
    /// Parses an id coming from outside (storage, manifests, discovery).
    pub fn parse(raw: &str) -> Result<Self, DomainError> {
        let slug = slugify(raw);
        if slug.is_empty() || slug != raw {
            return Err(DomainError::InvalidPackageId);
        }
        Ok(Self(slug))
    }

    /// Derives the id from a validated name.
    pub fn from_name(name: &PackageName) -> Result<Self, DomainError> {
        let slug = slugify(name.as_str());
        if slug.is_empty() {
            return Err(DomainError::InvalidPackageId);
        }
        Ok(Self(slug))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for PackageId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

fn slugify(raw: &str) -> String {
    let mut slug = String::with_capacity(raw.len());
    let mut pending_dash = false;
    for c in raw.chars() {
        if c.is_alphanumeric() {
            if pending_dash && !slug.is_empty() {
                slug.push('-');
            }
            pending_dash = false;
            slug.extend(c.to_lowercase());
        } else {
            pending_dash = true;
        }
    }
    slug
}

/// Human-readable package name (trimmed, 2..=64 characters).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PackageName(String);

impl PackageName {
    pub const MIN_LEN: usize = 2;
    pub const MAX_LEN: usize = 64;

    pub fn parse(raw: &str) -> Result<Self, DomainError> {
        let trimmed = raw.trim();
        let len = trimmed.chars().count();
        if !(Self::MIN_LEN..=Self::MAX_LEN).contains(&len) {
            return Err(DomainError::InvalidPackageName {
                min: Self::MIN_LEN,
                max: Self::MAX_LEN,
            });
        }
        Ok(Self(trimmed.to_owned()))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for PackageName {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

/// Installation state of a package on this device.
///
/// ```text
/// NotInstalled --install--> Installed --flag_update_available--> UpdateAvailable
///      ^                       |  ^                                   |
///      +-------uninstall-------+  +--------------update---------------+
///      +------------------------uninstall-----------------------------+
/// ```
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InstallationStatus {
    NotInstalled,
    Installed,
    UpdateAvailable,
}

impl fmt::Display for InstallationStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(match self {
            Self::NotInstalled => "not installed",
            Self::Installed => "installed",
            Self::UpdateAvailable => "update available",
        })
    }
}

/// Aggregate root: a software package by the hub's author.
///
/// All state changes go through intention-revealing commands that enforce the
/// lifecycle in [`InstallationStatus`] and record [`PackageEvent`]s.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SoftwarePackage {
    id: PackageId,
    name: PackageName,
    status: InstallationStatus,
    pending_events: Vec<PackageEvent>,
}

impl SoftwarePackage {
    /// Registers a new, not yet installed package.
    pub fn register(name: PackageName) -> Result<Self, DomainError> {
        let id = PackageId::from_name(&name)?;
        let event = PackageEvent::Registered {
            id: id.clone(),
            name: name.as_str().to_owned(),
        };
        Ok(Self {
            id,
            name,
            status: InstallationStatus::NotInstalled,
            pending_events: vec![event],
        })
    }

    /// Rehydrates a persisted package. Records no events.
    pub fn restore(id: PackageId, name: PackageName, status: InstallationStatus) -> Self {
        Self {
            id,
            name,
            status,
            pending_events: Vec::new(),
        }
    }

    pub fn id(&self) -> &PackageId {
        &self.id
    }

    pub fn name(&self) -> &PackageName {
        &self.name
    }

    pub fn status(&self) -> InstallationStatus {
        self.status
    }

    pub fn install(&mut self) -> Result<(), DomainError> {
        self.transition("install", &[InstallationStatus::NotInstalled])?;
        self.status = InstallationStatus::Installed;
        self.record(PackageEvent::Installed {
            id: self.id.clone(),
        });
        Ok(())
    }

    pub fn flag_update_available(&mut self) -> Result<(), DomainError> {
        self.transition("flag an update for", &[InstallationStatus::Installed])?;
        self.status = InstallationStatus::UpdateAvailable;
        self.record(PackageEvent::UpdateBecameAvailable {
            id: self.id.clone(),
        });
        Ok(())
    }

    pub fn update(&mut self) -> Result<(), DomainError> {
        self.transition("update", &[InstallationStatus::UpdateAvailable])?;
        self.status = InstallationStatus::Installed;
        self.record(PackageEvent::Updated {
            id: self.id.clone(),
        });
        Ok(())
    }

    pub fn uninstall(&mut self) -> Result<(), DomainError> {
        self.transition(
            "uninstall",
            &[
                InstallationStatus::Installed,
                InstallationStatus::UpdateAvailable,
            ],
        )?;
        self.status = InstallationStatus::NotInstalled;
        self.record(PackageEvent::Uninstalled {
            id: self.id.clone(),
        });
        Ok(())
    }

    /// Drains the events recorded since the last call.
    pub fn take_events(&mut self) -> Vec<PackageEvent> {
        std::mem::take(&mut self.pending_events)
    }

    fn transition(
        &self,
        action: &'static str,
        allowed_from: &[InstallationStatus],
    ) -> Result<(), DomainError> {
        if allowed_from.contains(&self.status) {
            Ok(())
        } else {
            Err(DomainError::InvalidTransition {
                from: self.status,
                action,
            })
        }
    }

    fn record(&mut self, event: PackageEvent) {
        self.pending_events.push(event);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn package(name: &str) -> SoftwarePackage {
        SoftwarePackage::register(PackageName::parse(name).unwrap()).unwrap()
    }

    #[test]
    fn name_is_trimmed_and_length_checked() {
        assert_eq!(PackageName::parse("  Hub  ").unwrap().as_str(), "Hub");
        assert!(PackageName::parse(" a ").is_err());
        assert!(PackageName::parse(&"x".repeat(65)).is_err());
        assert!(PackageName::parse(&"é".repeat(64)).is_ok());
    }

    #[test]
    fn id_is_derived_deterministically_from_name() {
        let a = package("Jumpmaster Engine Core");
        let b = package("  jumpmaster   engine-core!! ");
        assert_eq!(a.id().as_str(), "jumpmaster-engine-core");
        assert_eq!(a.id(), b.id());
    }

    #[test]
    fn id_requires_alphanumerics() {
        let name = PackageName::parse("--").unwrap();
        assert_eq!(
            PackageId::from_name(&name),
            Err(DomainError::InvalidPackageId)
        );
        assert!(PackageId::parse("Not A Slug").is_err());
        assert!(PackageId::parse("valid-slug-2").is_ok());
    }

    #[test]
    fn registration_starts_not_installed_and_records_event() {
        let mut p = package("Asset Pipeline");
        assert_eq!(p.status(), InstallationStatus::NotInstalled);
        assert_eq!(
            p.take_events(),
            vec![PackageEvent::Registered {
                id: p.id().clone(),
                name: "Asset Pipeline".into()
            }]
        );
        assert_eq!(p.take_events(), []);
    }

    #[test]
    fn full_lifecycle() {
        let mut p = package("Asset Pipeline");
        p.install().unwrap();
        p.flag_update_available().unwrap();
        p.update().unwrap();
        p.flag_update_available().unwrap();
        p.uninstall().unwrap();
        assert_eq!(p.status(), InstallationStatus::NotInstalled);
        assert_eq!(p.take_events().len(), 6);
    }

    #[test]
    fn invalid_transitions_are_rejected_without_side_effects() {
        let mut p = package("Asset Pipeline");
        p.take_events();
        assert!(p.update().is_err());
        assert!(p.uninstall().is_err());
        assert!(p.flag_update_available().is_err());
        p.install().unwrap();
        assert_eq!(
            p.install(),
            Err(DomainError::InvalidTransition {
                from: InstallationStatus::Installed,
                action: "install"
            })
        );
        assert_eq!(p.status(), InstallationStatus::Installed);
        assert_eq!(p.take_events().len(), 1);
    }

    #[test]
    fn restore_records_no_events() {
        let mut p = SoftwarePackage::restore(
            PackageId::parse("hub").unwrap(),
            PackageName::parse("Hub").unwrap(),
            InstallationStatus::Installed,
        );
        assert_eq!(p.take_events(), []);
    }
}
