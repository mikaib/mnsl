import mnsl.MNSL;
import mnsl.MNSLContext;

class Demo {

    public static function main() {
        js.Syntax.code('window.compile = {0}', compile);
    }

    public static function compile(code: String, optimize: Bool) {
        var shader: MNSLContext;

        if (optimize) shader = MNSL.fromSource(code, {});
        else shader = MNSL.fromSource(code, { optimizerPlugins: [] });

        var glsl: String = shader.emitGLSL({
            version: GLSL_VER_300_ES,
        });

        return glsl;
    }

}