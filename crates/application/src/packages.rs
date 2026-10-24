use std::sync::Arc;

use hub_domain::{PackageId, PackageName, SoftwarePackage, SoftwarePackageRepository};

use crate::dto::PackageView;
use crate::error::ApplicationError;
use crate::ports::EventPublisher;

/// Persists the aggregate, then publishes the events it recorded.
///
/// Events are drained *before* saving so they are never persisted with the
/// aggregate (and therefore never re-published after a reload).
fn save_and_publish(
    repo: &dyn SoftwarePackageRepository,
    events: &dyn EventPublisher,
    package: &mut SoftwarePackage,
) -> Result<(), ApplicationError> {
    let pending = package.take_events();
    repo.save(package)?;
    events.publish(&pending);
    Ok(())
}

/// Registers a new software package in the hub.
#[derive(Clone)]
pub struct RegisterPackage {
    repo: Arc<dyn SoftwarePackageRepository>,
    events: Arc<dyn EventPublisher>,
}

impl RegisterPackage {
    pub fn new(repo: Arc<dyn SoftwarePackageRepository>, events: Arc<dyn EventPublisher>) -> Self {
        Self { repo, events }
    }

    pub fn execute(&self, name: &str) -> Result<PackageView, ApplicationError> {
        let mut package = SoftwarePackage::register(PackageName::parse(name)?)?;
        if self.repo.find_by_id(package.id())?.is_some() {
            return Err(ApplicationError::AlreadyRegistered {
                id: package.id().to_string(),
            });
        }
        save_and_publish(self.repo.as_ref(), self.events.as_ref(), &mut package)?;
        Ok(PackageView::from(&package))
    }
}

/// Lists all packages, sorted by name (case-insensitive) for a stable UI.
#[derive(Clone)]
pub struct ListPackages {
    repo: Arc<dyn SoftwarePackageRepository>,
}

impl ListPackages {
    pub fn new(repo: Arc<dyn SoftwarePackageRepository>) -> Self {
        Self { repo }
    }

    pub fn execute(&self) -> Result<Vec<PackageView>, ApplicationError> {
        let mut views: Vec<PackageView> = self
            .repo
            .find_all()?
            .iter()
            .map(PackageView::from)
            .collect();
        views.sort_by_cached_key(|v| (v.name.to_lowercase(), v.id.clone()));
        Ok(views)
    }
}

/// Installation facts reported by an installer/discovery adapter.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InstallationChange {
    Installed,
    UpdateAvailable,
    Updated,
    Uninstalled,
}

/// Applies an installation change to a package, enforcing the domain lifecycle.
#[derive(Clone)]
pub struct RecordInstallationChange {
    repo: Arc<dyn SoftwarePackageRepository>,
    events: Arc<dyn EventPublisher>,
}

impl RecordInstallationChange {
    pub fn new(repo: Arc<dyn SoftwarePackageRepository>, events: Arc<dyn EventPublisher>) -> Self {
        Self { repo, events }
    }

    pub fn execute(
        &self,
        id: &str,
        change: InstallationChange,
    ) -> Result<PackageView, ApplicationError> {
        let id = PackageId::parse(id)?;
        let mut package = self
            .repo
            .find_by_id(&id)?
            .ok_or_else(|| ApplicationError::NotFound { id: id.to_string() })?;
        match change {
            InstallationChange::Installed => package.install(),
            InstallationChange::UpdateAvailable => package.flag_update_available(),
            InstallationChange::Updated => package.update(),
            InstallationChange::Uninstalled => package.uninstall(),
        }?;
        save_and_publish(self.repo.as_ref(), self.events.as_ref(), &mut package)?;
        Ok(PackageView::from(&package))
    }
}

macro_rules! opaque_debug {
    ($($t:ty),*) => {$(
        impl std::fmt::Debug for $t {
            fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                f.debug_struct(stringify!($t)).finish_non_exhaustive()
            }
        }
    )*};
}
opaque_debug!(RegisterPackage, ListPackages, RecordInstallationChange);

#[cfg(test)]
mod tests {
    use super::*;
    use crate::PackageStatusView;
    use crate::test_support::{FailingRepo, MemoryRepo, RecordingPublisher};
    use hub_domain::{DomainError, PackageEvent};

    fn setup() -> (Arc<MemoryRepo>, Arc<RecordingPublisher>) {
        (
            Arc::new(MemoryRepo::default()),
            Arc::new(RecordingPublisher::default()),
        )
    }

    #[test]
    fn registers_and_publishes_event() {
        let (repo, events) = setup();
        let view = RegisterPackage::new(repo.clone(), events.clone())
            .execute("Asset Pipeline")
            .unwrap();
        assert_eq!(view.id, "asset-pipeline");
        assert_eq!(view.status, PackageStatusView::NotInstalled);
        assert!(matches!(
            events.taken()[..],
            [PackageEvent::Registered { .. }]
        ));
    }

    #[test]
    fn rejects_duplicates_instead_of_overwriting() {
        let (repo, events) = setup();
        let register = RegisterPackage::new(repo.clone(), events);
        register.execute("Asset Pipeline").unwrap();
        assert_eq!(
            register.execute("asset   pipeline"),
            Err(ApplicationError::AlreadyRegistered {
                id: "asset-pipeline".into()
            })
        );
        assert_eq!(ListPackages::new(repo).execute().unwrap().len(), 1);
    }

    #[test]
    fn surfaces_domain_validation() {
        let (repo, events) = setup();
        assert!(matches!(
            RegisterPackage::new(repo, events).execute("a"),
            Err(ApplicationError::Domain(
                DomainError::InvalidPackageName { .. }
            ))
        ));
    }

    #[test]
    fn lists_sorted_by_name() {
        let (repo, events) = setup();
        let register = RegisterPackage::new(repo.clone(), events);
        for n in ["zeta", "Alpha", "beta"] {
            register.execute(n).unwrap();
        }
        let names: Vec<_> = ListPackages::new(repo)
            .execute()
            .unwrap()
            .into_iter()
            .map(|v| v.name)
            .collect();
        assert_eq!(names, ["Alpha", "beta", "zeta"]);
    }

    #[test]
    fn records_installation_changes_and_enforces_lifecycle() {
        let (repo, events) = setup();
        RegisterPackage::new(repo.clone(), events.clone())
            .execute("Hub Tool")
            .unwrap();
        let record = RecordInstallationChange::new(repo.clone(), events.clone());
        let view = record
            .execute("hub-tool", InstallationChange::Installed)
            .unwrap();
        assert_eq!(view.status, PackageStatusView::Installed);
        assert!(matches!(
            record.execute("hub-tool", InstallationChange::Installed),
            Err(ApplicationError::Domain(
                DomainError::InvalidTransition { .. }
            ))
        ));
        assert!(matches!(
            record.execute("missing", InstallationChange::Installed),
            Err(ApplicationError::NotFound { .. })
        ));
        // Registered + Installed, no duplicates from reloads.
        assert_eq!(events.taken().len(), 2);
    }

    #[test]
    fn repository_failures_are_reported_and_nothing_is_published() {
        let events = Arc::new(RecordingPublisher::default());
        let result =
            RegisterPackage::new(Arc::new(FailingRepo), events.clone()).execute("Hub Tool");
        assert!(matches!(result, Err(ApplicationError::Repository(_))));
        assert_eq!(events.taken(), []);
    }
}
