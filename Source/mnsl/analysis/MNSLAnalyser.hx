package mnsl.analysis;

import mnsl.parser.MNSLNodeChildren;
import mnsl.parser.MNSLNode;
import haxe.EnumTools.EnumValueTools;
import haxe.EnumTools;
import mnsl.parser.MNSLNodeInfo;
import mnsl.parser.MNSLShaderDataKind;

class MNSLAnalyser {

    private var _context: MNSLContext;
    private var _inputs: MNSLAnalyserVariable;
    private var _outputs: MNSLAnalyserVariable;
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

        this._inputs = {
            name: "input",
            type: MNSLType.TCTValue,
            struct: true,
            fields: []
        };

        this._outputs = {
            name: "output",
            type: MNSLType.TCTValue,
            struct: true,
            fields: [
                { name: "Position", type: MNSLType.TVec4 }
            ]
        };

        for (d in this._context.getShaderData()) {
            var toCat: MNSLAnalyserVariable = d.kind == MNSLShaderDataKind.Input || d.kind == MNSLShaderDataKind.Uniform ? this._inputs : this._outputs;
            toCat.fields.push({
                name: d.name,
                type: d.type
            });
        }

        this._globalCtx.variables.push(this._inputs);
        this._globalCtx.variables.push(this._outputs);
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

            case StructAccess(on, field, type, _):
                return type;

            case BinaryOp(left, op, right, type, _):
                return type;

            case UnaryOp(op, value, _):
                return getType(value);

            case SubExpression(value, _):
                return getType(value);

            case VectorConversion(on, fromComp, toComp):
                return MNSLType.fromString('Vec$toComp');

            case VectorCreation(comp, values, _):
                return MNSLType.fromString('Vec$comp');

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
            if (!arg.type.isDefined()) {
                arg.type.setType(MNSLType.TVoid);
                arg.type.setTempType(true);
            }

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
     * Get the MNSLAnalyserVariable from a node.
     */
    public function getVariableOf(node: MNSLNode, info: MNSLNodeInfo, ctx: MNSLAnalyserContext): MNSLAnalyserVariable {
        var structStck: Array<String> = [];

        function findName(node: MNSLNode): String {
            switch (node) {
                case Identifier(name, _, _):
                    return name;
                case StructAccess(on, field, type, info):
                    structStck.push(field);
                    return findName(on);
                default:
                    _context.emitError(AnalyserInvalidAccess(node));
                    return null;
            }
        }

        var currCtx = ctx;
        var currField = findName(node);
        var currName = currField;
        var accessOk: Bool = true;
        var v: MNSLAnalyserVariable = null;

        while (accessOk) {
            v = currCtx.findVariable(currField);
            if (v == null) {
                accessOk = false;
                break;
            }

            if (structStck.length <= 0) {
                break;
            }

            currField = structStck.pop();
            currName += "." + currField;

            currCtx = new MNSLAnalyserContext();
            currCtx.variables = currCtx.variables.concat(v.fields);
        }

        if (!accessOk) {
            _context.emitError(AnalyserUndeclaredVariable(currName, info));
            return null;
        }

        return v;
    }

    /**
     * Run on a variable assignment node (post)
     * @param node The variable assignment node to run on.
     * @param name The name of the variable.
     * @param value The value of the variable.
     */
    public function analyseVariableAssignPost(node: MNSLNode, on: MNSLNode, value: MNSLNode, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        var v = getVariableOf(on, info, ctx);
        if (v == null) {
            return node;
        }

        _solver.addConstraint({
            type: getType(value),
            mustBe: v.type,
            ofNode: value,
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
     * Run on a struct access node (post)
     * @param node The struct access node to run on.
     * @param on The node to access the struct from.
     * @param field The field to access.
     */
    public function analyseStructAccessPost(node: MNSLNode, on: MNSLNode, field: String, type: MNSLType, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        var v = getVariableOf(node, info, ctx);
        if (v == null) {
            return node;
        }

        _solver.addConstraint({
            type: v.type,
            mustBe: type,
            ofNode: node,
        });

        return node;
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
            type: f.returnType,
            mustBe: returnType,
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
     * Run on a vector creation node (post)
     * @param node The vector creation node to run on.
     * @param comp The component of the vector.
     * @param nodes The nodes to create the vector from.
     */
    public function analyseVectorCreationPost(node: MNSLNode, comp: Int, nodes: MNSLNodeChildren, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        if (comp > 4 || comp < 2) {
            _context.emitError(AnalyserInvalidVectorComponent(comp, info));
            return node;
        }

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

            case VariableAssign(on, value, info):
                return analyseVariableAssignPost(node, on, value, ctx, info);

            case Return(value, type, info):
                return analyseReturnPost(node, value, type, ctx, info);

            case StructAccess(on, field, type, info):
                return analyseStructAccessPost(node, on, field, type, ctx, info);

            case VectorCreation(comp, nodes, info):
                return analyseVectorCreationPost(node, comp, nodes, ctx, info);

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

    public function applyReplacements(body: MNSLNodeChildren, replacements: Array<MNSLReplaceCmd>): Void {
        for (i in 0...body.length) {
            body[i] = applyReplacementsToNode(body[i], replacements);
        }
    }

    private function applyReplacementsToNode(node: MNSLNode, replacements: Array<MNSLReplaceCmd>): MNSLNode {
        for (r in replacements) {
            if (r.node == node) {
                return r.to;
            }
        }

        if (node == null) {
            return null;
        }

        var e = Type.getEnum(node);

        var name = EnumValueTools.getName(node);
        var params = EnumValueTools.getParameters(node);
        var changed = false;

        for (i in 0...params.length) {
            var p: Dynamic = params[i];
            if (p == null) {
                continue;
            }

            if (Std.isOfType(p, MNSLNodeChildren) && p[0] != null && Std.isOfType(p[0], MNSLNode)) {
               this.applyReplacements(p, replacements);
            } else if (Std.isOfType(p, MNSLNode)) {
                var newP = applyReplacementsToNode(p, replacements);
                if (newP != p) {
                    params[i] = newP;
                    changed = true;
                }
            }
        }

        return changed ? Type.createEnum(e, name, params) : node;
    }

    /**
     * Run the analysis.
     */
    public function run(): MNSLNodeChildren {
        var res = execAtBody(this._ast, this._globalCtx);

        if (!this._solver.solve()) {
            var unresolvedConstraints = this._solver.getUnresolvedConstraints();
            for (c in unresolvedConstraints) {
                _context.emitError(AnalyserUnresolvedConstraint(c));
            }
        }

        var replacements = this._solver.getReplacements();
        this.applyReplacements(res, replacements);

        return res;
    }

}
