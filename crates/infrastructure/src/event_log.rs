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
