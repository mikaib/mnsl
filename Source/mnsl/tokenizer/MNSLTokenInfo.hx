package mnsl.tokenizer;

@:structInit
class MNSLTokenInfo {
    public var line: Int = 0;
    public var column: Int = 0;
    public var position: Int = 0;
    public var length: Int = 1;

    @:to(String)
    public function toString(): String {
        return line + ":" + column + " ";
    }

}
