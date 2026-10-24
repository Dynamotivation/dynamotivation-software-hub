package infrastructure.persistence;

import domain.model.HubItem;
import domain.model.ItemId;
import domain.port.HubItemRepository;

/**
 * In-memory persistence adapter implementing the HubItemRepository port.
 * Useful for development, unit testing, and initial scaffolding.
 */
class InMemoryHubItemRepository implements HubItemRepository {
    final storage:Map<String, HubItem> = new Map<String, HubItem>();

    public function new() {}

    public function findById(id:ItemId):Null<HubItem> {
        return storage.get(id);
    }

    public function findAll():Array<HubItem> {
        var list = [];
        for (item in storage) {
            list.push(item);
        }
        return list;
    }

    public function save(item:HubItem):Void {
        storage.set(item.id, item);
    }

    public function delete(id:ItemId):Bool {
        return storage.remove(id);
    }
}
