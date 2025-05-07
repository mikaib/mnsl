package mnsl.tokenizer;

using StringTools;

class MNSLTokenizer {

    private var source: String;
    private var position: Int;
    private var length: Int;
    private var context: MNSLContext;

    /**
     * The MNSLTokenizer class is used to tokenize MNSL (Mana Shader Language) source code. (dot mns files)
     * @param source The MNSL source code to tokenize.
     */
    public function new(context: MNSLContext, source:String) {
        this.source = source
            .replace("\r\n", "\n")
            .replace("\r", "\n");

        this.position = 0;
        this.length = source.length;
        this.context = context;
    }

    /**
     * Runs the tokenizer and returns a list of tokens.
     */
    public function run(): Array<MNSLToken> {
        var tokens: Array<MNSLToken> = [];
        var line: Int = 1;
        var column: Int = 0;

        while (position < length) {
            var char = source.charAt(position);
            var initialPosition: Int = position;
            
            switch (char) {
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

                case '(':
                    tokens.push(MNSLToken.LeftParen({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case ')':
                    tokens.push(MNSLToken.RightParen({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '[':
                    tokens.push(MNSLToken.LeftBracket({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case ']':
                    tokens.push(MNSLToken.RightBracket({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case "{":
                    tokens.push(MNSLToken.LeftBrace({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case "}":
                    tokens.push(MNSLToken.RightBrace({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case ',':
                    tokens.push(MNSLToken.Comma({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '-':
                    tokens.push(MNSLToken.Minus({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '+':
                    tokens.push(MNSLToken.Plus({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case ';':
                    tokens.push(MNSLToken.Semicolon({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '/':
                    if (source.charAt(position + 1) == '/') {
                        while (position < length && source.charAt(position) != '\n') {
                            position++;
                            column++;
                        }
                    } else {
                        tokens.push(MNSLToken.Slash({ line: line, column: column, length: 1, position: initialPosition }));
                        position++;
                        column++;
                    }

                case '*':
                    if (source.charAt(position + 1) == '*') {
                        while (position < length && !(source.charAt(position) == '*' && source.charAt(position + 1) == '/')) {
                            position++;
                            column++;
                        }
                        position += 2;
                        column += 2;
                    } else {
                        tokens.push(MNSLToken.Star({ line: line, column: column, length: 1, position: initialPosition }));
                        position++;
                        column++;
                    }

                case '%':
                    tokens.push(MNSLToken.Percent({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '?':
                    tokens.push(MNSLToken.Question({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '=':
                    if (source.charAt(position + 1) == '=') {
                        tokens.push(MNSLToken.Equal({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        tokens.push(MNSLToken.Assign({ line: line, column: column, length: 1, position: initialPosition }));
                        position++;
                        column++;
                    }

                case ':':
                    tokens.push(MNSLToken.Colon({ line: line, column: column, length: 1, position: initialPosition }));
                    position++;
                    column++;

                case '&':
                    if (source.charAt(position + 1) == '&') {
                        tokens.push(MNSLToken.And({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        tokens.push(MNSLToken.And({ line: line, column: column, length: 1, position: initialPosition })); // TODO: Handle bitwise AND
                        position++;
                        column++;
                    }

                case '|':
                    if (source.charAt(position + 1) == '|') {
                        tokens.push(MNSLToken.Or({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        tokens.push(MNSLToken.Or({ line: line, column: column, length: 1, position: initialPosition })); // TODO: Handle bitwise OR
                        position++;
                        column++;
                    }

                case '<':
                    if (source.charAt(position + 1) == '=') {
                        tokens.push(MNSLToken.LessEqual({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        tokens.push(MNSLToken.Less({ line: line, column: column, length: 1, position: initialPosition })); // TODO: Handle bitwise left shift
                        position++;
                        column++;
                    }

                case '>':
                    if (source.charAt(position + 1) == '=') {
                        tokens.push(MNSLToken.GreaterEqual({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        tokens.push(MNSLToken.Greater({ line: line, column: column, length: 1, position: initialPosition })); // TODO: Handle bitwise right shift
                        position++;
                        column++;
                    }

                case '!':
                    if (source.charAt(position + 1) == '=') {
                        tokens.push(MNSLToken.NotEqual({ line: line, column: column, length: 2, position: initialPosition }));
                        position += 2;
                        column += 2;
                    } else {
                        tokens.push(MNSLToken.Not({ line: line, column: column, length: 1, position: initialPosition }));
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
                        tokens.push(MNSLToken.StringLiteral(source.substr(start + 1, position - start - 1), { line: line, column: column, length: position - start, position: initialPosition }));
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
                        tokens.push(MNSLToken.StringLiteral(source.substr(start + 1, position - start - 1), { line: line, column: column, length: position - start, position: initialPosition }));
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
                        tokens.push(MNSLToken.Spread({ line: line, column: column, length: 3, position: initialPosition }));
                        position += 3;
                        column += 3;
                    } else {
                        tokens.push(MNSLToken.Dot({ line: line, column: column, length: 1, position: initialPosition }));
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
                            tokens.push(MNSLToken.FloatLiteral(value, { line: line, column: column, length: position - start, position: initialPosition }));
                        } else {
                            tokens.push(MNSLToken.IntegerLiteral(value, { line: line, column: column, length: position - start, position: initialPosition }));
                        }
                    } else if (charCode >= 65 && charCode <= 90 || charCode >= 97 && charCode <= 122 || charCode == 95) { // A-Z, a-z, _
                        var start = position;
                        while (position < length && (isLetter(source.charCodeAt(position)) || isDigit(source.charCodeAt(position)) || source.charAt(position) == '_')) {
                            position++;
                            column++;
                        }
                        var value = source.substr(start, position - start);
                        tokens.push(MNSLToken.Identifier(value, { line: line, column: column, length: position - start, position: initialPosition }));
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
