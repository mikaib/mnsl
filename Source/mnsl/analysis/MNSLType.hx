package mnsl.analysis;

class MNSLType {

    public static var TUnknown(get, never): MNSLType;
    public static var TString(get, never): MNSLType;
    public static var TBool(get, never): MNSLType;
    public static var TVoid(get, never): MNSLType;
    public static var TFloat(get, never): MNSLType;
    public static var TInt(get, never): MNSLType;
    public static var TMat2(get, never): MNSLType;
    public static var TMat3(get, never): MNSLType;
    public static var TMat4(get, never): MNSLType;
    public static var TVec2(get, never): MNSLType;
    public static var TVec3(get, never): MNSLType;
    public static var TVec4(get, never): MNSLType;
    public static var TSampler(get, never): MNSLType;
    public static var TCubeSampler(get, never): MNSLType;
    public static var TCTValue(get, never): MNSLType;

    public static function Template(T: String, ?limits: Array<MNSLType>): MNSLType {
        return new MNSLType('Template<$T>', true, limits);
    }

    public static function Array(T: String, size: Int): MNSLType {
        return new MNSLType('Array<$T, $size>', false, []);
    }

    private var _type: String;
    private var _tempType: Bool;
    private var _arrayBaseType: MNSLType;
    private var _arraySize: Int = -1;
    private var _limits: Array<MNSLType>;

    /**
     * Create a new MNSLType instance.
     * @param type The type name.
     */
    private function new(t: String, temp: Bool = false, ?limits: Array<MNSLType>): Void {
        _tempType = temp;
        _limits = limits != null ? limits : [];
        _arrayBaseType = null;

        setTypeStrUnsafe(t);
    }

    /**
     * Get the limits of the template type.
     * @return An array of MNSLType representing the limits, or an empty array if not a template.
     */
    public inline function getLimits(): Array<MNSLType> {
        return _limits;
    }

    /**
     * Set the limits of the template type.
     * @param limits An array of MNSLType representing the limits.
     */
    public function setLimits(limits: Array<MNSLType>): Void {
        _limits = limits;
    }

    /**
     * Check if the type has limits
     * @return True if the type has limits, false otherwise.
     */
    public inline function hasLimits(): Bool {
        return _limits.length > 0;
    }

    /**
     * Set the array base type.
     */
    public function setArrayBaseType(base: MNSLType): Void {
        _arrayBaseType = base;
    }

    /**
    * Set the array size.
    * @param size The size of the array.
    */
    public function setArraySize(size: Int): Void {
        _arraySize = size;
    }

    /**
     * Get the array size.
     * @return The size of the array, or -1 if not an array.
     */
    public inline function getArraySize(): Int {
        return _arraySize;
    }

    /**
     * Get the array base type.
     * @return The base type of the array, or null if not an array.
     */
    public inline function getArrayBaseType(): MNSLType {
        return _arrayBaseType ?? this;
    }

    /**
     * Check if the type is an array.
     * @return True if the type is an array, false otherwise.
     */
    public inline function isArray(): Bool {
        return _arrayBaseType != null;
    }

    /**
     * Check if the type accepts a specific type as a limit.
     */
    public function accepts(t: MNSLType): Bool {
        if (!hasLimits()) return true;

        for (l in _limits) {
            if (l.equals(t)) return true;
        }

        return false;
    }

    /**
     * Unsafely set the type name.
     * @param type The type name.
     */
    public function setTypeStrUnsafe(type: String): Void {
        if (StringTools.startsWith(type, "Array<") && StringTools.endsWith(type, ">")) {
            var baseTypeContent = type.substr(6, type.length - 7);
            var parts = StringTools.replace(baseTypeContent, " ", "").split(",");
            if (parts.length > 0) _arrayBaseType = MNSLType.fromString(parts[0]);
            if (parts.length > 1) _arraySize = Std.parseInt(parts[1]) ?? -1;
        }

        _type = type;
    }

    /**
     * Set a type.
     * @param type The type name.
     */
    public function setType(type: MNSLType): Void {
        setTypeStrUnsafe(type.toString());
    }

    /**
     * Checks if the type equals another type.
     */
    public function equals(type: MNSLType): Bool {
        @:privateAccess return _type == type._type;
    }

    /**
     * Mark the type as temporary.
     * @param temp True if the type is temporary, false otherwise.
     */
    public function setTempType(temp: Bool): Void {
        _tempType = temp;
    }

    /**
     * Check if the type is defined.
     */
    public inline function isDefined(): Bool {
        return _type != "Unknown" && !_tempType;
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
        return _type == "Float";
    }

    /**
     * Check if the type is numeric, which includes both integers and floating point numbers.
     */
    public inline function isNumerical(): Bool {
        return isFloat() || isInt();
    }

