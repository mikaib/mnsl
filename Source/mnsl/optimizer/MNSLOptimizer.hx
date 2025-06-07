package mnsl.optimizer;

import mnsl.parser.MNSLNodeChildren;
import mnsl.parser.MNSLNode;
import haxe.EnumTools.EnumValueTools;
import haxe.EnumTools;

class MNSLOptimizer {

    public var plugins: Array<MNSLOptimizerPlugin>;
    public var context: MNSLContext;
    public var ast: MNSLNodeChildren;

    /**
     * Create a new optimizer instance.
     * @param context The MNSL context.
     * @param ast The AST to optimize.
     */
    public function new(context: MNSLContext, ast: MNSLNodeChildren) {
        this.plugins = [];
        this.context = context;
        this.ast = ast;
    }

    /**
     * Add a plugin to the optimizer.
     * @param plugin The plugin to add.
     */
    public function addPlugin(plugin: MNSLOptimizerPlugin): Void {
        this.plugins.push(plugin);
    }

    /**
     * Run the optimizer on the AST.
     */
    public function run(): MNSLNodeChildren {
        return this.runOnBody(this.ast);
    }

    /**
     * Run the optimizer on a specific body of nodes.
     * @param body The body of nodes to optimize.
     */
    public function runOnBody(body: MNSLNodeChildren): MNSLNodeChildren {
        var optimizedBody: Array<MNSLNode> = [];
        for (child in body) {
            optimizedBody.push(this.runOnNode(child));
        }
        return optimizedBody;
    }

    /**
     * Run the optimizer on a specific node.
     * @param node The node to optimize.
     */
    public function runOnNode(node: MNSLNode): MNSLNode {
        var params = EnumValueTools.getParameters(node);

        for (plugin in this.plugins) {
            if (plugin.canOptimize(node, this)) {
                var result = plugin.optimize(node, params, this);
                if (result != null) {
                    node = result;
                    params = EnumValueTools.getParameters(node);
                }
            }
        }

        for (pIdx in 0...params.length) {
            var p: Dynamic = params[pIdx];

            if (Std.isOfType(p, MNSLNodeChildren) && p[0] != null && Std.isOfType(p[0], MNSLNode)) {
                params[pIdx] = this.runOnBody(p);
            } else if (Std.isOfType(p, MNSLNode)) {
                params[pIdx] = this.runOnNode(p);
            }
        }

        return Type.createEnum(Type.getEnum(node), EnumValueTools.getName(node), params);
    }

}
