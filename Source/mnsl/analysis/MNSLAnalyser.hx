package mnsl.analysis;

import mnsl.parser.MNSLNodeChildren;
import mnsl.parser.MNSLNode;
import haxe.EnumTools.EnumValueTools;
import haxe.EnumTools;
import mnsl.parser.MNSLNodeInfo;
import mnsl.parser.MNSLShaderDataKind;
import mnsl.tokenizer.MNSLToken;

class MNSLAnalyser {

    private var _context: MNSLContext;
    private var _inputs: MNSLAnalyserVariable;
    private var _outputs: MNSLAnalyserVariable;
    private var _uniforms: MNSLAnalyserVariable;
    private var _functions: Array<MNSLAnalyserFunction>;
    private var _ast: MNSLNodeChildren;
    private var _globalCtx: MNSLAnalyserContext;
    private var _cpyStck: Array<String> = ["FunctionDecl", "WhileLoop", "ForLoop"];
    private var _types: Array<String> = [
        "Void", "Int", "Float", "Bool",
        "Vec2", "Vec3", "Vec4", "Mat2", "Mat3", "Mat4",
        "Sampler"
    ];
    private var _deferPostType: Array<Void -> Void> = [];
    private var _vectorAccess: Map<String, { comp: Int, char: String }> = [
        "x" => { comp: 0, char: "x" },
        "y" => { comp: 1, char: "y" },
        "z" => { comp: 2, char: "z" },
        "w" => { comp: 3, char: "w" },
        "r" => { comp: 0, char: "x" },
        "g" => { comp: 1, char: "y" },
        "b" => { comp: 2, char: "z" },
        "a" => { comp: 3, char: "w" }
    ];
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

        this._uniforms = {
            name: "uniform",
            type: MNSLType.TCTValue,
            struct: true,
            fields: []
        };

