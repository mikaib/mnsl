package mnsl;

import mnsl.tokenizer.MNSLTokenizer;
import mnsl.tokenizer.MNSLToken;
import mnsl.parser.MNSLNodeChildren;
import mnsl.parser.MNSLShaderData;
import mnsl.parser.MNSLParser;
import mnsl.glsl.MNSLGLSLConfig;
import mnsl.glsl.MNSLGLSLPrinter;
import mnsl.analysis.MNSLAnalyser;

class MNSLContext {

    private var _finalAst: MNSLNodeChildren;
    private var _finalData: Array<MNSLShaderData>;
    private var _defines: Map<String, MNSLToken>;

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
        analyser.run();
    }

    /**
     * Get the defines.
     * @return The defines.
     */
    public function getDefines(): Map<String, MNSLToken> {
        return _defines;
    }

    /**
     * Set an integer define.
     * @param key The key of the define.
     * @param value The value of the define.
     */
    public function setDefineInt(key: String, value: Int): Void {
        _defines.set(key, IntegerLiteral('$value', null));
    }

    /**
     * Set a float define.
     * @param key The key of the define.
     * @param value The value of the define.
     */
    public function setDefineFloat(key: String, value: Float): Void {
        _defines.set(key, FloatLiteral('$value', null));
    }

    /**
     * Set a direct define.
     * @param key The key of the define.
     * @param value The value of the define.
     */
    public function setDefine(key: String, value: MNSLToken): Void {
        _defines.set(key, value);
    }

    /**
     * Get a define.
     * @param key The key of the define.
     * @return The value of the define.
     */
    public function getDefine(key: String): MNSLToken {
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
        }
    }

}
