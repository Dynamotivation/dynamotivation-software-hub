//! Domain model of the Dynamotivation Software Hub.
//!
//! The hub is a launcher/toolbox for software packages published by the same
//! author and installed on the user's device. This crate is pure: no I/O, no
//! clock, no UI, no external crates.

pub mod error;
pub mod events;
pub mod package;
pub mod repository;

pub use error::DomainError;
pub use events::PackageEvent;
pub use package::{InstallationStatus, PackageId, PackageName, SoftwarePackage};
pub use repository::{RepositoryError, SoftwarePackageRepository};
