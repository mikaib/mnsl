package mnsl.parser;

import haxe.EnumTools;
import mnsl.tokenizer.MNSLToken;
import mnsl.tokenizer.MNSLTokenInfo;
import mnsl.analysis.MNSLFuncArgs;
import mnsl.analysis.MNSLType;

class MNSLParser {

    private var currentIndex: Int;
    private var tokens: Array<MNSLToken>;
    private var context: MNSLContext;
    private var ast: MNSLNodeChildren;
    private var dataList: Array<MNSLShaderData>;

    private var keywords: Array<String> = [
        "func",
        "return",
        "var",
        "if",
        "else",
        "while",
        "for",
        "break",
        "continue"
    ];

    private var operators: Array<String> = [
        "Plus",
        "Minus",
        "Star",
        "Slash",
        "Percent",
        "Equal",
        "NotEqual",
        "Greater",
        "GreaterEqual",
        "Less",
        "LessEqual",
        "And",
        "Or",
        "Not"
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
        this.dataList = [];
    }

    /**
     * Get the data list.
     */
    public function getDataList(): Array<MNSLShaderData> {
        return dataList;
    }

    /**
     * This function will parse the tokens and return an MNSLParserResults.
     */
    public function run(): MNSLParserResults {
        this._runInternal();

        return {
            ast: ast,
            dataList: dataList
        };
    }

    /**
     * This function will parse the tokens and return an AST.
     * @return The AST.
     */
    public function _runInternal(): MNSLNodeChildren {
        while (currentIndex < tokens.length) {
            var token: MNSLToken = tokens[currentIndex];
            currentIndex++;

            switch (token) {
                case Identifier(value, info):
                    parseIdentifier(value, info);

                case LeftParen(_):
                    parseSubExpression(token);

                case LeftBracket(_):
                    parseArrayAccess(token);

                case Dot(_):
                    parseStructAccess(token);

                case At(_):
                    parseMeta(token);

                case Assign(_):
                    parseVarAssign(getCurrentTokenValue(), getTokenInfo(token));

                case IntegerLiteral(value, info):
                    append(IntegerLiteralNode(value, MNSLNodeInfo.fromTokenInfo(info)));

                case FloatLiteral(value, info):
                    append(FloatLiteralNode(value, MNSLNodeInfo.fromTokenInfo(info)));

                case StringLiteral(value, info):
                    append(StringLiteralNode(value, MNSLNodeInfo.fromTokenInfo(info)));

                case Semicolon(_):
                    continue;

                default:
                    if (isOperator(token)) {
                        if (peekCurrentToken(0).match(Assign(_))) {
                            getCurrentToken();
                            parseOperatorAssignment(token);
                            continue;
                        }

                        parseOperator(token);
                        continue;
                    }

                    context.emitError(ParserInvalidToken(token));
            }
        }

        return ast;
    }

    /**
     * This function will parse a struct access.
     * @param token The token to parse.
     */
    public function parseStructAccess(token: MNSLToken): Void {
        var accessOn = pop();
        if (accessOn == null) {
            context.emitError(ParserUnexpectedExpression(accessOn, null));
            return;
        }

        var accessName = getCurrentTokenValue();
        if (accessName == null) {
            context.emitError(ParserUnexpectedToken(tokens[currentIndex], null));
            return;
        }

        append(StructAccess(
            accessOn,
            accessName,
            MNSLType.TUnknown,
            MNSLNodeInfo.fromTokenInfos([getTokenInfo(token), getTokenInfo(tokens[currentIndex - 1])])
        ));
    }

    /**
     * This function will parse an array access.
     * @param token The token to parse.
     */
    public function parseArrayAccess(token: MNSLToken): Void {
        var accessOn = pop();
        if (accessOn == null) {
            context.emitError(ParserUnexpectedExpression(accessOn, null));
            return;
        }

        var accessBlock = getBlock(LeftBracket(null), RightBracket(null), 1);
        var accessCtx = new MNSLParser(context, accessBlock);
        var access = accessCtx._runInternal();

        if (access.length == 0) {
            context.emitError(ParserUnexpectedToken(accessBlock[0], null));
            return;
        }

        if (access.length > 1) {
            context.emitError(ParserUnexpectedExpression(access[1], null));
            return;
        }

        append(ArrayAccess(
            accessOn,
            access[0],
            MNSLNodeInfo.fromTokenInfos([getTokenInfo(token), getTokenInfo(accessBlock[accessBlock.length - 1])])
        ));
    }

