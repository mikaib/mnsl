package mnsl.spirv;

@:structInit
class MNSLSPIRVScope {

    public var variables: Map<String, { id: Int, isParam: Bool }> = [];

    public function copy(): MNSLSPIRVScope {
        return {
            variables: variables.copy()
        };
    }

    public function setVariable(name: String, id: Int): Void {
        variables.set(name, { id: id, isParam: false });
    }

    public function setParameter(name: String, id: Int): Void {
        variables.set(name, { id: id, isParam: true });
    }

}
