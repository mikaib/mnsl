package mnsl.spirv;

import mnsl.parser.MNSLNode;
import mnsl.parser.MNSLNodeChildren;
import mnsl.analysis.MNSLType;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import mnsl.analysis.MNSLFuncArgs;
import mnsl.parser.MNSLNodeInfo;
import haxe.io.FPHelper;
import haxe.EnumTools.EnumValueTools;
import mnsl.tokenizer.MNSLToken;

class MNSLSPIRVPrinter extends MNSLPrinter {

    private var _bin: BytesOutput;
    private var _config: MNSLSPIRVConfig;
    private var _types: Map<MNSLType, Int>;
    private var _variables: Map<String, Int>;
    private var _functions: Map<String, Int>;
    private var _constants: Map<String, { id: Int, op: MNSLSPIRVOpCode, oper: Array<Int> }>;
    private var _entry: Int;

    private var _idCount: Int;
    private var _instructions: Array<Array<Int>>;
    private var _debugLabels: Map<Int, String>;

    public function new(context: MNSLContext, config: MNSLSPIRVConfig) {
        super(context);

        this._config = config;
        this._bin = new BytesOutput();

        this._types = [];
        this._variables = [];
        this._functions = [];
        this._constants = [];
        this._instructions = [];
        this._debugLabels = [];

        this._idCount = 1;
    }

    public function convString(str: String): Array<Int> {
        var bytes = haxe.io.Bytes.ofString(str + String.fromCharCode(0));
        var words = [];
        var i = 0;
        while (i < bytes.length) {
            var word = 0;
            for (j in 0...4) {
                if (i + j < bytes.length) {
                    word |= bytes.get(i + j) << (j * 8);
                }
            }
            words.push(word);
            i += 4;
        }
        return words;
    }

    public function getType(type: MNSLType): Int {
        for (t in _types.keys()) {
            if (t.equals(type)) {
                return _types.get(t);
            }
        }

        var id = assignId();
        emitDebugLabel(id, 'Type(${type.toHumanString()})');

        _types.set(type, id);

        if (type.isMatrix()) {
            var w = type.getMatrixWidth();
            var h = type.getMatrixHeight();
            emitInstruction(MNSLSPIRVOpCode.OpTypeMatrix, [id, getType(MNSLType.fromString('Vec$w')), h]);

            return id;
        }

        if (type.isVector()) {
            emitInstruction(MNSLSPIRVOpCode.OpTypeVector, [id, getType(MNSLType.TFloat), type.getVectorComponents()]);
            return id;
        }

        var typeStr = type.toString();
        switch (typeStr) {
            case "Void":
                emitInstruction(MNSLSPIRVOpCode.OpTypeVoid, [id]);
            case "Bool":
                emitInstruction(MNSLSPIRVOpCode.OpTypeBool, [id]);
            case "Int":
                emitInstruction(MNSLSPIRVOpCode.OpTypeInt, [id, 32, 1]);
            case "Float":
                emitInstruction(MNSLSPIRVOpCode.OpTypeFloat, [id, 32]);
            case "Sampler":
                var sampledId = id;
                emitInstruction(MNSLSPIRVOpCode.OpTypeImage, [id, getType(MNSLType.TFloat), 1, 0, 0, 0, 1, 0]);
                id = assignId();
                emitInstruction(MNSLSPIRVOpCode.OpTypeSampledImage, [id, sampledId]);
                emitDebugLabel(sampledId, 'Image(Sampler)');
            case "CubeSampler":
                var sampledId = id;
                emitInstruction(MNSLSPIRVOpCode.OpTypeImage, [id, getType(MNSLType.TFloat), 3, 0, 0, 0, 1, 0]);
                id = assignId();
                emitInstruction(MNSLSPIRVOpCode.OpTypeSampledImage, [id, sampledId]);
                emitDebugLabel(sampledId, 'Image(CubeSampler)');
            default:
                throw "Invalid type: " + typeStr;
        }

        return id;
    }

    public function getConst(v: Dynamic, type: MNSLType): Int {
        var key = type.toString() + ":" + Std.string(v);
        if (_constants.exists(key)) {
            return _constants.get(key).id;
        }

        var id = assignId();
        emitDebugLabel(id, 'Constant(${v}: ${type.toHumanString()})');

        if (type.isBool()) {
            _constants.set(key, { id: id, op: v == true ? MNSLSPIRVOpCode.OpConstantTrue : MNSLSPIRVOpCode.OpConstantFalse, oper: [getType(type), id] });
            return id;
        }

        if (type.isInt()) {
            _constants.set(key, { id: id, op: MNSLSPIRVOpCode.OpConstant, oper: [getType(type), id, Std.int(v)] });
            return id;
        }

        if (type.isFloat()) {
            _constants.set(key, { id: id, op: MNSLSPIRVOpCode.OpConstant, oper: [getType(type), id, FPHelper.floatToI32(v)] });
            return id;
        }

        throw "Unhandled constant type: " + type + " with value: " + v;
    }

