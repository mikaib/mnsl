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
import mnsl.parser.MNSLShaderDataKind;
import mnsl.spirv.MNSLSPIRVBuiltIn;
import mnsl.parser.MNSLShaderData;

class MNSLSPIRVPrinter extends MNSLPrinter {

    private var _bin: BytesOutput;
    private var _config: MNSLSPIRVConfig;
    private var _types: Map<MNSLType, Int>;
    private var _functions: Map<String, Int>;
    private var _functionTypes: Map<String, Int>;
    private var _ptrTypes: Map<String, Int>;
    private var _ptrInit: Array<{ id: Int, typeId: Int, storageClass: MNSLSPIRVStorageClass }>;
    private var _typeInit: Array<{ id: Int, op: MNSLSPIRVOpCode, oper: Array<Int> }>;
    private var _constants: Map<String, { id: Int, op: MNSLSPIRVOpCode, oper: Array<Int> }>;
    private var _constInit: Array<{ id: Int, op: MNSLSPIRVOpCode, oper: Array<Int> }>;
    private var _decorations: Array<{ id: Int, decoration: MNSLSPIRVDecoration, oper: Array<Int>, kind: MNSLShaderDataKind, name: String }>;
    private var _componentList: Array<String>;
    private var _entry: Int;

    private var _idCount: Int;
    private var _instructions: Array<Array<Int>>;
    private var _debugLabels: Map<Int, String>;

    private var _glslFuncMap: Array<{ name: String, mapping: MNSLSPIRVUnifiedStd }>;
    private var _glslExtId: Int;

    public function new(context: MNSLContext, config: MNSLSPIRVConfig) {
        super(context);
        this._glslExtId = -1;
        this._componentList = ['x', 'y', 'z', 'w'];
        this._glslFuncMap = [
            { name: "texture", mapping: MNSLSPIRVUnifiedStd.MNSLInternal },
            { name: "dot", mapping: MNSLSPIRVUnifiedStd.MNSLInternal },
            { name: "mod", mapping: MNSLSPIRVUnifiedStd.MNSLInternal },
            { name: "sin", mapping: MNSLSPIRVUnifiedStd.Sin },
            { name: "cos", mapping: MNSLSPIRVUnifiedStd.Cos },
            { name: "tan", mapping: MNSLSPIRVUnifiedStd.Tan },
            { name: "normalize", mapping: MNSLSPIRVUnifiedStd.Normalize },
            { name: "cross", mapping: MNSLSPIRVUnifiedStd.Cross },
            { name: "length", mapping: MNSLSPIRVUnifiedStd.Length },
            { name: "reflect", mapping: MNSLSPIRVUnifiedStd.Reflect },
            { name: "refract", mapping: MNSLSPIRVUnifiedStd.Refract },
            { name: "pow", mapping: MNSLSPIRVUnifiedStd.Pow },
            { name: "exp", mapping: MNSLSPIRVUnifiedStd.Exp },
            { name: "log", mapping: MNSLSPIRVUnifiedStd.Log },
            { name: "sqrt", mapping: MNSLSPIRVUnifiedStd.Sqrt },
            { name: "abs", mapping: MNSLSPIRVUnifiedStd.FAbs },
            { name: "clamp", mapping: MNSLSPIRVUnifiedStd.FClamp },
            { name: "mix", mapping: MNSLSPIRVUnifiedStd.FMix },
            { name: "step", mapping: MNSLSPIRVUnifiedStd.Step },
            { name: "smoothstep", mapping: MNSLSPIRVUnifiedStd.SmoothStep },
            { name: "max", mapping: MNSLSPIRVUnifiedStd.FMax },
            { name: "min", mapping: MNSLSPIRVUnifiedStd.FMin },
            { name: "atan", mapping: MNSLSPIRVUnifiedStd.Atan2 },
            { name: "acos", mapping: MNSLSPIRVUnifiedStd.Acos },
            { name: "asin", mapping: MNSLSPIRVUnifiedStd.Asin },
            { name: "fract", mapping: MNSLSPIRVUnifiedStd.Fract },
            { name: "floor", mapping: MNSLSPIRVUnifiedStd.Floor }
        ];

        this._config = config;
        this._bin = new BytesOutput();

        this._types = [];

        this._functions = [];
        this._constants = [];
        this._instructions = [];
        this._debugLabels = [];
        this._functionTypes = [];
        this._ptrTypes = [];
        this._ptrInit = [];
        this._typeInit = [];
        this._constInit = [];
        this._decorations = [];

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
        if (type.isUnknown()) {
            type.setType(MNSLType.TVoid);
        }

        for (t in _types.keys()) {
            if (t.equals(type)) {
                return _types.get(t);
            }
        }

        var id = assignId();
        emitDebugLabel(id, '${type.toHumanString()}');

        _types.set(type, id);

        if (type.isArray()) {
            var typeId = getType(type.getArrayBaseType());
            var arraySizeId = getConst(type.getArraySize(), MNSLType.TInt);
            _typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeArray, oper: [id, typeId, arraySizeId] });

