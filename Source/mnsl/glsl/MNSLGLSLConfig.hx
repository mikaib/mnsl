package mnsl.glsl;

@:structInit
class MNSLGLSLConfig {
    public var version: MNSLGLSLVersion;
    public var versionDirective: MNSLGLSLVersionDirective;
    public var useAttributeAndVaryingKeywords: Null<Bool> = null;
    public var usePrecision: Null<Bool> = null;
}
