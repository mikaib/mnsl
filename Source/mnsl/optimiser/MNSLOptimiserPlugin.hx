package mnsl.optimiser;

import mnsl.parser.MNSLNode;
import mnsl.analysis.MNSLType;
import mnsl.analysis.MNSLAnalyser;
import haxe.EnumTools.EnumValueTools;

class MNSLOptimiserPlugin {

    private var _on: MNSLNode;

    /**
     * Constructor for the MNSLOptimizerPlugin class.
     * @param onNode The node type that this optimizer will run on
     */
    public function new(onNode: MNSLNode) {
        this._on = onNode;
    }

    /**
     * The function to run the optimizer on a node, this function should be overridden by subclasses.
     * @param node The node to optimize
     * @return The optimized node
     */
    private function onRun(node: MNSLNode, params: Array<Dynamic>, optimizer: MNSLOptimiser): MNSLNode {
        return node;
    }

    /**
     * Get the type of a node
     * @param node The node to get the type of
     * @return A copy of the type of the node
     */
    public function typeOf(node: MNSLNode): MNSLType {
        return MNSLAnalyser.getType(node).copy();
    }

    /**
     * Checks if all values in an array match each other.
     * @param values The array of values to check
     */
    public function allMatchValue(values: Array<Dynamic>): Bool {
        return allMatchFunction(values, function(value: Dynamic): Bool {
            return value == values[0];
        });
    }

    /**
     * Checks if all values in an array match again a function.
     * @param values The array of values to check
     * @param func The function to check against
     */
    public function allMatchFunction(values: Array<Dynamic>, func: Dynamic -> Bool): Bool {
        if (values.length == 0) return true;

        for (value in values) {
            if (!func(value)) return false;
        }

        return true;
    }

    /**
     * Check if the optimizer is applicable to the given node.
     * @param node The node to check
     */
    public function canOptimise(node: MNSLNode, optimizer: MNSLOptimiser): Bool {
        return EnumValueTools.getName(node) == EnumValueTools.getName(_on);
    }

    /**
     * Run the optimizer
     * @param node The node to optimize
     * @return The optimized node
     */
    public function optimise(node: MNSLNode, params: Array<Dynamic>, optimizer: MNSLOptimiser): MNSLNode {
        return onRun(node, params, optimizer);
    }

}
