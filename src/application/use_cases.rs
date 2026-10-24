use std::sync::Arc;
use crate::domain::model::{HubItem, ItemId, ItemStatus};
use crate::domain::repository::HubItemRepository;

pub struct RegisterItemCommand {
    pub name: String,
    pub initial_status: Option<ItemStatus>,
}

pub struct RegisterItemUseCase {
    repo: Arc<dyn HubItemRepository>,
}

impl RegisterItemUseCase {
    pub fn new(repo: Arc<dyn HubItemRepository>) -> Self {
        Self { repo }
    }

    pub fn execute(&self, cmd: RegisterItemCommand) -> Result<HubItem, &'static str> {
        let id = ItemId::generate();
        let item = HubItem::new(id, cmd.name, cmd.initial_status)?;
        self.repo.save(item.clone());
        Ok(item)
    }
}

pub struct ListItemsUseCase {
    repo: Arc<dyn HubItemRepository>,
}

impl ListItemsUseCase {
    pub fn new(repo: Arc<dyn HubItemRepository>) -> Self {
        Self { repo }
    }

    pub fn execute(&self) -> Vec<HubItem> {
        self.repo.find_all()
    }
}
