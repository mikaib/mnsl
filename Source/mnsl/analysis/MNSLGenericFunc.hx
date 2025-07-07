package mnsl.analysis;

import mnsl.parser.MNSLNode;

typedef MNSLGenericFunc = { declNode: MNSLNode, callNode: MNSLNode, replaceCmdDecl: MNSLReplaceCmd, replaceCmdCall: MNSLReplaceCmd, name: String, ret: MNSLType, args: MNSLFuncArgs };
