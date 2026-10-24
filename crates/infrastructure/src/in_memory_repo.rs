use std::collections::BTreeMap;
use std::sync::{RwLock, RwLockReadGuard, RwLockWriteGuard};

use hub_domain::{PackageId, RepositoryError, SoftwarePackage, SoftwarePackageRepository};

/// In-memory adapter for the [`SoftwarePackageRepository`] port.
///
/// Packages are discovered at runtime, so they are intentionally not persisted.
#[derive(Debug, Default)]
pub struct InMemorySoftwarePackageRepository {
    storage: RwLock<BTreeMap<PackageId, SoftwarePackage>>,
}

impl InMemorySoftwarePackageRepository {
    pub fn new() -> Self {
        Self::default()
    }

    fn read(
        &self,
    ) -> Result<RwLockReadGuard<'_, BTreeMap<PackageId, SoftwarePackage>>, RepositoryError> {
        self.storage
            .read()
            .map_err(|_| RepositoryError::new("storage lock poisoned"))
    }

    fn write(
        &self,
    ) -> Result<RwLockWriteGuard<'_, BTreeMap<PackageId, SoftwarePackage>>, RepositoryError> {
        self.storage
            .write()
            .map_err(|_| RepositoryError::new("storage lock poisoned"))
    }
}

impl SoftwarePackageRepository for InMemorySoftwarePackageRepository {
    fn find_by_id(&self, id: &PackageId) -> Result<Option<SoftwarePackage>, RepositoryError> {
        Ok(self.read()?.get(id).cloned())
    }

    fn find_all(&self) -> Result<Vec<SoftwarePackage>, RepositoryError> {
        Ok(self.read()?.values().cloned().collect())
    }

    fn save(&self, package: &SoftwarePackage) -> Result<(), RepositoryError> {
        self.write()?.insert(package.id().clone(), package.clone());
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    #![allow(clippy::unwrap_used)]
    use super::*;
    use hub_domain::PackageName;

    #[test]
    fn saves_and_finds() {
        let repo = InMemorySoftwarePackageRepository::new();
        let p = SoftwarePackage::register(PackageName::parse("Hub Tool").unwrap()).unwrap();
        repo.save(&p).unwrap();
        assert_eq!(repo.find_by_id(p.id()).unwrap().unwrap().name(), p.name());
        assert_eq!(repo.find_all().unwrap().len(), 1);
    }
}
