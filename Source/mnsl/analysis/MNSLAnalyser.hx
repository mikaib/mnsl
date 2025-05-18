package mnsl.analysis;

import mnsl.parser.MNSLNodeChildren;
import mnsl.parser.MNSLNode;
import haxe.EnumTools.EnumValueTools;
import haxe.EnumTools;
import mnsl.parser.MNSLNodeInfo;

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

        var resPre = this.execAtNodePre(node, ctx);
        if (resPre != null) {
            name = EnumValueTools.getName(resPre);
            params = EnumValueTools.getParameters(resPre);
            node = resPre;
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

        node = Type.createEnum(eNode, name, params);

        var resPost = this.execAtNodePost(node, ctx);
        if (resPost != null) {
            name = EnumValueTools.getName(resPost);
            params = EnumValueTools.getParameters(resPost);
            node = resPost;
        }

        return node;
    }

    /**
     * Run on the given node before the children are processed.
     * @param node The node to run on.
     * @param changeTo A function to change the node.
     */
    public function execAtNodePre(node: MNSLNode, ctx: MNSLAnalyserContext): Null<MNSLNode> {
        switch (node) {
            case FunctionDecl(name, returnType, args, _, info):
                return analyseFunctionDeclPre(node, name, returnType, args, ctx, info);

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

            case BinaryOp(left, op, right, type, _):
                return type;

            case UnaryOp(op, value, _):
                return getType(value);

            case SubExpression(value, _):
                return getType(value);

            case IntegerLiteralNode(value, _):
                return MNSLType.TInt;

            case FloatLiteralNode(value, _):
                return MNSLType.TFloat;

            case StringLiteralNode(value, _):
                return MNSLType.TString;

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
    public function analyseFunctionDeclPre(node: MNSLNode, name: String, returnType: MNSLType, args: MNSLFuncArgs, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        if (!returnType.isDefined()) {
            returnType.setType(MNSLType.TVoid);
            returnType.setTempType(true);
        }

        for (arg in args) {
            if (arg.type.isDefined()) continue;

            arg.type.setType(MNSLType.TVoid);
            arg.type.setTempType(true);

            ctx.variables.push({
                name: arg.name,
                type: arg.type
            });
        }

        var f: MNSLAnalyserFunction = {
            name: name,
            returnType: returnType,
            args: args,
            hasImplementation: true
        };

        ctx.functions.push(f);
        ctx.currentFunction = f;

        return node;
    }

    /**
     * Run on a variable declaration node (post)
     * @param node The variable declaration node to run on.
     * @param name The name of the variable.
     * @param type The type of the variable.
     * @param value The value of the variable.
     */
    public function analyseVariableDeclPost(node: MNSLNode, name: String, type: MNSLType, value: MNSLNode, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        if (ctx.findVariable(name) != null) {
            _context.emitError(AnalyserDuplicateVariable(name, info));
            return node;
        }

        _solver.addConstraint({
            type: getType(value),
            mustBe: type,
            ofNode: value,
        });

        ctx.variables.push({
            name: name,
            type: type
        });

        return node;
    }

    /**
     * Run on an identifier node (post)
     * @param node The identifier node to run on.
     * @param name The name of the identifier.
     * @param type The type of the identifier.
     */
    public function analyseIdentifierPost(node: MNSLNode, name: String, type: MNSLType, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        var v = ctx.findVariable(name);
        if (v == null) {
            _context.emitError(AnalyserUndeclaredVariable(name, info));
            return node;
        }

        return Identifier(name, v.type, info);
    }

    /**
     * Run on a function call (post)
     * @param node The function call node to run on.
     * @param name The name of the function.
     * @param args The arguments of the function.
     * @param ctx The context of the function.
     * @return The function call node.
     */
    public function analyseFunctionCallPost(node: MNSLNode, name: String, args: MNSLNodeChildren, returnType: MNSLType, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        var f = ctx.findFunction(name, args.map(x -> getType(x)), true);
        if (f == null) {
            _context.emitError(AnalyserNoImplementation({
                name: name,
                args: args.map(x -> new MNSLFuncArg("", getType(x))),
                returnType: returnType,
            }, info));
            return node;
        }

        for (i in 0...args.length) {
            var arg = args[i];
            var argType = getType(arg);

            _solver.addConstraint({
                type: argType,
                mustBe: f.args[i].type,
                ofNode: arg,
            });
        }

        _solver.addConstraint({
            type: returnType,
            mustBe: f.returnType,
            ofNode: node,
        });

        return node;
    }

    /**
     * Run on a return node (post)
     * @param node The return node to run on.
     * @param value The value of the return node.
     */
    public function analyseReturnPost(node: MNSLNode, value: MNSLNode, type: MNSLType, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        if (ctx.currentFunction == null) {
            _context.emitError(AnalyserReturnOutsideFunction(info));
            return node;
        }

        _solver.addConstraint({
            type: getType(value),
            mustBe: ctx.currentFunction.returnType,
            ofNode: value,
        });

        return node;
    }

    /**
     * Run on the given node after the children are processed.
     * @param node The node to run on.
     * @param changeTo A function to change the node.
     */
    public function execAtNodePost(node: MNSLNode, ctx: MNSLAnalyserContext): Null<MNSLNode> {
        switch (node) {
            case FunctionCall(name, args, returnType, info):
                return analyseFunctionCallPost(node, name, args, returnType, ctx, info);

            case Identifier(name, type, info):
                return analyseIdentifierPost(node, name, type, ctx, info);

            case VariableDecl(name, type, value, info):
                return analyseVariableDeclPost(node, name, type, value, ctx, info);

            case Return(value, type, info):
                return analyseReturnPost(node, value, type, ctx, info);

            default:
                return node;
        }
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
        var res = execAtBody(this._ast, this._globalCtx);
        this._solver.solve();

        return res;
    }

}
