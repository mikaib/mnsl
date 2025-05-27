package mnsl.analysis;

@:structInit
class MNSLAnalyserVariable {
    public var name: String;
    public var type: MNSLType;
    public var struct: Bool = false;
    public var fields: Array<MNSLAnalyserVariable> = [];

    @:to
    public function toString(): String {
        return "MNSLAnalyserVariable(" + name + ", " + type.toString() + ")";
    }
}
