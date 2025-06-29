package mnsl.glsl;

import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeChildren;
import mnsl.tokenizer.MNSLToken;
import mnsl.parser.MNSLShaderDataKind;
import mnsl.analysis.MNSLType;

class MNSLGLSLPrinter extends MNSLPrinter {

    private var _config: MNSLGLSLConfig;
    private var _prefixes = {
        input: "in_",
        output: "out_",
        uniform: "u_"
    };

    private var _types: Map<String, String> = [
        "Void" => "void",
        "Int" => "int",
        "Float" => "float",
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

    private var _defaultPrecision: Map<String, String> = [
        "float" => "mediump",
        "int"   => "mediump"
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
        config.usePrecision = config.usePrecision ?? (config.versionDirective == GLSL_ES);

        switch (config.shaderType) {
            case GLSL_SHADER_TYPE_VERTEX:
                _prefixes.input = "in_";
                _prefixes.output = "frag_";
            case GLSL_SHADER_TYPE_FRAGMENT:
                _prefixes.input = "frag_";
                _prefixes.output = "out_";
        }
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
                   returnType.isArray() ? '${getTypeStr(returnType)}[${returnType.getArraySize()}]' : getTypeStr(returnType),
                    name,
                    arguments
                        .map(arg -> getTypeStr(arg.type) + " " + arg.name + (arg.type.isArray() ? '[${arg.type.getArraySize()}]' : ""))
                        .join(", ")
                );
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}\n");

            case FunctionCall(name, args, type, info):
                printIndented("{0}(", name);

                for (arg in args) {
                    printNode(arg);
                    if (arg != args[args.length - 1]) {
                        print(", ");
                    }
                }

                println(")" + (_sameLine ? "" : ";"));

            case VariableDecl(name, type, value, info):
                if (value == null) {
                    printlnIndented("{0} {1};", getTypeStr(type), name + (type.isArray() ? '[${type.getArraySize()}]' : ""));
                } else {
                    printIndented("{0} {1} = ", getTypeStr(type), name + (type.isArray() ? '[${type.getArraySize()}]' : ""));
                    enableInline();
                    printNode(value);
                    disableInline();
                    removeLastSemicolon();
                    println(";");
                }