    public function assignId(): Int {
        return _idCount++;
    }

    public function emitInstruction(op: MNSLSPIRVOpCode, operands: Array<Int>): Void {
        _instructions.push(
            [((operands.length + 1) << 16) | op]
            .concat(operands)
        );
    }

    public function emitDebugLabel(id: Int, name: String): Void {
        _debugLabels.set(id, name);
    }

    public function emitConstants(ast: MNSLNodeChildren): Void {
        for (node in ast) {
            switch (node) {
                case FloatLiteralNode(value, info):
                    getConst(Std.parseFloat(value), MNSLType.TFloat);
                case IntegerLiteralNode(value, info):
                    getConst(Std.parseInt(value), MNSLType.TInt);
                case BooleanLiteralNode(value, info):
                    getConst(value, MNSLType.TBool);
                default:
            }

            var params = EnumValueTools.getParameters(node);
            for (p in params) {
                if (p is MNSLNodeChildren && p[0] != null && p[0] is MNSLNode) {
                    emitConstants(p);
                } else if (p is MNSLNode) {
                    emitConstants([p]);
                }
            }
        }
    }

    public function emitBody(body: MNSLNodeChildren): Void {
        for (node in body) {
            emitNode(node);
        }
    }

    public function emitNode(node: MNSLNode): Int {
        switch (node) {
            case FunctionDecl(name, returnType, arguments, body, info):
                return emitFunctionDecl(name, returnType, arguments, body, info);
            case FunctionCall(name, args, returnType, info):
                return emitFunctionCall(name, args, returnType, info);
            case BinaryOp(left, op, right, type, info):
                return emitBinaryOp(left, op, right, type, info);
            case UnaryOp(op, right, info):
                return emitUnaryOp(op, right, info);
            case Return(value, type, info):
                return emitReturn(value, type, info);
            case FloatLiteralNode(value, info):
                return getConst(Std.parseFloat(value), MNSLType.TFloat);
            case IntegerLiteralNode(value, info):
                return getConst(Std.parseInt(value), MNSLType.TInt);
            case BooleanLiteralNode(value, info):
                return getConst(value, MNSLType.TBool);
            case SubExpression(node, info):
                return emitNode(node);
            case Block(body, info):
                emitBody(body);
                return 0;
            default:
                trace("Unhandled node", node);
                return 0;
        }
    }

    public function emitUnaryOp(op: MNSLToken, right: MNSLNode, info: MNSLNodeInfo): Int {
        var rightId = emitNode(right);
        var resultId = assignId();

        emitDebugLabel(resultId, 'UnaryOp(${op})');

        switch (op) {
            case MNSLToken.Plus(_):
                _idCount--; // unary plus doesn't do anything, we undo the ID increment
                return rightId; // just return the value
            case MNSLToken.Minus(_):
                emitInstruction(MNSLSPIRVOpCode.OpFNegate, [getType(MNSLType.TFloat), resultId, rightId]);
            case MNSLToken.Not(_):
                emitInstruction(MNSLSPIRVOpCode.OpLogicalNot, [getType(MNSLType.TBool), resultId, rightId]);
            default:
                throw "Unsupported unary operator: " + op;
        }

        return resultId;
    }

