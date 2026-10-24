//! Test doubles for the outbound ports.
#![allow(clippy::unwrap_used)]

use std::collections::BTreeMap;
use std::sync::Mutex;

use hub_domain::{
    PackageEvent, PackageId, RepositoryError, SoftwarePackage, SoftwarePackageRepository,
};

use crate::ports::{EventPublisher, PreferencesError, PreferencesStore};
use crate::preferences::Preferences;

#[derive(Debug, Default)]
pub struct MemoryRepo(Mutex<BTreeMap<PackageId, SoftwarePackage>>);

impl SoftwarePackageRepository for MemoryRepo {
    fn find_by_id(&self, id: &PackageId) -> Result<Option<SoftwarePackage>, RepositoryError> {
        Ok(self.0.lock().unwrap().get(id).cloned())
    }
    fn find_all(&self) -> Result<Vec<SoftwarePackage>, RepositoryError> {
        Ok(self.0.lock().unwrap().values().cloned().collect())
    }
    fn save(&self, package: &SoftwarePackage) -> Result<(), RepositoryError> {
        self.0
            .lock()
            .unwrap()
            .insert(package.id().clone(), package.clone());
        Ok(())
    }
}

#[derive(Debug)]
pub struct FailingRepo;

impl SoftwarePackageRepository for FailingRepo {
    fn find_by_id(&self, _: &PackageId) -> Result<Option<SoftwarePackage>, RepositoryError> {
        Ok(None)
    }
    fn find_all(&self) -> Result<Vec<SoftwarePackage>, RepositoryError> {
        Err(RepositoryError::new("boom"))
    }
    fn save(&self, _: &SoftwarePackage) -> Result<(), RepositoryError> {
        Err(RepositoryError::new("boom"))
    }
}

#[derive(Debug, Default)]
pub struct RecordingPublisher(Mutex<Vec<PackageEvent>>);

impl RecordingPublisher {
    pub fn taken(&self) -> Vec<PackageEvent> {
        std::mem::take(&mut *self.0.lock().unwrap())
    }
}

impl EventPublisher for RecordingPublisher {
    fn publish(&self, events: &[PackageEvent]) {
        self.0.lock().unwrap().extend_from_slice(events);
    }
}

#[derive(Debug, Default)]
pub struct MemoryPreferences(Mutex<Preferences>);

impl PreferencesStore for MemoryPreferences {
    fn load(&self) -> Result<Preferences, PreferencesError> {
        Ok(*self.0.lock().unwrap())
    }
    fn save(&self, preferences: &Preferences) -> Result<(), PreferencesError> {
        *self.0.lock().unwrap() = *preferences;
        Ok(())
    }
}
