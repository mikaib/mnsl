package mnsl.analysis;

import mnsl.parser.MNSLNode;

@:structInit
class MNSLReplaceCmd {
    public var node: MNSLNode;
    public var to: MNSLNode;

    @:to
    public function toString(): String {
        return 'MNSLReplaceCmd(' + node + ', ' + to + ')';
    }
}
