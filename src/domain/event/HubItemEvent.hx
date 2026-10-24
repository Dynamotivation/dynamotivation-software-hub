package domain.event;

import domain.model.ItemId;
import domain.model.ItemStatus;

/**
 * Domain Events emitted when aggregate state changes.
 */
enum HubItemEvent {
    ItemRegistered(id:ItemId, name:String, createdAt:Date);
    ItemStatusUpdated(id:ItemId, previousStatus:ItemStatus, newStatus:ItemStatus);
    ItemRenamed(id:ItemId, oldName:String, newName:String);
}
