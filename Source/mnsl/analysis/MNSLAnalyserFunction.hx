package mnsl.analysis;

@:structInit
class MNSLAnalyserFunction {
    public var name: String;
    public var args: MNSLFuncArgs;
    public var returnType: MNSLType;
    public var hasImplementation: Bool = false;

    @:to
    public function toString(): String {
        return "MNSLAnalyserFunction(" + name + ", " + args.toString() + ", " + returnType.toString() + ")" + (hasImplementation ? " hasImplementation" : "");
    }
}
