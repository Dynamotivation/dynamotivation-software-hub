#![allow(dead_code)]

use std::fmt;

/// Value Object representing a unique identifier for a HubItem.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ItemId(String);

impl ItemId {
    pub fn new(val: impl Into<String>) -> Result<Self, &'static str> {
        let s = val.into();
        let trimmed = s.trim();
        if trimmed.is_empty() {
            return Err("ItemId cannot be empty");
        }
        Ok(Self(trimmed.to_string()))
    }

    pub fn generate() -> Self {
        use std::time::{SystemTime, UNIX_EPOCH};
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis();
        Self(format!("item-{}", now))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for ItemId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Lifecycle status for a HubItem.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ItemStatus {
    Draft,
    Active,
    Maintenance,
    Deprecated,
}

impl ItemStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Draft => "Draft",
            Self::Active => "Active",
            Self::Maintenance => "Active",
            Self::Deprecated => "Deprecated",
        }
    }
}

/// Aggregate Root: HubItem
/// Governs invariants for software packages registered in the hub.
#[derive(Debug, Clone)]
pub struct HubItem {
    id: ItemId,
    name: String,
    status: ItemStatus,
}

impl HubItem {
    pub fn new(id: ItemId, name: impl Into<String>, status: Option<ItemStatus>) -> Result<Self, &'static str> {
        let name_str = name.into();
        let trimmed = name_str.trim();
        if trimmed.len() < 2 {
            return Err("HubItem name must be at least 2 characters long");
        }

        Ok(Self {
            id,
            name: trimmed.to_string(),
            status: status.unwrap_or(ItemStatus::Active),
        })
    }

    pub fn id(&self) -> &ItemId {
        &self.id
    }

    pub fn name(&self) -> &str {
        &self.name
    }

    pub fn status(&self) -> ItemStatus {
        self.status
    }

    pub fn change_status(&mut self, new_status: ItemStatus) -> Result<(), &'static str> {
        if self.status == ItemStatus::Deprecated {
            return Err("Cannot change status of a deprecated HubItem");
        }
        self.status = new_status;
        Ok(())
    }
}
