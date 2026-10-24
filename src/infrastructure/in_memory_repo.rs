use std::collections::HashMap;
use std::sync::RwLock;
use crate::domain::model::{HubItem, ItemId};
use crate::domain::repository::HubItemRepository;

/// In-Memory adapter implementing the HubItemRepository port.
pub struct InMemoryHubItemRepository {
    storage: RwLock<HashMap<ItemId, HubItem>>,
}

impl InMemoryHubItemRepository {
    pub fn new() -> Self {
        Self {
            storage: RwLock::new(HashMap::new()),
        }
    }
}

impl HubItemRepository for InMemoryHubItemRepository {
    fn find_by_id(&self, id: &ItemId) -> Option<HubItem> {
        let lock = self.storage.read().ok()?;
        lock.get(id).cloned()
    }

    fn find_all(&self) -> Vec<HubItem> {
        let lock = match self.storage.read() {
            Ok(guard) => guard,
            Err(_) => return Vec::new(),
        };
        lock.values().cloned().collect()
    }

    fn save(&self, item: HubItem) {
        if let Ok(mut lock) = self.storage.write() {
            lock.insert(item.id().clone(), item);
        }
    }
}
