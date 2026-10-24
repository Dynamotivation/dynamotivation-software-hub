use hub_domain::{InstallationStatus, SoftwarePackage};

/// Read model of a package for presentation adapters.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PackageView {
    pub id: String,
    pub name: String,
    pub status: PackageStatusView,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PackageStatusView {
    NotInstalled,
    Installed,
    UpdateAvailable,
}

impl From<&SoftwarePackage> for PackageView {
    fn from(p: &SoftwarePackage) -> Self {
        Self {
            id: p.id().as_str().to_owned(),
            name: p.name().as_str().to_owned(),
            status: p.status().into(),
        }
    }
}

impl From<InstallationStatus> for PackageStatusView {
    fn from(s: InstallationStatus) -> Self {
        match s {
            InstallationStatus::NotInstalled => Self::NotInstalled,
            InstallationStatus::Installed => Self::Installed,
            InstallationStatus::UpdateAvailable => Self::UpdateAvailable,
        }
    }
}
