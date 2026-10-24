package domain.model;

import domain.event.HubItemEvent;

/**
 * Aggregate Root: HubItem
 * Enforces business rules and invariants for software managed by the hub.
 */
class HubItem {
    public var id(default, null):ItemId;
    public var name(default, null):String;
    public var status(default, null):ItemStatus;
    public var createdAt(default, null):Date;

    final uncommittedEvents:Array<HubItemEvent> = [];

    public function new(id:ItemId, name:String, ?status:ItemStatus, ?createdAt:Date) {
        validateName(name);

        this.id = id;
        this.name = StringTools.trim(name);
        this.status = status != null ? status : ItemStatus.Active;
        this.createdAt = createdAt != null ? createdAt : Date.now();

        recordEvent(HubItemEvent.ItemRegistered(this.id, this.name, this.createdAt));
    }

    public function changeStatus(newStatus:ItemStatus):Void {
        if (this.status == newStatus) {
            return;
        }

        if (this.status == ItemStatus.Deprecated) {
            throw "Cannot change status of an already deprecated HubItem";
        }

        var oldStatus = this.status;
        this.status = newStatus;
        recordEvent(HubItemEvent.ItemStatusUpdated(this.id, oldStatus, newStatus));
    }

    public function rename(newName:String):Void {
        validateName(newName);
        var trimmed = StringTools.trim(newName);
        if (this.name == trimmed) {
            return;
        }

        var oldName = this.name;
        this.name = trimmed;
        recordEvent(HubItemEvent.ItemRenamed(this.id, oldName, this.name));
    }

    public function pullUncommittedEvents():Array<HubItemEvent> {
        var events = uncommittedEvents.copy();
        uncommittedEvents.resize(0);
        return events;
    }

    static function validateName(name:String):Void {
        if (name == null || StringTools.trim(name).length < 2) {
            throw "HubItem name must be at least 2 characters long";
        }
    }

    inline function recordEvent(event:HubItemEvent):Void {
        uncommittedEvents.push(event);
    }
}