       this._functions = [
           {
               name: "texture",
               remap: "__mnsl_texture",
               args: [
                   { name: "sampler", type: MNSLType.TSampler },
                   { name: "texCoord", type: MNSLType.TVec2 },
               ],
               returnType: MNSLType.TVec4
           },
           {
               name: "sin",
               remap: "__mnsl_sin",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4, MNSLType.TMat2, MNSLType.TMat3, MNSLType.TMat4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4, MNSLType.TMat2, MNSLType.TMat3, MNSLType.TMat4])
           },
           {
               name: "cos",
               remap: "__mnsl_cos",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4, MNSLType.TMat2, MNSLType.TMat3, MNSLType.TMat4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4, MNSLType.TMat2, MNSLType.TMat3, MNSLType.TMat4])
           },
           {
               name: "tan",
               remap: "__mnsl_tan",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4, MNSLType.TMat2, MNSLType.TMat3, MNSLType.TMat4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4, MNSLType.TMat2, MNSLType.TMat3, MNSLType.TMat4])
           },
           {
               name: "normalize",
               remap: "__mnsl_normalize",
               args: [
                   { name: "v", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "dot",
               remap: "__mnsl_dot",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "y", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.TFloat
           },
           {
               name: "cross",
               remap: "__mnsl_cross",
               args: [
                   { name: "x", type: MNSLType.TVec3 },
                   { name: "y", type: MNSLType.TVec3 }
               ],
               returnType: MNSLType.TVec3
           },
           {
               name: "length",
               remap: "__mnsl_length",
               args: [
                   { name: "v", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.TFloat
           },
           {
               name: "reflect",
               remap: "__mnsl_reflect",
               args: [
                   { name: "I", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "N", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "refract",
               remap: "__mnsl_refract",
               args: [
                   { name: "I", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "N", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "eta", type: MNSLType.TFloat }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "pow",
               remap: "__mnsl_pow",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4, MNSLType.TFloat]) },
                   { name: "y", type: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4, MNSLType.TFloat]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4, MNSLType.TFloat])
           },
           {
               name: "exp",
               remap: "__mnsl_exp",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "log",
               remap: "__mnsl_log",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "sqrt",
               remap: "__mnsl_sqrt",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "abs",
               remap: "__mnsl_abs",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "clamp",
               remap: "__mnsl_clamp",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "minVal", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "maxVal", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "mix",
               remap: "__mnsl_mix",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "y", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "a", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "step",
               remap: "__mnsl_step",
               args: [
                   { name: "edge", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "smoothstep",
               remap: "__mnsl_smoothstep",
               args: [
                   { name: "edge0", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "edge1", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "max",
               remap: "__mnsl_max",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "y", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           },
           {
               name: "min",
               remap: "__mnsl_min",
               args: [
                   { name: "x", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) },
                   { name: "y", type: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4]) }
               ],
               returnType: MNSLType.Template("T", [MNSLType.TInt, MNSLType.TFloat, MNSLType.TVec2, MNSLType.TVec3, MNSLType.TVec4])
           }
       ];

        var varMap: Map<MNSLShaderDataKind, MNSLAnalyserVariable> = [
            MNSLShaderDataKind.Input => this._inputs,
            MNSLShaderDataKind.Output => this._outputs,
            MNSLShaderDataKind.Uniform => this._uniforms
        ];

        for (d in this._context.getShaderData()) {
            var toCat = varMap.get(d.kind);
            toCat.fields.push({
                name: d.name,
                type: d.type
            });
        }

        this._globalCtx.variables.push(this._inputs);
        this._globalCtx.variables.push(this._outputs);
        this._globalCtx.variables.push(this._uniforms);
        this._globalCtx.functions = this._globalCtx.functions.concat(this._functions);

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

            // hack to get properly functional function params
            if (name == "FunctionDecl") {
                var args: MNSLFuncArgs = params[2];
                for (arg in args) {
                    ctx.variables.push({
                        name: arg.name,
                        type: arg.type
                    });
                }
            }

            // hack to make continue; and break; work correctly
            if (name == "WhileLoop" || name == "ForLoop") {
                ctx.currentIsLoop = true;
            }
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

        this._solver.solve();

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
    public static function getType(node: MNSLNode): MNSLType {
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

            case TypeCast(on, from, to):
                return to;

            case SubExpression(value, _):
                return getType(value);

            case ArrayAccess(on, index, info):
                return getType(on);

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

            case BooleanLiteralNode(value, _):
                return MNSLType.TInt;

            case VoidNode(_):
                return MNSLType.TVoid;

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
     * Run on a variable declaration node (post`)
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

            currCtx = new MNSLAnalyserContext();
            currCtx.variables = currCtx.variables.concat(v.fields);

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
        switch (on) {
            case VectorCreation(comp, values, _):
                _solver.addConstraint({
                    type: getType(value),
                    mustBe: MNSLType.fromString('Vec$comp'),
                    ofNode: value,
                });

                var blockBody: Array<MNSLNode> = [];
                var componentOrder = ['x', 'y', 'z', 'w'];

                for (cIdx in 0...values.length) {
                    blockBody.push(VariableAssign(values[cIdx], StructAccess(value, componentOrder[cIdx], MNSLType.fromString('Vec$comp'), info), info));
                }

                return Block(blockBody, info);

            case StructAccess(accessOn, field, type, structInfo): // identifier will already be VectorCreation when using swizzling, thus this is only needed for 1 component.
                var t = getType(accessOn);
                if (t.isVector()) {
                    if (_vectorAccess.exists(field)) {
                        var vecAccess = _vectorAccess.get(field);
                        if (vecAccess.comp >= t.getVectorComponents()) {
                            _context.emitError(AnalyserInvalidVectorComponent(vecAccess.comp, info));
                            return node;
                        }

                        _solver.addConstraint({
                            type: getType(value),
                            mustBe: MNSLType.TFloat,
                            ofNode: value,
                        });

                        return VariableAssign(StructAccess(accessOn, _vectorAccess.get(field).char, type, structInfo), value, info);
                    } else {
                        _context.emitError(AnalyserUndeclaredVariable('VectorAccess($t.$field)', info));
                        return node;
                    }
                }

            default:
        }

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
        var t = getType(on);

        if (t.isDefined() && t.isVector()) {
            var parts = field.split("");
            if (parts.length == 1) {
                if (!_vectorAccess.exists(parts[0])) {
                    _context.emitError(AnalyserUndeclaredVariable('VectorAccess($t.$field)', info));
                    return node;
                }

                if (_vectorAccess.get(parts[0]).comp >= t.getVectorComponents()) {
                    _context.emitError(AnalyserInvalidVectorComponent(_vectorAccess.get(parts[0]).comp, info));
                    return node;
                }

                _solver.addConstraint({
                    type: type,
                    mustBe: MNSLType.TFloat,
                    ofNode: node,
                });

                return StructAccess(on, _vectorAccess.get(parts[0]).char, type, info);
            }

            var newComps: Array<MNSLNode> = [];
            for (c in parts) {
                if (!_vectorAccess.exists(c)) {
                    _context.emitError(AnalyserUndeclaredVariable('VectorAccess($t.$field)', info));
                    return node;
                }

                if (_vectorAccess.get(c).comp >= t.getVectorComponents()) {
                    _context.emitError(AnalyserInvalidVectorComponent(_vectorAccess.get(c).comp, info));
                    return node;
                }

                newComps.push(StructAccess(on, _vectorAccess.get(c).char, type, info));
            }

            _solver.addConstraint({
                type: type,
                mustBe: MNSLType.fromString('Vec${newComps.length}'),
                ofNode: node,
            });

            return VectorCreation(newComps.length, newComps, info);
        }

        var v = getVariableOf(node, info, ctx);
        if (v == null) {
            return node;
        }

        _solver.addConstraint({
            type: type,
            mustBe: v.type,
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

        var templates: Map<String, MNSLType> = [];
        for (i in 0...args.length) {
            var arg = args[i];
            var argType = getType(arg);

            if (f.args[i].type.isTemplate()) {
                if (!templates.exists(f.args[i].type.getTemplateName())) {
                    var t = MNSLType.TUnknown;
                    t.setLimits(f.args[i].type.getLimits());

                    templates.set(f.args[i].type.getTemplateName(), t);
                }

                _solver.addConstraint({
                    type: argType,
                    mustBe: templates.get(f.args[i].type.getTemplateName()),
                    ofNode: arg
                });

                continue;
            }

            _solver.addConstraint({
                type: argType,
                mustBe: f.args[i].type,
                ofNode: arg,
            });
        }

        if (f.returnType.isTemplate()) {
            if (!templates.exists(f.returnType.getTemplateName())) {
                templates.set(f.returnType.getTemplateName(), MNSLType.TUnknown);
            }

            _solver.addConstraint({
                type: returnType,
                mustBe: templates.get(f.returnType.getTemplateName()),
                ofNode: node,
            });
        } else {
            _solver.addConstraint({
                type: returnType,
                mustBe: f.returnType,
                ofNode: node,
            });
        }

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

        var newComp = 0;
        var newNodes: MNSLNodeChildren = [];
        for (arg in nodes) {
            var t = getType(arg);
            if (!t.isDefined()) {
                _context.emitError(AnalyserUnknownVectorComponent(arg, info));
                return node;
            }

            if (t.isVector()) {
                var compArr = ['x', 'y', 'z', 'w'];
                for (cIdx in 0...t.getVectorComponents()) {
                    if (cIdx < t.getVectorComponents()) {
                        newNodes.push(StructAccess(arg, compArr[cIdx], MNSLType.TFloat, info));
                        newComp++;
                    }
                }
            } else {
                newNodes.push(arg);
                newComp++;
            }
        }

        if (newComp != comp) {
            if (newComp < comp) {
                if (newComp == 1) {
                    while (newComp < comp) { // vecN(x) -> vecN(x, x, x, x)
                        newNodes.push(newNodes[0]);
                        newComp++;
                    }
                } else {
                    while (newComp < comp) { // vecN(x, y, z, w) -> vecN(x ?? 0.0, y ?? 0.0, z ?? 0.0, w ?? 1.0)
                        if (newComp == 3) newNodes.push(FloatLiteralNode("1.0", info));
                        else newNodes.push(FloatLiteralNode("0.0", info));

                        newComp++;
                    }
                }
            } else if (newComp > 4) { // allow vecN(vecN) truncation
                newNodes = newNodes.slice(0, 4);
                newComp = comp;
            }
        }

        if (newComp > 4 || newComp < 2) {
            _context.emitError(AnalyserInvalidVectorComponent(newComp, info));
            return node;
        }

        return VectorCreation(newComp, newNodes, info);
    }

    /**
     * Run on a binary operation node (post)
     * @param node The binary operation node to run on.
     * @param left The left operand of the binary operation.
     * @param op The operator of the binary operation.
     * @param right The right operand of the binary operation.
     */
    public function analyseBinaryOpPost(node: MNSLNode, left: MNSLNode, op: MNSLToken, right: MNSLNode, type: MNSLType, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        var leftType = getType(left);
        var rightType = getType(right);

        var opName: String = switch(op) {
            case Minus(_):
                "-";
            case Plus(_):
                "+";
            case Slash(_):
                "/";
            case Star(_):
                "*";
            case Percent(_):
                "%";
            case Question(_):
                "?";
            case Equal(_):
                "=";
            case Colon(_):
                ":";
            case Spread(_):
                "...";
            case And(_):
                "&&";
            case Or(_):
                "||";
            case Less(_):
                "<";
            case Greater(_):
                ">";
            case LessEqual(_):
                "<=";
            case GreaterEqual(_):
                ">=";
            case NotEqual(_):
                "!=";
            case Not(_):
                "!";
            default:
                "<->";
        }

         _solver.addConstraint({
             type: rightType,
             mustBe: leftType,
             ofNode: right,
             _operationOperator: opName,
             _isBinaryOp: true,
             _optional: true
         });

        _solver.addConstraint({
            type: leftType,
            mustBe: rightType,
            ofNode: left,
            _operationOperator: opName,
            _isBinaryOp: true,
            _optional: true
        });

        var resType = switch(op) {
            case Equal(_): MNSLType.TBool;
            case NotEqual(_): MNSLType.TBool;
            case Less(_): MNSLType.TBool;
            case Greater(_): MNSLType.TBool;
            case LessEqual(_): MNSLType.TBool;
            case GreaterEqual(_): MNSLType.TBool;
            case And(_): MNSLType.TBool;
            case Or(_): MNSLType.TBool;
            case Slash (_): rightType.isInt() ? MNSLType.TFloat : rightType;
            default: rightType;
        };

        _solver.addConstraint({
            type: type,
            mustBe: resType,
            ofNode: node,
            _mustBeOfNode: right
        });

        return node;
    }

    /**
     * Run on a conditional node (post)
     * @param node The conditional node to run on.
     * @param cond The condition of the conditional node.
     * @param body The body of the conditional node.
     */
    public function analyseConditionalPost(node: MNSLNode, cond: MNSLNode, body: MNSLNodeChildren, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        _solver.addConstraint({
            type: getType(cond),
            mustBe: MNSLType.TBool,
            ofNode: cond,
        });

        return node;
    }

    /**
     * Run on a unary operation node (post)
     * @param node The unary operation node to run on.
     * @param op The operator of the unary operation.
     * @param value The value of the unary operation.
     */
    public function analyseUnaryOpPost(node: MNSLNode, op: MNSLToken, value: MNSLNode, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        var isAllowed = switch(op) {
            case Not(_): true;
            case Minus(_): true;
            case Plus(_): true;
            default: false;
        };

        if (!isAllowed) {
            _context.emitError(AnalyserInvalidUnaryOp(op, info));
            return node;
        }

        return node;
    }

    /**
     * Run on a loop keyword node (post)
     * @param node The loop keyword node to run on.
     */
    public function analyseLoopKeyword(node: MNSLNode, ctx: MNSLAnalyserContext, info: MNSLNodeInfo): MNSLNode {
        if (!ctx.currentIsLoop) {
            _context.emitError(AnalyserLoopKeywordOutsideLoop(node, info));
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

            case BinaryOp(left, op, right, type, info):
                return analyseBinaryOpPost(node, left, op, right, type, ctx, info);

            case UnaryOp(op, value, info):
                return analyseUnaryOpPost(node, op, value, ctx, info);

            case IfStatement(cond, body, info):
                return analyseConditionalPost(node, cond, body, ctx, info);

            case ElseIfStatement(cond, body, info):
                return analyseConditionalPost(node, cond, body, ctx, info);

            case WhileLoop(cond, body, info):
                return analyseConditionalPost(node, cond, body, ctx, info);

            case ForLoop(init, condition, increment, body, info):
                return analyseConditionalPost(node, condition, body, ctx, info);

            case Continue(info):
                return analyseLoopKeyword(node, ctx, info);

            case Break(info):
                return analyseLoopKeyword(node, ctx, info);

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
     * Applies replacements to the body.
     * @param body The body to apply replacements to.
     * @param replacements The replacements to apply.
     */
    public function applyReplacements(body: MNSLNodeChildren, replacements: Array<MNSLReplaceCmd>, exceptions: Array<MNSLNode>) {
        body = body.copy();
        for (i in 0...body.length) {
            body[i] = applyReplacementsToNode(body[i], replacements, exceptions);
        }
        return body;
    }

    /**
     * Check the type validity of a node.
     */
    public function checkTypeValidity(node: MNSLNode): Void {
        var t = getType(node);
        if (t.isDefined() && !_types.contains(t.toString())) {
            _context.emitError(AnalyserUnknownType(t, node));
            return;
        }
    }

    /**
     * Applies replacements to a single node.
     * @param node The node to apply replacements to.
     * @param replacements The replacements to apply.
     * @return The new node after applying the replacements.
     */
    private function applyReplacementsToNode(node: MNSLNode, replacements: Array<MNSLReplaceCmd>, exceptions: Array<MNSLNode>): MNSLNode {
        exceptions = exceptions.copy();

        for (e in exceptions) {
            if (Type.enumEq(e, node)) return node;
        }

         for (r in replacements) {
            if (r.node == node) {
                exceptions.push(node);
                node = r.to;
            }
         }

        if (node == null) {
            checkTypeValidity(node);
            return null;
        }

        var e = Type.getEnum(node);

        var name = EnumValueTools.getName(node);
        var params = EnumValueTools.getParameters(node);

        for (i in 0...params.length) {
            var p: Dynamic = params[i];
            if (p == null) {
                continue;
            }

            if (Std.isOfType(p, MNSLNodeChildren) && p[0] != null && Std.isOfType(p[0], MNSLNode)) {
                params[i] = applyReplacements(p, replacements, exceptions);
            } else if (Std.isOfType(p, MNSLNode)) {
                params[i] = applyReplacementsToNode(p, replacements, exceptions);
            }
        }

        var resNode = Type.createEnum(e, name, params);
        checkTypeValidity(resNode);

        return resNode;
    }

    /**
     * Defer something to be run after the analysis is done.
     */
    public function deferPostType(f: Void -> Void): Void {
        this._deferPostType.push(f);
    }

    /**
     * Check branches for missing return statements.
     */
    public function checkBranchesOnBody(body: MNSLNodeChildren, inFunction: Null<MNSLAnalyserFunction>) {
        if (inFunction == null) {
            for (node in body) {
                checkBranchesOnNode(node, inFunction);
            }
            return;
        }

        if (inFunction.returnType.equals(MNSLType.TVoid)) {
            for (node in body) {
                checkBranchesOnNode(node, inFunction);
            }
            return;
        }

        for (node in body) {
            checkBranchesOnNode(node, inFunction);
        }
    }

    /**
     * Check branches for missing return statements.
     */
    public function checkBranchesOnNode(node: MNSLNode, inFunction: Null<MNSLAnalyserFunction>) {
        if (node == null) return;

        switch (node) {
            case FunctionDecl(name, returnType, args, body, info):
                var func: MNSLAnalyserFunction = {
                    name: name,
                    returnType: returnType,
                    args: args,
                    hasImplementation: true
                };

                if (!func.returnType.equals(MNSLType.TVoid) && !bodyHasReturn(body)) {
                    _context.emitError(AnalyserMissingReturn(func, body));
                }

                checkBranchesOnBody(body, func);

            case IfStatement(cond, body, info):
                checkBranchesOnBody(body, inFunction);

            case ElseStatement(body, info):
                checkBranchesOnBody(body, inFunction);

            case ElseIfStatement(cond, body, info):
                checkBranchesOnBody(body, inFunction);

            case WhileLoop(cond, body, info):
                checkBranchesOnBody(body, inFunction);

            case ForLoop(init, condition, increment, body, info):
                checkBranchesOnBody(body, inFunction);

            case Block(body, info):
                checkBranchesOnBody(body, inFunction);

            default:
                var params = EnumValueTools.getParameters(node);
                for (p in 0...params.length) {
                    var pNode: Dynamic = params[p];
                    if (pNode == null) continue;

                    if (Std.isOfType(pNode, MNSLNodeChildren) && pNode[0] != null && Std.isOfType(pNode[0], MNSLNode)) {
                        checkBranchesOnBody(pNode, inFunction);
                    } else if (Std.isOfType(pNode, MNSLNode)) {
                        checkBranchesOnNode(pNode, inFunction);
                    }
                }
        }
    }

    /**
     * function to check if a body has a guaranteed return path
     */
    private function bodyHasReturn(body: MNSLNodeChildren): Bool {
        var i = 0;
        while (i < body.length) {
            var node = body[i];

            switch (node) {
                case Return(_, _, _):
                    return true;

                case IfStatement(cond, ifBody, info):
                    var ifHasReturn = bodyHasReturn(ifBody);
                    var hasElse = false;
                    var allBranchesReturn = ifHasReturn;

                    var j = i + 1;
                    while (j < body.length) {
                        switch (body[j]) {
                            case ElseIfStatement(elseCond, elseIfBody, _):
                                var elseIfHasReturn = bodyHasReturn(elseIfBody);
                                allBranchesReturn = allBranchesReturn && elseIfHasReturn;
                                j++;

                            case ElseStatement(elseBody, _):
                                hasElse = true;
                                var elseHasReturn = bodyHasReturn(elseBody);
                                allBranchesReturn = allBranchesReturn && elseHasReturn;
                                j++;
                                break;

                            default:
                                break;
                        }
                    }

                    if (hasElse && allBranchesReturn) {
                        return true;
                    }

                    i = j;
                    continue;

                case ElseIfStatement(_, _, _):
                    i++;
                    continue;

                case ElseStatement(_, _):
                    i++;
                    continue;

                case Block(blockBody, _):
                    if (bodyHasReturn(blockBody)) {
                        return true;
                    }

                default:
            }

            i++;
        }

        return false;
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
        res = this.applyReplacements(res, replacements, []);

        for (f in this._deferPostType) {
            f();
        }

        this.checkBranchesOnBody(res, null);

        return res;
    }

}
