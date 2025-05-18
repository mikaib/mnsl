package mnsl;
import mnsl.parser.MNSLNodeChildren;

class MNSLPrinter {

    private var _context: MNSLContext;
    private var _ast: MNSLNodeChildren;
    private var _output: String;
    private var _indent: Int;
    private var _inline: Bool;
    private var _inlineCounter: Int;

    /**
     * Creates a new printer.
     * @param ast The AST to print.
     */
    public function new(context: MNSLContext) {
        _output = "";
        _indent = 0;
        _ast = context.getAST();
        _context = context;
        _inline = false;
        _inlineCounter = 0;
    }

    /**
     * Enables inline printing.
     */
    public function enableInline(): Void {
        _inlineCounter++;

        if (_inlineCounter >= 1) {
            _inline = true;
        }
    }

    /**
     * Disables inline printing.
     */
    public function disableInline(): Void {
        _inlineCounter--;

        if (_inlineCounter <= 0) {
            _inline = false;
        }
    }

    /**
     * Runs the printer.
     */
    public function run(): Void {
        // TODO: impl
    }

    /**
     * Template a string
     * @param content The content to print.
     * @param args The arguments to format the content.
     */
    public function template(content: String, args: Array<Dynamic>): String {
        var result = content;

        for (i in 0...args.length) {
            var arg = args[i];
            result = StringTools.replace(result, "{" + i + "}", Std.string(arg));
        }

        return result;
    }

    /**
     * Prints a new line (indented)
     * @param content The content to print.
     * @param args The arguments to format the content.
     */
    public function printlnIndented(content: String, ...args: Dynamic): Void {
        if (_inline) {
            return println(content, ...args);
        }

        _output += StringTools.lpad("", " ", _indent) + template(content, args) + "\n";
    }

    /**
     * Prints a new line
     * @param content The content to print.
     * @param args The arguments to format the content.
     */
    public function println(content: String, ...args: Dynamic): Void {
        _output += template(content, args) + (_inline ? "" : "\n");
    }

    /**
     * Prints on the same line
     * @param content The content to print.
     * @param args The arguments to format the content.
     */
    public function print(content: String, ...args: Dynamic): Void {
        _output += template(content, args);
    }

    /**
     * Prints on the same line (indented)
     * @param content The content to print.
     * @param args The arguments to format the content.
     */
    public function printIndented(content: String, ...args: Dynamic): Void {
        if (_inline) {
            return print(content, ...args);
        }

        _output += StringTools.lpad("", " ", _indent) + template(content, args);
    }

    /**
     * Removes last trailing new line
     */
    public function removeLastNewLine(): Void {
        if (_output.length > 0 && _output.charAt(_output.length - 1) == "\n") {
            _output = _output.substr(0, _output.length - 1);
        }
    }

    /**
     * Removes the last semicolon
     */
    public function removeLastSemicolon(): Void {
        if (_output.length > 0 && _output.charAt(_output.length - 1) == ";") {
            _output = _output.substr(0, _output.length - 1);
        }
    }

    /**
     * Increases the indentation level
     */
    public function increaseIndent(by: Int = 1): Void {
        _indent += 4 * by;
    }

    /**
     * Decreases the indentation level
     */
    public function decreaseIndent(by: Int = 1): Void {
        _indent = Std.int(Math.max(0, _indent - (4 * by)));
    }

    /**
     * Sets the indentation level
     * @param indent The new indentation level.
     */
    public function setIndent(indent: Int): Void {
        _indent = indent * 4;
    }

    /**
     * Get the printed output
     * @return The printed output.
     */
    public function getOutput(): String {
        return _output;
    }

}
