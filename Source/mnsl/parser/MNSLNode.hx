package mnsl.parser;

import mnsl.analysis.MNSLType;
import mnsl.analysis.MNSLFuncArgs;
import mnsl.tokenizer.MNSLToken;

enum MNSLNode {
    // functions
    FunctionDecl(name: String, returnType: MNSLType, arguments: MNSLFuncArgs, body: MNSLNodeChildren, info: MNSLNodeInfo);
    FunctionCall(name: String, args: MNSLNodeChildren, returnType: MNSLType, info: MNSLNodeInfo);
    Return(value: MNSLNode, type: MNSLType, info: MNSLNodeInfo);

    // variables
    VariableDecl(name: String, type: MNSLType, value: MNSLNode, info: MNSLNodeInfo);
    VariableAssign(name: MNSLNode, value: MNSLNode, info: MNSLNodeInfo);
    Identifier(name: String, type: MNSLType, info: MNSLNodeInfo);

    // if statements
    IfStatement(condition: MNSLNode, body: MNSLNodeChildren, info: MNSLNodeInfo);
    ElseIfStatement(condition: MNSLNode, body: MNSLNodeChildren, info: MNSLNodeInfo);
    ElseStatement(body: MNSLNodeChildren, info: MNSLNodeInfo);

    // operations
    BinaryOp(left: MNSLNode, op: MNSLToken, right: MNSLNode, info: MNSLNodeInfo);
    UnaryOp(op: MNSLToken, right: MNSLNode, info: MNSLNodeInfo);

    // loops
    WhileLoop(condition: MNSLNode, body: MNSLNodeChildren, info: MNSLNodeInfo);
    ForLoop(init: MNSLNode, condition: MNSLNode, increment: MNSLNode, body: MNSLNodeChildren, info: MNSLNodeInfo);
    Break(info: MNSLNodeInfo);
    Continue(info: MNSLNodeInfo);

    // other lang features
    SubExpression(node: MNSLNode, info: MNSLNodeInfo);
    StructAccess(on: MNSLNode, field: String, info: MNSLNodeInfo);
    ArrayAccess(on: MNSLNode, index: MNSLNode, info: MNSLNodeInfo);

    // literals
    IntegerLiteralNode(value: String, info: MNSLNodeInfo);
    FloatLiteralNode(value: String, info: MNSLNodeInfo);
    StringLiteralNode(value: String, info: MNSLNodeInfo);
}