    /**
     * Check if the type is an integer of any precision.
     */
    public inline function isInt(): Bool {
        return _type == "Int";
    }

    /**
     * Check if the type is a boolean.
     */
    public inline function isBool(): Bool {
        return _type == "Bool";
    }

    /**
     * check if the type is a template
     */
    public inline function isTemplate(): Bool {
        return StringTools.startsWith(_type, "Template<") && StringTools.endsWith(_type, ">");
    }

    /**
     * Get template name.
     * @return The template name, or null if not a template.
     */
    public inline function getTemplateName(): String {
        if (!isTemplate()) return null;
        return _type.substr(9, _type.length - 10);
    }

    /**
     * Check if it is a vector of a specific kind of type.
     * @param components The number of components.
     */
    public inline function isVectorWithComponents(components: Int): Bool {
        return _type == "Vec" + components;
    }

    /**
     * Gets the amount of components in the vector type.
     * @return The number of components, or -1 if not a vector.
     */
    public inline function getVectorComponents(): Int {
        switch (_type) {
            case "Vec2": return 2;
            case "Vec3": return 3;
            case "Vec4": return 4;
            default: return -1;
        }
    }

    /**
     * Check if the type is a vector of any kind.
     */
    public inline function isVector(): Bool {
        return isVectorWithComponents(2) || isVectorWithComponents(3) || isVectorWithComponents(4);
    }

    /**
     * Check if the type is a matrix of a size with an equal number of columns and rows.
     * @param size The number of columns and rows.
     */
    public inline function isMatrixWithEqualSize(size: Int): Bool {
        return _type == "Mat" + size;
    }

    /**
     * Gets the width of the matrix.
     * @return The number of columns, or -1 if not a matrix.
     */
    public inline function getMatrixWidth(): Int {
        switch (_type) {
            case "Mat2": return 2;
            case "Mat3": return 3;
            case "Mat4": return 4;
            default: return -1;
        }
    }

    /**
     * Gets the height of the matrix.
     * @return The number of rows, or -1 if not a matrix.
     */
    public inline function getMatrixHeight(): Int {
        switch (_type) {
            case "Mat2": return 2;
            case "Mat3": return 3;
            case "Mat4": return 4;
            default: return -1;
        }
    }

    /**
     * Check if the type is a matrix of any kind.
     */
    public inline function isMatrix(): Bool {
        return isMatrixWithEqualSize(2) || isMatrixWithEqualSize(3) || isMatrixWithEqualSize(4);
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
     * Create a new TFloat type.
     */
    public static inline function get_TFloat():MNSLType {
        return new MNSLType("Float");
    }

    /**
     * Create a new TInt type.
     */
    public static inline function get_TInt():MNSLType {
        return new MNSLType("Int");
    }

    /**
     * Create a new TMat2 type.
     */
    public static inline function get_TMat2():MNSLType {
        return new MNSLType("Mat2");
    }

    /**
     * Create a new TMat3 type.
     */
    public static inline function get_TMat3():MNSLType {
        return new MNSLType("Mat3");
    }


    /**
     * Create a new TMat4 type.
     */
    public static inline function get_TMat4():MNSLType {
        return new MNSLType("Mat4");
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
     * Create a new TVoid type.
     */
    public static inline function get_TVoid():MNSLType {
        return new MNSLType("Void");
    }

    /**
     * Create a new TString type.
     */
    public static inline function get_TString():MNSLType {
        return new MNSLType("String");
    }

    /**
     * Create a new TSampler type.
     */
    public static inline function get_TSampler():MNSLType {
        return new MNSLType("Sampler");
    }

    /**
     * Create a new TCubeSampler type.
     */
    public static inline function get_TCubeSampler():MNSLType {
        return new MNSLType("CubeSampler");
    }

    /**
     * Create a new TCTValue type.
     */
    public static inline function get_TCTValue():MNSLType {
        return new MNSLType("CTValue");
    }

    /**
     * Get the type name.
     * @return The type name.
     */
    @:to
    public function toString(): String {
        return _type;
    }

    /**
     * Convert to base string
     * @return The type name without template or temporary information.
     */
    public function toBaseString(): String {
        if (isTemplate()) {
            return getTemplateName();
        }
        if (isArray()) {
            return getArrayBaseType().toBaseString();
        }
        return _type;
    }

    /**
     * To human readable string.
     * @return The type name.
     */
    public function toHumanString(): String {
        return 'T${_type}${_tempType ? " (temp)" : ""}';
    }

    /**
     * Copy the type.
     */
    public function copy(): MNSLType {
        return new MNSLType(_type, _tempType);
    }

}