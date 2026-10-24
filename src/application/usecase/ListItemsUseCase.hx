package application.usecase;

import domain.model.HubItem;
import domain.port.HubItemRepository;

/**
 * Application Use Case: Query all registered software hub items.
 */
class ListItemsUseCase {
    final repository:HubItemRepository;

    public function new(repository:HubItemRepository) {
        this.repository = repository;
    }

    public function execute():Array<HubItem> {
        return repository.findAll();
    }
}
