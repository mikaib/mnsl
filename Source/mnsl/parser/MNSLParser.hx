package mnsl.parser;

import mnsl.tokenizer.MNSLToken;
import mnsl.tokenizer.MNSLTokenInfo;
import haxe.EnumTools;
import mnsl.analysis.MNSLFuncArgs;
import mnsl.analysis.MNSLType;

class MNSLParser {

    private var currentIndex: Int;
    private var tokens: Array<MNSLToken>;
    private var context: MNSLContext;
    private var ast: MNSLNodeChildren;
    private var keywords: Array<String> = [
        "func"
    ];

    /**
     * Given a list of tokens, this function will parse them and return an AST.
     * @param tokens The list of tokens to parse.
     */
    public function new(context: MNSLContext, tokens: Array<MNSLToken>){
        this.tokens = tokens;
        this.currentIndex = 0;
        this.ast = [];
        this.context = context;
    }

    /**
     * This function will parse the tokens and return an AST.
     * @return The AST.
     */
    public function run(): MNSLNodeChildren {
        while (currentIndex < tokens.length) {
            var token: MNSLToken = tokens[currentIndex];
            currentIndex++;

            switch (token) {
                case Identifier(value, info):
                    if (keywords.contains(value)) {
                        parseKeyword(value, info);
                    } else {
                        append(MNSLNode.Identifier(value, MNSLNodeInfo.fromTokenInfo(info)));
                    }

                default:
                    // context.emitError(ParserInvalidToken(token));
            }

        }
        return ast;
    }

    /**
     * Get a block of tokens.
     * @param start The start token.
     * @param end The end token.
     */
    public function getBlock(start: MNSLToken, end: MNSLToken, inc: Int = 1): Array<MNSLToken> {
        var block: Array<MNSLToken> = [];
        var depth: Int = 0;
        var token: MNSLToken;

        var startTokenType = EnumValueTools.getName(start);
        var endTokenType = EnumValueTools.getName(end);

        while (currentIndex < tokens.length) {
            token = tokens[currentIndex];

            var tokenType = EnumValueTools.getName(token);
            if (tokenType == startTokenType) {
                depth++;
            } else if (tokenType == endTokenType) {
                depth--;
            }

            if (depth == 0) {
                break;
            }

            block.push(token);
            currentIndex++;
        }

        if (block[0] != null && EnumValueTools.getName(block[0]) != startTokenType) {
            context.emitError(ParserUnexpectedToken(block[0], null));
            return [];
        }

        currentIndex += inc;

        return block.slice(1, block.length);
    }

    /**
     * Split block with each seperator.
     * @param block The block to split.
     * @param sep The seperator to split with.
     */
    public function splitBlock(block: Array<MNSLToken>, sep: MNSLToken): Array<Array<MNSLToken>> {
        var blocks: Array<Array<MNSLToken>> = [];
        var currentBlock: Array<MNSLToken> = [];
        var sepType = EnumValueTools.getName(sep);

        for (token in block) {
            if (EnumValueTools.getName(token) == sepType) {
                blocks.push(currentBlock);
                currentBlock = [];
            } else {
                currentBlock.push(token);
            }
        }

        if (currentBlock.length > 0) {
            blocks.push(currentBlock);
        }

        return blocks;
    }

    /**
     * Append a node to the current body.
     * @param node The node to append.
     */
    public function append(node: MNSLNode): Void {
        ast.push(node);
    }

    /**
     * This function will parse a keyword.override
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseKeyword(value: String, info: MNSLTokenInfo): Void {
        switch (value) {
            case "func":
                parseFunction(value, info);
            default:
                context.emitError(ParserInvalidKeyword(value, info));
        }
    }

    /**
     * Gets the token value for a given token if possible.
     * @param token The token to get the value for.
     */
    public function getTokenValue(token: MNSLToken): String {
        switch (token) {
            case Identifier(value, _):
                return value;
            case IntegerLiteral(value, _):
                return value;
            case FloatLiteral(value, _):
                return value;
            case StringLiteral(value, _):
                return value;
            default:
                return null;
        }
    }

