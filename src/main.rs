mod application;
mod domain;
mod infrastructure;

use std::rc::Rc;
use std::sync::Arc;

use application::use_cases::{ListItemsUseCase, RegisterItemCommand, RegisterItemUseCase};
use infrastructure::in_memory_repo::InMemoryHubItemRepository;
use slint::{ModelRc, VecModel};

slint::include_modules!();

fn refresh_ui_items(list_use_case: &ListItemsUseCase, ui: &AppWindow) {
    let items = list_use_case.execute();
    let slint_items: Vec<HubItemData> = items
        .into_iter()
        .map(|item| HubItemData {
            name: item.name().into(),
            status: item.status().as_str().into(),
            id: item.id().to_string().into(),
        })
        .collect();

    let model = Rc::new(VecModel::from(slint_items));
    ui.set_items(ModelRc::from(model));
}

fn main() -> Result<(), slint::PlatformError> {
    // 1. Initialize Infrastructure & Use Cases
    let repo = Arc::new(InMemoryHubItemRepository::new());
    let register_use_case = Arc::new(RegisterItemUseCase::new(repo.clone()));
    let list_use_case = Arc::new(ListItemsUseCase::new(repo));

    // Seed preview items
    let _ = register_use_case.execute(RegisterItemCommand {
        name: "Jumpmaster Engine Core".to_string(),
        initial_status: None,
    });
    let _ = register_use_case.execute(RegisterItemCommand {
        name: "Cross-Platform Asset Pipeline".to_string(),
        initial_status: None,
    });

    // 2. Initialize Slint UI
    let ui = AppWindow::new()?;

    // Populate initial list
    refresh_ui_items(&list_use_case, &ui);

    // 3. Wire UI Callbacks to Application Use Cases
    let ui_weak = ui.as_weak();
    let register_uc_clone = register_use_case.clone();
    let list_uc_clone = list_use_case.clone();
    ui.on_register_software(move |name| {
        if let Some(ui) = ui_weak.upgrade() {
            let cmd = RegisterItemCommand {
                name: name.to_string(),
                initial_status: None,
            };
            if let Ok(_) = register_uc_clone.execute(cmd) {
                refresh_ui_items(&list_uc_clone, &ui);
            }
        }
    });

    let ui_weak = ui.as_weak();
    let list_uc_clone = list_use_case.clone();
    ui.on_refresh_software(move || {
        if let Some(ui) = ui_weak.upgrade() {
            refresh_ui_items(&list_uc_clone, &ui);
        }
    });

    // 4. Run native event loop
    ui.run()
}
