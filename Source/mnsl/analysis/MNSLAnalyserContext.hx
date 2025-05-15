package mnsl.analysis;

import mnsl.MNSLError;

class MNSLAnalyserContext {

    public static var contexts: Array<MNSLAnalyserContext> = [];

    public static function validate(mnslCtx: MNSLContext): Void {
        for (ctx in contexts) {
            for (f in ctx.functions) {
                if (!f.hasImplementation) {
                    mnslCtx.emitError(AnalyserNoImplementation(f));
                }
            }
        }
    }

    public static function reset(): Void {
        contexts = [];
    }

    public var functions: Array<MNSLAnalyserFunction>;

    public function new() {
        functions = [];
        MNSLAnalyserContext.contexts.push(this);
    }

    public function copy(): MNSLAnalyserContext {
        var x = new MNSLAnalyserContext();
        x.functions = functions.copy();

        return x;
    }

    public function findFunctions(name: String, args: Array<MNSLType>): Array<MNSLAnalyserFunction> {
        var result = [];
        for (f in functions) {
            if (f.name == name && f.args.length == args.length) {
                var match = true;
                for (i in 0...args.length) {
                    if (!f.args[i].type.equals(args[i])) {
                        match = false;
                        break;
                    }
                }
                if (match) {
                    result.push(f);
                }
            }
        }
        return result;
    }
}
