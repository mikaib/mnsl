package mnsl;

import mnsl.tokenizer.MNSLTokenInfo;
import mnsl.tokenizer.MNSLToken;

enum MNSLError {
    TokenizerInvalidChar(char: Int, pos: MNSLTokenInfo);
    TokenizerUnterminatedString(pos: MNSLTokenInfo);
    ParserInvalidToken(token: MNSLToken);
    ParserInvalidKeyword(value: String, pos: MNSLTokenInfo);
    ParserUnexpectedToken(token: MNSLToken, pos: MNSLTokenInfo);
}