    /**
     * Get token infos
     * @param token The token to get the info for.
     */
    public function getTokenInfo(token: MNSLToken): MNSLTokenInfo {
        var params = EnumValueTools.getParameters(token);
        if (params.length == 0) {
            return null;
        }

        for (param in params) {
            if (Std.isOfType(param, MNSLTokenInfo)) {
                return param;
            }
        }

        return null;
    }

    /**
     * This function will attempt to get the value of the current token.
     */
    public function getCurrentTokenValue(inc: Int = 1): String {
        var t = tokens[currentIndex];
        if (t == null) {
            return null;
        }

        currentIndex += inc;
        return getTokenValue(t);
    }

    /**
     * Gets the current token
     * @param inc The amount to increment the index by.
     */
    public function getCurrentToken(inc: Int = 1): MNSLToken {
        var t = tokens[currentIndex];

        currentIndex += inc;
        return t;
    }

    /**
     * Get the type of the current token as a string.
     * @param inc The amount to increment the index by.
     */
    public function getCurrentTokenType(inc: Int = 1): String {
        var t = tokens[currentIndex];
        if (t == null) {
            return null;
        }

        currentIndex += inc;
        return EnumValueTools.getName(t);
    }

    /**
     * Peek the current token.
     */
    public function peekCurrentToken(inc: Int = 1): MNSLToken {
        var t = tokens[currentIndex + inc];
        if (t == null) {
            return null;
        }

        return t;
    }

    /**
     * Peek the current token type.
     */
    public function peekCurrentTokenType(inc: Int = 1): String {
        var t = tokens[currentIndex + inc];
        if (t == null) {
            return null;
        }

        return EnumValueTools.getName(t);
    }

    /**
     * Peek the current token value.
     */
    public function peekCurrentTokenValue(inc: Int = 1): String {
        var t = tokens[currentIndex + inc];
        if (t == null) {
            return null;
        }

        return getTokenValue(t);
    }

    /**
     * This function will parse a function declaration.
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseFunction(value: String, info: MNSLTokenInfo): Void {
        var name: String = getCurrentTokenValue();
        if (name == null) {
            context.emitError(ParserUnexpectedToken(tokens[currentIndex], info));
            return;
        }

        var returnType: MNSLType = MNSLType.TUnknown;

        var params: MNSLFuncArgs = [];
        var paramBlock = getBlock(LeftParen(null), RightParen(null));
        var paramsTokens = splitBlock(paramBlock, Comma(null));

        for (paramTokens in paramsTokens) {
            var c = new MNSLParser(context, paramTokens);

            var name = c.getCurrentTokenValue();
            if (name == null) {
                context.emitError(ParserUnexpectedToken(paramTokens[0], info));
                continue;
            }

            var paramType = MNSLType.TUnknown;
            params.push({
                name: name,
                type: paramType
            });

            var t = c.getCurrentTokenType();
            if (t == null) {
                continue;
            }

            if (t != "Colon") {
                context.emitError(ParserUnexpectedToken(paramTokens[0], info));
                continue;
            }

            var type = c.getCurrentTokenValue();
            if (type == null) {
                context.emitError(ParserUnexpectedToken(paramTokens[0], info));
                continue;
            }

            paramType.setTypeStrUnsafe(type);
        }

        if (peekCurrentTokenType(0) == "Colon") {
            currentIndex++;

            var type = getCurrentTokenValue();
            if (type == null) {
                context.emitError(ParserUnexpectedToken(tokens[currentIndex], info));
                return;
            }

            returnType.setTypeStrUnsafe(type);
        }

        var bodyBlock = getBlock(LeftBrace(null), RightBrace(null));
        var body = new MNSLParser(context, bodyBlock).run();

        append(FunctionDecl(
            name,
            returnType,
            params,
            body,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(bodyBlock[bodyBlock.length - 1])])
        ));
    }

}