    /**
     * This function will parse a meta token.
     * @param token The token to parse.
     */
    public function parseMeta(token: MNSLToken): Void {
        var name = getCurrentTokenValue();
        if (name == null) {
            context.emitError(ParserUnexpectedToken(tokens[currentIndex], null));
            return;
        }

        if (peekCurrentTokenType(0) != "LeftParen") {
            context.emitError(ParserUnexpectedToken(tokens[currentIndex], null));
            return;
        }

        var block = getBlock(LeftParen(null), RightParen(null));

        switch(name) {
            case "input":
                parseShaderDataMeta(block, MNSLShaderDataKind.Input);
            case "output":
                parseShaderDataMeta(block, MNSLShaderDataKind.Output);
            case "uniform":
                parseShaderDataMeta(block, MNSLShaderDataKind.Uniform);
            case "define":
                parseDefineMeta(block);
        }
    }

    /**
     * Parses a list of tokens for shader data to a name and type
     */
    public function parseShaderDataMeta(block: Array<MNSLToken>, kind: MNSLShaderDataKind): Void {
        var nameToken = block[0];
        var name = getTokenValue(nameToken);
        if (name == null) {
            context.emitError(ParserUnexpectedToken(nameToken, null));
            return;
        }

        var colonToken = block[1];
        if (colonToken == null || !colonToken.match(Colon(_))) {
            context.emitError(ParserUnexpectedToken(colonToken, null));
            return;
        }

        var typeToken = block[2];
        var type = getTokenValue(typeToken);
        if (type == null) {
            context.emitError(ParserUnexpectedToken(typeToken, null));
            return;
        }

        var bracketOpenToken = block[3];
        var arraySize = block[4];
        var arraySizeInt: Int = -1;
        var bracketCloseToken = block[5];

        if (bracketOpenToken != null) {
            if (!bracketOpenToken.match(LeftBracket(_))) {
                context.emitError(ParserUnexpectedToken(bracketOpenToken, null));
                return;
            }

            if (arraySize == null) {
                context.emitError(ParserUnexpectedToken(arraySize, null));
                return;
            }

            if (bracketCloseToken == null || !bracketCloseToken.match(RightBracket(_))) {
                context.emitError(ParserUnexpectedToken(bracketCloseToken, null));
                return;
            }

            if (!arraySize.match(IntegerLiteral(_, _))) {
                if (!arraySize.match(Identifier(_, _))) {
                    context.emitError(ParserUnexpectedToken(arraySize, null));
                    return;
                }

                var defineValues = context.getDefine(getTokenValue(arraySize));
                if (defineValues == null) {
                    context.emitError(ParserUnexpectedToken(arraySize, null));
                    return;
                }

                var defineValue = defineValues[0];
                if (defineValue == null) {
                    context.emitError(ParserUnexpectedToken(arraySize, null));
                    return;
                }

                if (!defineValue.match(IntegerLiteral(_, _))) {
                    context.emitError(ParserUnexpectedToken(arraySize, null));
                    return;
                }

                arraySizeInt = Std.parseInt(getTokenValue(defineValue));
            } else {
                arraySizeInt = Std.parseInt(getTokenValue(arraySize));
            }
        }

        var shData: MNSLShaderData = {
            name: name,
            type: MNSLType.fromString(type),
            arraySize: arraySizeInt,
            kind: kind
        };

        dataList.push(shData);
    }

    /**
     * Parses a define meta token
     */
    public function parseDefineMeta(block: Array<MNSLToken>): Void {
        var nameToken = block[0];
        var name = getTokenValue(nameToken);
        if (name == null) {
            context.emitError(ParserUnexpectedToken(nameToken, null));
            return;
        }

        var commaToken = block[1];
        if (commaToken == null || !commaToken.match(Comma(_))) {
            context.emitError(ParserUnexpectedToken(commaToken, null));
            return;
        }

        var valueTokens = block.slice(2);
        if (valueTokens.length == 0) {
            context.emitError(ParserUnexpectedToken(valueTokens[2], null));
            return;
        }

        context.setDefine(name, valueTokens);
    }

