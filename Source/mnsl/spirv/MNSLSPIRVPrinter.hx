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
import mnsl.analysis.MNSLAnalyser;

class MNSLSPIRVPrinter extends MNSLPrinter {

    private var _bin: BytesOutput;
    private var _config: MNSLSPIRVConfig;
    private var _types: Map<MNSLType, Int>;
    private var _functions: Map<String, Int>;
    private var _functionTypes: Map<String, Int>;
    private var _ptrTypes: Map<String, Int>;
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

        this._functions = [];
        this._constants = [];
        this._instructions = [];
        this._debugLabels = [];
        this._functionTypes = [];
        this._ptrTypes = [];

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
        emitDebugLabel(id, 'T${type.toHumanString()}');

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
                emitDebugLabel(sampledId, 'TSamplerImage');
            case "CubeSampler":
                var sampledId = id;
                emitInstruction(MNSLSPIRVOpCode.OpTypeImage, [id, getType(MNSLType.TFloat), 3, 0, 0, 0, 1, 0]);
                id = assignId();
                emitInstruction(MNSLSPIRVOpCode.OpTypeSampledImage, [id, sampledId]);
                emitDebugLabel(sampledId, 'TCubeSamplerImage');
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
        emitDebugLabel(id, '${v}');

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

    public function getPtr(id: Int, storageClass: MNSLSPIRVStorageClass): Int {
        var key = '${id}:${storageClass}';
        if (_ptrTypes.exists(key)) {
            return _ptrTypes.get(key);
        }

        var typeId = assignId();

        emitInstruction(MNSLSPIRVOpCode.OpTypePointer, [typeId, storageClass, id]);
        _ptrTypes.set(key, typeId);

        return typeId;
    }

    public function getFunctionType(ret: MNSLType, params: Array<MNSLType>): Int {
        var key = ret.toString() + ":" + params.map(t -> t.toString()).join(",");
        if (_functionTypes.exists(key)) {
            return _functionTypes.get(key);
        }

        var paramTypes = [for (p in params) getType(p)];
        var retTypeId = getType(ret);
        var typeId = assignId();

        emitInstruction(MNSLSPIRVOpCode.OpTypeFunction, [typeId, retTypeId].concat(paramTypes));
        _functionTypes.set(key, typeId);

        return typeId;
    }

    public function getVarBase(on: MNSLNode): String {
        switch (on) {
            case Identifier(name, type, info):
                return name;
            case StructAccess(on, field, type, info):
                return getVarBase(on);
            case ArrayAccess(on, index, info):
                return getVarBase(on);
            default:
                throw "Invalid node for variable base: " + on;
        }
    }

    public function assignId(): Int {
        return _idCount++;
    }

    public function emitInstruction(op: MNSLSPIRVOpCode, operands: Array<Int>): Int {
        _instructions.push(
            [((operands.length + 1) << 16) | op]
            .concat(operands)
        );

        return _instructions.length - 1;
    }

    public function insertInstruction(index: Int, op: MNSLSPIRVOpCode, operands: Array<Int>): Int {
        if (index < 0 || index > _instructions.length) {
            throw "Index out of bounds for instruction insertion: " + index;
        }

        var instruction = [((operands.length + 1) << 16) | op].concat(operands);
        _instructions.insert(index, instruction);

        return index;
    }

    public function editInstruction(index: Int, op: MNSLSPIRVOpCode, operands: Array<Int>): Void {
        if (index < 0 || index >= _instructions.length) {
            throw "Index out of bounds for instruction edit: " + index;
        }

        _instructions[index] = [((operands.length + 1) << 16) | op].concat(operands);
    }

    public function emitDebugLabel(id: Int, name: String): Void {
        _debugLabels.set(id, name);
    }

