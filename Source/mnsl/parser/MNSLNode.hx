package mnsl.parser;

import mnsl.analysis.MNSLType;
import mnsl.analysis.MNSLFuncArgs;
import mnsl.tokenizer.MNSLToken;

enum MNSLNode {
    // functions
    FunctionDecl(name: String, returnType: MNSLType, arguments: MNSLFuncArgs, body: MNSLNodeChildren, inlined: Bool, info: MNSLNodeInfo);
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
    BinaryOp(left: MNSLNode, op: MNSLToken, right: MNSLNode, type: MNSLType, info: MNSLNodeInfo);
    UnaryOp(op: MNSLToken, right: MNSLNode, info: MNSLNodeInfo);

    // loops
    WhileLoop(condition: MNSLNode, body: MNSLNodeChildren, info: MNSLNodeInfo);
    ForLoop(init: MNSLNode, condition: MNSLNode, increment: MNSLNode, body: MNSLNodeChildren, info: MNSLNodeInfo);
    Break(info: MNSLNodeInfo);
    Continue(info: MNSLNodeInfo);

    // other lang features
    SubExpression(node: MNSLNode, info: MNSLNodeInfo);
    Block(body: MNSLNodeChildren, info: MNSLNodeInfo);
    StructAccess(on: MNSLNode, field: String, type: MNSLType, info: MNSLNodeInfo);
    ArrayAccess(on: MNSLNode, index: MNSLNode, info: MNSLNodeInfo);
    TypeCast(on: MNSLNode, from: MNSLType, to: MNSLType);
    ImplicitTypeCast(on: MNSLNode, to: MNSLType);
    VoidNode(info: MNSLNodeInfo);
    TypeWrapper(type: MNSLType);

    // vector operations
    VectorCreation(components: Int, nodes: MNSLNodeChildren, info: MNSLNodeInfo);
    VectorConversion(on: MNSLNode, fromComponents: Int, toComponents: Int);

    // matrix operations
    MatrixCreation(size: Int, nodes: MNSLNodeChildren, info: MNSLNodeInfo);

    // literals
    IntegerLiteralNode(value: String, info: MNSLNodeInfo);
    FloatLiteralNode(value: String, info: MNSLNodeInfo);
    StringLiteralNode(value: String, info: MNSLNodeInfo);
    BooleanLiteralNode(value: Bool, info: MNSLNodeInfo);
}
