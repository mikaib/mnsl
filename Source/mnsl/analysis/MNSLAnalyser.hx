package mnsl.analysis;

import mnsl.parser.MNSLNodeChildren;
import mnsl.parser.MNSLNode;
import haxe.EnumTools.EnumValueTools;
import haxe.EnumTools;

class MNSLAnalyser {

    private var _context: MNSLContext;
    private var _ast: MNSLNodeChildren;

    /**
     * Create a new analyser.
     */
    public function new(context: MNSLContext, ast: MNSLNodeChildren) {
        this._context = context;
        this._ast = ast;
    }

    /**
     * Run on a given node.
     * @param node The node to run on.
     */
    public function execAtNode(node: MNSLNode): MNSLNode {
        var eNode = Type.getEnum(node);
        var name = EnumValueTools.getName(node);
        var params: Array<Dynamic> = EnumValueTools.getParameters(node);

        var changeTo = (node: MNSLNode) -> {
            name = EnumValueTools.getName(node);
            params = EnumValueTools.getParameters(node);
        };

        var resPre = this.execAtNodePre(node);
        if (resPre != null) {
            changeTo(resPre);
        }

        for (pi in 0...params.length) {
            var p: Dynamic = params[pi];

            if (Std.isOfType(p, MNSLNode)) {
                params[pi] = execAtNode(p);
                continue;
            }

            if (Std.isOfType(p, MNSLNodeChildren)) {
                params[pi] = execAtBody(p);
                continue;
            }
        }

        var resPost = this.execAtNodePost(node);
        if (resPost != null) {
            changeTo(resPost);
        }

        return EnumTools.createByName(eNode, name, params);
    }

    /**
     * Run on the given node before the children are processed.
     * @param node The node to run on.
     * @param changeTo A function to change the node.
     */
    public function execAtNodePre(node: MNSLNode): Null<MNSLNode> {
        switch (node) {
            case FunctionCall(name, params, info):
                return FunctionCall(
                    'testing',
                    params.concat([
                        Identifier("ExtraArg", null)
                    ]),
                    info
                );

            default:
                return null;
        }
    }

    /**
     * Run on the given node after the children are processed.
     * @param node The node to run on.
     * @param changeTo A function to change the node.
     */
    public function execAtNodePost(node: MNSLNode): Null<MNSLNode> {
        return null;
    }

    /**
     * Run on the given body.
     * @param body The body to run on.
     */
    public function execAtBody(body: MNSLNodeChildren): MNSLNodeChildren {
        var newBody: MNSLNodeChildren = [];

        for (node in body) {
            newBody.push(this.execAtNode(node));
        }

        return newBody;
    }

    /**
     * Run the analysis.
     */
    public function run(): MNSLNodeChildren {
        return execAtBody(this._ast);
    }

}
