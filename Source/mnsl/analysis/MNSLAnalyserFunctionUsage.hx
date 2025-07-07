package mnsl.analysis;
import mnsl.parser.MNSLNode;

@:structInit
class MNSLAnalyserFunctionUsage {
    public var varyingArgTypes: Array<MNSLType> = [];
    public var varyingRetType: MNSLType = null;
    public var callNode: MNSLNode = null;

    @:to
    public function toString(): String {
        return "MNSLAnalyserFunctionUsage(" + varyingArgTypes.toString() + ", " + (varyingRetType != null ? varyingRetType.toString() : "null") + ")";
    }
}
