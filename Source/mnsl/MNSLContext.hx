package mnsl;
import mnsl.tokenizer.MNSLTokenizer;
import mnsl.tokenizer.MNSLToken;
import mnsl.parser.MNSLParser;

class MNSLContext {

    /**
     * Creates a new MNSLContext instance.
     * @param source The source code to be parsed.
     */
    public function new(source: String) {
        var tokenizer: MNSLTokenizer = new MNSLTokenizer(this, source);
        var tokens: Array<MNSLToken> = tokenizer.run();

        for (token in tokens) {
            trace(token);
        }

        var parser = new MNSLParser(this, tokens);
        //var ast = parser.run();
    }

}
