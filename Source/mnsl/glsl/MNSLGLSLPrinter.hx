package mnsl.glsl;

import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeChildren;
import mnsl.tokenizer.MNSLToken;
import mnsl.parser.MNSLShaderDataKind;
import mnsl.parser.MNSLParser;

class MNSLGLSLPrinter extends MNSLPrinter {

    private var _config: MNSLGLSLConfig;

    private var _types: Map<String, String> = [
        "Void" => "void",
        "Int32" => "int",
        "Float32" => "float",
        "Vec2" => "vec2",
        "Vec3" => "vec3",
        "Vec4" => "vec4",
        "Mat2" => "mat2",
        "Mat3" => "mat3",
        "Mat4" => "mat4",
        "Bool" => "bool",
        "Sampler" => "sampler2D",
        "CubeSampler" => "samplerCube",
    ];

    private var _internalOutputStruct: Map<String, String> = [
        "Position" => "gl_Position",
        "PointSize" => "gl_PointSize",
    ];

    private var _internalInputStruct: Map<String, String> = [
        "VertexID" => "gl_VertexID",
        "InstanceID" => "gl_InstanceID",
        "BaseVertex" => "gl_BaseVertex",
        "BaseInstance" => "gl_BaseInstance",
        "FragCoord" => "gl_FragCoord",
        "FrontFacing" => "gl_FrontFacing",
        "FragDepth" => "gl_FragDepth",
    ];

    /**
     * Create a new GLSL printer.
     * @param context The MNSL context.
     * @param config The GLSL configuration.
     */
    public function new(context: MNSLContext, config: MNSLGLSLConfig) {
        super(context);
        this._config = config;

        var versionInt: Int = config.version;
        config.useAttributeAndVaryingKeywords = config.useAttributeAndVaryingKeywords ?? (versionInt < 130);
    }

    /**
     * Print a MNSLNodeChildren object
     * @param node The node to print.
     */
    public function printNodeChildren(children: MNSLNodeChildren): Void {
        for (child in children) {
            printNode(child);
        }
    }

    /**
     * Print a MNSLNode object
     * @param node The node to print.
     */
    public function printNode(node: MNSLNode): Void {
        if (node == null) {
            return;
        }

        switch (node) {
            case FunctionDecl(name, returnType, arguments, body, info):
                printlnIndented(
                    "{0} {1}({2}) {",
                    _types.get(returnType.toString()),
                    name,
                    arguments
                        .map(arg -> _types.get(arg.type.toString()) + " " + arg.name)
                        .join(", ")
                );
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}\n");

            case FunctionCall(name, args, info):
                printIndented("{0}(", name);

                for (arg in args) {
                    printNode(arg);
                    if (arg != args[args.length - 1]) {
                        print(", ");
                    }
                }

                println(")" + (_inline ? "" : ";"));

            case VariableDecl(name, type, value, info):
                if (value == null) {
                    printlnIndented("{0} {1};", _types.get(type.toString()), name);
                } else {
                    printIndented("{0} {1} = ", _types.get(type.toString()), name);
                    enableInline();
                    printNode(value);
                    disableInline();
                    removeLastSemicolon();
                    println(";");
                }

            case IfStatement(condition, body, info):
                printIndented("if (");
                printNode(condition);
                println(") {");
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}");

