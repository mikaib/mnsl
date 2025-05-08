package mnsl.analysis;

import mnsl.parser.MNSLNodeChildren;
import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeInfo;

class MNSLAnalyser {

    private var _context: MNSLContext;
    private var _ast: MNSLNodeChildren;

    /**
     * Create a new analyser.
     */
    public function new(context: MNSLContext, ast: MNSLNodeChildren) {
        this._context = context;
        this._ast = ast;
    }

    /**
     * Run on a given node.
     * @param node The node to run on.
     */
    public function execAtNode(node) {
        switch (node) {
            case FunctionDecl(name, returnType, arguments, body, info):
                // TODO: impl
                execAtBody(body);

            case FunctionCall(name, args, info):
                // TODO: impl

            case Return(value, type, info):
                // TODO: impl

            case VariableDecl(name, type, value, info):
                // TODO: impl

            case VariableAssign(name, value, info):
                // TODO: impl

            case Identifier(name, info):
                // TODO: impl

            case IfStatement(condition, body, info):
                // TODO: impl
                execAtBody(body);

            case ElseIfStatement(condition, body, info):
                // TODO: impl
                execAtBody(body);

            case ElseStatement(body, info):
                // TODO: impl
                execAtBody(body);

            case BinaryOp(left, op, right, info):
                // TODO: impl

            case UnaryOp(op, right, info):
                // TODO: impl

            case WhileLoop(condition, body, info):
                // TODO: impl
                execAtBody(body);

            case ForLoop(init, condition, increment, body, info):
                // TODO: impl
                execAtBody(body);

            case Break(info):
                // TODO: impl

            case Continue(info):
                // TODO: impl

            case SubExpression(node, info):
                // TODO: impl

            case StructAccess(on, field, info):
                // TODO: impl

            case ArrayAccess(on, index, info):
                // TODO: impl

            case IntegerLiteralNode(value, info):
                // TODO: impl

            case FloatLiteralNode(value, info):
                // TODO: impl

            case StringLiteralNode(value, info):
                // TODO: impl

        }
    }

    /**
     * Run on the given body.
     * @param body The body to run on.
     */
    public function execAtBody(body: MNSLNodeChildren): Void {
        for (node in body) {
            this.execAtNode(node);
        }
    }

    /**
     * Run the analysis.
     */
    public function run(): Void {
        execAtBody(this._ast);
    }

}