    /**
     * This function will parse a sub expression.
     * @param token The token to parse.
     */
    public function parseSubExpression(token: MNSLToken): Void {
        var block = getBlock(LeftParen(null), RightParen(null), 1);
        var parts = splitBlock(block, Comma(null));
        var nodes: MNSLNodeChildren = [];

        for (part in parts) {
            var parser = new MNSLParser(context, part);
            var parsed = parser._runInternal();

            if (parsed.length == 0) {
                context.emitError(ParserUnexpectedToken(part[0], null));
                return;
            }

            if (parsed.length > 1) {
                context.emitError(ParserUnexpectedExpression(parsed[1], null));
                return;
            }

            nodes.push(parsed[0]);
        }

        if (nodes.length > 1) {
            append(VectorCreation(
                nodes.length,
                nodes,
                MNSLNodeInfo.fromTokenInfos([getTokenInfo(token), getTokenInfo(block[block.length - 1])])
            ));
        } else {
            append(SubExpression(
                nodes[0],
                MNSLNodeInfo.fromTokenInfos([getTokenInfo(token), getTokenInfo(block[block.length - 1])])
            ));
        }
    }

    /**
     * This function will parse an identifier.
     * @param value The identifier to parse.
     * @param info The token info.
     */
    public function parseIdentifier(value: String, info: MNSLTokenInfo): Void {
        if (context.getDefine(value) != null) {
            var parseCtx = new MNSLParser(context, context.getDefine(value));
            var parsed = parseCtx._runInternal();
            if (parsed.length == 0) {
                context.emitError(ParserUnexpectedToken(context.getDefine(value)[0], info));
                return;
            }

            if (parsed.length > 1) {
                context.emitError(ParserUnexpectedExpression(parsed[1], null));
                return;
            }

            append(parsed[0]);
            return;
        }

        if (keywords.contains(value)) {
            parseKeyword(value, info);
            return;
        }

        var nextToken = peekCurrentTokenType(0);

        if (nextToken == "LeftParen") {
            parseFunctionCall(value, info);
            return;
        }

        if (value == "true") {
            append(BooleanLiteralNode(true, MNSLNodeInfo.fromTokenInfo(info)));
            return;
        }

        if (value == "false") {
            append(BooleanLiteralNode(false, MNSLNodeInfo.fromTokenInfo(info)));
            return;
        }

        if (keywords.contains(value)) {
            context.emitError(ParserInvalidKeyword(value, info));
            return;
        }

        append(MNSLNode.Identifier(value, MNSLType.TUnknown, MNSLNodeInfo.fromTokenInfo(info)));
    }

