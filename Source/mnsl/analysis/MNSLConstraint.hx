package mnsl.analysis;

import mnsl.parser.MNSLNode;

@:structInit
class MNSLConstraint {
    public var type: MNSLType;
    public var ofNode: MNSLNode;
    public var mustBe: MNSLType;
}
