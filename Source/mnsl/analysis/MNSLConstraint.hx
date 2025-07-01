package mnsl.analysis;

import mnsl.parser.MNSLNode;

@:structInit
class MNSLConstraint {
    public var type: MNSLType;
    public var ofNode: MNSLNode;
    public var mustBe: MNSLType;
    public var _optional: Bool = false;
    public var _isBinaryOp: Bool = false;
    public var _isLeftSide: Bool = false;
    public var _isRightSide: Bool = false;
    public var _operationOperator: String = '';
    public var _mustBeOfNode: MNSLNode = null;

    @:to
    public function toString(): String {
        return "MNSLConstraint(" + type.toHumanString() + " = " + mustBe.toHumanString() + " in " + ofNode + ")";
    }
}
