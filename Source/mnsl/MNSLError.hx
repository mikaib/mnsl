package mnsl;

import mnsl.tokenizer.MNSLTokenInfo;
import mnsl.tokenizer.MNSLToken;
import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeInfo;
import mnsl.analysis.MNSLAnalyserFunction;
import mnsl.analysis.MNSLConstraint;
import mnsl.analysis.MNSLType;
import mnsl.parser.MNSLNodeChildren;

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
    AnalyserMissingReturn(func: MNSLAnalyserFunction, node: MNSLNodeChildren);
    AnalyserMismatchingType(constraint: MNSLConstraint);
    AnalyserUnknownType(type: MNSLType, node: MNSLNode);
    AnalyserUnresolvedConstraint(constraint: MNSLConstraint);
    AnalyserInvalidAssignment(on: MNSLNode);
    AnalyserInvalidAccess(on: MNSLNode);
    AnalyserInvalidVectorComponent(comp: Int, info: MNSLNodeInfo);
    AnalyserRecursiveFunction(functionName: String, recursionChain: Array<String>, info: MNSLNodeInfo);
    AnalyserUnknownVectorComponent(node: MNSLNode, info: MNSLNodeInfo);
    AnalyserInvalidBinop(tLeft: MNSLType, tRight: MNSLType, op: String, constraint: MNSLConstraint);
    AnalyserInvalidUnaryOp(op: MNSLToken, info: MNSLNodeInfo);
    AnalyserLoopKeywordOutsideLoop(node: MNSLNode, info: MNSLNodeInfo);
    AnalyserMismatchingEitherType(limits: Array<MNSLType>, node: MNSLNode);
    AnalyserUnknownArraySize(type: MNSLType, node: MNSLNode);
    AnalyserReadOnlyAssignment(node: MNSLNode);
    AnalyserVariableOutsideFunction(name: String, node: MNSLNode, info: MNSLNodeInfo);
    AnalyserInvalidReturnType(func: MNSLAnalyserFunction, expected: MNSLType, actual: MNSLType);
    AnalyserInvalidArrayAccess(on: MNSLNode, index: MNSLNode, info: MNSLNodeInfo);
    AnalyserInvalidVectorArrayAccess(on: MNSLNode, index: MNSLNode, info: MNSLNodeInfo);
    AnalyserMissingMainFunction;
}
