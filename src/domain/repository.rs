#![allow(dead_code)]

use super::model::{HubItem, ItemId};

/// Outbound Port: Repository interface for HubItem persistence.
pub trait HubItemRepository: Send + Sync {
    fn find_by_id(&self, id: &ItemId) -> Option<HubItem>;
    fn find_all(&self) -> Vec<HubItem>;
    fn save(&self, item: HubItem);
}
