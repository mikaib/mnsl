package mnsl.spirv;

import mnsl.analysis.MNSLType;

@:structInit
class MNSLSPIRVScope {

    public var variables: Map<String, { id: Int, isParam: Bool }> = [];
    public var swizzlePointers: Map<Int, { basePtr: Int, components: Array<Int>, vectorType: MNSLType }> = [];

    public function copy(): MNSLSPIRVScope {
        return {
            variables: variables.copy(),
            swizzlePointers: swizzlePointers.copy()
        };
    }

    public function setVariable(name: String, id: Int): Void {
        variables.set(name, { id: id, isParam: false });
    }

    public function setParameter(name: String, id: Int): Void {
        variables.set(name, { id: id, isParam: true });
    }

    public function getVariable(name: String): { id: Int, isParam: Bool } {
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

}
