package mnsl.analysis;

import mnsl.parser.MNSLNode;

typedef MNSLGenericFunc = { declNode: MNSLNode, callNode: MNSLNode, name: String, ret: MNSLType, args: MNSLFuncArgs };