    public function emitBinaryOp(left: MNSLNode, op: MNSLToken, right: MNSLNode, type: MNSLType, info: MNSLNodeInfo): Int {
        var leftId = emitNode(left);
        var rightId = emitNode(right);
        var resultId = assignId();

        emitDebugLabel(resultId, 'BinaryOp(${op})');

        switch (op) {
            case MNSLToken.Plus(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFAdd, [getType(type), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpIAdd, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for addition: " + type.toHumanString();
            case MNSLToken.Minus(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFSub, [getType(type), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpISub, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for subtraction: " + type.toHumanString();
            case MNSLToken.Star(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFMul, [getType(type), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpIMul, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for multiplication: " + type.toHumanString();
            case MNSLToken.Slash(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFDiv, [getType(type), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSDiv, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for division: " + type.toHumanString();
            case MNSLToken.Percent(_):
                if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSRem, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for modulo: " + type.toHumanString();
            case MNSLToken.Equal(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFOrdEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpIEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for equality: " + type.toHumanString();
            case MNSLToken.Greater(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFOrdGreaterThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSGreaterThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for greater than: " + type.toHumanString();
            case MNSLToken.GreaterEqual(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFOrdGreaterThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSGreaterThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for greater than or equal: " + type.toHumanString();
            case MNSLToken.Less(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFOrdLessThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSLessThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for less than: " + type.toHumanString();
            case MNSLToken.LessEqual(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFOrdLessThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSLessThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for less than or equal: " + type.toHumanString();
            case MNSLToken.NotEqual(_):
                if (type.isFloat()) emitInstruction(MNSLSPIRVOpCode.OpFOrdNotEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpINotEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for not equal: " + type.toHumanString();
            case MNSLToken.And(_):
                if (type.isBool()) emitInstruction(MNSLSPIRVOpCode.OpLogicalAnd, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for logical AND: " + type.toHumanString();
            case MNSLToken.Or(_):
                if (type.isBool()) emitInstruction(MNSLSPIRVOpCode.OpLogicalOr, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for logical OR: " + type.toHumanString();
            default:
                throw "Unsupported binary operator: " + op;
        }

        return resultId;
    }

    public function emitFunctionDecl(name: String, returnType: MNSLType, arguments: MNSLFuncArgs, body: MNSLNodeChildren, info: MNSLNodeInfo): Int {
        var paramTypes = [for (arg in arguments) getType(arg.type)];
        var typeId = assignId();
        var id = assignId();

        emitInstruction(MNSLSPIRVOpCode.OpTypeFunction, [typeId, getType(returnType)].concat(paramTypes));
        emitInstruction(MNSLSPIRVOpCode.OpFunction, [getType(returnType), id, 0, typeId]);
        emitDebugLabel(id, 'Function($name)');

        for (arg in arguments) {
            var paramId = assignId();
            emitInstruction(MNSLSPIRVOpCode.OpFunctionParameter, [getType(arg.type), paramId]);
            emitDebugLabel(paramId, 'Parameter(${arg.name}: ${arg.type.toHumanString()})');

            _variables.set(arg.name, paramId);
        }

        _functions.set(name, id);

        emitInstruction(MNSLSPIRVOpCode.OpLabel, [assignId()]);
        emitBody(body);

        if (returnType.equals(MNSLType.TVoid)) {
            emitInstruction(MNSLSPIRVOpCode.OpReturn, []);
        }

        emitInstruction(MNSLSPIRVOpCode.OpFunctionEnd, []);

        if (name == "main") {
            _entry = id;
        }

        return id;
    }

    public function emitFunctionCall(name: String, args: Array<MNSLNode>, returnType: MNSLType, info: MNSLNodeInfo): Int {
        if (!_functions.exists(name)) {
            throw "Function not found: " + name;
        }

        var funcId: Int = _functions.get(name);
        var argIds = [for (arg in args) emitNode(arg)];
        var retId = assignId();

        trace(returnType);

        emitDebugLabel(retId, 'Call($name)');
        emitInstruction(MNSLSPIRVOpCode.OpFunctionCall, [getType(returnType), retId, funcId].concat(argIds));

        return retId;
    }

    public function emitReturn(value: MNSLNode, type: MNSLType, info: MNSLNodeInfo): Int {
        switch(value) {
            case VoidNode(_):
                emitInstruction(MNSLSPIRVOpCode.OpReturn, []);
            default:
                emitInstruction(MNSLSPIRVOpCode.OpReturnValue, [emitNode(value)]);
        }

        return 0;
    }

    public function getBytes(): Bytes {
        return _bin.getBytes();
    }

    override public function run(): Void {
        // caps
        emitInstruction(MNSLSPIRVOpCode.OpCapability, [MNSLSPIRVCapability.Shader]);
        emitInstruction(MNSLSPIRVOpCode.OpMemoryModel, [0, 1]);

        // types
        getType(MNSLType.TVoid);
        getType(MNSLType.TBool);
        getType(MNSLType.TInt);
        getType(MNSLType.TFloat);
        getType(MNSLType.TVec2);
        getType(MNSLType.TVec3);
        getType(MNSLType.TVec4);
        getType(MNSLType.TMat2);
        getType(MNSLType.TMat3);
        getType(MNSLType.TMat4);
        getType(MNSLType.TSampler);
        getType(MNSLType.TCubeSampler);

        // find all constants and assign IDs
        emitConstants(_ast);

        // constants
        for (constKey in _constants.keys()) {
            var const = _constants.get(constKey);
            emitInstruction(const.op, const.oper);
        }

        // ast
        emitBody(_ast);

        // entry point
        if (_entry == 0) {
            throw "No entry point found in the SPIR-V module.";
        }

        var execModel = switch (_config.shaderType) {
            case MNSLSPIRVShaderType.ShaderTypeVertex: MNSLSPIRVExecutionModel.Vertex;
            case MNSLSPIRVShaderType.ShaderTypeFragment: MNSLSPIRVExecutionModel.Fragment;
            default: throw "Unsupported shader type: " + _config.shaderType;
        }

        emitInstruction(MNSLSPIRVOpCode.OpEntryPoint, [execModel, _entry].concat(convString("main")));

        // debug
        for (label in _debugLabels.keys()) {
            var name = _debugLabels.get(label);
            emitInstruction(MNSLSPIRVOpCode.OpName, [label].concat(convString(name)));
        }

        // header
        _bin.writeInt32(0x07230203);
        _bin.writeInt32(0x00010000);
        _bin.writeInt32(0x00000000);
        _bin.writeInt32(_idCount);
        _bin.writeInt32(0x00000000);

        // instructions
        for (inst in _instructions) {
            for (word in inst) {
                _bin.writeInt32(word);
            }
        }
    }

}