            case IfStatement(condition, body, info):
                printIndented("if (");
                enableInline();
                printNode(condition);
                disableInline();
                println(") {");
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}");

            case VoidNode(info):
                return;

            case ElseIfStatement (condition, body, info):
                removeLastNewLine();
                print(" else if (");
                enableInline();
                printNode(condition);
                disableInline();
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

            case BooleanLiteralNode(value, info):
                print(value ? "1" : "0");

            case Return(node, type, info):
                var nodeIsVoid = (node == null || node.match(VoidNode(_)));
                printIndented('return${nodeIsVoid ? "" : " "}');
                if (node != null) {
                    enableInline();
                    printNode(node);
                    disableInline();
                }
                println(";");

            case BinaryOp(left, op, right, type, info):
                enableInline();
                printNode(left);
                print(" " + toOperationStr(op) + " ");
                printNode(right);
                disableInline();

            case UnaryOp(op, node, info):
                enableInline();
                print(toOperationStr(op));
                printNode(node);
                disableInline();

            case WhileLoop (condition, body, info):
                printIndented("while (");
                enableInline();
                printNode(condition);
                disableInline();
                println(") {");
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}");

            case ForLoop (init, condition, increment, body, info):
                printIndented("for (");
                enableInline();
                if (init != null) {
                    printNode(init);
                }
                removeLastSemicolon();
                print("; ");
                if (condition != null) {
                    printNode(condition);
                }
                removeLastSemicolon();
                print("; ");
                if (increment != null) {
                    printNode(increment);
                }
                removeLastSemicolon();
                disableInline();
                println(") {");
                increaseIndent();
                printNodeChildren(body);
                decreaseIndent();
                printlnIndented("}");

            case VectorConversion(node, fromComp, toComp):
                if (fromComp == toComp) {
                    enableInline();
                    printNode(node);
                    disableInline();
                } else if (fromComp < toComp) {
                    print("vec");
                    print('$toComp');
                    print("(");
                    enableInline();
                    printNode(node);
                    disableInline();

                    for (i in fromComp ... toComp) {
                        print(", ");
                        if (i == 2)
                            print("0.0");
                        else
                            print("1.0");
                    }

                    print(")");
                } else {
                    print("vec");
                    print('$toComp');
                    print("(");
                    enableInline();
                    printNode(node);
                    disableInline();
                    print(")");
                }

            case VectorCreation(components, nodes, info):
                print("vec");
                print('$components');
                print("(");

                for (i in 0 ... nodes.length) {
                    enableInline();
                    printNode(nodes[i]);
                    disableInline();
                    if (i < nodes.length - 1) {
                        print(", ");
                    }
                }

                print(")");

            case IntegerLiteralNode(value, info):
                print(value);

            case FloatLiteralNode(value, info):
                print(value);

            case Identifier (name, type, info):
                print(name);

            case Break (info):
                printlnIndented("break;");

            case Continue (info):
                printlnIndented("continue;");

            case SubExpression(node, info):
                print("(");
                enableInline();
                printNode(node);
                disableInline();
                print(")");

            case ArrayAccess(on, index, info):
                printNode(on);
                print("[");
                printNode(index);
                print("]");

            case TypeCast(on, from, to):
                if (from.isArray() || to.isArray()) {
                    throw "Type casting of arrays is not supported!";
                }
                print(getTypeStr(to));
                print("(");
                enableInline();
                printNode(on);
                disableInline();
                print(")");

            case Block(body, info):
                printNodeChildren(body);

            case StructAccess(on, field, type, info):
                if (on.match(Identifier("output", _))) {
                    if (_internalOutputStruct.exists(field)) {
                        print(_internalOutputStruct.get(field));
                        return;
                    }

                    for (data in _context.getShaderData()) {
                        if (data.name == field && data.kind == MNSLShaderDataKind.Output) {
                            print(_prefixes.output + data.name);
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
                        if (data.name == field && data.kind == MNSLShaderDataKind.Input) {
                            print(_prefixes.input + data.name);
                            return;
                        }
                    }
                }

                if (on.match(Identifier("uniform", _))) {
                    for (data in _context.getShaderData()) {
                        if (data.name == field && data.kind == MNSLShaderDataKind.Uniform) {
                            print(_prefixes.uniform + data.name);
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
        println("#version {0} {1}", _config.version, _config.versionDirective);
        println("");

        if (_config.usePrecision) {
            var printed: Map<String, Bool> = new Map();
            for (type in _types.iterator()) {
                if (_defaultPrecision.exists(type) && !printed.exists(type)) {
                    println("precision {0} {1};", _defaultPrecision.get(type), type);
                    printed.set(type, true);
                }
            }
            println("");
        }

        var dataOutputLength: Int = 0;
        for (data in _context.getShaderData()) {
            switch (data.kind) {
                case MNSLShaderDataKind.Input:
                    if (_internalInputStruct.exists(data.name)) {
                        continue;
                    }

                    dataOutputLength++;
                    if (_config.useAttributeAndVaryingKeywords) {
                        println("attribute {0} {1}{2};", getTypeStr(data.type), _prefixes.input, data.name);
                    } else {
                        println("in {0} {1}{2};", getTypeStr(data.type), _prefixes.input, data.name);
                    }

                case MNSLShaderDataKind.Output:
                    if (_internalOutputStruct.exists(data.name)) {
                        continue;
                    }

                    dataOutputLength++;
                    if (_config.useAttributeAndVaryingKeywords) {
                        println("varying {0} {1}{2};", getTypeStr(data.type), _prefixes.output, data.name);
                    } else {
                        println("out {0} {1}{2};", getTypeStr(data.type), _prefixes.output, data.name);
                    }

                case MNSLShaderDataKind.Uniform:
                    dataOutputLength++;
                    if (data.type.isArray()) {
                        println("uniform {0} {1}{2}[{3}];", getTypeStr(data.type.getArrayBaseType()), _prefixes.uniform, data.name, data.type.getArraySize());
                    } else {
                        println("uniform {0} {1}{2};", getTypeStr(data.type.getArrayBaseType()), _prefixes.uniform, data.name);
                    }
            }
        }

        if (dataOutputLength > 0) {
            println("");
        }

        printNodeChildren(_ast);
    }

    public function getTypeStr(type: MNSLType): String {
        return _types.get(type.toBaseString());
    }
    
}
