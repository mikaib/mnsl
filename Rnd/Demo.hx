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

        if (shader.hasErrors()) {
            throw shader.errorToString(
                shader.getErrors()[0]
            );
        }

        var glsl: String = shader.emitGLSL({
            version: GLSL_VER_300,
            versionDirective: GLSL_ES
        });

        return glsl;
    }

}