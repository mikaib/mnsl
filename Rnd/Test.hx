import mnsl.MNSL;
import mnsl.MNSLContext;
import mnsl.glsl.MNSLGLSLVersion;
import mnsl.glsl.MNSLGLSLVersionDirective;

class Test {

    public static function main() {
        var shader: MNSLContext = MNSL.fromFile("test.mns", {});

        var glsl: String = shader.emitGLSL({
            version: GLSL_VER_300,
            versionDirective: GLSL_CORE
        });

        trace(glsl);
    }

}