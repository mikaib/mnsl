package mnsl.tokenizer;

using StringTools;

class MNSLTokenizer {

    private var source: String;
    private var position: Int;
    private var length: Int;
    private var context: MNSLContext;
    private var defines: Map<String, Dynamic>;
    private var conditionStack: Array<{wasActive: Bool, wasSkipping: Bool, conditionResult: Bool, hasElse: Bool}>;

    /**
     * The MNSLTokenizer class is used to tokenize MNSL (Mana Shader Language) source code. (dot mns files)
     * @param source The MNSL source code to tokenize.
     */
    public function new(context: MNSLContext, source: String, defines: Map<String, Dynamic>) {
        this.source = source
            .replace("\r\n", "\n")
            .replace("\r", "\n");

        this.position = 0;
        this.length = source.length;
        this.context = context;
        this.defines = defines;
        this.conditionStack = [];
    }

    /**
     * Evaluates a condition string against the defined preprocessor directives.
     * @param condition The condition string to evaluate.
     * @return True if the condition is met, false otherwise.
     */
    private function evaluateCondition(condition: String): Bool {
        if (condition.indexOf("||") != -1) {
            var parts = condition.split("||");
            for (part in parts) {
                if (evaluateCondition(part.trim())) {
                    return true;
                }
            }
            return false;
        }

        if (condition.indexOf("&&") != -1) {
            var parts = condition.split("&&");
            for (part in parts) {
                if (!evaluateCondition(part.trim())) {
                    return false;
                }
            }
            return true;
        }

        if (condition.startsWith("!")) {
            return !defines.exists(condition.substr(1).trim());
        } else {
            return defines.exists(condition.trim());
        }
    }

