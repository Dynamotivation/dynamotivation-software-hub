use std::fmt;

use hub_domain::{DomainError, RepositoryError};

use crate::ports::PreferencesError;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ApplicationError {
    Domain(DomainError),
    AlreadyRegistered { id: String },
    NotFound { id: String },
    Repository(RepositoryError),
    Preferences(PreferencesError),
}

impl fmt::Display for ApplicationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Domain(e) => e.fmt(f),
            Self::AlreadyRegistered { id } => {
                write!(f, "A package with id '{id}' is already registered")
            }
            Self::NotFound { id } => write!(f, "No package with id '{id}' exists"),
            Self::Repository(e) => e.fmt(f),
            Self::Preferences(e) => e.fmt(f),
        }
    }
}

impl std::error::Error for ApplicationError {}

impl From<DomainError> for ApplicationError {
    fn from(e: DomainError) -> Self {
        Self::Domain(e)
    }
}

impl From<RepositoryError> for ApplicationError {
    fn from(e: RepositoryError) -> Self {
        Self::Repository(e)
    }
}

impl From<PreferencesError> for ApplicationError {
    fn from(e: PreferencesError) -> Self {
        Self::Preferences(e)
    }
}
