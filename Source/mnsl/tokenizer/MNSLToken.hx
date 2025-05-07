package mnsl.tokenizer;
import mnsl.tokenizer.MNSLTokenInfo;

enum MNSLToken {
    Identifier(value: String, info: MNSLTokenInfo);
    IntegerLiteral(value: String, info: MNSLTokenInfo);
    FloatLiteral(value: String, info: MNSLTokenInfo);
    StringLiteral(value: String, info: MNSLTokenInfo);
    LeftParen(info: MNSLTokenInfo);
    RightParen(info: MNSLTokenInfo);
    LeftBracket(info: MNSLTokenInfo);
    RightBracket(info: MNSLTokenInfo);
    LeftBrace(info: MNSLTokenInfo);
    RightBrace(info: MNSLTokenInfo);
    Comma(info: MNSLTokenInfo);
    Dot(info: MNSLTokenInfo);
    Minus(info: MNSLTokenInfo);
    Plus(info: MNSLTokenInfo);
    Semicolon(info: MNSLTokenInfo);
    Slash(info: MNSLTokenInfo);
    Star(info: MNSLTokenInfo);
    Percent(info: MNSLTokenInfo);
    Question(info: MNSLTokenInfo);
    Assign(info: MNSLTokenInfo);
    Equal(info: MNSLTokenInfo);
    Colon(info: MNSLTokenInfo);
    Spread(info: MNSLTokenInfo);
    And(info: MNSLTokenInfo);
    Or(info: MNSLTokenInfo);
    Less(info: MNSLTokenInfo);
    Greater(info: MNSLTokenInfo);
    LessEqual(info: MNSLTokenInfo);
    GreaterEqual(info: MNSLTokenInfo);
    NotEqual(info: MNSLTokenInfo);
    Not(info: MNSLTokenInfo);
}