    public function preEmit(ast: MNSLNodeChildren, scope: Null<MNSLSPIRVScope> = null): Void {
        for (node in ast) {
            switch (node) {
                case FloatLiteralNode(value, info):
                    getConst(Std.parseFloat(value), MNSLType.TFloat);
                case IntegerLiteralNode(value, info):
                    getConst(Std.parseInt(value), MNSLType.TInt);
                case BooleanLiteralNode(value, info):
                    getConst(value, MNSLType.TBool);
                case FunctionDecl(name, returnType, arguments, body, info):
                    getFunctionType(returnType, [for (arg in arguments) arg.type]);
                case VariableDecl(name, type, value, info):
                    getPtr(getType(type), MNSLSPIRVStorageClass.Function);
                    if (scope != null) {
                        var varId = assignId();
                        var ptrId = getPtr(getType(type), MNSLSPIRVStorageClass.Function);
                        emitInstruction(MNSLSPIRVOpCode.OpVariable, [ptrId, varId, MNSLSPIRVStorageClass.Function]);
                        emitDebugLabel(varId, name);
                        scope.setVariable(name, varId);
                    }
                case VariableAssign(name, value, info):
                    if (scope != null &&
                        scope.variables.exists(getVarBase(name)) &&
                        scope.variables.get(getVarBase(name)).isParam &&
                        !scope.variables.exists("__mnsl_param_" + getVarBase(name))
                    ) {

                        // this is a parameter assignment, we need to create a temporary variable
                        var varId = assignId();
                        var ptrId = getPtr(getType(MNSLAnalyser.getType(value)), MNSLSPIRVStorageClass.Function);
                        emitInstruction(MNSLSPIRVOpCode.OpVariable, [ptrId, varId, MNSLSPIRVStorageClass.Function]);
                        emitDebugLabel(varId, "__mnsl_param_" + getVarBase(name));
                        scope.setVariable("__mnsl_param_" + getVarBase(name), varId);
                    }
                default:
            }

            var params = EnumValueTools.getParameters(node);
            for (p in params) {
                if (p is MNSLNodeChildren && p[0] != null && p[0] is MNSLNode) {
                    preEmit(p, scope);
                } else if (p is MNSLNode) {
                    preEmit([p], scope);
                }
            }
        }
    }

    public function emitBody(body: MNSLNodeChildren, scope: MNSLSPIRVScope): Void {
        for (node in body) {
            emitNode(node, scope);
        }
    }

    public function emitNode(node: MNSLNode, scope: MNSLSPIRVScope): Int {
        switch (node) {
            case VariableDecl(name, type, value, info):
                return emitVariableDecl(name, type, value, info, scope);
            case VariableAssign(name, value, info):
                return emitVariableAssign(name, value, info, scope);
            case Identifier(name, type, info):
                return emitIdentifier(name, type, info, scope);
            case FunctionDecl(name, returnType, arguments, body, info):
                return emitFunctionDecl(name, returnType, arguments, body, info, scope);
            case FunctionCall(name, args, returnType, info):
                return emitFunctionCall(name, args, returnType, info, scope);
            case BinaryOp(left, op, right, type, info):
                return emitBinaryOp(left, op, right, type, info, scope);
            case UnaryOp(op, right, info):
                return emitUnaryOp(op, right, info, scope);
            case Return(value, type, info):
                return emitReturn(value, type, info, scope);
            case VectorCreation(comp, nodes, info):
                return emitVectorCreation(comp, nodes, info, scope);
            case VectorConversion(on, from, to):
                return emitVectorConversion(on, from, to, scope);
            case FloatLiteralNode(value, info):
                return getConst(Std.parseFloat(value), MNSLType.TFloat);
            case IntegerLiteralNode(value, info):
                return getConst(Std.parseInt(value), MNSLType.TInt);
            case BooleanLiteralNode(value, info):
                return getConst(value, MNSLType.TBool);
            case TypeCast(on, from, to):
                return emitTypeCast(on, from, to, scope);
            case SubExpression(node, info):
                return emitNode(node, scope);
            case Block(body, info):
                emitBody(body, scope);
                return 0;
            default:
                trace("Unhandled node", node);
                return 0;
        }
    }

