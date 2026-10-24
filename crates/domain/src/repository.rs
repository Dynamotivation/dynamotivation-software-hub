use std::fmt;

use crate::package::{PackageId, SoftwarePackage};

/// Outbound port: persistence of [`SoftwarePackage`] aggregates.
pub trait SoftwarePackageRepository: Send + Sync {
    fn find_by_id(&self, id: &PackageId) -> Result<Option<SoftwarePackage>, RepositoryError>;
    fn find_all(&self) -> Result<Vec<SoftwarePackage>, RepositoryError>;
    fn save(&self, package: &SoftwarePackage) -> Result<(), RepositoryError>;
}

/// Technical failure of a repository adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RepositoryError(String);

impl RepositoryError {
    pub fn new(message: impl Into<String>) -> Self {
        Self(message.into())
    }
}

impl fmt::Display for RepositoryError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Repository error: {}", self.0)
    }
}

impl std::error::Error for RepositoryError {}
