package mnsl;

import mnsl.tokenizer.MNSLToken;
import mnsl.optimizer.MNSLOptimizerPlugin;

@:structInit
class MNSLContextOptions {
    public var defines: Map<String, Array<MNSLToken>> = [];
    public var rootPath: Null<String> = null;
    public var optimizerPlugins: Array<MNSLOptimizerPlugin> = [
        new mnsl.optimizer.impl.MNSLOptimizeScalarVectorInit(),
        new mnsl.optimizer.impl.MNSLOptimizeSwizzleAccess(),
        new mnsl.optimizer.impl.MNSLOptimizeSwizzleAssign()
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