            case ElseIfStatement (condition, body, info):
                removeLastNewLine();
                print(" else if (");
                printNode(condition);
                println(") {");
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}");

            case ElseStatement(body, info):
                removeLastNewLine();
                println(" else {");
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}");

            case VariableAssign(name, value, info):
                printIndented("");
                printNode(name);
                print(" = ");
                enableInline();
                printNode(value);
                disableInline();
                removeLastSemicolon();
                println(";");

            case Return(node, type, info):
                printIndented("return ");
                if (node != null) {
                    printNode(node);
                }
                println(";");

            case BinaryOp(left, op, right, info):
                printNode(left);
                print(" " + toOperationStr(op) + " ");
                printNode(right);

            case UnaryOp(op, node, info):
                print(toOperationStr(op));
                printNode(node);

            case WhileLoop (condition, body, info):
                printIndented("while (");
                printNode(condition);
                println(") {");
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}");

            case ForLoop (init, condition, increment, body, info):
                printIndented("for (");
                enableInline();
                if (init != null) {
                    trace("init", init);
                    printNode(init);
                }
                removeLastSemicolon();
                print("; ");
                if (condition != null) {
                    trace("condition", condition);
                    printNode(condition);
                }
                removeLastSemicolon();
                print("; ");
                if (increment != null) {
                    trace("increment", increment);
                    printNode(increment);
                }
                removeLastSemicolon();
                disableInline();
                println(") {");
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}");

            case IntegerLiteralNode(value, info):
                print(value);

            case FloatLiteralNode(value, info):
                print(value);

            case Identifier (name, info):
                print(name);

            case Break (info):
                printlnIndented("break;");

            case Continue (info):
                printlnIndented("continue;");

            case SubExpression(node, info):
                print("(");
                printNode(node);
                print(")");

            case ArrayAccess(on, index, info):
                printNode(on);
                print("[");
                printNode(index);
                print("]");

            case StructAccess(on, field, info):
                if (on.match(Identifier("output", _))) {
                    if (_internalOutputStruct.exists(field)) {
                        print(_internalOutputStruct.get(field));
                        return;
                    }

                    for (data in _context.getShaderData()) {
                        if (data.name == field && data.kind == MNSLShaderDataKind.Output) {
                            print("out_" + data.name);
                            return;
                        }
                    }
                }

                if (on.match(Identifier("input", _))) {
                    if (_internalInputStruct.exists(field)) {
                        print(_internalInputStruct.get(field));
                        return;
                    }

                    for (data in _context.getShaderData()) {
                        if (data.name == field) {
                            print((data.kind == MNSLShaderDataKind.Uniform ? "u_" : "in_") + data.name);
                            return;
                        }
                    }
                }

                printNode(on);
                print(".");
                print(field);

            default:
                throw "Unknown node type: " + node;
        }
    }

    /**
     * Convert an operation to a string.
     * @param op The token representing the operation.
     * @return The string representation of the operation.
     */
    private function toOperationStr(op: MNSLToken): String {
        switch (op) {
            case MNSLToken.Plus(_):
                return "+";
            case MNSLToken.Minus(_):
                return "-";
            case MNSLToken.Star(_):
                return "*";
            case MNSLToken.Slash(_):
                return "/";
            case MNSLToken.Percent(_):
                return "%";
            case MNSLToken.Equal(_):
                return "==";
            case MNSLToken.NotEqual(_):
                return "!=";
            case MNSLToken.Greater(_):
                return ">";
            case MNSLToken.GreaterEqual(_):
                return ">=";
            case MNSLToken.Less(_):
                return "<";
            case MNSLToken.LessEqual(_):
                return "<=";
            case MNSLToken.And(_):
                return "&&";
            case MNSLToken.Or(_):
                return "||";
            case MNSLToken.Not(_):
                return "!";
            default:
                throw "Unknown operation: " + op;
        }
    }

    /**
     * Runs the printer.
     */
    override public function run():Void {
        println("#version {0} core", _config.version);
        println("");

        for (data in _context.getShaderData()) {
            switch (data.kind) {
                case MNSLShaderDataKind.Input:
                    if (_config.useAttributeAndVaryingKeywords) {
                        println("attribute {0} in_{1};", _types.get(data.type.toString()), data.name);
                    } else {
                        println("in {0} in_{1};", _types.get(data.type.toString()), data.name);
                    }

                case MNSLShaderDataKind.Output:
                    if (_config.useAttributeAndVaryingKeywords) {
                        println("varying {0} out_{1};", _types.get(data.type.toString()), data.name);
                    } else {
                        println("out {0} out_{1};", _types.get(data.type.toString()), data.name);
                    }

                case MNSLShaderDataKind.Uniform:
                    if (data.arraySize != -1) {
                        println("uniform {0} u_{1}[{2}];", _types.get(data.type.toString()), data.name, data.arraySize);
                    } else {
                        println("uniform {0} u_{1};", _types.get(data.type.toString()), data.name);
                    }
            }
        }

        if (_context.getShaderData().length > 0) {
            println("");
        }

        printNodeChildren(_ast);
    }

}
