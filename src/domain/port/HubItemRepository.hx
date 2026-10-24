package domain.port;

import domain.model.HubItem;
import domain.model.ItemId;

/**
 * Outbound Port: HubItemRepository
 * Abstracts data storage operations away from business logic.
 */
interface HubItemRepository {
    function findById(id:ItemId):Null<HubItem>;
    function findAll():Array<HubItem>;
    function save(item:HubItem):Void;
    function delete(id:ItemId):Bool;
}
