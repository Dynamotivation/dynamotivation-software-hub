#![allow(dead_code)]

use super::model::{ItemId, ItemStatus};

#[derive(Debug, Clone)]
pub enum HubItemEvent {
    ItemRegistered { id: ItemId, name: String },
    ItemStatusChanged { id: ItemId, new_status: ItemStatus },
}
