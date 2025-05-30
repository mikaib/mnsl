package mnsl.analysis;

@:structInit
class MNSLAnalyserFunction {
    public var name: String;
    public var args: MNSLFuncArgs;
    public var returnType: MNSLType;
    public var hasImplementation: Bool = false;
    public var remap: Null<String> = null;

    @:to
    public function toString(): String {
        return "MNSLAnalyserFunction(" + name + ", " + args.toString() + ", " + returnType.toString() + ")" + (hasImplementation ? " hasImplementation" : "");
    }
}