    public function emitIdentifier(name: String, type: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope): Int {
        if (!scope.variables.exists(name)) {
            throw "Variable not found in scope: " + name;
        }

        var varId = scope.variables.get(name);
        if (varId.isParam) {
            return varId.id;
        }

        var typeId = getType(type);
        var resultId = assignId();

        emitInstruction(MNSLSPIRVOpCode.OpLoad, [typeId, resultId, varId.id]);

        return resultId;
    }

    public function emitVariableAssign(on: MNSLNode, value: MNSLNode, info: MNSLNodeInfo, scope: MNSLSPIRVScope): Int {
        var name = getVarBase(on);
        if (!scope.variables.exists(name)) {
            throw "Variable not found in scope: " + name;
        }

        var varId = scope.variables.get(name);
        var valueId = emitNode(value, scope);

        if (varId.isParam) {
            // this is a small hack to handle assignments to parameters
            // it first loads the parameter into a temporary variable, then updates the scope to use the temporary variable from now on
            if (!scope.variables.exists("__mnsl_param_" + name)) {
                throw "Parameter variable not found in scope: " + name;
            }

            var paramVarId = scope.variables.get("__mnsl_param_" + name);
            emitInstruction(MNSLSPIRVOpCode.OpStore, [paramVarId.id, valueId]);

            scope.setVariable(name, paramVarId.id);

            return paramVarId.id;
        }

        emitInstruction(MNSLSPIRVOpCode.OpStore, [varId.id, valueId]);

        return varId.id;
    }

    public function emitVariableDecl(name: String, type: MNSLType, value: MNSLNode, info: MNSLNodeInfo, scope: MNSLSPIRVScope): Int {
        if (!scope.variables.exists(name)) {
            throw "Pre-emit error: Variable not found in scope: " + name;
        }

        var varId = scope.variables.get(name);
        if (value != null) {
            var valueId = emitNode(value, scope);
            emitInstruction(MNSLSPIRVOpCode.OpStore, [varId.id, valueId]);
        }

        return varId.id;
    }

    public function emitVectorConversion(on: MNSLNode, fromComp: Int, toComp: Int, scope: MNSLSPIRVScope): Int {
        var onId = emitNode(on, scope);
        var fromType = MNSLType.fromString('Vec$fromComp');
        var toType = MNSLType.fromString('Vec$toComp');

        if (fromComp == toComp) {
            return onId;
        } else if (fromComp < toComp) {
            var resultId = assignId();
            var targetTypeId = getType(toType);
            var componentIds = [];
            var scalarType = getType(MNSLType.TFloat);

            for (i in 0...fromComp) {
                var componentId = assignId();
                emitInstruction(MNSLSPIRVOpCode.OpCompositeExtract, [scalarType, componentId, onId, i]);
                componentIds.push(componentId);
            }

            for (i in fromComp...toComp) {
                if (i == toComp - 1) {
                    componentIds.push(getConst(1.0, MNSLType.TFloat));
                } else {
                    componentIds.push(getConst(0.0, MNSLType.TFloat));
                }
            }

            emitInstruction(MNSLSPIRVOpCode.OpCompositeConstruct, [targetTypeId, resultId].concat(componentIds));
            return resultId;
        } else {
            var resultId = assignId();
            var targetTypeId = getType(toType);
            var shuffleList = [];
            for (i in 0...toComp) {
                shuffleList.push(i);
            }
            emitInstruction(MNSLSPIRVOpCode.OpVectorShuffle, [targetTypeId, resultId, onId, onId].concat(shuffleList));
            return resultId;
        }

    }

