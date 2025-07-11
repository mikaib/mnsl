package mnsl.spirv;

import mnsl.analysis.MNSLType;

@:structInit
class MNSLSPIRVScope {

    public var variables: Map<String, { id: Int, isParam: Bool, type: MNSLType }> = [];
    public var swizzlePointers: Map<Int, { basePtr: Int, components: Array<Int>, vectorType: MNSLType }> = [];
    public var loopActions: { breakBranch: Int, continueBranch: Int } = { breakBranch: -1, continueBranch: -1 };

    public function copy(): MNSLSPIRVScope {
        return {
            variables: variables.copy(),
            swizzlePointers: swizzlePointers.copy(),
            loopActions: { breakBranch: loopActions.breakBranch, continueBranch: loopActions.continueBranch }
        };
    }

    public function setVariable(name: String, id: Int, type: MNSLType): Void {
        variables.set(name, { id: id, isParam: false, type: type });
    }

    public function setParameter(name: String, id: Int, type: MNSLType): Void {
        variables.set(name, { id: id, isParam: true, type: type });
    }

    public function remapVar(name: String, remapTo: Int): Void {
        var curr = variables.get(name);
        curr.id = remapTo;

        variables.set(name, curr);
    }

    public function getVariable(name: String): { id: Int, isParam: Bool, type: MNSLType } {
        return variables.get(name);
    }

    public function hasVariable(name: String): Bool {
        return variables.exists(name);
    }

    public function setSwizzlePointer(basePtr: Int, components: Array<Int>, vectorType: MNSLType): Void {
        swizzlePointers.set(basePtr, { basePtr: basePtr, components: components, vectorType: vectorType });
    }

    public function getSwizzlePointer(basePtr: Int): { basePtr: Int, components: Array<Int>, vectorType: MNSLType } {
        return swizzlePointers.get(basePtr);
    }

    public function hasSwizzlePointer(basePtr: Int): Bool {
        return swizzlePointers.exists(basePtr);
    }

    public function setLoopActions(breakBranch: Int, continueBranch: Int): Void {
        loopActions.breakBranch = breakBranch;
        loopActions.continueBranch = continueBranch;
    }

    public function getLoopActions(): { breakBranch: Int, continueBranch: Int } {
        return loopActions;
    }

    public function clearLoopActions(): Void {
        loopActions.breakBranch = -1;
        loopActions.continueBranch = -1;
    }

}
