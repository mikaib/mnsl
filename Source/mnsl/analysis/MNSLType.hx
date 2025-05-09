package mnsl.analysis;

class MNSLType {

    public static var TUnknown(get, never): MNSLType;
    public static var TBool(get, never): MNSLType;
    public static var TFloat32(get, never): MNSLType;
    public static var TInt32(get, never): MNSLType;
    public static var TMat2(get, never): MNSLType;
    public static var TMat23(get, never): MNSLType;
    public static var TMat24(get, never): MNSLType;
    public static var TMat3(get, never): MNSLType;
    public static var TMat32(get, never): MNSLType;
    public static var TMat34(get, never): MNSLType;
    public static var TMat4(get, never): MNSLType;
    public static var TMat42(get, never): MNSLType;
    public static var TMat43(get, never): MNSLType;
    public static var TVec2(get, never): MNSLType;
    public static var TVec3(get, never): MNSLType;
    public static var TVec4(get, never): MNSLType;

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
     * Check if the type is unknown.
     * @return True if the type is unknown, false otherwise.
     */
    public inline function isUnknown(): Bool {
        return _type == "Unknown";
    }

    /**
     * Check if the type is a floating point number of any precision.
     */
    public inline function isFloat(): Bool {
        return _type == "Float32";
    }

    /**
     * Check if the type is an integer of any precision.
     */
    public inline function isInt(): Bool {
        return _type == "Int32";
    }

    /**
     * Check if the type is a boolean.
     */
    public inline function isBool(): Bool {
        return _type == "Bool";
    }

    /**
     * Check if it is a vector of a specific kind of type.
     * @param components The number of components.
     */
    public inline function isVectorWithComponents(components: Int): Bool {
        return _type == "Vec" + components;
    }

    /**
     * Check if the type is a vector of any kind.
     */
    public inline function isVector(): Bool {
        return isVectorWithComponents(2) || isVectorWithComponents(3) || isVectorWithComponents(4);
    }

    /**
     * Check if the type is a matrix of a specific size.
     * @param columns The number of columns.
     * @param rows The number of rows.
     */
    public inline function isMatrixWithSize(columns: Int, rows: Int): Bool {
        if (columns == rows) {
            return isMatrixWithEqualSize(columns);
        }

        return _type == "Mat" + columns + "" + rows;
    }

    /**
     * Check if the type is a matrix of a size with an equal number of columns and rows.
     * @param size The number of columns and rows.
     */
    public inline function isMatrixWithEqualSize(size: Int): Bool {
        return _type == "Mat" + size + "" + size || _type == "Mat" + size;
    }

    /**
     * Check if the type is a matrix of any kind.
     */
    public inline function isMatrix(): Bool {
        return isMatrixWithEqualSize(2) || isMatrixWithEqualSize(3) || isMatrixWithEqualSize(4)
            || isMatrixWithSize(2, 3) || isMatrixWithSize(2, 4)
            || isMatrixWithSize(3, 2) || isMatrixWithSize(3, 4)
            || isMatrixWithSize(4, 2) || isMatrixWithSize(4, 3);
    }

    /**
     * Check if the type is a boolean.
     */
    public inline function isBoolean(): Bool {
        return _type == "Bool";
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
     * Create a new TBool type.
     */
    public static inline function get_TBool():MNSLType {
        return new MNSLType("Bool");
    }

    /**
     * Create a new TFloat32 type.
     */
    public static inline function get_TFloat32():MNSLType {
        return new MNSLType("Float32");
    }

    /**
     * Create a new TInt32 type.
     */
    public static inline function get_TInt32():MNSLType {
        return new MNSLType("Int32");
    }

    /**
     * Create a new TMat2 type.
     */
    public static inline function get_TMat2():MNSLType {
        return new MNSLType("Mat2");
    }

    /**
     * Create a new TMat23 type.
     */
    public static inline function get_TMat23():MNSLType {
        return new MNSLType("Mat23");
    }

    /**
     * Create a new TMat24 type.
     */
    public static inline function get_TMat24():MNSLType {
        return new MNSLType("Mat24");
    }

    /**
     * Create a new TMat3 type.
     */
    public static inline function get_TMat3():MNSLType {
        return new MNSLType("Mat3");
    }

    /**
     * Create a new TMat32 type.
     */
    public static inline function get_TMat32():MNSLType {
        return new MNSLType("Mat32");
    }

    /**
     * Create a new TMat34 type.
     */
    public static inline function get_TMat34():MNSLType {
        return new MNSLType("Mat34");
    }

    /**
     * Create a new TMat4 type.
     */
    public static inline function get_TMat4():MNSLType {
        return new MNSLType("Mat4");
    }

    /**
     * Create a new TMat42 type.
     */
    public static inline function get_TMat42():MNSLType {
        return new MNSLType("Mat42");
    }

    /**
     * Create a new TMat43 type.
     */
    public static inline function get_TMat43():MNSLType {
        return new MNSLType("Mat43");
    }

    /**
     * Create a new TVec2 type.
     */
    public static inline function get_TVec2():MNSLType {
        return new MNSLType("Vec2");
    }

    /**
     * Create a new TVec3 type.
     */
    public static inline function get_TVec3():MNSLType {
        return new MNSLType("Vec3");
    }

    /**
     * Create a new TVec4 type.
     */
    public static inline function get_TVec4():MNSLType {
        return new MNSLType("Vec4");
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
