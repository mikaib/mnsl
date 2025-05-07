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
        var first: MNSLTokenInfo = {
            line: 0xFF,
            column: 0xFF,
            length: 0
        };

        var last: MNSLTokenInfo = tokenInfos[0] ?? {
            line: 0,
            column: 0,
            length: 0
        };

        for (tokenInfo in tokenInfos) {
            if (tokenInfo == null) {
                continue;
            }

            if (tokenInfo.line < first.line || (tokenInfo.line == first.line && tokenInfo.column < first.column)) {
                first = tokenInfo;
            }
            if (tokenInfo.line > last.line || (tokenInfo.line == last.line && tokenInfo.column + tokenInfo.length > last.column + last.length)) {
                last = tokenInfo;
            }
        }

        return {
            fromLine: first.line,
            fromColumn: first.column,
            toLine: last.line,
            toColumn: last.column + last.length
        };
    }

    /**
     * Converts MNSLNodeInfo into a string.
     */
    @:to
    public function toString(): String {
        return fromLine + ":" + fromColumn + " - " + toLine + ":" + toColumn;
    }
}
