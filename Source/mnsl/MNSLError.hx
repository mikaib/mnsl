package mnsl;

import mnsl.tokenizer.MNSLTokenInfo;
import mnsl.tokenizer.MNSLToken;
import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeInfo;
import mnsl.analysis.MNSLAnalyserFunction;
import mnsl.analysis.MNSLConstraint;
import mnsl.analysis.MNSLType;

enum MNSLError {
    TokenizerInvalidChar(char: Int, pos: MNSLTokenInfo);
    TokenizerPreprocessorError(msg: String, pos: MNSLTokenInfo);
    TokenizerUnterminatedString(pos: MNSLTokenInfo);
    ParserInvalidToken(token: MNSLToken);
    ParserInvalidKeyword(value: String, pos: MNSLTokenInfo);
    ParserUnexpectedToken(token: MNSLToken, pos: MNSLTokenInfo);
    ParserUnexpectedExpression(node: MNSLNode, pos: MNSLNodeInfo);
    ParserConditionalWithoutIf(pos: MNSLTokenInfo);
    AnalyserNoImplementation(fn: MNSLAnalyserFunction, pos: MNSLNodeInfo);
    AnalyserDuplicateVariable(name: String, pos: MNSLNodeInfo);
    AnalyserUndeclaredVariable(name: String, pos: MNSLNodeInfo);
    AnalyserReturnOutsideFunction(pos: MNSLNodeInfo);
    AnalyserMismatchingType(constraint: MNSLConstraint);
    AnalyserUnresolvedConstraint(constraint: MNSLConstraint);
    AnalyserInvalidAssignment(on: MNSLNode);
    AnalyserInvalidAccess(on: MNSLNode);
    AnalyserInvalidVectorComponent(comp: Int, info: MNSLNodeInfo);
    AnalyserUnknownVectorComponent(node: MNSLNode, info: MNSLNodeInfo);
    AnalyserInvalidBinop(tLeft: MNSLType, tRight: MNSLType, op: String, constraint: MNSLConstraint);
    AnalyserInvalidUnaryOp(op: MNSLToken, info: MNSLNodeInfo);
    AnalyserLoopKeywordOutsideLoop(node: MNSLNode, info: MNSLNodeInfo);
    AnalyserMismatchingEitherType(limits: Array<MNSLType>, node: MNSLNode);
}
