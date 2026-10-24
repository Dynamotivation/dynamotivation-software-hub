package domain.model;

/**
 * Value Object representing a strongly-typed unique identifier for a HubItem.
 * Uses Haxe zero-cost abstract types with compile-time validation.
 */
abstract ItemId(String) to String {
    public inline function new(value:String) {
        if (value == null || StringTools.trim(value).length == 0) {
            throw "ItemId cannot be null or empty";
        }
        this = value;
    }

    public static inline function generate():ItemId {
        var timestamp = Std.string(Date.now().getTime());
        var randomSuffix = Std.string(Math.floor(Math.random() * 100000));
        return new ItemId('item-${timestamp}-${randomSuffix}');
    }

    public static inline function fromString(value:String):ItemId {
        return new ItemId(value);
    }

    @:op(A == B)
    public inline function equals(other:ItemId):Bool {
        return (this : String) == (other : String);
    }
}
