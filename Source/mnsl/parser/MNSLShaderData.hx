package mnsl.parser;

import mnsl.analysis.MNSLType;

@:structInit
class MNSLShaderData {
    public var kind: MNSLShaderDataKind;
    public var type: MNSLType;
    public var name: String;
}
