package mnsl.analysis;

import mnsl.parser.MNSLNodeChildren;
import mnsl.parser.MNSLNode;
import haxe.EnumTools.EnumValueTools;
import haxe.EnumTools;

class MNSLAnalyser {

    private var _context: MNSLContext;
    private var _ast: MNSLNodeChildren;
    private var _globalCtx: MNSLAnalyserContext;
    private var _cpyStck: Array<String> = ["FunctionDecl"];
    private var _solver: MNSLSolver;

    /**
     * Create a new analyser.
     */
    public function new(context: MNSLContext, ast: MNSLNodeChildren) {
        this._context = context;
        this._ast = ast;
        this._globalCtx = new MNSLAnalyserContext();
        this._solver = new MNSLSolver(context);
    }

    /**
     * Run on a given node.
     * @param node The node to run on.
     */
    public function execAtNode(node: MNSLNode, ctx: MNSLAnalyserContext): MNSLNode {
        if (node == null) {
            return null;
        }

        var eNode = Type.getEnum(node);
        var name = EnumValueTools.getName(node);
        var params: Array<Dynamic> = EnumValueTools.getParameters(node);

        var changeTo = (node: MNSLNode) -> {
            name = EnumValueTools.getName(node);
            params = EnumValueTools.getParameters(node);
        };

        var resPre = this.execAtNodePre(node, ctx);
        if (resPre != null) {
            changeTo(resPre);
        }

        if (_cpyStck.contains(name)) {
            ctx = ctx.copy();
        }

        for (pi in 0...params.length) {
            var p: Dynamic = params[pi];

            if (Std.isOfType(p, MNSLNode)) {
                params[pi] = execAtNode(p, ctx);
                continue;
            }

            if (Std.isOfType(p, MNSLNodeChildren) && p[0] != null && Std.isOfType(p[0], MNSLNode)) {
                params[pi] = execAtBody(p, ctx);
                continue;
            }
        }

        var resPost = this.execAtNodePost(node, ctx);
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
    public function execAtNodePre(node: MNSLNode, ctx: MNSLAnalyserContext): Null<MNSLNode> {
        switch (node) {
            case FunctionDecl(name, returnType, args, _, _):
                return analyseFunctionDeclPre(node, name, returnType, args, ctx);

            case FunctionCall(name, args, returnType, _):
                return analyseFunctionCallPre(node, name, args, returnType, ctx);

            default:
                return node;
        }
    }

    /**
     * Get the type of a specific node (if available).
     */
    public function getType(node: MNSLNode): MNSLType {
        if (node == null) {
            return MNSLType.TUnknown;
        }

        switch (node) {
            case FunctionDecl(name, returnType, args, _, _):
                return returnType;

            case FunctionCall(name, args, returnType, _):
                return returnType;

            case Return(value, _):
                return getType(value);

            case VariableDecl(name, type, value, _):
                return type;

            case Identifier (name, type, _):
                return type;

            case BinaryOp(left, op, right, _):
                var leftType = getType(left);
                var rightType = getType(right);
                var resType = MNSLType.TUnknown;

                _solver.addConstraint({
                    type: leftType,
                    ofNode: left,
                    mustBe: rightType
                });

                _solver.addConstraint({
                    type: resType,
                    ofNode: null,
                    mustBe: leftType
                });

                return resType;

            case UnaryOp(op, value, _):
                return getType(value);

            case SubExpression(value, _):
                return getType(value);

            case IntegerLiteralNode(value, _):
                return MNSLType.TInt32;

            case FloatLiteralNode(value, _):
                return MNSLType.TFloat32;

            default:
                return MNSLType.TUnknown;
        }
    }

    /**
     * Run on a function node (pre)
     * @param node The function node to run on.
     * @param returnType The return type of the function.
     * @param args The arguments of the function.
     */
    public function analyseFunctionDeclPre(node: MNSLNode, name: String, returnType: MNSLType, args: MNSLFuncArgs, ctx: MNSLAnalyserContext): MNSLNode {
        if (!returnType.isDefined()) {
            returnType.setType(MNSLType.TVoid);
            returnType.setTempType(true);
        }

        for (arg in args) {
            if (arg.type.isDefined()) continue;

            arg.type.setType(MNSLType.TVoid);
            arg.type.setTempType(true);
        }

        ctx.functions.push({
            name: name,
            returnType: returnType,
            args: args,
            hasImplementation: true
        });

        return node;
    }

    /**
     * Run on a function call (pre)
     * @param node The function call node to run on.
     * @param name The name of the function.
     * @param args The arguments of the function.
     * @param ctx The context of the function.
     * @return The function call node.
     */
    public function analyseFunctionCallPre(node: MNSLNode, name: String, args: MNSLNodeChildren, returnType: MNSLType, ctx: MNSLAnalyserContext): MNSLNode {
        var f = ctx.findFunctions(name, args.map(x -> getType(x)), true);
        if (f.length <= 0) {
            _context.emitError(AnalyserNoImplementation({
                name: name,
                args: args.map(x -> new MNSLFuncArg("", getType(x))),
                returnType: returnType
            }));
            return node;
        }

        returnType.setType(f[0].returnType);

        return node;
    }

    /**
     * Run on the given node after the children are processed.
     * @param node The node to run on.
     * @param changeTo A function to change the node.
     */
    public function execAtNodePost(node: MNSLNode, ctx: MNSLAnalyserContext): Null<MNSLNode> {
        return node;
    }

    /**
     * Run on the given body.
     * @param body The body to run on.
     */
    public function execAtBody(body: MNSLNodeChildren, ctx: MNSLAnalyserContext): MNSLNodeChildren {
        var newBody: MNSLNodeChildren = [];

        for (node in body) {
            newBody.push(this.execAtNode(node, ctx));
        }

        return newBody;
    }

    /**
     * Run the analysis.
     */
    public function run(): MNSLNodeChildren {
        MNSLAnalyserContext.reset();
        var res = execAtBody(this._ast, this._globalCtx);
        this._solver.solve();
        MNSLAnalyserContext.validate(this._context);

        return res;
    }

}
