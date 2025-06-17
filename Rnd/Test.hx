import mnsl.MNSL;
import mnsl.MNSLContext;
import sys.io.File;
import mnsl.spirv.MNSLSPIRVShaderType;

class Test {
    static final RESET = "\033[0m";
    static final RED = "\033[31m";
    static final GREEN = "\033[32m";
    static final YELLOW = "\033[33m";
    static final BLUE = "\033[34m";
    static final MAGENTA = "\033[35m";
    static final CYAN = "\033[36m";
    static final BOLD = "\033[1m";

    public static function main() {
        var shader: MNSLContext = MNSL.fromFile("test.mns", {
            optimizerPlugins: [],
        });

        if (shader.hasWarnings()) {
            for (warning in shader.getWarnings()) {
                Sys.println(YELLOW + shader.warningToString(warning) + RESET);
            }
        }

        if(shader.hasErrors()) {
            for (error in shader.getErrors()) {
                Sys.println(RED + shader.errorToString(error) + RESET);
            }
            Sys.println("\n" + RED + BOLD + 'Failed to compile with ' +
                YELLOW + '${shader.getWarnings().length}' + RED + ' warnings and ' +
                RED + '${shader.getErrors().length}' + RED + ' errors.' + RESET);
            return;
        }

        var glsl: String = shader.emitGLSL({
            version: GLSL_VER_300,
            versionDirective: GLSL_CORE
        });

        var spirv = shader.emitSPIRV({
            shaderType: ShaderTypeVertex
        });

        Sys.println("\n" + GREEN + BOLD + 'Successfully compiled with ' +
            (shader.getWarnings().length > 0 ? YELLOW : GREEN) +
            '${shader.getWarnings().length}' + GREEN + ' warnings and no errors.' + RESET);

        Sys.println(MAGENTA + BOLD + "SPIR-V Output:" + RESET);
        showBin(spirv);

        File.saveBytes("rnd_spirv.spv", spirv);
        File.saveContent("rnd_glsl.glsl", glsl);

        Sys.command('spirv-cross rnd_spirv.spv --version 450 --output rnd_spirv.glsl');
        Sys.command('spirv-dis rnd_spirv.spv -o rnd_spirv.spvasm');

        Sys.println(MAGENTA + BOLD + "SPIR-V Assembly Output:" + RESET);
        var spirvAsm = File.getContent("rnd_spirv.spvasm");
        Sys.println(spirvAsm);

        Sys.println(MAGENTA + BOLD + "AST:" + RESET);
        shader.printAST(shader.getAST());
        Sys.println("");

        Sys.println(MAGENTA + BOLD + "SPIR-V GLSL Output:" + RESET);
        var spirvGlsl = File.getContent("rnd_spirv.glsl");
        Sys.println(spirvGlsl);

        Sys.println(MAGENTA + BOLD + "GLSL Output:" + RESET);
        Sys.println(glsl);
    }

static function showBin(bytes: haxe.io.Bytes) {
    var hex = bytes.toHex();
    var output = new StringBuf();
    var byteLen = bytes.length;
    for (i in 0...byteLen >> 4) {
        var line = "";
        var ascii = "";
        for (j in 0...16) {
            var idx = (i << 4) + j;
            if (idx < byteLen) {
                var hexByte = hex.substr(idx * 2, 2);
                line += hexByte;
                if (j != 15) line += " ";
                var byteVal = bytes.get(idx);
                ascii += (byteVal >= 32 && byteVal <= 126) ? String.fromCharCode(byteVal) : ".";
            } else {
                line += "   ";
                ascii += " ";
            }
        }
        output.add(StringTools.lpad(Std.string(i << 4), "0", 4) + ": " + line + " " + ascii + "\n");
    }
    Sys.println(output.toString() + RESET);
}

}