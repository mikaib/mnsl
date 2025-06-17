package mnsl.spirv;

enum abstract MNSLSPIRVStorageClass(Int) to Int {
    var UniformConstant = 0;
    var Input = 1;
    var Uniform = 2;
    var Output = 3;
    var Workgroup = 4;
    var CrossWorkgroup = 5;
    var Private = 6;
    var Function = 7;
    var Generic = 8;
    var PushConstant = 9;
    var AtomicCounter = 10;
    var Image = 11;
    var StorageBuffer = 12;
}
