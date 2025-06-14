package mnsl.optimiser.impl;

import mnsl.parser.MNSLNode;
import haxe.EnumTools.EnumValueTools;

class MNSLOptimiseSwizzleAssign extends MNSLOptimiserPlugin {

    /**
     * Create a new MNSLOptimizerPlugin.
     */
    public function new() {
        super(
            Block(null, null)
        );
    }

    /**
     * Run the optimizer on the given node.
     * @param node The MNSLNode to optimize.
     * @param optimizer The MNSLOptimizer instance.
     */
    override public function onRun(node: MNSLNode, params: Array<Dynamic>, optimizer: MNSLOptimiser): MNSLNode {
        // check if all elements in the block are assignments
        if (!allMatchFunction(params[0], function(node: MNSLNode) {
            return EnumValueTools.getName(node) == "VariableAssign";
        })) return node;

        // optimize
        trace("can optim");

        return node;
    }

}
