package mnsl.optimiser.impl;

import mnsl.parser.MNSLNode;
import haxe.EnumTools.EnumValueTools;
import mnsl.analysis.MNSLAnalyser;
import mnsl.parser.MNSLNodeInfo;

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
        // run checks and collect info
        var onArr: Array<MNSLNode> = [];
        var vOnArr: Array<MNSLNode> = [];
        var fieldLeftArr: Array<String> = [];
        var fieldRightArr: Array<String> = [];
        var optimInfo: MNSLNodeInfo = null;
        if (!allMatchFunction(params[0], function(node: MNSLNode) {
            switch (node) {
                case VariableAssign(StructAccess(on, field, type, stuctInfo), value, info):
                    if (optimInfo == null) {
                        optimInfo = info;
                    }

                    onArr.push(on);
                    fieldLeftArr.push(field);

                    if (field != 'x' && field != 'y' && field != 'z' && field != 'w') {
                        return false;
                    }

                    if (!MNSLAnalyser.getType(on).isVector()) {
                        return false;
                    }

                    switch (value) {
                        case StructAccess(vOn, vField, vType, vInfo):
                            if (vField != 'x' && vField != 'y' && vField != 'z' && vField != 'w') {
                                return false;
                            }

                            if (!MNSLAnalyser.getType(vOn).isVector()) {
                                return false;
                            }

                            vOnArr.push(vOn);
                            fieldRightArr.push(vField);
                        default:
                             return false;
                    }

                    return true;
                default:
                    return false;
            }
        })) return node;

        // all of on nodes must be the same
        if (onArr.length == 0) return node;
        var firstOn = onArr[0];

        if (!allMatchFunction(onArr, function(node: MNSLNode) {
            return Std.string(firstOn) == Std.string(node);
        })) return node;

        // all of vOn nodes must be the same
        if (vOnArr.length == 0) return node;
        var firstVOn = vOnArr[0];

        if (!allMatchFunction(vOnArr, function(node: MNSLNode) {
            return Std.string(firstVOn) == Std.string(node);
        })) return node;

        // optimize
        return VariableAssign(
            StructAccess(firstOn, fieldLeftArr.join(''), MNSLAnalyser.getType(firstOn), null),
            firstVOn,
            optimInfo
        );
    }

}
