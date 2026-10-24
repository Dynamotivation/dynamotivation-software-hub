use crate::package::PackageId;

/// Facts that happened to a [`SoftwarePackage`](crate::SoftwarePackage).
///
/// Recorded by the aggregate and drained by the application layer after a
/// successful save via [`SoftwarePackage::take_events`](crate::SoftwarePackage::take_events).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PackageEvent {
    Registered { id: PackageId, name: String },
    Installed { id: PackageId },
    UpdateBecameAvailable { id: PackageId },
    Updated { id: PackageId },
    Uninstalled { id: PackageId },
}
