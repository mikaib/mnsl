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
import mnsl.optimiser.MNSLOptimiser;
import haxe.io.Bytes;
import mnsl.spirv.MNSLSPIRVPrinter;
import mnsl.spirv.MNSLSPIRVConfig;

class MNSLContext {

    private var _finalAst: MNSLNodeChildren;
    private var _finalData: Array<MNSLShaderData>;
    private var _defines: Map<String, Array<MNSLToken>>;
    private var _options: MNSLContextOptions;
    private var _errors: Array<MNSLError>;
    private var _warnings: Array<MNSLWarning>;

    /**
     * Creates a new MNSLContext instance.
     * @param source The source code to be parsed.
     */
    public function new(source: String, options: MNSLContextOptions) {
        _defines = options.defines;
        _options = options;
        _errors = [];
        _warnings = [];

        if (_options.rootPath == null) {
            _options.rootPath = "./";
        }

        var preprocDefines: Map<String, Dynamic> = [];
        for (def in options.preprocessorDefines) {
            preprocDefines[def] = 1;
        }

        var tokenizer: MNSLTokenizer = new MNSLTokenizer(this, source, preprocDefines);
        var tokens: Array<MNSLToken> = tokenizer.run();

        var parser = new MNSLParser(this, tokens);
        var res = parser.run();
        _finalAst = res.ast;
        _finalData = res.dataList;

        var analyser = new MNSLAnalyser(this, res.ast);
        var output = analyser.run();
        _finalAst = output;

        var optimizer = new MNSLOptimiser(this, output);
        for (plugin in _options.optimizerPlugins) {
            optimizer.addPlugin(plugin);
        }

        var optimized = optimizer.run();
        _finalAst = optimized;
    }

    /**
     * Get the options of the context.
     * @return The options of the context.
     */
    public function getOptions(): MNSLContextOptions {
        return _options;
    }

