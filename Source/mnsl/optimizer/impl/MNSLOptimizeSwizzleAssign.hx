package mnsl.optimizer.impl;

import mnsl.parser.MNSLNode;

class MNSLOptimizeSwizzleAssign extends MNSLOptimizerPlugin {

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
    override public function onRun(node: MNSLNode, params: Array<Dynamic>, optimizer: MNSLOptimizer): MNSLNode {
       return node;
    }

}
