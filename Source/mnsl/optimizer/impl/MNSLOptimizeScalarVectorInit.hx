package mnsl.optimizer.impl;

import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeChildren;

class MNSLOptimizeScalarVectorInit extends MNSLOptimizerPlugin {

    /**
     * Create a new MNSLOptimizerPlugin.
     */
    public function new() {
        super(
            VectorCreation(0, null, null)
        );
    }

    /**
     * Run the optimizer on the given node.
     * @param node The MNSLNode to optimize.
     * @param optimizer The MNSLOptimizer instance.
     */
    override public function onRun(node: MNSLNode, params: Array<Dynamic>, optimizer: MNSLOptimizer): MNSLNode {
        var components: Int = params[0];
        var values: MNSLNodeChildren = params[1];

        // check if all values are the same.
        if (allMatchValue(values) && values.length > 1) {
            return VectorCreation(components, [values[0]], null);
        }

        return node;
    }

}
