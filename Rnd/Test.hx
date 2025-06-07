import mnsl.MNSL;
import mnsl.MNSLContext;
import mnsl.glsl.MNSLGLSLVersion;

class Test {

    public static function main() {
        var shader: MNSLContext = MNSL.fromFile("test.mns", {
            preprocessorDefines: [
                "TEST_DEFINE"
            ]
        });

        var glsl: String = shader.emitGLSL({
            version: GLSL_VER_300_ES,
        });

        trace(glsl);
    }

}