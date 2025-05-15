package mnsl;

import mnsl.tokenizer.MNSLTokenInfo;
import mnsl.tokenizer.MNSLToken;
import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeInfo;
import mnsl.analysis.MNSLAnalyserFunction;

enum MNSLError {
    TokenizerInvalidChar(char: Int, pos: MNSLTokenInfo);
    TokenizerUnterminatedString(pos: MNSLTokenInfo);
    ParserInvalidToken(token: MNSLToken);
    ParserInvalidKeyword(value: String, pos: MNSLTokenInfo);
    ParserUnexpectedToken(token: MNSLToken, pos: MNSLTokenInfo);
    ParserUnexpectedExpression(node: MNSLNode, pos: MNSLNodeInfo);
    AnalyserNoImplementation(fn: MNSLAnalyserFunction);
}
