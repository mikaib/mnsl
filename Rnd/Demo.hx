import mnsl.MNSL;
import mnsl.MNSLContext;
import haxe.io.UInt8Array;
import haxe.io.Bytes;
import haxe.io.BytesData;

class Demo {

    public static function main() {
        js.Syntax.code('window.compile = {0}', compile);
    }

    public static function compile(code: String, optimize: Bool): Array<Dynamic> {
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

        var spirv: Bytes = shader.emitSPIRV({
            shaderType: SPIRV_SHADER_TYPE_FRAGMENT
        });

        var spirvArr: UInt8Array = UInt8Array.fromBytes(spirv);
        return [glsl, spirvArr];
    }

}