    public function emitVectorCreation(comp: Int, nodes: Array<MNSLNode>, info: MNSLNodeInfo, scope: MNSLSPIRVScope): Int {
        if (nodes.length != comp && nodes.length != 1) {
            throw 'Vector creation expects ${comp} components, but got ${nodes.length}';
        }

        var type = MNSLType.fromString('Vec${comp}');
        var typeId = getType(type);
        var resId = assignId();

        if (nodes.length == 1) {
            var scalarId = emitNode(nodes[0], scope);
            var componentIds = [for (i in 0...comp) scalarId];

            emitInstruction(MNSLSPIRVOpCode.OpCompositeConstruct, [typeId, resId].concat(componentIds));
            return resId;
        }

        emitInstruction(MNSLSPIRVOpCode.OpCompositeConstruct, [typeId, resId].concat([for (n in nodes) emitNode(n, scope)]));

        return resId;
    }

    public function emitTypeCast(on: MNSLNode, from: MNSLType, to: MNSLType, scope: MNSLSPIRVScope): Int {
        var onId = emitNode(on, scope);
        var resId = assignId();
        var targetType = getType(to);

        if (from.isFloat() && to.isInt()) {
            emitInstruction(MNSLSPIRVOpCode.OpConvertFToS, [targetType, resId, onId]);
            return resId;
        }

        if (from.isInt() && to.isFloat()) {
            trace(on);
            emitInstruction(MNSLSPIRVOpCode.OpConvertSToF, [targetType, resId, onId]);
            return resId;
        }

        emitInstruction(MNSLSPIRVOpCode.OpBitcast, [targetType, resId, onId]);
        return resId;
    }

    public function emitUnaryOp(op: MNSLToken, right: MNSLNode, info: MNSLNodeInfo, scope: MNSLSPIRVScope): Int {
        var rightId = emitNode(right, scope);
        var resultId = assignId();

        switch (op) {
            case MNSLToken.Plus(_):
                _idCount--; // unary plus doesn't do anything, we undo the ID increment
                return rightId; // just return the value
            case MNSLToken.Minus(_):
                var type = MNSLAnalyser.getType(right);
                if (type.isFloat() || type.isVector()) {
                    emitInstruction(MNSLSPIRVOpCode.OpFNegate, [getType(type), resultId, rightId]);
                } else if (type.isInt()) {
                    emitInstruction(MNSLSPIRVOpCode.OpSNegate, [getType(type), resultId, rightId]);
                } else {
                    throw "Unsupported type for unary minus: " + type.toHumanString();
                }
            case MNSLToken.Not(_):
                emitInstruction(MNSLSPIRVOpCode.OpLogicalNot, [getType(MNSLType.TBool), resultId, rightId]);
            default:
                throw "Unsupported unary operator: " + op;
        }

        return resultId;
    }

