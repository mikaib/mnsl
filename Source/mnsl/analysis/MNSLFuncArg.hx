package mnsl.analysis;

import mnsl.analysis.MNSLType;

@:structInit
class MNSLFuncArg {
    public var name: String;
    public var type: MNSLType;

    @:to
    public function toString(): String {
        return name + "(" + type + ")";
    }

    public function new(name: String, type: MNSLType) {
        this.name = name;
        this.type = type;
    }

}
