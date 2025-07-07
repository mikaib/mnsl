package mnsl.analysis;

class MNSLAnalyserContext {

    public var functions: Array<MNSLAnalyserFunction>;
    public var variables: Array<MNSLAnalyserVariable>;
    public var currentFunction: MNSLAnalyserFunction;
    public var templates: Map<String, MNSLType>;
    public var currentIsLoop: Bool;

    public function new() {
        functions = [];
        variables = [];
        templates = [];
        currentFunction = null;
        currentIsLoop = false;
    }

    public function copy(): MNSLAnalyserContext {
        var x = new MNSLAnalyserContext();
        x.functions = functions.copy();
        x.variables = variables.copy();
        x.templates = templates.copy();
        x.currentFunction = currentFunction;
        x.currentIsLoop = currentIsLoop;

        return x;
    }

    public function findFunction(name: String, args: Array<MNSLType>, hasImpl: Bool = false): MNSLAnalyserFunction {
        for (f in functions) {
            if (f.name == name && f.args.length == args.length) {
                return f;
            }
        }
        return null;
    }

    public function findVariable(name: String): MNSLAnalyserVariable {
        for (v in variables) {
            if (v.name == name) {
                return v;
            }
        }
        return null;
    }

}
