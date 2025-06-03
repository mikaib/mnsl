package mnsl;

import mnsl.tokenizer.MNSLTokenizer;
import mnsl.tokenizer.MNSLToken;
import mnsl.parser.MNSLNodeChildren;
import mnsl.parser.MNSLShaderData;
import mnsl.parser.MNSLParser;
import mnsl.glsl.MNSLGLSLConfig;
import mnsl.glsl.MNSLGLSLPrinter;
import mnsl.analysis.MNSLAnalyser;
import haxe.EnumTools.EnumValueTools;

class MNSLContext {

    private var _finalAst: MNSLNodeChildren;
    private var _finalData: Array<MNSLShaderData>;
    private var _defines: Map<String, Array<MNSLToken>>;

    /**
     * Creates a new MNSLContext instance.
     * @param source The source code to be parsed.
     */
    public function new(source: String) {
        _defines = [];

        var tokenizer: MNSLTokenizer = new MNSLTokenizer(this, source);
        var tokens: Array<MNSLToken> = tokenizer.run();

        var parser = new MNSLParser(this, tokens);
        var res = parser.run();

        _finalAst = res.ast;
        _finalData = res.dataList;

        var analyser = new MNSLAnalyser(this, res.ast);
        var output = analyser.run();

        _finalAst = output;
        printAST(_finalAst);
    }

    /**
     * Print a given AST.
     * @param ast The AST to be printed.
     * @param indent The indentation level.
     */
    public function printAST(ast: MNSLNodeChildren, indent: Int = 0): Void {
        var indentStr = StringTools.lpad("", " ", indent * 2);

        for (node in ast) {
            var name = EnumValueTools.getName(node);

            switch(node) {
                case FunctionDecl(funcName, returnType, params, body, info):
                    Sys.println(indentStr + name + '[$funcName: $returnType]');
                    printAST(body, indent + 1);
                case FunctionCall(funcName, args, type, info):
                    Sys.println(indentStr + name + '[$funcName: $type]');
                    printAST(args, indent + 1);
                case Return(value, type, info):
                    Sys.println(indentStr + name);
                    printAST([value], indent + 1);
                case VariableDecl(varName, type, value, info):
                    Sys.println(indentStr + name + '[$varName: $type]');
                    if (value != null) {
                        printAST([value], indent + 1);
                    }
                case VariableAssign(varName, value, info):
                    Sys.println(indentStr + name + '[$varName]');
                    printAST([value], indent + 1);
                case IfStatement(condition, body, info):
                    Sys.println(indentStr + name);
                    printAST([condition], indent + 1);
                    printAST(body, indent + 1);
                case ElseIfStatement(condition, body, info):
                    Sys.println(indentStr + name);
                    printAST([condition], indent + 1);
                    printAST(body, indent + 1);
                case ElseStatement(body, info):
                    Sys.println(indentStr + name);
                    printAST(body, indent + 1);
                case BinaryOp(left, op, right, type, info):
                    Sys.println(indentStr + name + '[$op -> $type]');
                    printAST([left, right], indent + 1);
                case UnaryOp(op, value, info):
                    Sys.println(indentStr + name + '[$op]');
                    printAST([value], indent + 1);
                case WhileLoop(condition, body, info):
                    Sys.println(indentStr + name);
                    printAST([condition], indent + 1);
                    printAST(body, indent + 1);
                case ForLoop(init, condition, increment, body, info):
                    Sys.println(indentStr + name);
                    printAST([init, condition, increment], indent + 1);
                    printAST(body, indent + 1);
                case SubExpression(value, info):
                    Sys.println(indentStr + name);
                    printAST([value], indent + 1);
                case StructAccess(structName, field, type, info):
                    Sys.println(indentStr + name + '[$structName.$field t=$type]');
                case ArrayAccess(arrayName, index, info):
                    Sys.println(indentStr + name + '[$arrayName[$index]]');
                case VectorConversion(on, fromComp, toComp):
                    Sys.println(indentStr + name + '[$fromComp -> $toComp]');
                    printAST([on], indent + 1);
                case VectorCreation(comp, values, info):
                    Sys.println(indentStr + name + '[Vec$comp]');
                    printAST(values, indent + 1);
                case Identifier(identifierName, type, info):
                    Sys.println(indentStr + name + '[$identifierName: $type]');
                case IntegerLiteralNode(value, info):
                    Sys.println(indentStr + name + '[$value]');
                case FloatLiteralNode(value, info):
                    Sys.println(indentStr + name + '[$value]');
                case StringLiteralNode(value, info):
                    Sys.println(indentStr + name + '[$value]');
                case TypeCast(on, from, to):
                    Sys.println(indentStr + name + '[$from -> $to]');
                    printAST([on], indent + 1);
                default:
                    Sys.println(indentStr + name);
            }
        }
    }

