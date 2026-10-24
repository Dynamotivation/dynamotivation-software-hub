package application.dto;

import domain.model.ItemStatus;

/**
 * Command DTO for registering a new software hub item.
 */
class RegisterItemCommand {
    public var name:String;
    public var initialStatus:Null<ItemStatus>;

    public function new(name:String, ?initialStatus:ItemStatus) {
        this.name = name;
        this.initialStatus = initialStatus;
    }
}
