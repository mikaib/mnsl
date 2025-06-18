package mnsl;

import mnsl.parser.MNSLNode;

enum MNSLWarning {
    ImplicitVectorTruncation(node: MNSLNode, from: Int, to: Int);
    ImplicitFloatToInt(node: MNSLNode);
}