    /**
     * Get the defines.
     * @return The defines.
     */
    public function getDefines(): Map<String, Array<MNSLToken>> {
        return _defines;
    }

    /**
     * Set an integer define.
     * @param key The key of the define.
     * @param value The value of the define.
     */
    public function setDefineInt(key: String, value: Int): Void {
        _defines.set(key, [IntegerLiteral('$value', null)]);
    }

    /**
     * Set a float define.
     * @param key The key of the define.
     * @param value The value of the define.
     */
    public function setDefineFloat(key: String, value: Float): Void {
        _defines.set(key, [FloatLiteral('$value', null)]);
    }

    /**
     * Set a direct define.
     * @param key The key of the define.
     * @param value The value of the define.
     */
    public function setDefine(key: String, value: Array<MNSLToken>): Void {
        _defines.set(key, value);
    }

    /**
     * Get a define.
     * @param key The key of the define.
     * @return The value of the define.
     */
    public function getDefine(key: String): Array<MNSLToken> {
        return _defines.get(key);
    }

    /**
     * Emit GLSL source code.
     * @param source The GLSL source code to be emitted.
     */
    public function emitGLSL(config: MNSLGLSLConfig): String {
        var p = new MNSLGLSLPrinter(this, config);
        p.run();

        return p.getOutput();
    }

    /**
     * Get the final AST.
     * @return The final AST.
     */
    public function getAST(): MNSLNodeChildren {
        return _finalAst;
    }

    /**
     * Get the final shader data.
     * @return The final shader data.
     */
    public function getShaderData(): Array<MNSLShaderData> {
        return _finalData;
    }

    /**
     * Emits an error in the context of the MNSLContext.
     * @param error The error to be emitted.
     */
    public function emitError(error: MNSLError): Void {
        throw errorToString(error);
    }

    /**
     * Convert an error to a human-readable string.
     * @param error The error to be converted.
     */
    public function errorToString(error: MNSLError): String {
        switch (error) {
            case ParserInvalidToken(token):
                return "Invalid token: " + token;
            case ParserInvalidKeyword(value, pos):
                return "Invalid keyword: " + value + " at position " + pos;
            case ParserUnexpectedToken (token, pos):
                return "Unexpected token: " + token + " at position " + pos;
            case ParserUnexpectedExpression(node, pos):
                return "Unexpected expression: " + node + " at position " + pos;
            case TokenizerInvalidChar(char, pos):
                return "Invalid character: " + char + " at position " + pos;
            case TokenizerUnterminatedString(pos):
                return "Unterminated string at position " + pos;
            case AnalyserNoImplementation(fn , pos):
                return "No implementation for function: " + fn + " at " + pos;
            case AnalyserUndeclaredVariable(varName, info):
                return "Undefined variable: " + varName + " at " + info;
            case AnalyserDuplicateVariable(varName, info):
                return "Duplicate variable: " + varName + " at " + info;
            case AnalyserReturnOutsideFunction(pos):
                return "Return statement outside of function at " + pos;
            case AnalyserMismatchingType(constraint):
                return "Expected " + constraint.mustBe + " but got " + constraint.type + " at " + constraint.ofNode;
            case AnalyserUnresolvedConstraint(constraint):
                return "Unresolved constraint: " + constraint;
            case AnalyserInvalidAssignment(on):
                return "Cannot assign to " + on;
            case AnalyserInvalidAccess(on):
                return "Cannot access on " + on;
            case AnalyserInvalidVectorComponent(comp, info):
                return "Invalid amount of vector components: " + comp + " at " + info;
            case AnalyserInvalidBinop(tLeft, tRight, op, constraint):
                return "Invalid binary operation: " + tLeft + " " + op + " " + tRight + " at " + constraint.ofNode;
            case AnalyserUnknownVectorComponent(node, info):
                return "Type of vector component is unknown: " + node + " at vector " + info;
        }
    }

}