    /**
     * logs a message to the console.
     */
    public function log(message: String): Void {
        trace(message);
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
                    log(indentStr + name + '[$funcName: $returnType]');
                    printAST(body, indent + 1);
                case FunctionCall(funcName, args, type, info):
                    log(indentStr + name + '[$funcName: $type]');
                    printAST(args, indent + 1);
                case Return(value, type, info):
                    log(indentStr + name);
                    printAST([value], indent + 1);
                case VariableDecl(varName, type, value, info):
                    log(indentStr + name + '[$varName: $type]');
                    if (value != null) {
                        printAST([value], indent + 1);
                    }
                case VariableAssign(varName, value, info):
                    log(indentStr + name + '[$varName]');
                    printAST([value], indent + 1);
                case IfStatement(condition, body, info):
                    log(indentStr + name);
                    printAST([condition], indent + 1);
                    printAST(body, indent + 1);
                case ElseIfStatement(condition, body, info):
                    log(indentStr + name);
                    printAST([condition], indent + 1);
                    printAST(body, indent + 1);
                case ElseStatement(body, info):
                    log(indentStr + name);
                    printAST(body, indent + 1);
                case BinaryOp(left, op, right, type, info):
                    log(indentStr + name + '[$op -> $type]');
                    printAST([left, right], indent + 1);
                case UnaryOp(op, value, info):
                    log(indentStr + name + '[$op]');
                    printAST([value], indent + 1);
                case WhileLoop(condition, body, info):
                    log(indentStr + name);
                    printAST([condition], indent + 1);
                    printAST(body, indent + 1);
                case ForLoop(init, condition, increment, body, info):
                    log(indentStr + name);
                    printAST([init, condition, increment], indent + 1);
                    printAST(body, indent + 1);
                case SubExpression(value, info):
                    log(indentStr + name);
                    printAST([value], indent + 1);
                case StructAccess(structName, field, type, info):
                    log(indentStr + name + '[$structName.$field t=$type]');
                case ArrayAccess(arrayName, index, info):
                    log(indentStr + name + '[$arrayName[$index]]');
                case VectorConversion(on, fromComp, toComp):
                    log(indentStr + name + '[$fromComp -> $toComp]');
                    printAST([on], indent + 1);
                case VectorCreation(comp, values, info):
                    log(indentStr + name + '[Vec$comp]');
                    printAST(values, indent + 1);
                case Identifier(identifierName, type, info):
                    log(indentStr + name + '[$identifierName: $type]');
                case IntegerLiteralNode(value, info):
                    log(indentStr + name + '[$value]');
                case FloatLiteralNode(value, info):
                    log(indentStr + name + '[$value]');
                case StringLiteralNode(value, info):
                    log(indentStr + name + '[$value]');
                case TypeCast(on, from, to):
                    log(indentStr + name + '[$from -> $to]');
                    printAST([on], indent + 1);
                case Block(body, info):
                    log(indentStr + name);
                    printAST(body, indent + 1);
                default:
                    log(indentStr + name);
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
     * @param config The configuration for the GLSL emitter.
     */
    public function emitGLSL(config: MNSLGLSLConfig): String {
        var p = new MNSLGLSLPrinter(this, config);
        p.run();

        return p.getOutput();
    }

    /**
     * Emit SPIRV binary.
     * @param config The configuration for the SPIRV emitter.
     */
    public function emitSPIRV(config: MNSLSPIRVConfig): Bytes {
        var p = new MNSLSPIRVPrinter(this, config);
        p.run();

        return p.getBytes();
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
        for (e in _errors) {
            if (Std.string(e) == Std.string(error)) {
                return;
            }
        }

        _errors.push(error);
    }

    /**
     * Emits a warning in the context of the MNSLContext.
     * @param warning The warning to be emitted.
     */
    public function emitWarning(warning: MNSLWarning): Void {
        for (w in _warnings) {
            if (Std.string(w) == Std.string(warning)) {
                return;
            }
        }

        _warnings.push(warning);
    }

    /**
     * Get the errors emitted in the context of the MNSLContext.
     * @return The errors emitted.
     */
    public function getErrors(): Array<MNSLError> {
        return _errors;
    }

    /**
     * Get the warnings emitted in the context of the MNSLContext.
     * @return The warnings emitted.
     */
    public function getWarnings(): Array<MNSLWarning> {
        return _warnings;
    }

    /**
     * Check if any errors were emitted in the context of the MNSLContext.
     * @return True if there are errors, false otherwise.
     */
    public function hasErrors(): Bool {
        return _errors.length > 0;
    }

    /**
     * Check if any warnings were emitted in the context of the MNSLContext.
     * @return True if there are warnings, false otherwise.
     */
    public function hasWarnings(): Bool {
        return _warnings.length > 0;
    }

    /**
     * Convert a warning to a human-readable string.
     * @param warning The warning to be converted.
     */
    public function warningToString(warning: MNSLWarning): String {
        switch (warning) {
            case ImplicitVectorTruncation(node, from, to):
                return "ImplicitVectorTrunation: Vec" + from + " to Vec" + to + " at " + node;
            case ImplicitFloatToInt(node):
                return "Implicit conversion from float to int at " + node;
        }
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
            case ParserConditionalWithoutIf(pos):
                return "Conditional statement without 'if' or 'elseif' at position " + pos;
            case TokenizerInvalidChar(char, pos):
                return "Invalid character: " + char + " at position " + pos;
            case TokenizerUnterminatedString(pos):
                return "Unterminated string at position " + pos;
            case TokenizerPreprocessorError(msg, pos):
                return "Preprocessor error: " + msg + " at position " + pos;
            case AnalyserNoImplementation(fn , pos):
                return "No implementation for function: " + fn + " at " + pos;
            case AnalyserUndeclaredVariable(varName, info):
                return "Undefined variable: " + varName + " at " + info;
            case AnalyserDuplicateVariable(varName, info):
                return "Duplicate variable: " + varName + " at " + info;
            case AnalyserMissingReturn(func, node):
                return "Missing return statement in function: " + func + " at " + node;
            case AnalyserReturnOutsideFunction(pos):
                return "Return statement outside of function at " + pos;
            case AnalyserMismatchingType(constraint):
                return "Expected " + constraint.mustBe + " but got " + constraint.type + " at " + constraint.ofNode;
            case AnalyserUnknownType(type, node):
                return "Unknown type: " + type + " at " + node;
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
            case AnalyserInvalidUnaryOp(op, info):
                return "Invalid unary operation: " + op + " at " + info;
            case AnalyserUnknownArraySize(type, node):
                return "Unknown array size for type: " + type + " at " + node;
            case AnalyserReadOnlyAssignment(node):
                return "Cannot assign to read-only variable: " + node;
            case AnalyserVariableOutsideFunction(name, node, info):
                return "Variable " + name + " is not allowed outside of a function at " + node + " at " + info;
            case AnalyserInvalidReturnType(func, expected, actual):
                return "Invalid return type for function " + func + ": expected " + expected + ", got " + actual;
            case AnalyserMissingMainFunction:
                return "Missing main function, expected a function named 'main' with no parameters returning void.";
            case AnalyserRecursiveFunction(func, chain, info):
                var chainStr = "";
                for (i in 0...chain.length) {
                    if (i > 0) {
                        chainStr += " -> ";
                    }
                    chainStr += chain[i];
                }
                return "Recursive function detected: " + func + " in chain: " + chainStr + " at " + info;
            case AnalyserLoopKeywordOutsideLoop(node, info):
                return EnumValueTools.getName(node) + " outside of loop at " + info;
            case AnalyserInvalidArrayAccess(on, index, info):
                return "Invalid array access on " + on + " with index " + index + " at " + info;
            case AnalyserInvalidVectorArrayAccess(on, index, info):
                return "Invalid vector array access on " + on + " with index " + index + " at " + info + " (index must be a constant integer!)";
            case AnalyserMismatchingEitherType(limits, node):
                var limitStr = "";
                for (limitIdx in 0...limits.length) {
                    if (limitIdx > 0) {
                        limitStr += limitIdx == limits.length - 1 ? " or " : ", ";
                    }
                    limitStr += limits[limitIdx];
                }

                return node + " did not match any of the expected types: " + limitStr;
        }
    }

}
