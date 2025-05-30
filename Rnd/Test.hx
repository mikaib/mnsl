import mnsl.MNSL;
import mnsl.MNSLContext;
import mnsl.glsl.MNSLGLSLVersion;

class Test {

    public static function main() {
        var shader: MNSLContext = MNSL.fromFile("test.mns");
        var glsl: String = shader.emitGLSL({
            version: GLSL_VER_300_ES
        });

        trace(glsl);

        var test: MyClass = {
            hello: "Hello",
            world: "World"
        };
    }

}

@:structInit
class MyClass {

    public var hello: String;
    public var world: String;
    public var helloGetter(get, never): String;

    inline function get_helloGetter(): String {
        return hello + " " + world;
    }

}