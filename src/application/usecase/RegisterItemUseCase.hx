package application.usecase;

import application.dto.RegisterItemCommand;
import domain.model.HubItem;
import domain.model.ItemId;
import domain.port.HubItemRepository;

/**
 * Application Use Case: Register a new software item in the hub.
 */
class RegisterItemUseCase {
    final repository:HubItemRepository;

    public function new(repository:HubItemRepository) {
        this.repository = repository;
    }

    public function execute(command:RegisterItemCommand):HubItem {
        var id = ItemId.generate();
        var item = new HubItem(id, command.name, command.initialStatus);

        repository.save(item);

        // Process domain events if an event bus or dispatcher is configured
        var events = item.pullUncommittedEvents();
        #if debug
        for (event in events) {
            Sys.println('Event dispatched: ' + Std.string(event));
        }
        #end

        return item;
    }
}