    /**
     * This function will parse a keyword.override
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseKeyword(value: String, info: MNSLTokenInfo): Void {
        switch (value) {
            case "func":
                parseFunctionDecl(value, info);

            case "return":
                parseReturnStmt(value, info);

            case "var":
                parseVarDecl(value, info);

            case "if":
                parseIfStmt(value, info);

            case "else":
                if (peekCurrentTokenType(0) == "Identifier" && peekCurrentTokenValue(0) == "if") {
                    currentIndex++;
                    parseElseIfStmt(value, info);
                } else {
                    parseElseStmt(value, info);
                }

            case "while":
                parseWhileStmt(value, info);

            case "for":
                parseForStmt(value, info);

            case "break":
                append(Break(
                    MNSLNodeInfo.fromTokenInfo(info)
                ));

            case "continue":
                append(Continue(
                    MNSLNodeInfo.fromTokenInfo(info)
                ));

            default:
                context.emitError(ParserInvalidKeyword(value, info));
        }
    }

    /**
     * This function will parse a while statement.
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseWhileStmt(value: String, info: MNSLTokenInfo): Void {
        var conditionBlock = getBlock(LeftParen(null), RightParen(null));
        var conditionTokens = splitBlock(conditionBlock, Comma(null));
        var conditions: MNSLNodeChildren = [];

        for (conditionTokens in conditionTokens) {
            var c = new MNSLParser(context, conditionTokens);
            var cond = c._runInternal();
            if (cond.length == 0) {
                context.emitError(ParserUnexpectedToken(conditionTokens[0], info));
                continue;
            }

            if (cond.length > 1) {
                context.emitError(ParserUnexpectedToken(conditionTokens[1], info));
                continue;
            }

            conditions.push(cond[0]);
        }

        if (conditions.length == 0) {
            context.emitError(ParserUnexpectedToken(conditionBlock[0], info));
            return;
        }

        if (conditions.length > 1) {
            context.emitError(ParserUnexpectedToken(conditionBlock[1], info));
            return;
        }

        var bodyBlock = getBlock(LeftBrace(null), RightBrace(null));
        var body = new MNSLParser(context, bodyBlock)._runInternal();

        append(WhileLoop(
            conditions[0],
            body,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(conditionBlock[conditionBlock.length - 1])])
        ));
    }

    /**
     * This function will parse a for statement.
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseForStmt(value: String, info: MNSLTokenInfo): Void {
        var forParamBlock = getBlock(LeftParen(null), RightParen(null));
        var forParamTokens = splitBlock(forParamBlock, Semicolon(null));

        if (forParamTokens.length != 3) {
            context.emitError(ParserUnexpectedToken(forParamBlock[0], info));
            return;
        }

        var initBlock = new MNSLParser(context, forParamTokens[0])._runInternal();
        var conditionBlock = new MNSLParser(context, forParamTokens[1])._runInternal();
        var incrementBlock = new MNSLParser(context, forParamTokens[2])._runInternal();

        if (initBlock.length == 0) {
            context.emitError(ParserUnexpectedToken(forParamTokens[0][0], info));
            return;
        }

        if (conditionBlock.length == 0) {
            context.emitError(ParserUnexpectedToken(forParamTokens[1][0], info));
            return;
        }

        if (incrementBlock.length == 0) {
            context.emitError(ParserUnexpectedToken(forParamTokens[2][0], info));
            return;
        }

        if (initBlock.length > 1) {
            context.emitError(ParserUnexpectedToken(forParamTokens[0][1], info));
            return;
        }

        if (conditionBlock.length > 1) {
            context.emitError(ParserUnexpectedToken(forParamTokens[1][1], info));
            return;
        }

        if (incrementBlock.length > 1) {
            context.emitError(ParserUnexpectedToken(forParamTokens[2][1], info));
            return;
        }

        var bodyBlock = getBlock(LeftBrace(null), RightBrace(null));
        var body = new MNSLParser(context, bodyBlock)._runInternal();

        append(ForLoop(
            initBlock[0],
            conditionBlock[0],
            incrementBlock[0],
            body,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(forParamBlock[forParamBlock.length - 1])])
        ));
    }

    /**
     * This function will parse an if statement.
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseIfStmt(value: String, info: MNSLTokenInfo): Void {
        var conditionBlock = getBlock(LeftParen(null), RightParen(null));
        var conditionTokens = splitBlock(conditionBlock, Comma(null));
        var conditions: MNSLNodeChildren = [];

        for (conditionTokens in conditionTokens) {
            var c = new MNSLParser(context, conditionTokens);
            var cond = c._runInternal();
            if (cond.length == 0) {
                context.emitError(ParserUnexpectedToken(conditionTokens[0], info));
                continue;
            }

            if (cond.length > 1) {
                context.emitError(ParserUnexpectedToken(conditionTokens[1], info));
                continue;
            }

            conditions.push(cond[0]);
        }

        if (conditions.length == 0) {
            context.emitError(ParserUnexpectedToken(conditionBlock[0], info));
            return;
        }

        if (conditions.length > 1) {
            context.emitError(ParserUnexpectedToken(conditionBlock[1], info));
            return;
        }

        var bodyBlock = getBlock(LeftBrace(null), RightBrace(null));
        var body = new MNSLParser(context, bodyBlock)._runInternal();

        append(IfStatement(
            conditions[0],
            body,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(conditionBlock[conditionBlock.length - 1])])
        ));
    }

    /**
     * This function will parse an else statement.
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseElseStmt(value: String, info: MNSLTokenInfo): Void {
        var last = peekLast();
        if (last == null || (!last.match(IfStatement(_, _, _)) && !last.match(ElseIfStatement(_, _, _)))) {
            context.emitError(ParserConditionalWithoutIf(info));
            return;
        }

        var bodyBlock = getBlock(LeftBrace(null), RightBrace(null));
        var body = new MNSLParser(context, bodyBlock)._runInternal();

        append(ElseStatement(
            body,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(bodyBlock[bodyBlock.length - 1])])
        ));
    }

    /**
     * This function will parse an else if statement.
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseElseIfStmt(value: String, info: MNSLTokenInfo): Void {
        var last = peekLast();
        if (last == null || !(last.match(IfStatement(_, _, _)) || last.match(ElseIfStatement(_, _, _)))) {
            context.emitError(ParserConditionalWithoutIf(info));
            return;
        }

        var conditionBlock = getBlock(LeftParen(null), RightParen(null));
        var conditionTokens = splitBlock(conditionBlock, Comma(null));
        var conditions: MNSLNodeChildren = [];

        for (conditionTokens in conditionTokens) {
            var c = new MNSLParser(context, conditionTokens);
            var cond = c._runInternal();
            if (cond.length == 0) {
                context.emitError(ParserUnexpectedToken(conditionTokens[0], info));
                continue;
            }

            if (cond.length > 1) {
                context.emitError(ParserUnexpectedToken(conditionTokens[1], info));
                continue;
            }

            conditions.push(cond[0]);
        }

        if (conditions.length == 0) {
            context.emitError(ParserUnexpectedToken(conditionBlock[0], info));
            return;
        }

        if (conditions.length > 1) {
            context.emitError(ParserUnexpectedToken(conditionBlock[1], info));
            return;
        }

        var bodyBlock = getBlock(LeftBrace(null), RightBrace(null));
        var body = new MNSLParser(context, bodyBlock)._runInternal();

        append(ElseIfStatement(
            conditions[0],
            body,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(conditionBlock[conditionBlock.length - 1])])
        ));
    }

    /**
     * This function will parse a variable declaration.
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseVarDecl(value: String, info: MNSLTokenInfo): Void {
        var name = getCurrentTokenValue();
        if (name == null) {
            context.emitError(ParserUnexpectedToken(tokens[currentIndex], info));
            return;
        }

        var type: MNSLType = MNSLType.TUnknown;
        if (peekCurrentTokenType(0) == "Colon") {
            currentIndex++;

            var typeStr = getCurrentTokenValue();
            if (typeStr == null) {
                context.emitError(ParserUnexpectedToken(tokens[currentIndex], info));
                return;
            }

            type.setTypeStrUnsafe(typeStr);
        }

        var nextToken = peekCurrentTokenType(0);
        if (nextToken == "Assign") {
            currentIndex++;

            var valueBlock = getBlock(None, Semicolon(null), 1);
            var c = new MNSLParser(context, valueBlock);
            var value = c._runInternal();

            if (value.length == 0) {
                context.emitError(ParserUnexpectedToken(valueBlock[0], info));
                return;
            }

            if (value.length > 1) {
                context.emitError(ParserUnexpectedToken(valueBlock[1], info));
                return;
            }

            if (keywords.contains(name)) {
                context.emitError(ParserInvalidKeyword(name, info));
                return;
            }

            append(VariableDecl(
                name,
                type,
                value[0],
                MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(valueBlock[valueBlock.length - 1])])
            ));
            return;
        }

        append(VariableDecl(
            name,
            type,
            null,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(tokens[currentIndex - 1])])
        ));
    }

    /**
     * This function will parse a variable assignment.
     * @param value The identifier to parse.
     * @param info The token info.
     */
    public function parseVarAssign(value: String, info: MNSLTokenInfo): Void {
        var name = pop();

        currentIndex--;
        var assignBlock = getBlock(None, Semicolon(null), 1);

        var c = new MNSLParser(context, assignBlock);
        var value = c._runInternal();

        if (value.length == 0) {
            context.emitError(ParserUnexpectedToken(assignBlock[0], info));
            return;
        }

        if (value.length > 1) {
            context.emitError(ParserUnexpectedToken(assignBlock[1], info));
            return;
        }

        append(VariableAssign(
            name,
            value[0],
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(assignBlock[assignBlock.length - 1])])
        ));
    }

    /**
     * This function will parse an operator assignment.
     * @param token The operator token to parse.
     */
    public function parseOperatorAssignment(token: MNSLToken): Void {
        var oper = token;
        var left: MNSLNode = pop();
        if (left == null) {
            context.emitError(ParserUnexpectedExpression(left, null));
            return;
        }

        var rightTokens: Array<MNSLToken> = [];
        while (currentIndex < tokens.length && !tokens[currentIndex].match(Semicolon(_))) {
            rightTokens.push(tokens[currentIndex]);
            currentIndex++;
        }

        if (rightTokens.length == 0) {
            context.emitError(ParserUnexpectedToken(tokens[currentIndex], null));
            return;
        }

        var right: MNSLNodeChildren = new MNSLParser(context, rightTokens)._runInternal();
        if (right.length == 0) {
            context.emitError(ParserUnexpectedToken(rightTokens[0], null));
            return;
        }

        if (right.length > 1) {
            context.emitError(ParserUnexpectedExpression(right[1], null));
            return;
        }

        append(VariableAssign(
            left,
            BinaryOp(
                left,
                oper,
                right[0],
                MNSLType.TUnknown,
                MNSLNodeInfo.fromTokenInfos([getTokenInfo(oper), getTokenInfo(rightTokens[rightTokens.length - 1])])
            ),
            MNSLNodeInfo.fromTokenInfos([getTokenInfo(oper), getTokenInfo(rightTokens[rightTokens.length - 1])])
        ));
    }


    /**
     * This function will parse a return statement.
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseReturnStmt(value: String, info: MNSLTokenInfo): Void {
        // peek next token
        if (peekCurrentTokenType(0) == "Semicolon") {
            append(Return(
                VoidNode(MNSLNodeInfo.fromTokenInfo(info)),
                MNSLType.TUnknown,
                MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(tokens[currentIndex - 1])])
            ));
            return;
        }

        var returnBlock = getBlock(None, Semicolon(null), 1);

        var c = new MNSLParser(context, returnBlock);
        var ret = c._runInternal();
        if (ret.length == 0) {
            context.emitError(ParserUnexpectedToken(returnBlock[0], info));
            return;
        }

        if (ret.length > 1) {
            context.emitError(ParserUnexpectedToken(returnBlock[returnBlock.length - 1], info));
            return;
        }

        append(Return(
            ret[0],
            MNSLType.TUnknown,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(returnBlock[returnBlock.length - 1])])
        ));
    }

    /**
     * This function will parse a function call.
     * @param value The identifier to parse.
     * @param info The token info.
     */
    public function parseFunctionCall(value: String, info: MNSLTokenInfo): Void {
        var name = value;

        var argsBlock = getBlock(LeftParen(null), RightParen(null));
        var argsTokens = splitBlock(argsBlock, Comma(null));
        var args: MNSLNodeChildren = [];

        for (argTokens in argsTokens) {
            var c = new MNSLParser(context, argTokens);
            var arg = c._runInternal();
            if (arg.length == 0) {
                context.emitError(ParserUnexpectedToken(argTokens[0], info));
                continue;
            }

            if (arg.length > 1) {
                context.emitError(ParserUnexpectedToken(argTokens[1], info));
                continue;
            }

            args.push(arg[0]);
        }

        if (name == "vec2" || name == "vec3" || name == "vec4") {
            var comp: Int = Std.parseInt(name.substr(3));
            var info: MNSLNodeInfo = MNSLNodeInfo.fromTokenInfos([getTokenInfo(argsBlock[0]), getTokenInfo(argsBlock[argsBlock.length - 1])]);

            append(VectorCreation(comp, args, info));
            return;
        }

        append(FunctionCall(
            name,
            args,
            MNSLType.TUnknown,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(argsBlock[argsBlock.length - 1])])
        ));
    }

    /**
     * This function will parse a function declaration.
     * @param value The keyword to parse.
     * @param info The token info.
     */
    public function parseFunctionDecl(value: String, info: MNSLTokenInfo): Void {
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

            var t = c.getCurrentTokenType(1);
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
        var body = new MNSLParser(context, bodyBlock)._runInternal();

        append(FunctionDecl(
            name,
            returnType,
            params,
            body,
            MNSLNodeInfo.fromTokenInfos([info, getTokenInfo(bodyBlock[bodyBlock.length - 1])])
        ));
    }

    /**
     * Parse operator
     * @param token The token that is the operator.
     */
    public function parseOperator(token: MNSLToken): Void {
        var precedence = getPrecedence(token);
        var left: MNSLNode = pop();

        var rightTokens: Array<MNSLToken> = [];
        var subExprDepth: Int = 0;

        while (currentIndex < tokens.length) {
            if (tokens[currentIndex].match(LeftParen(_))){
                subExprDepth++;
            }

            if (isOperator(tokens[currentIndex]) && getPrecedence(tokens[currentIndex]) < (precedence + 1) && subExprDepth == 0 && rightTokens.length > 0) {
                break;
            }

            if (tokens[currentIndex].match(RightParen(_))){
                subExprDepth--;
            }

            rightTokens.push(tokens[currentIndex]);
            currentIndex++;
        }

        var right: MNSLNodeChildren = new MNSLParser(context, rightTokens)._runInternal();
        if (right.length == 0) {
            context.emitError(ParserUnexpectedToken(tokens[currentIndex], null));
            return;
        }

        if (right.length > 1) {
            context.emitError(ParserUnexpectedExpression(right[1], null));
            return;
        }

        if (left == null) {
            append(UnaryOp(
                token,
                right[0],
                MNSLNodeInfo.fromTokenInfos([getTokenInfo(rightTokens[0]), getTokenInfo(rightTokens[rightTokens.length - 1])])
            ));
            return;
        }

        append(BinaryOp(
            left,
            token,
            right[0],
            MNSLType.TUnknown,
            MNSLNodeInfo.fromTokenInfos([getTokenInfo(rightTokens[0]), getTokenInfo(rightTokens[rightTokens.length - 1])])
        ));
    }

    /**
     * Append a node to the current body.
     * @param node The node to append.
     */
    public function append(node: MNSLNode): Void {
        ast.push(node);
    }

    /**
     * Pop the last added node from the AST.
     * @return The last added node.
     */
    public function pop(): MNSLNode {
        if (ast.length == 0) {
            return null;
        }

        return ast.pop();
    }

    /**
     * Peek the last added node from the AST.
    * @return The last added node.
    */
    public function peekLast(): MNSLNode {
        if (ast.length == 0) {
            return null;
        }

        return ast[ast.length - 1];
    }

    /**
     * Get a block of tokens.
     * @param start The start token.
     * @param end The end token.
     */
    public function getBlock(start: MNSLToken, end: MNSLToken, startDepth: Int = 0, inc: Int = 1): Array<MNSLToken> {
        var block: Array<MNSLToken> = [];
        var depth: Int = startDepth;
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

        if (block[0] != null && startDepth == 0 && EnumValueTools.getName(block[0]) != startTokenType) {
            context.emitError(ParserUnexpectedToken(block[0], null));
            return [];
        }

        currentIndex += inc;

        return startDepth == 0 ? block.slice(1, block.length) : block;
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
        var depth = 0;

        for (token in block) {
            var tokenName = EnumValueTools.getName(token);

            if (tokenName == "LeftParen") {
                depth++;
            }

            if (tokenName == "RightParen") {
                depth--;
            }

            if (tokenName == sepType && depth == 0) {
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
        if (token == null) {
            return null;
        }

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
    public function getCurrentTokenType(inc: Int): String {
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
    public function peekCurrentToken(inc: Int): MNSLToken {
        var t = tokens[currentIndex + inc];
        if (t == null) {
            return null;
        }

        return t;
    }

    /**
     * Peek the current token type.
     */
    public function peekCurrentTokenType(inc: Int): String {
        var t = tokens[currentIndex + inc];
        if (t == null) {
            return null;
        }

        return EnumValueTools.getName(t);
    }

    /**
     * Peek the current token value.
     */
    public function peekCurrentTokenValue(inc: Int): String {
        var t = tokens[currentIndex + inc];
        if (t == null) {
            return null;
        }

        return getTokenValue(t);
    }

    /**
     * Get the precedence of an operator.
     * @param op The operator to get the precedence for.
     */
    private function getPrecedence(op: MNSLToken): Int {
        switch (op) {
            case MNSLToken.Or(_):
                return 1;
            case MNSLToken.And(_):
                return 2;
            case MNSLToken.Equal(_), MNSLToken.NotEqual(_):
                return 3;
            case MNSLToken.Less(_), MNSLToken.LessEqual(_), MNSLToken.Greater(_), MNSLToken.GreaterEqual(_):
                return 4;
            case MNSLToken.Plus(_), MNSLToken.Minus(_):
                return 5;
            case MNSLToken.Star(_), MNSLToken.Slash(_), MNSLToken.Percent(_):
                return 6;
            case MNSLToken.Not(_):
                return 7;
            default:
                throw "Unknown operation: " + op;
        }
    }

    /**
     * Checks if the current token is a operator.
     * @param token The token to check.
     */
    public function isOperator(token: MNSLToken): Bool {
        var name = EnumValueTools.getName(token);
        return operators.indexOf(name) != -1;
    }

}
