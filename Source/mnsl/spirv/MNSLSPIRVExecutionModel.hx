package mnsl.spirv;

enum abstract MNSLSPIRVExecutionModel(Int) to Int {
    var Vertex = 0;
    var TessellationControl = 1;
    var TessellationEvaluation = 2;
    var Geometry = 3;
    var Fragment = 4;
    var GLCompute = 5;
    var Kernel = 6;
}