    /**
     * Runs the tokenizer and returns a list of tokens.
     */
    public function run(): Array<MNSLToken> {
        var tokens: Array<MNSLToken> = [];
        var line: Int = 1;
        var column: Int = 0;

        var skipActive: Bool = false;
        var condActive: Bool = false;
        var condResult: Bool = true;

        var appendToken = (token: MNSLToken) -> {
            if (!skipActive) {
                tokens.push(token);
            }
        };

        while (position < length) {
            var char = source.charAt(position);
            var initialPosition: Int = position;

            switch (char) {
                case '#':
                    position++;
                    column++;
                    var cmd = "";
                    while (position < length && isLetter(source.charCodeAt(position))) {
                        cmd += source.charAt(position);
                        position++;
                        column++;
                    }

                    cmd = cmd.toLowerCase();
                    var args = [];
                    while (position < length && source.charAt(position) != '\n') {
                        if (source.charAt(position) == ' ') {
                            position++;
                            column++;
                        } else {
                            var arg = "";
                            while (position < length && source.charAt(position) != ' ' && source.charAt(position) != '\n') {
                                if (source.charAt(position) == '"' || source.charAt(position) == '\'') {
                                    position++;
                                    column++;
                                    continue;
                                }
                                arg += source.charAt(position);
                                position++;
                                column++;
                            }
                            args.push(arg);
                        }
                    }

                    position++;
                    column = 0;
                    line++;

                    if (cmd == "if") {
                        if (args.length == 0) {
                            context.emitError(TokenizerPreprocessorError(
                                "Missing condition for #if directive",
                                {
                                    line: line,
                                    column: column,
                                    length: position - initialPosition,
                                    position: initialPosition
                                }
                            ));
                        } else {
                            var condition = args.join(" ");
                            var result = evaluateCondition(condition);

                            conditionStack.push({
                                wasActive: condActive,
                                wasSkipping: skipActive,
                                conditionResult: result,
                                hasElse: false
                            });

                            condActive = true;
                            skipActive = skipActive || !result;
                        }
                    } else if (cmd == "else" && condActive) {
                        if (conditionStack.length > 0) {
                            var currentState = conditionStack[conditionStack.length - 1];
                            if (currentState.hasElse) {
                                context.emitError(TokenizerPreprocessorError(
                                    "Multiple #else directives for single #if",
                                    {
                                        line: line,
                                        column: column,
                                        length: position - initialPosition,
                                        position: initialPosition
                                    }
                                ));
                            } else {
                                currentState.hasElse = true;
                                skipActive = currentState.wasSkipping || currentState.conditionResult;
                            }
                        }
                    } else if (cmd == "end") {
                        if (conditionStack.length > 0) {
                            var state = conditionStack.pop();
                            skipActive = state.wasSkipping;
                            condActive = state.wasActive;
                        } else {
                            context.emitError(TokenizerPreprocessorError(
                                "#end without matching #if",
                                {
                                    line: line,
                                    column: column,
                                    length: position - initialPosition,
                                    position: initialPosition
                                }
                            ));
                        }
                    } else if (cmd == "include" && !skipActive) {
                        var sourceStr = context.getOptions().preprocessorIncludeFunc(args[0], context.getOptions().rootPath);
                        if (sourceStr == null) {
                            context.emitError(TokenizerPreprocessorError(
                                "Failed to include file: " + args[0],
                                {
                                    line: line,
                                    column: column,
                                    length: position - initialPosition,
                                    position: initialPosition
                                }
                            ));
                        } else {
                            var tokenizer = new MNSLTokenizer(context, sourceStr, defines);
                            var includedTokens = tokenizer.run();
                            for (token in includedTokens) {
                                appendToken(token);
                            }
                        }
                    } else {
                        context.emitError(TokenizerPreprocessorError(
                            "Unknown or invalid preprocessor command: #" + cmd,
                            {
                                line: line,
                                column: column,
                                length: position - initialPosition,
                                position: initialPosition
                            }
                        ));
                    }

                case '\t':
                    column += 4;
                    position++;

                case '\n':
                    line++;
                    column = 0;
                    position++;

                case ' ':
                    column++;
                    position++;

                case '@':
                    appendToken(MNSLToken.At({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '(':
                    appendToken(MNSLToken.LeftParen({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case ')':
                    appendToken(MNSLToken.RightParen({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '[':
                    appendToken(MNSLToken.LeftBracket({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;


                case ']':
                    appendToken(MNSLToken.RightBracket({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case "{":
                    appendToken(MNSLToken.LeftBrace({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case "}":
                    appendToken(MNSLToken.RightBrace({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case ',':
                    appendToken(MNSLToken.Comma({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '-':
                    if (source.charAt(position + 1) == '>') {
                        appendToken(MNSLToken.Arrow({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                        continue;
                    }

                    appendToken(MNSLToken.Minus({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                    if (source.charAt(position) == "-") {
                        appendToken(MNSLToken.Assign({ line: line, column: column, length: 2, position: initialPosition }));
                        appendToken(MNSLToken.IntegerLiteral("1", { line: line, column: column, length: 1, position: initialPosition }));
                        position++;
                        column++;
                    }
                case '+':
                    appendToken(MNSLToken.Plus({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                    if (source.charAt(position) == "+") {
                        appendToken(MNSLToken.Assign({ line: line, column: column, length: 2, position: initialPosition }));
                        appendToken(MNSLToken.IntegerLiteral("1", { line: line, column: column, length: 1, position: initialPosition }));
                        position++;
                        column++;
                    }

                case ';':
                    appendToken(MNSLToken.Semicolon({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '/':
                    if (source.charAt(position + 1) == '/') {
                        while (position < length && source.charAt(position) != '\n') {
                            position++;
                            column++;
                        }
                    } else {
                        appendToken(MNSLToken.Slash({ line: line, column: column, length: 1, position: initialPosition }));
                        position++;
                        column++;
                    }

                case '*':
                    appendToken(MNSLToken.Star({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '%':
                    appendToken(MNSLToken.Percent({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '?':
                    appendToken(MNSLToken.Question({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '=':
                    if (source.charAt(position + 1) == '=') {
                        appendToken(MNSLToken.Equal({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        appendToken(MNSLToken.Assign({ line: line, column: column, length: 1, position: initialPosition }));
                        position++;
                        column++;
                    }

                case ':':
                    appendToken(MNSLToken.Colon({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '&':
                    if (source.charAt(position + 1) == '&') {
                        appendToken(MNSLToken.And({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        appendToken(MNSLToken.And({ line: line, column: column, length: 1, position: initialPosition })); // TODO: Handle bitwise AND
                        position++;
                        column++;
                    }

                case '|':
                    if (source.charAt(position + 1) == '|') {
                        appendToken(MNSLToken.Or({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        appendToken(MNSLToken.Or({ line: line, column: column, length: 1, position: initialPosition })); // TODO: Handle bitwise OR
                        position++;
                        column++;
                    }

                case '<':
                    if (source.charAt(position + 1) == '=') {
                        appendToken(MNSLToken.LessEqual({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        appendToken(MNSLToken.Less({ line: line, column: column, length: 1, position: initialPosition })); // TODO: Handle bitwise left shift
                        position++;
                        column++;
                    }

                case '>':
                    if (source.charAt(position + 1) == '=') {
                        appendToken(MNSLToken.GreaterEqual({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        appendToken(MNSLToken.Greater({ line: line, column: column, length: 1, position: initialPosition })); // TODO: Handle bitwise right shift
                        position++;
                        column++;
                    }

                case '!':
                    if (source.charAt(position + 1) == '=') {
                        appendToken(MNSLToken.NotEqual({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        appendToken(MNSLToken.Not({ line: line, column: column, length: 1, position: initialPosition }));
                        position++;
                        column++;
                    }

                case '"':
                    var start = position;
                    position++;
                    column++;
                    while (position < length && source.charAt(position) != '"') {
                        if (source.charAt(position) == '\\') {
                            position++;
                            column++;
                        }
                        position++;
                        column++;
                    }

                    position++;
                    column++;

                    if (position < length) {
                        appendToken(MNSLToken.StringLiteral(source.substr(start + 1, position - start - 2), { line: line, column: column, length: position - start, position: initialPosition }));
                    } else {
                        context.emitError(TokenizerUnterminatedString({
                            line: line,
                            column: column,
                            length: position - start,
                            position: initialPosition
                        }));
                    }

                case '\'':
                    var start = position;
                    position++;
                    column++;
                    while (position < length && source.charAt(position) != '\'') {
                        if (source.charAt(position) == '\\') {
                            position++;
                            column++;
                        }
                        position++;
                        column++;
                    }

                    position++;
                    column++;

                    if (position < length) {
                        appendToken(MNSLToken.StringLiteral(source.substr(start + 1, position - start - 1), { line: line, column: column, length: position - start, position: initialPosition }));
                    } else {
                        context.emitError(TokenizerUnterminatedString({
                            line: line,
                            column: column,
                            length: position - start,
                            position: initialPosition
                        }));
                    }

                case '.':
                    if (source.charAt(position + 1) == '.' && source.charAt(position + 2) == '.') {
                        appendToken(MNSLToken.Spread({ line: line, column: column, length: 3, position: initialPosition }));
                        position += 3;
                        column += 3;
                    } else {
                        appendToken(MNSLToken.Dot({ line: line, column: column, length: 1, position: initialPosition }));
                        position++;
                        column++;
                    }

                default:
                    var charCode = char.charCodeAt(0);
                    if (charCode >= 48 && charCode <= 57) {
                        var start = position;
                        var hasDot = false;
                        while (position < length && (isDigit(source.charCodeAt(position)) || (!hasDot && source.charAt(position) == '.'))) {
                            if (source.charAt(position) == '.') {
                                hasDot = true;
                            }
                            position++;
                            column++;
                        }
                        var value = source.substr(start, position - start);
                        if (hasDot) {
                            appendToken(MNSLToken.FloatLiteral(value, { line: line, column: column, length: position - start, position: initialPosition }));
                        } else {
                            appendToken(MNSLToken.IntegerLiteral(value, { line: line, column: column, length: position - start, position: initialPosition }));
                        }
                    } else if (charCode >= 65 && charCode <= 90 || charCode >= 97 && charCode <= 122 || charCode == 95) { // A-Z, a-z, _
                        var start = position;
                        while (position < length && (isLetter(source.charCodeAt(position)) || isDigit(source.charCodeAt(position)) || source.charAt(position) == '_')) {
                            position++;
                            column++;
                        }
                        var value = source.substr(start, position - start);
                        appendToken(MNSLToken.Identifier(value, { line: line, column: column, length: position - start, position: initialPosition }));
                    } else {
                        position++;
                        column++;

                        if (charCode == null) {
                            continue;
                        }

                        context.emitError(TokenizerInvalidChar(charCode, {
                            line: line,
                            column: column,
                            length: 1,
                            position: initialPosition
                        }));
                    }

            }
        }

        return tokens;
    }

    private function isDigit(charCode: Int): Bool {
        return charCode >= 48 && charCode <= 57;
    }

    private function isLetter(charCode: Int): Bool {
        return (charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122);
    }

}
