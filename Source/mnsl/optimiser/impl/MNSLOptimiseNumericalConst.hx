package mnsl.optimiser.impl;

import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeChildren;
import mnsl.analysis.MNSLType;

class MNSLOptimiseNumericalConst extends MNSLOptimiserPlugin {

    /**
     * Create a new MNSLOptimizerPlugin.
     */
    public function new() {
        super(
            TypeCast(null, null, null),
        );
    }

    /**
     * Run the optimizer on the given node.
     * @param node The MNSLNode to optimize.
     * @param optimizer The MNSLOptimizer instance.
     */
    override public function onRun(node: MNSLNode, params: Array<Dynamic>, optimizer: MNSLOptimiser): MNSLNode {
        var lit: MNSLNode = params[0];
        var from: MNSLType = params[1];
        var to: MNSLType = params[2];

        switch (lit) {
            case IntegerLiteralNode(val, info):
                if (to.isFloat()) return FloatLiteralNode('$val.0', info);
            case FloatLiteralNode(val, info):
                if (to.isInt()) return IntegerLiteralNode(Std.string(Std.int(Std.parseFloat(val))), info);
            default: null;
        }

        return node;
    }

}