            return id;
        }

        if (type.isMatrix()) {
            var w = type.getMatrixWidth();
            var h = type.getMatrixHeight();
            this._typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeMatrix, oper: [id, getType(MNSLType.fromString('Vec$w')), h]});

            return id;
        }

        if (type.isVector()) {
            this._typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeVector, oper: [id, getType(MNSLType.TFloat), type.getVectorComponents()] });
            return id;
        }

        var typeStr = type.toString();
        switch (typeStr) {
            case "Void":
                this._typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeVoid, oper: [id] });
            case "Bool":
                this._typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeBool, oper: [id] });
            case "Int":
                this._typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeInt, oper: [id, 32, 1] });
            case "Float":
                this._typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeFloat, oper: [id, 32] });
            case "Sampler":
                var sampledId = assignId();
                this._typeInit.push({ id: sampledId, op: MNSLSPIRVOpCode.OpTypeImage, oper: [sampledId, getType(MNSLType.TFloat), 1, 0, 0, 0, 1, 0] });
                this._typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeSampledImage, oper: [id, sampledId] });
                emitDebugLabel(sampledId, 'TSamplerImage');
            case "CubeSampler":
                var sampledId = id;
                this._typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeImage, oper: [id, getType(MNSLType.TFloat), 3, 0, 0, 0, 1, 0] });
                id = assignId();
                this._typeInit.push({ id: id, op: MNSLSPIRVOpCode.OpTypeSampledImage, oper: [id, sampledId] });
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

        if (type.isBool()) {
            var data = { id: id, op: v == true ? MNSLSPIRVOpCode.OpConstantTrue : MNSLSPIRVOpCode.OpConstantFalse, oper: [getType(type), id] };
            _constants.set(key, data);
            _constInit.push(data);

            return id;
        }

        if (type.isInt()) {
            var data = { id: id, op: MNSLSPIRVOpCode.OpConstant, oper: [getType(type), id, Std.int(v)] };
            _constants.set(key, data);
            _constInit.push(data);

            return id;
        }

        if (type.isFloat()) {
            var data = { id: id, op: MNSLSPIRVOpCode.OpConstant, oper: [getType(type), id, FPHelper.floatToI32(v)] };
            _constInit.push(data);
            _constants.set(key, data);

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

        _ptrInit.push({ id: typeId, typeId: id, storageClass: storageClass });
        _ptrTypes.set(key, typeId);

        return typeId;
    }

    public function getExtGlslStd(): Int {
        if (_glslExtId == -1) {
            _glslExtId = assignId();
            emitInstruction(MNSLSPIRVOpCode.OpExtInstImport, [_glslExtId].concat(convString("GLSL.std.450")));
        }
        return _glslExtId;
    }

    public function getFunctionType(ret: MNSLType, params: Array<MNSLType>): Int {
        var key = ret.toString() + ":" + params.map(t -> t.toString()).join(",");
        if (_functionTypes.exists(key)) {
            return _functionTypes.get(key);
        }

        var paramTypes = [for (p in params) getType(p)];
        var retTypeId = getType(ret);
        var typeId = assignId();

        _typeInit.push({ id: typeId, op: MNSLSPIRVOpCode.OpTypeFunction, oper: [typeId, retTypeId].concat(paramTypes) });
        _functionTypes.set(key, typeId);

        return typeId;
    }

    public function getShaderData(name: String, kind: MNSLShaderDataKind): Int {
        for (data in _decorations) {
            if (data.kind == kind && data.name == name) {
                return data.id;
            }
        }

        return 0;
    }

    public function getVarBaseName(on: MNSLNode): String {
        switch (on) {
            case Identifier(name, type, info):
                return name;
            case StructAccess(on, field, type, info):
                return getVarBaseName(on);
            case ArrayAccess(on, index, info):
                return getVarBaseName(on);
            default:
                throw "Invalid node for variable base: " + on;
        }
    }

    public function getVar(on: MNSLNode, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int, requirePtr: Bool = false): { id: Int, isParam: Bool } {
        var stack: Array<{ name: String, type: MNSLType, node: MNSLNode, arrayIndex: MNSLNode }> = [];
        var currScope: MNSLSPIRVScope = scope;
        var currIsParam: Bool = false;
        var currRetId: Int = 0;
        var currIsShaderData: Bool = false;
        var currShaderDataKind: MNSLShaderDataKind = MNSLShaderDataKind.Input;
        var currIsVecAccess: Bool = false;
        var nextIsVecAccess: Bool = false;
        var currStorageClass: MNSLSPIRVStorageClass = MNSLSPIRVStorageClass.Function;
        var lastType: MNSLType = MNSLType.TVoid;

        function iterNode(node: MNSLNode) {
            switch (node) {
                case Identifier(iterName, iterType, iterInfo):
                    stack.push({ name: iterName, type: iterType, node: node, arrayIndex: null });
                case StructAccess(iterOn, iterField, iterType, iterInfo):
                    iterNode(iterOn);
                    stack.push({ name: iterField, type: iterType, node: node, arrayIndex: null });
                case FunctionCall(iterName, iterArgs, iterRet, iterInfo):
                    stack.push({ name: '__mnsl_eval_tmp', type: iterRet, node: node, arrayIndex: null });
                case ArrayAccess(iterOn, iterIndex, iterInfo):
                    iterNode(iterOn);
                    stack.push({ name: '__mnsl_array_access', type: MNSLAnalyser.getType(node), node: node, arrayIndex: iterIndex });
                default:
                    throw "Invalid node for variable access: " + node;
            }
        }

        function enter(name: String, type: MNSLType, node: MNSLNode, isLast: Bool, arrayIndex: MNSLNode) {
            var varDef = currScope.variables.get(name);

            if (nextIsVecAccess) {
                currIsVecAccess = true;
                nextIsVecAccess = false;
            }

            if (type.isVector() && !isLast) {
                nextIsVecAccess = true;
            }

            if (currIsShaderData) {
                var shData = getShaderData(name, currShaderDataKind);
                if (shData == 0) {
                    throw "Shader data not found: " + name + " of kind " + currShaderDataKind;
                }

                currRetId = shData;
                currIsShaderData = false;
                currIsParam = false;
                lastType = type;
                return;
            }

            if (name == '__mnsl_eval_tmp') {
                var funcRet = emitNode(node, scope, inBody, at);
                currRetId = funcRet;
                currIsParam = true;
                lastType = type;
                return;
            }

            if (name == '__mnsl_array_access') {
                var indexId = emitNode(arrayIndex, scope, inBody, at);
                var resId = assignId();

                if (currIsParam) {
                    throw "Cannot get pointer to array access of a temporary value";
                }

                emitInstruction(MNSLSPIRVOpCode.OpAccessChain, [
                    getPtr(getType(type), currStorageClass),
                    resId,
                    currRetId,
                    indexId
                ]);

                currRetId = resId;
                currIsParam = false;
                lastType = type;
                return;
            }

            if (name == "input" || name == "output" || name == "uniform") {
                var varKind = switch(name) {
                    case "input": MNSLShaderDataKind.Input;
                    case "output": MNSLShaderDataKind.Output;
                    case "uniform": MNSLShaderDataKind.Uniform;
                    default: null;
                };

                currIsParam = false;
                currIsShaderData = true;
                currShaderDataKind = varKind;
                currStorageClass = switch(varKind) {
                    case MNSLShaderDataKind.Input: MNSLSPIRVStorageClass.Input;
                    case MNSLShaderDataKind.Output: MNSLSPIRVStorageClass.Output;
                    case MNSLShaderDataKind.Uniform: MNSLSPIRVStorageClass.UniformConstant;
                    default: throw "Invalid shader data kind: " + varKind;
                };
                lastType = type;
                return;
            }

            if (currIsVecAccess) {
                var componentsIdxList = name.split("").map(c -> _componentList.indexOf(c));
                if (componentsIdxList.length == 0) {
                    throw "Invalid vector access: " + name;
                }

                for (comp in componentsIdxList) {
                    if (comp < 0 || comp >= _componentList.length) {
                        throw "Invalid vector component index: " + comp + " in " + name;
                    }
                }

                if (requirePtr) {
                    if (componentsIdxList.length == 1) {
                        var accessId = assignId();
                        var basePtr = currRetId;

                        if (currIsParam) {
                            throw "Cannot get pointer to vector component of a temporary value";
                        }

                        emitInstruction(MNSLSPIRVOpCode.OpAccessChain, [
                            getPtr(getType(MNSLType.TFloat), MNSLSPIRVStorageClass.Function),
                            accessId,
                            basePtr,
                            getConst(componentsIdxList[0], MNSLType.TInt)
                        ]);

                        currRetId = accessId;
                        currIsParam = false;
                        lastType = type;
                        return;
                    } else {
                        var swizzleId = assignId();
                        var basePtr = currRetId;

                        if (currIsParam) {
                            throw "Cannot get pointer to vector component of a temporary value";
                        }

                        currScope.swizzlePointers.set(swizzleId, {
                            basePtr: basePtr,
                            components: componentsIdxList,
                            vectorType: lastType
                        });

                        currRetId = swizzleId;
                        currIsParam = false;
                        lastType = type;
                        return;
                    }
                }

                var vecId = currRetId;
                if (!currIsParam) {
                    vecId = assignId();
                    emitInstruction(MNSLSPIRVOpCode.OpLoad, [getType(lastType), vecId, currRetId]);
                }

                currRetId = assignId();
                currIsParam = true;
                lastType = type;

                if (componentsIdxList.length == 1) emitInstruction(MNSLSPIRVOpCode.OpCompositeExtract, [getType(MNSLType.TFloat), currRetId, vecId, componentsIdxList[0]]);
                else emitInstruction(MNSLSPIRVOpCode.OpVectorShuffle, [
                    getType(type),
                    currRetId,
                    vecId,
                    vecId,
                ].concat(componentsIdxList));

                return;
            }

            if (varDef == null) {
                throw "Undefined variable: " + stack.map(e -> e.name).join(".");
            } else {
                currRetId = varDef.id;
                currIsParam = varDef.isParam;
                lastType = type;
            }
        }

        iterNode(on);

        var idx = 0;
        for (entry in stack) {
            enter(entry.name, entry.type, entry.node, idx == stack.length - 1, entry.arrayIndex);
            idx++;
        }

        if (requirePtr && currIsParam) {
            if (stack.length == 1 && scope.variables.exists("__mnsl_param_" + stack[0].name)) {
                return { id: scope.variables.get("__mnsl_param_" + stack[0].name).id, isParam: false };
            }

            var accessPath = stack.map(e -> e.name).join(".");
            throw "Cannot get pointer to computed value: " + accessPath;
        }

        if (requirePtr && !currIsParam) {
            return { id: currRetId, isParam: false };
        }

        if (!requirePtr && !currIsParam) {
            var loadId = assignId();
            emitInstruction(MNSLSPIRVOpCode.OpLoad, [getType(lastType), loadId, currRetId]);
            return { id: loadId, isParam: true };
        }

        return { id: currRetId, isParam: currIsParam };
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

    public function emitDecoration(name: String, kind: MNSLShaderDataKind, id: Int, decoration: MNSLSPIRVDecoration, params: Array<Int>): Void {
        _decorations.push({ id: id, decoration: decoration, oper: params, kind: kind, name: name });
    }

    public function emitShaderData(): Void {
        var locationCount = 0;
        var internalData: Array<MNSLShaderData> = [
            {
                name: "VertexID",
                type: MNSLType.TInt,
                kind: MNSLShaderDataKind.Input,
                arraySize: -1
            },
            {
                name: "InstanceID",
                type: MNSLType.TInt,
                kind: MNSLShaderDataKind.Input,
                arraySize: -1
            },
            {
                name: "FragCoord",
                type: MNSLType.TVec4,
                kind: MNSLShaderDataKind.Input,
                arraySize: -1
            },
            {
                name: "FrontFacing",
                type: MNSLType.TBool,
                kind: MNSLShaderDataKind.Input,
                arraySize: -1
            },
            {
                name: "FragDepth",
                type: MNSLType.TFloat,
                kind: MNSLShaderDataKind.Input,
                arraySize: -1
            },
            {
                name: "Position",
                type: MNSLType.TVec4,
                kind: MNSLShaderDataKind.Output,
                arraySize: -1
            },
            {
                name: "PointSize",
                type: MNSLType.TFloat,
                kind: MNSLShaderDataKind.Output,
                arraySize: -1
            }
        ];

        for (data in _context.getShaderData().concat(internalData)) {
            var typeId = getType(data.type);
            var varId = assignId();
            var varName: String;
            var storageClass: MNSLSPIRVStorageClass;

            switch (data.kind) {
                case MNSLShaderDataKind.Input:
                    storageClass = MNSLSPIRVStorageClass.Input;
                    varName = "in_" + data.name;
                case MNSLShaderDataKind.Output:
                    storageClass = MNSLSPIRVStorageClass.Output;
                    varName = "out_" + data.name;
                case MNSLShaderDataKind.Uniform:
                    storageClass = MNSLSPIRVStorageClass.UniformConstant;
                    varName = "u_" + data.name;
            }

            emitInstruction(MNSLSPIRVOpCode.OpVariable, [getPtr(typeId, storageClass), varId, storageClass]);
            emitDebugLabel(varId, varName);

            if (data.kind == MNSLShaderDataKind.Output) {
                switch (data.name) {
                    case "Position":
                        emitDecoration("Position", data.kind, varId, MNSLSPIRVDecoration.BuiltIn, [MNSLSPIRVBuiltIn.Position]);
                        continue;
                    case "PointSize":
                        emitDecoration("PointSize", data.kind, varId, MNSLSPIRVDecoration.BuiltIn, [MNSLSPIRVBuiltIn.PointSize]);
                        continue;
                    default:
                        emitDecoration(data.name, data.kind, varId, MNSLSPIRVDecoration.Location, [locationCount]);
                        locationCount++;
                }
            }

            if (data.kind == MNSLShaderDataKind.Input) {
                switch(data.name) {
                    case "VertexID":
                        emitDecoration("VertexID", data.kind, varId, MNSLSPIRVDecoration.BuiltIn, [MNSLSPIRVBuiltIn.VertexId]);
                        continue;
                    case "InstanceID":
                        emitDecoration("InstanceID", data.kind, varId, MNSLSPIRVDecoration.BuiltIn, [MNSLSPIRVBuiltIn.InstanceId]);
                        continue;
                    case "FragCoord":
                        emitDecoration("FragCoord", data.kind, varId, MNSLSPIRVDecoration.BuiltIn, [MNSLSPIRVBuiltIn.FragCoord]);
                        continue;
                    case "FrontFacing":
                        emitDecoration("FrontFacing", data.kind, varId, MNSLSPIRVDecoration.BuiltIn, [MNSLSPIRVBuiltIn.FrontFacing]);
                        continue;
                    case "FragDepth":
                        emitDecoration("FragDepth", data.kind, varId, MNSLSPIRVDecoration.BuiltIn, [MNSLSPIRVBuiltIn.FragDepth]);
                        continue;
                    default:
                        emitDecoration(data.name, data.kind, varId, MNSLSPIRVDecoration.Location, [locationCount]);
                        locationCount++;
                }
            }

            if (data.kind == MNSLShaderDataKind.Uniform) {
                emitDecoration(data.name, data.kind, varId, MNSLSPIRVDecoration.MNSLInternalNone, []);
            }
        }
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
                        scope.variables.exists(getVarBaseName(name)) &&
                        scope.variables.get(getVarBaseName(name)).isParam &&
                        !scope.variables.exists("__mnsl_param_" + getVarBaseName(name))
                    ) {

                        // this is a parameter assignment, we need to create a temporary variable as they are read-only
                        var varId = assignId();
                        var ptrId = getPtr(getType(MNSLAnalyser.getType(value)), MNSLSPIRVStorageClass.Function);
                        emitInstruction(MNSLSPIRVOpCode.OpVariable, [ptrId, varId, MNSLSPIRVStorageClass.Function]);
                        emitDebugLabel(varId, "__mnsl_param_" + getVarBaseName(name));
                        scope.setVariable("__mnsl_param_" + getVarBaseName(name), varId);
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

    public function emitBody(body: MNSLNodeChildren, scope: MNSLSPIRVScope, ?branchTo: Int): Void {
        if (body == null) {
            body = [];
        }

        var bodyHasReturned: Bool = false;
        for (nodeIdx in 0...body.length) {
            var node = body[nodeIdx];

            switch (node) {
                case IfStatement(_, _, _):
                    emitIfStatement(body, nodeIdx, scope, branchTo);
                    return;
                case WhileLoop(whileCond, whileBody, whileInfo):
                    emitWhileLoop(whileCond, whileBody, whileInfo, scope, body, nodeIdx, branchTo);
                    return;
                case ForLoop(forInit, forCond, forInc, forBody, forInfo):
                    emitForLoop(forInit, forCond, forInc, forBody, forInfo, scope, body, nodeIdx, branchTo);
                    return;
                case Return(_, _, _):
                    bodyHasReturned = true;
                case Continue(_):
                    bodyHasReturned = true;
                case Break(_):
                    bodyHasReturned = true;
                default:
            }

            emitNode(node, scope, body, nodeIdx);
        }

        if (branchTo != null && !bodyHasReturned) {
            emitInstruction(MNSLSPIRVOpCode.OpBranch, [branchTo]);
        }
    }

    public function emitNode(node: MNSLNode, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        switch (node) {
            case VariableDecl(name, type, value, info):
                return emitVariableDecl(name, type, value, info, scope, inBody, at);
            case VariableAssign(name, value, info):
                return emitVariableAssign(name, value, info, scope, inBody, at);
            case Identifier(name, type, info):
                return emitIdentifier(name, type, info, scope, inBody, at);
            case FunctionDecl(name, returnType, arguments, body, info):
                return emitFunctionDecl(name, returnType, arguments, body, info, scope, inBody, at);
            case FunctionCall(name, args, returnType, info):
                return emitFunctionCall(name, args, returnType, info, scope, inBody, at);
            case BinaryOp(left, op, right, type, info):
                return emitBinaryOp(left, op, right, type, info, scope, inBody, at);
            case UnaryOp(op, right, info):
                return emitUnaryOp(op, right, info, scope, inBody, at);
            case Return(value, type, info):
                return emitReturn(value, type, info, scope, inBody, at);
            case VectorCreation(comp, nodes, info):
                return emitVectorCreation(comp, nodes, info, scope, inBody, at);
            case VectorConversion(on, from, to):
                return emitVectorConversion(on, from, to, scope, inBody, at);
            case MatrixCreation(size, nodes, info):
                return emitMatrixCreation(size, nodes, info, scope, inBody, at);
            case FloatLiteralNode(value, info):
                return getConst(Std.parseFloat(value), MNSLType.TFloat);
            case IntegerLiteralNode(value, info):
                return getConst(Std.parseInt(value), MNSLType.TInt);
            case BooleanLiteralNode(value, info):
                return getConst(value, MNSLType.TBool);
            case TypeCast(on, from, to):
                return emitTypeCast(on, from, to, scope, inBody, at);
            case ImplicitTypeCast(on, to):
                return emitNode(on, scope, inBody, at);
            case SubExpression(node, info):
                return emitNode(node, scope, inBody, at);
            case StructAccess(on, field, type, info):
                return emitStructAccess(on, field, type, info, scope, inBody, at);
            case ArrayAccess(on, index, info):
                return emitArrayAccess(on, index, MNSLAnalyser.getType(node), info, scope, inBody, at);
            case Break(_):
                emitInstruction(MNSLSPIRVOpCode.OpBranch, [scope.getLoopActions().breakBranch]);
                return 0;
            case Continue(_):
                emitInstruction(MNSLSPIRVOpCode.OpBranch, [scope.getLoopActions().continueBranch]);
                return 0;
            case Block(body, info):
                emitBody(body, scope);
                return 0;
            default:
                trace("Unhandled node", node);
                return 0;
        }
    }

    public function emitMatrixCreation(size: Int, nodes: MNSLNodeChildren, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        if (nodes.length != size * size) {
            throw 'Matrix creation expects ${size * size} elements, got ${nodes.length}';
        }

        var id = assignId();
        var type = MNSLType.fromString('Mat${size}');
        var matrixType = getType(type);
        var vectorType = getType(MNSLType.fromString('Vec${size}'));

        var columnVectors = [];

        for (col in 0...size) {
            var colVecId = assignId();
            var colElements = [];

            for (row in 0...size) {
                var elementIdx = col * size + row;
                var elementId = emitNode(nodes[elementIdx], scope, inBody, at);
                colElements.push(elementId);
            }

            emitInstruction(MNSLSPIRVOpCode.OpCompositeConstruct, [vectorType, colVecId].concat(colElements));
            columnVectors.push(colVecId);
        }

        emitInstruction(MNSLSPIRVOpCode.OpCompositeConstruct, [matrixType, id].concat(columnVectors));

        return id;
    }

    public function emitWhileLoop(cond: MNSLNode, body: MNSLNodeChildren, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int, ?branchTo: Int): Int {
        var headerLabel = assignId();
        var loopLabel = assignId();
        var mergeLabel = assignId();
        var enterLabel = assignId();
        var branchToEnter = assignId();
        var whileAfter = inBody.slice(at + 1);

        // goto header
        emitInstruction(MNSLSPIRVOpCode.OpBranch, [enterLabel]);

        // enter
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [enterLabel]);
        emitInstruction(MNSLSPIRVOpCode.OpLoopMerge, [mergeLabel, branchToEnter, 0]);
        emitInstruction(MNSLSPIRVOpCode.OpBranch, [headerLabel]);

        // header
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [headerLabel]);
        var condId = emitNode(cond, scope, inBody, at);
        emitInstruction(MNSLSPIRVOpCode.OpBranchConditional, [condId, loopLabel, mergeLabel]);

        // loop body
        var newScope = scope.copy();
        newScope.setLoopActions(mergeLabel, branchToEnter);
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [loopLabel]);
        emitBody(body, newScope, branchToEnter);

        // enter branch
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [branchToEnter]);
        emitInstruction(MNSLSPIRVOpCode.OpBranch, [enterLabel]);

        // merge
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [mergeLabel]);
        emitBody(whileAfter, scope, branchTo);
        if (whileAfter.length == 0 && branchTo == null) {
            emitInstruction(MNSLSPIRVOpCode.OpUnreachable, []);
        }

        return 0;
    }

    public function emitForLoop(init: MNSLNode, cond: MNSLNode, inc: MNSLNode, body: MNSLNodeChildren, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int, ?branchTo: Int): Int {
        var headerLabel = assignId();
        var loopLabel = assignId();
        var mergeLabel = assignId();
        var enterLabel = assignId();
        var branchToEnter = assignId();
        var iterLabel = assignId();
        var forAfter = inBody.slice(at + 1);

        // goto header
        emitNode(init, scope, inBody, at);
        emitInstruction(MNSLSPIRVOpCode.OpBranch, [enterLabel]);

        // enter
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [enterLabel]);
        emitInstruction(MNSLSPIRVOpCode.OpLoopMerge, [mergeLabel, branchToEnter, 0]);
        emitInstruction(MNSLSPIRVOpCode.OpBranch, [headerLabel]);

        // header
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [headerLabel]);
        var condId = emitNode(cond, scope, inBody, at);
        emitInstruction(MNSLSPIRVOpCode.OpBranchConditional, [condId, loopLabel, mergeLabel]);

        // loop body
        var newScope = scope.copy();
        newScope.setLoopActions(mergeLabel, branchToEnter);
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [loopLabel]);
        emitBody(body, newScope, iterLabel);

        // iter body
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [iterLabel]);
        emitNode(inc, scope, inBody, at);
        emitInstruction(MNSLSPIRVOpCode.OpBranch, [branchToEnter]);

        // enter branch
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [branchToEnter]);
        emitInstruction(MNSLSPIRVOpCode.OpBranch, [enterLabel]);

        // merge
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [mergeLabel]);
        emitBody(forAfter, scope, branchTo);
        if (forAfter.length == 0 && branchTo == null) {
            emitInstruction(MNSLSPIRVOpCode.OpUnreachable, []);
        }

        return 0;
    }

    public function emitIfStatement(inBody: MNSLNodeChildren, at: Int, scope: MNSLSPIRVScope, ?branchTo: Int): Int {
        var condChainIdx = at;
        var condChainStatements: Array<{ cond: MNSLNode, body: MNSLNodeChildren, info: MNSLNodeInfo }> = [];
        var condChainElse: Null<MNSLNodeChildren> = null;

        while (condChainIdx < inBody.length) {
            var condChainNode = inBody[condChainIdx];

            switch (condChainNode) {
                case IfStatement(chainCond, chainBody, chainInfo):
                    if (condChainStatements.length == 0) {
                        condChainStatements.push({ cond: chainCond, body: chainBody, info: chainInfo });
                    } else {
                        break; // new block
                    }
                case ElseIfStatement(chainCond, chainBody, chainInfo):
                    condChainStatements.push({ cond: chainCond, body: chainBody, info: chainInfo });
                case ElseStatement(chainBody, chainInfo):
                    condChainElse = chainBody;
                    break;
                default:
                    break;
            }

            condChainIdx++;
        }

        var condAfter = inBody.slice(at + condChainStatements.length + (condChainElse != null ? 1 : 0));
        var condInfo = condChainStatements[0];
        var mergeLabel = assignId();
        var falseLabel = condChainElse != null ? assignId() : mergeLabel;
        var trueLabel = assignId();
        var condId = emitNode(condInfo.cond, scope, inBody, at);

        // handle elseif
        if (condChainStatements.length > 1) {
            var newElseBody: MNSLNodeChildren = [];
            for (i in 1...condChainStatements.length) {
                var chain = condChainStatements[i];
                newElseBody.push(
                    i == 1 ? IfStatement(chain.cond, chain.body, chain.info) :
                    ElseIfStatement(chain.cond, chain.body, chain.info)
                );
            }

            newElseBody.push(ElseStatement(condChainElse ?? [], condInfo.info));
            condChainElse = newElseBody;
        }

        // conditional
        emitInstruction(MNSLSPIRVOpCode.OpSelectionMerge, [mergeLabel, 0]);
        emitInstruction(MNSLSPIRVOpCode.OpBranchConditional, [condId, trueLabel, falseLabel]);

        // false
        if (condChainElse != null) {
            emitInstruction(MNSLSPIRVOpCode.OpLabel, [falseLabel]);
            emitBody(condChainElse ?? [], scope, mergeLabel);
        }

        // true
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [trueLabel]);
        emitBody(condInfo.body, scope, mergeLabel);

        // merge
        emitInstruction(MNSLSPIRVOpCode.OpLabel, [mergeLabel]);
        emitBody(condAfter, scope, branchTo);
        if (condAfter.length == 0 && branchTo == null) {
            emitInstruction(MNSLSPIRVOpCode.OpUnreachable, []);
        }

        return 0;
    }

    public function emitStructAccess(on: MNSLNode, field: String, type: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var varDef = getVar(StructAccess(on, field, type, info), scope, inBody, at);
        if (varDef.isParam) {
            return varDef.id;
        }

        var typeId = getType(type);
        var resultId = assignId();

        emitInstruction(MNSLSPIRVOpCode.OpLoad, [typeId, resultId, varDef.id]);

        return resultId;
    }

    public function emitArrayAccess(on: MNSLNode, index: MNSLNode, type: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var varDef = getVar(ArrayAccess(on, index, info), scope, inBody, at);
        if (varDef.isParam) {
            return varDef.id;
        }

        var typeId = getType(type);
        var resultId = assignId();
        var indexId = emitNode(index, scope, inBody, at);

        emitInstruction(MNSLSPIRVOpCode.OpLoad, [typeId, resultId, varDef.id]);
        emitInstruction(MNSLSPIRVOpCode.OpAccessChain, [
            getPtr(typeId, MNSLSPIRVStorageClass.Function),
            resultId,
            resultId,
            indexId
        ]);

        return resultId;
    }

    public function emitIdentifier(name: String, type: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var varDef = getVar(Identifier(name, type, info), scope, inBody, at);
        if (varDef.isParam) {
            return varDef.id;
        }

        var typeId = getType(type);
        var resultId = assignId();

        emitInstruction(MNSLSPIRVOpCode.OpLoad, [typeId, resultId, varDef.id]);

        return resultId;
    }

    public function emitVariableAssign(on: MNSLNode, value: MNSLNode, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var varDef = getVar(on, scope, inBody, at, true);
        var valueId = emitNode(value, scope, inBody, at);

        if (scope.swizzlePointers.exists(varDef.id)) {
            return emitSwizzleStore(varDef.id, valueId, scope, inBody, at);
        }

        emitInstruction(MNSLSPIRVOpCode.OpStore, [varDef.id, valueId]);

        return varDef.id;
    }

    public function emitSwizzleStore(swizzleId: Int, valueId: Int, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var swizzleInfo = scope.swizzlePointers.get(swizzleId);
        if (swizzleInfo == null) {
            throw "Invalid swizzle pointer: " + swizzleId;
        }

        var originalVecId = assignId();
        emitInstruction(MNSLSPIRVOpCode.OpLoad, [getType(swizzleInfo.vectorType), originalVecId, swizzleInfo.basePtr]);

        var newVecId = assignId();
        var originalSize = swizzleInfo.vectorType.getVectorComponents();

        var shuffleIndices = [];

        for (i in 0...originalSize) {
            var componentInSwizzle = swizzleInfo.components.indexOf(i);
            if (componentInSwizzle >= 0) {
                shuffleIndices.push(originalSize + componentInSwizzle);
            } else {
                shuffleIndices.push(i);
            }
        }

        emitInstruction(MNSLSPIRVOpCode.OpVectorShuffle, [
            getType(swizzleInfo.vectorType),
            newVecId,
            originalVecId,
            valueId
        ].concat(shuffleIndices));

        emitInstruction(MNSLSPIRVOpCode.OpStore, [swizzleInfo.basePtr, newVecId]);
        scope.swizzlePointers.remove(swizzleId);

        return swizzleInfo.basePtr;
    }

    public function emitVariableDecl(name: String, type: MNSLType, value: MNSLNode, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        if (!scope.variables.exists(name)) {
            throw "Pre-emit error: Variable not found in scope: " + name;
        }

        var varId = scope.variables.get(name);
        if (value != null) {
            var valueId = emitNode(value, scope, inBody, at);
            emitInstruction(MNSLSPIRVOpCode.OpStore, [varId.id, valueId]);
        }

        return varId.id;
    }

    public function emitVectorConversion(on: MNSLNode, fromComp: Int, toComp: Int, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var onId = emitNode(on, scope, inBody, at);
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

    public function emitVectorCreation(comp: Int, nodes: Array<MNSLNode>, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        if (nodes.length != comp && nodes.length != 1) {
            throw 'Vector creation expects ${comp} components, but got ${nodes.length}';
        }

        var type = MNSLType.fromString('Vec${comp}');
        var typeId = getType(type);
        var resId = assignId();

        if (nodes.length == 1) {
            var scalarId = emitTypeCast(nodes[0], MNSLAnalyser.getType(nodes[0]), MNSLType.TFloat, scope, inBody, at);
            var componentIds = [for (i in 0...comp) scalarId];

            emitInstruction(MNSLSPIRVOpCode.OpCompositeConstruct, [typeId, resId].concat(componentIds));
            return resId;
        }

        emitInstruction(MNSLSPIRVOpCode.OpCompositeConstruct, [typeId, resId].concat([for (n in nodes) emitTypeCast(n, MNSLAnalyser.getType(n), MNSLType.TFloat, scope, inBody, at)]));

        return resId;
    }

    public function emitTypeCast(on: MNSLNode, from: MNSLType, to: MNSLType, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var onId = emitNode(on, scope, inBody, at);
        if (from.equals(to)) {
            return onId;
        }

        var resId = assignId();
        var targetType = getType(to);

        if (from.isFloat() && to.isInt()) {
            emitInstruction(MNSLSPIRVOpCode.OpConvertFToS, [targetType, resId, onId]);
            return resId;
        }

        if (from.isInt() && to.isFloat()) {
            emitInstruction(MNSLSPIRVOpCode.OpConvertSToF, [targetType, resId, onId]);
            return resId;
        }

        emitInstruction(MNSLSPIRVOpCode.OpBitcast, [targetType, resId, onId]); // TODO: review
        return resId;
    }

    public function emitUnaryOp(op: MNSLToken, right: MNSLNode, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var rightId = emitNode(right, scope, inBody, at);
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

    public function emitBinaryOp(left: MNSLNode, op: MNSLToken, right: MNSLNode, resType: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var leftId = emitNode(left, scope, inBody, at);
        var rightId = emitNode(right, scope, inBody, at);
        var leftType = MNSLAnalyser.getType(left, true);
        var rightType = MNSLAnalyser.getType(right, true);
        var resultType = MNSLAnalyser.getType(right);

        var resultId = assignId();

        switch (op) {
            case MNSLToken.Plus(_):
                if (resultType.isFloat() || resultType.isVector())
                    emitInstruction(MNSLSPIRVOpCode.OpFAdd, [getType(resultType), resultId, leftId, rightId]);
                else if (resultType.isMatrix())
                    emitInstruction(MNSLSPIRVOpCode.OpFAdd, [getType(resultType), resultId, leftId, rightId]);
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpIAdd, [getType(resultType), resultId, leftId, rightId]);
                else throw "Unsupported type for addition: " + resultType.toHumanString();

            case MNSLToken.Minus(_):
                if (resultType.isFloat() || resultType.isVector())
                    emitInstruction(MNSLSPIRVOpCode.OpFSub, [getType(resultType), resultId, leftId, rightId]);
                else if (resultType.isMatrix())
                    emitInstruction(MNSLSPIRVOpCode.OpFSub, [getType(resultType), resultId, leftId, rightId]);
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpISub, [getType(resultType), resultId, leftId, rightId]);
                else throw "Unsupported type for subtraction: " + resultType.toHumanString();

            case MNSLToken.Star(_):
                if (leftType.isMatrix() && rightType.isMatrix()) {
                    emitInstruction(MNSLSPIRVOpCode.OpMatrixTimesMatrix, [getType(resultType), resultId, leftId, rightId]);
                }
                else if (leftType.isMatrix() && rightType.isVector()) {
                    emitInstruction(MNSLSPIRVOpCode.OpMatrixTimesVector, [getType(resultType), resultId, leftId, rightId]);
                }
                else if (leftType.isVector() && rightType.isMatrix()) {
                    emitInstruction(MNSLSPIRVOpCode.OpVectorTimesMatrix, [getType(resultType), resultId, leftId, rightId]);
                }
                else if (leftType.isMatrix() && rightType.isFloat()) {
                    emitInstruction(MNSLSPIRVOpCode.OpMatrixTimesScalar, [getType(resultType), resultId, leftId, rightId]);
                }
                else if (leftType.isFloat() && rightType.isMatrix()) {
                    emitInstruction(MNSLSPIRVOpCode.OpMatrixTimesScalar, [getType(resultType), resultId, rightId, leftId]);
                }
                else if (resultType.isFloat() || resultType.isVector())
                    emitInstruction(MNSLSPIRVOpCode.OpFMul, [getType(resultType), resultId, leftId, rightId]);
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpIMul, [getType(resultType), resultId, leftId, rightId]);
                else throw "Unsupported type for multiplication: " + resultType.toHumanString();

            case MNSLToken.Slash(_):
                if (leftType.isMatrix() && rightType.isFloat()) {
                    var invScalarId = assignId();

                    emitInstruction(MNSLSPIRVOpCode.OpFDiv, [getType(MNSLType.TFloat), invScalarId, getConst(1.0, MNSLType.TFloat), rightId]);
                    emitInstruction(MNSLSPIRVOpCode.OpMatrixTimesScalar, [getType(resultType), resultId, leftId, invScalarId]);
                }
                else if (resultType.isFloat() || resultType.isVector()) {
                    if (leftType.isInt()) {
                        var leftConvId = assignId();
                        emitInstruction(MNSLSPIRVOpCode.OpConvertSToF, [getType(MNSLType.TFloat), leftConvId, leftId]);
                        leftId = leftConvId;
                    }

                    if (rightType.isInt()) {
                        var rightConvId = assignId();
                        emitInstruction(MNSLSPIRVOpCode.OpConvertSToF, [getType(MNSLType.TFloat), rightConvId, rightId]);
                        rightId = rightConvId;
                    }

                    emitInstruction(MNSLSPIRVOpCode.OpFDiv, [getType(resultType), resultId, leftId, rightId]);
                }
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpSDiv, [getType(resultType), resultId, leftId, rightId]);
                else throw "Unsupported type for division: " + resultType.toHumanString();

            case MNSLToken.Percent(_):
                if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpSRem, [getType(resultType), resultId, leftId, rightId]);
                else throw "Unsupported type for modulo: " + resultType.toHumanString();

            case MNSLToken.Equal(_):
                if (resultType.isFloat() || resultType.isVector())
                    emitInstruction(MNSLSPIRVOpCode.OpFOrdEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpIEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (resultType.isBool())
                    emitInstruction(MNSLSPIRVOpCode.OpLogicalEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for equality: " + resultType.toHumanString();

            case MNSLToken.Greater(_):
                if (resultType.isFloat() || resultType.isVector())
                    emitInstruction(MNSLSPIRVOpCode.OpFOrdGreaterThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpSGreaterThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for greater than: " + resultType.toHumanString();

            case MNSLToken.GreaterEqual(_):
                if (resultType.isFloat() || resultType.isVector())
                    emitInstruction(MNSLSPIRVOpCode.OpFOrdGreaterThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpSGreaterThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for greater than or equal: " + resultType.toHumanString();

            case MNSLToken.Less(_):
                if (resultType.isFloat() || resultType.isVector())
                    emitInstruction(MNSLSPIRVOpCode.OpFOrdLessThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpSLessThan, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for less than: " + resultType.toHumanString();

            case MNSLToken.LessEqual(_):
                if (resultType.isFloat() || resultType.isVector())
                    emitInstruction(MNSLSPIRVOpCode.OpFOrdLessThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpSLessThanEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for less than or equal: " + resultType.toHumanString();

            case MNSLToken.NotEqual(_):
                if (resultType.isFloat() || resultType.isVector())
                    emitInstruction(MNSLSPIRVOpCode.OpFOrdNotEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else if (resultType.isInt())
                    emitInstruction(MNSLSPIRVOpCode.OpINotEqual, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for not equal: " + resultType.toHumanString();

            case MNSLToken.And(_):
                if (resultType.isBool())
                    emitInstruction(MNSLSPIRVOpCode.OpLogicalAnd, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for logical AND: " + resultType.toHumanString();

            case MNSLToken.Or(_):
                if (resultType.isBool())
                    emitInstruction(MNSLSPIRVOpCode.OpLogicalOr, [getType(MNSLType.TBool), resultId, leftId, rightId]);
                else throw "Unsupported type for logical OR: " + resultType.toHumanString();

            default:
                throw "Unsupported binary operator: " + op;
        }

        return resultId;
    }

    public function emitFunctionDecl(name: String, returnType: MNSLType, arguments: MNSLFuncArgs, body: MNSLNodeChildren, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
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

    public function emitBuiltinFunctionCall(name: String, args: Array<MNSLNode>, returnType: MNSLType, info: MNSLNodeInfo, glslMapping: MNSLSPIRVUnifiedStd, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        var argIds = [for (arg in args) emitNode(arg, scope, inBody, at)];
        var retId = assignId();
        var typeId = getType(returnType);

        switch(name) {
            case "texture":
                if (args.length != 2) {
                    throw "texture() requires sampler and texcoords";
                }

                emitInstruction(MNSLSPIRVOpCode.OpImageSampleImplicitLod, [typeId, retId].concat(argIds)); // TODO: fix
                return retId;

            case "dot":
                if (args.length != 2) {
                    throw "dot() requires 2 arguments";
                }
                emitInstruction(MNSLSPIRVOpCode.OpDot, [typeId, retId].concat(argIds));
                return retId;

            case "mod":
                if (args.length != 2) {
                    throw "mod() requires 2 arguments";
                }

                emitInstruction(MNSLSPIRVOpCode.OpFRem, [typeId, retId].concat(argIds)); // TODO: review
                return retId;

            default:
                var glslExtId = getExtGlslStd();
                var glslInst = glslMapping;
                emitInstruction(MNSLSPIRVOpCode.OpExtInst, [typeId, retId, glslExtId, glslInst].concat(argIds));
                return retId;
        }
    }

    public function emitFunctionCall(name: String, args: Array<MNSLNode>, returnType: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        for (func in _glslFuncMap) {
            if (func.name == name) {
                return emitBuiltinFunctionCall(name, args, returnType, info, func.mapping, scope, inBody, at);
            }
        }

        if (!_functions.exists(name)) {
            throw "Function not found: " + name;
        }

        var funcId: Int = _functions.get(name);
        var argIds = [for (arg in args) emitNode(arg, scope, inBody, at)];
        var retId = assignId();

        emitInstruction(MNSLSPIRVOpCode.OpFunctionCall, [getType(returnType), retId, funcId].concat(argIds));

        return retId;
    }

    public function emitReturn(value: MNSLNode, type: MNSLType, info: MNSLNodeInfo, scope: MNSLSPIRVScope, inBody: MNSLNodeChildren, at: Int): Int {
        switch(value) {
            case VoidNode(_):
                emitInstruction(MNSLSPIRVOpCode.OpReturn, []);
            default:
                emitInstruction(MNSLSPIRVOpCode.OpReturnValue, [emitNode(value, scope, inBody, at)]);
        }

        return 0;
    }

    public function getBytes(): Bytes {
        return _bin.getBytes();
    }

    override public function run(): Void {
        // caps
        emitInstruction(MNSLSPIRVOpCode.OpCapability, [MNSLSPIRVCapability.Shader]);

        // extensions
        getExtGlslStd();

        // memory model + entry point
        emitInstruction(MNSLSPIRVOpCode.OpMemoryModel, [0, 1]); // Logical, GLSL450
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

        // store index
        var preShaderIdx = _instructions.length;

        // find/create all constants and assign IDs
        getConst(0.0, MNSLType.TFloat); // vec init (x,y,z)
        getConst(1.0, MNSLType.TFloat); // vec init (w)
        getConst(0, MNSLType.TInt); // vec idx (x)
        getConst(1, MNSLType.TInt); // vec idx (y)
        getConst(2, MNSLType.TInt); // vec idx (z)
        getConst(3, MNSLType.TInt); // vec idx (w)
        preEmit(_ast); // user-defined constants

        // shader data
        emitShaderData();

        // reverse init order
        _ptrInit.reverse();
        _constInit.reverse();
        _typeInit.reverse();

        // ast
        emitBody(_ast, {});

        // ptr types
        for (ptr in _ptrInit) {
            insertInstruction(preShaderIdx, MNSLSPIRVOpCode.OpTypePointer, [ptr.id, ptr.storageClass, ptr.typeId]);
        }

        // function types
        var functionTypes = _typeInit.filter(x -> x.op == MNSLSPIRVOpCode.OpTypeFunction);
        for (type in functionTypes) {
            insertInstruction(preShaderIdx, type.op, type.oper);
        }

        // array types
        var arrayTypes = _typeInit.filter(x -> x.op == MNSLSPIRVOpCode.OpTypeArray);
        for (type in arrayTypes) {
            insertInstruction(preShaderIdx, type.op, type.oper);
        }

        // constants
        for (const in _constInit) {
            insertInstruction(preShaderIdx, const.op, const.oper);
        }

        // types (excl. functions and arrays)
        var basicTypes = _typeInit.filter(x -> x.op != MNSLSPIRVOpCode.OpTypeArray && x.op != MNSLSPIRVOpCode.OpTypeFunction);
        for (type in basicTypes) {
            insertInstruction(preShaderIdx, type.op, type.oper);
        }

        // debug
        var debugLabels = Lambda.count(_debugLabels);
        for (label in _debugLabels.keys()) {
            var name = _debugLabels.get(label);
            insertInstruction(entryInst + 1, MNSLSPIRVOpCode.OpName, [label].concat(convString(name)));
        }

        // decorations
        for (decoration in _decorations) {
            if (decoration.decoration == -1) continue;
            insertInstruction(entryInst + debugLabels + 1, MNSLSPIRVOpCode.OpDecorate, [decoration.id, decoration.decoration].concat(decoration.oper));
        }

        // entry point
        if (_entry == 0) {
            throw "No entry point found in the SPIR-V module.";
        }

        var execModel = switch (_config.shaderType) {
            case MNSLSPIRVShaderType.SPIRV_SHADER_TYPE_VERTEX: MNSLSPIRVExecutionModel.Vertex;
            case MNSLSPIRVShaderType.SPIRV_SHADER_TYPE_FRAGMENT: MNSLSPIRVExecutionModel.Fragment;
            default: throw "Unsupported shader type: " + _config.shaderType;
        }

        editInstruction(entryInst, MNSLSPIRVOpCode.OpEntryPoint,
            [execModel, _entry]
            .concat(convString("main")
            .concat([for (data in _decorations.filter(x -> x.kind == MNSLShaderDataKind.Input || x.kind == MNSLShaderDataKind.Output )) data.id]))
        );

        if (_config.shaderType == MNSLSPIRVShaderType.SPIRV_SHADER_TYPE_FRAGMENT) {
            insertInstruction(entryInst + 1, MNSLSPIRVOpCode.OpExecutionMode, [_entry, 7]); // OriginUpperLeft
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