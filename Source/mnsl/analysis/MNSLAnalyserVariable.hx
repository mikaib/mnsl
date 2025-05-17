package mnsl.analysis;

@:structInit
class MNSLAnalyserVariable {
    public var name: String;
    public var type: MNSLType;

    @:to
    public function toString(): String {
        return "MNSLAnalyserVariable(" + name + ", " + type.toString() + ")";
    }
}
