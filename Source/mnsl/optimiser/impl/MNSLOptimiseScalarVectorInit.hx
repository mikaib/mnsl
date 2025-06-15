package mnsl.optimiser.impl;

import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeChildren;

class MNSLOptimiseScalarVectorInit extends MNSLOptimiserPlugin {

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
    override public function onRun(node: MNSLNode, params: Array<Dynamic>, optimizer: MNSLOptimiser): MNSLNode {
        var components: Int = params[0];
        var values: MNSLNodeChildren = params[1];
        var valuesString: Array<String> = [for (v in values) Std.string(v)];

        // check if all values are the same.
        if (allMatchValue(valuesString) && values.length > 1) {
            return VectorCreation(components, [values[0]], null);
        }

        return node;
    }

}