    public function emitBinaryOp(left: MNSLNode, op: MNSLToken, right: MNSLNode, type: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope): Int {
        var leftId = emitNode(left, scope);
        var rightId = emitNode(right, scope);
        var resultId = assignId();

        switch (op) {
            case MNSLToken.Plus(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFAdd, [getType(type), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpIAdd, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for addition: " + type.toHumanString();
            case MNSLToken.Minus(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFSub, [getType(type), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpISub, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for subtraction: " + type.toHumanString();
            case MNSLToken.Star(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFMul, [getType(type), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpIMul, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for multiplication: " + type.toHumanString();
            case MNSLToken.Slash(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFDiv, [getType(type), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSDiv, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for division: " + type.toHumanString();
            case MNSLToken.Percent(_):
                if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSRem, [getType(type), resultId, leftId, rightId]);
                else throw "Unsupported type for modulo: " + type.toHumanString();
            case MNSLToken.Equal(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFOrdEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpIEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for equality: " + type.toHumanString();
            case MNSLToken.Greater(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFOrdGreaterThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSGreaterThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for greater than: " + type.toHumanString();
            case MNSLToken.GreaterEqual(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFOrdGreaterThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSGreaterThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for greater than or equal: " + type.toHumanString();
            case MNSLToken.Less(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFOrdLessThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSLessThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for less than: " + type.toHumanString();
            case MNSLToken.LessEqual(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFOrdLessThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (type.isInt()) emitInstruction(MNSLSPIRVOpCode.OpSLessThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for less than or equal: " + type.toHumanString();
            case MNSLToken.NotEqual(_):
                if (type.isFloat() || type.isVector()) emitInstruction(MNSLSPIRVOpCode.OpFOrdNotEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
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

    public function emitFunctionDecl(name: String, returnType: MNSLType, arguments: MNSLFuncArgs, body: MNSLNodeChildren, info: MNSLNodeInfo, scope: MNSLSPIRVScope): Int {
        scope = scope.copy();

        var typeId = getFunctionType(returnType, [for (arg in arguments) arg.type]);
        var id = assignId();

        emitInstruction(MNSLSPIRVOpCode.OpFunction, [getType(returnType), id, 0, typeId]);
        emitDebugLabel(id, name);

        for (arg in arguments) {
            var paramId = assignId();
            emitInstruction(MNSLSPIRVOpCode.OpFunctionParameter, [getType(arg.type), paramId]);
            emitDebugLabel(paramId, arg.name);

            scope.setParameter(arg.name, paramId);
        }

        _functions.set(name, id);

        emitInstruction(MNSLSPIRVOpCode.OpLabel, [assignId()]);
        preEmit(body, scope);
        emitBody(body, scope);

        if (returnType.equals(MNSLType.TVoid)) {
            emitInstruction(MNSLSPIRVOpCode.OpReturn, []);
        }

        emitInstruction(MNSLSPIRVOpCode.OpFunctionEnd, []);

        if (name == "main") {
            _entry = id;
        }

        return id;
    }

    public function emitFunctionCall(name: String, args: Array<MNSLNode>, returnType: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope): Int {
        if (!_functions.exists(name)) {
            throw "Function not found: " + name;
        }

        var funcId: Int = _functions.get(name);
        var argIds = [for (arg in args) emitNode(arg, scope)];
        var retId = assignId();

        emitDebugLabel(retId, name);
        emitInstruction(MNSLSPIRVOpCode.OpFunctionCall, [getType(returnType), retId, funcId].concat(argIds));

        return retId;
    }

    public function emitReturn(value: MNSLNode, type: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope): Int {
        switch(value) {
            case VoidNode(_):
                emitInstruction(MNSLSPIRVOpCode.OpReturn, []);
            default:
                emitInstruction(MNSLSPIRVOpCode.OpReturnValue, [emitNode(value, scope)]);
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
        var entryInst = emitInstruction(MNSLSPIRVOpCode.OpEntryPoint, []);

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

        // find/create all constants and assign IDs
        getConst(0.0, MNSLType.TFloat);
        getConst(1.0, MNSLType.TFloat);
        preEmit(_ast);

        // constants
        for (constKey in _constants.keys()) {
            var const = _constants.get(constKey);
            emitInstruction(const.op, const.oper);
        }

        // ast
        emitBody(_ast, {});

        // entry point
        if (_entry == 0) {
            throw "No entry point found in the SPIR-V module.";
        }

        var execModel = switch (_config.shaderType) {
            case MNSLSPIRVShaderType.SPIRV_SHADER_TYPE_VERTEX: MNSLSPIRVExecutionModel.Vertex;
            case MNSLSPIRVShaderType.SPIRV_SHADER_TYPE_FRAGMENT: MNSLSPIRVExecutionModel.Fragment;
            default: throw "Unsupported shader type: " + _config.shaderType;
        }

        editInstruction(entryInst, MNSLSPIRVOpCode.OpEntryPoint, [execModel, _entry].concat(convString("main")));

        // debug
        for (label in _debugLabels.keys()) {
            var name = _debugLabels.get(label);
            insertInstruction(entryInst + 1, MNSLSPIRVOpCode.OpName, [label].concat(convString(name)));
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