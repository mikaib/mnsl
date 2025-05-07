package mnsl.parser;

import mnsl.tokenizer.MNSLToken;

class MNSLParser {

    private var currentIndex: Int;
    private var tokens: Array<MNSLToken>;
    private var context: MNSLContext;
    private var ast: MNSLNodeChildren;

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

            switch (token) {
                default:
                    throw "Unknown token type: " + token;
            }
        }
        return ast;
    }

}
