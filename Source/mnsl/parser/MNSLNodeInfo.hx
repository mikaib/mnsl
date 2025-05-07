package mnsl.parser;
import mnsl.tokenizer.MNSLTokenInfo;

@:structInit
class MNSLNodeInfo {
    public var fromLine: Int;
    public var fromColumn: Int;
    public var toLine: Int;
    public var toColumn: Int;

    /**
     * Converts a single token info to a node info.
     */
    public static function fromTokenInfo(tokenInfo: MNSLTokenInfo): MNSLNodeInfo {
        return {
            fromLine: tokenInfo.line,
            fromColumn: tokenInfo.column,
            toLine: tokenInfo.line,
            toColumn: tokenInfo.column + tokenInfo.length
        };
    }

    /**
     * Converts a list of token infos to a node info.
     * @param tokenInfos The list of token infos.
     */
    public static function fromTokenInfos(tokenInfos: Array<MNSLTokenInfo>): MNSLNodeInfo {
        var first = tokenInfos[0];
        var last = tokenInfos[tokenInfos.length - 1];

        return {
            fromLine: first.line,
            fromColumn: first.column,
            toLine: last.line,
            toColumn: last.column + last.length
        };
    }

}
