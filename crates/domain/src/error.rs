use std::fmt;

use crate::package::InstallationStatus;

/// Violations of domain invariants or lifecycle rules.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DomainError {
    /// Package names must have between [`PackageName::MIN_LEN`] and [`PackageName::MAX_LEN`] characters.
    ///
    /// [`PackageName::MIN_LEN`]: crate::PackageName::MIN_LEN
    /// [`PackageName::MAX_LEN`]: crate::PackageName::MAX_LEN
    InvalidPackageName { min: usize, max: usize },
    /// The name contains no letters or digits, so no stable id can be derived.
    InvalidPackageId,
    /// The requested lifecycle transition is not allowed from the current status.
    InvalidTransition {
        from: InstallationStatus,
        action: &'static str,
    },
}

impl fmt::Display for DomainError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidPackageName { min, max } => {
                write!(
                    f,
                    "Package name must be between {min} and {max} characters long"
                )
            }
            Self::InvalidPackageId => {
                write!(f, "Package id must contain at least one letter or digit")
            }
            Self::InvalidTransition { from, action } => {
                write!(f, "Cannot {action} a package that is {from}")
            }
        }
    }
}

impl std::error::Error for DomainError {}
