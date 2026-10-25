use std::fs::OpenOptions;
use std::io::Write;
use std::path::{Path, PathBuf};

use hub_application::EventPublisher;
use hub_domain::PackageEvent;

/// Writes published domain events to stderr (visible in debug/console runs).
#[derive(Debug, Default)]
pub struct StderrEventPublisher;

impl EventPublisher for StderrEventPublisher {
    fn publish(&self, events: &[PackageEvent]) {
        for event in events {
            eprintln!("[event] {event:?}");
        }
    }
}

/// Writes published domain events to a persistent log file.
#[derive(Debug, Clone)]
pub struct FileEventPublisher {
    path: PathBuf,
}

impl FileEventPublisher {
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self { path: path.into() }
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    /// Logs an arbitrary message line to the file (e.g. startup / diagnostics).
    pub fn log(&self, message: &str) {
        if let Some(parent) = self.path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        if let Ok(mut file) = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.path)
        {
            let _ = writeln!(file, "{message}");
        }
    }
}

impl EventPublisher for FileEventPublisher {
    fn publish(&self, events: &[PackageEvent]) {
        if events.is_empty() {
            return;
        }
        if let Some(parent) = self.path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        if let Ok(mut file) = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.path)
        {
            for event in events {
                let _ = writeln!(file, "[event] {event:?}");
            }
        }
    }
}

/// Discards all published domain events.
#[derive(Debug, Default, Clone, Copy)]
pub struct NoopEventPublisher;

impl EventPublisher for NoopEventPublisher {
    fn publish(&self, _events: &[PackageEvent]) {}
}

#[cfg(test)]
mod tests {
    use super::*;
    use hub_domain::PackageId;

    #[test]
    fn file_publisher_writes_events_and_messages() {
        let temp_dir = std::env::temp_dir().join(format!("test-hub-{}", std::process::id()));
        let log_file = temp_dir.join("test.log");
        let publisher = FileEventPublisher::new(&log_file);

        publisher.log("startup message");

        let event = PackageEvent::Registered {
            id: PackageId::parse("test-pkg").expect("valid id"),
            name: "Test Package".to_string(),
        };
        publisher.publish(&[event]);

        let contents = std::fs::read_to_string(&log_file).expect("log file exists");
        assert!(contents.contains("startup message"));
        assert!(contents.contains("[event] Registered"));

        let _ = std::fs::remove_dir_all(temp_dir);
    }

    #[test]
    fn noop_publisher_ignores_events() {
        let publisher = NoopEventPublisher;
        let event = PackageEvent::Installed {
            id: PackageId::parse("test-pkg").expect("valid id"),
        };
        publisher.publish(&[event]);
    }
}
