package mnsl.analysis;
import mnsl.parser.MNSLNode;

@:structInit
class MNSLAnalyserFunction {
    public var name: String;
    public var args: MNSLFuncArgs;
    public var returnType: MNSLType;
    public var internal: Bool = true;
    public var scope: MNSLAnalyserContext = null;
    public var hasImplementation: Bool = false;
    public var remap: Null<String> = null;
    public var usages: Array<MNSLAnalyserFunctionUsage> = [];
    public var node: MNSLNode = null;
    public var atIdx: Int = -1;
    public var isTemplate: Bool = false;
    public var isInlined: Bool = false;

    @:to
    public function toString(): String {
        return "MNSLAnalyserFunction(" + name + ", " + args.toString() + ", " + returnType.toString() + ")" + (hasImplementation ? " hasImplementation" : "");
    }
}
