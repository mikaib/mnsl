package mnsl.analysis;

class MNSLType {
    public static var TUnknown(get, never): MNSLType;

    private var _type: String;

    /**
     * Create a new MNSLType instance.
     * @param type The type name.
     */
    private function new(t: String) {
        _type = t;
    }

    /**
     * Unsafely set the type name.
     * @param type The type name.
     */
    public function setTypeStrUnsafe(type: String): Void {
        _type = type;
    }

    /**
     * Create a type from a String.
     * @param type The type name.
     */
    public static inline function fromString(type: String):MNSLType {
        return new MNSLType(type);
    }

    /**
     * Create a new TUnknown type.
     */
    public static inline function get_TUnknown():MNSLType {
        return new MNSLType("Unknown");
    }

    /**
     * Get the type name.
     * @return The type name.
     */
    @:to
    public function toString(): String {
        return _type;
    }


}
