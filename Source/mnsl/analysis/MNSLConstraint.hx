package mnsl.analysis;

import mnsl.parser.MNSLNode;

@:structInit
class MNSLConstraint {
    public var type: MNSLType;
    public var ofNode: MNSLNode;
    public var mustBe: MNSLType;
    public var _isBinaryOp: Bool = false;
    public var _operationOperator: String = '';

    @:to
    public function toString(): String {
        return "MNSLConstraint(" + type.toHumanString() + " = " + mustBe.toHumanString() + " in " + ofNode + ")";
    }
}
