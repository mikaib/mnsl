package mnsl.optimiser.impl;

import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeChildren;
import haxe.EnumTools.EnumValueTools;

class MNSLOptimiseSwizzleAccess extends MNSLOptimiserPlugin {

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

        // check if all values are StructAccess
        if (!allMatchFunction(values, function(node: MNSLNode) {
            return EnumValueTools.getName(node) == "StructAccess";
        })) return node;

        // retrieve data of first node.
        var firstNode = values[0];
        var firstOn = EnumValueTools.getParameters(firstNode)[0];
        var firstType = EnumValueTools.getParameters(firstNode)[2];
        var firstInfo = EnumValueTools.getParameters(firstNode)[3];

        // check if all values have the same struct "on" node.
        var fields: Array<String> = [];
        if (!allMatchFunction(values, function(node: MNSLNode) {
            var params = EnumValueTools.getParameters(node);
            var on: MNSLNode = params[0];
            fields.push(params[1]);

            return Std.string(on) == Std.string(firstOn);
        })) return node;

        // ensure all fields are either x, y, z or w
        if (!allMatchFunction(fields, function(field: String) {
            return field == "x" || field == "y" || field == "z" || field == "w";
        })) return node;

        // optimize it
        return StructAccess(firstOn, fields.join(''), firstType, firstInfo);
    }

}
