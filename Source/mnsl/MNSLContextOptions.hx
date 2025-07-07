package mnsl;

import mnsl.tokenizer.MNSLToken;
import mnsl.optimiser.MNSLOptimiserPlugin;

@:structInit
class MNSLContextOptions {
    public var defines: Map<String, Array<MNSLToken>> = [];
    public var rootPath: Null<String> = null;
    public var optimizerPlugins: Array<MNSLOptimiserPlugin> = [
        new mnsl.optimiser.impl.MNSLOptimiseScalarVectorInit(),
        new mnsl.optimiser.impl.MNSLOptimiseSwizzleAssign(),
        new mnsl.optimiser.impl.MNSLOptimiseSwizzleAccess(),
    ];
    public var preprocessorDefines: Array<String> = [];
    public var preprocessorIncludeFunc: String->String->Null<String> = (path: String, root: String) -> {
        #if !MNSL_NO_SYS
        var filePath = haxe.io.Path.join([root, path]);
        if (sys.FileSystem.exists(filePath)) {
            return sys.io.File.getContent(filePath);
        } else {
            return null;
        }
        #else
        return null;
        #end
    };
}
