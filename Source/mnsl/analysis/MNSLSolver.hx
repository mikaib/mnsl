package mnsl.analysis;

import mnsl.parser.MNSLNode;
import mnsl.tokenizer.MNSLToken;
import mnsl.MNSLWarning;
import haxe.EnumTools.EnumValueTools;

class MNSLSolver {

    private var _constraints: Array<MNSLConstraint> = [];
    private var _replacements: Array<MNSLReplaceCmd> = [];
    private var _context: MNSLContext;

    public function new(context: MNSLContext) {
        _context = context;
    }

    public function addConstraint(c: MNSLConstraint): Void {
        _constraints.push(c);
    }

    public function iter(): Bool {
        var _toRemove: Array<MNSLConstraint> = [];

        for (c in _constraints) {
            if (c.type.isDefined() && c.mustBe.isDefined()) {
                if (!c.type.equals(c.mustBe)) {
                    if (this.tryCast(c)) {
                        _toRemove.push(c);
                        continue;
                    }

                    if (c._optional) {
                        _toRemove.push(c);
                        continue;
                    }

                    if (c._isBinaryOp) {
                        _context.emitError(AnalyserInvalidBinop(c.type, c.mustBe, c._operationOperator, c));
                    } else {
                        _context.emitError(AnalyserMismatchingType(c));
                    }
                }
            }

            if (!c.type.isDefined() && c.mustBe.isDefined()) {
                if (c.type.accepts(c.mustBe)) {
                    c.type.setType(c.mustBe);
                    c.type.setTempType(false);
                    _toRemove.push(c);
                } else {
                    var done: Bool = false;
                    for (l in c.type.getLimits()) {
                        if (this.tryCastType(c.ofNode, c.type, l)) {
                            c.type.setType(l);
                            c.type.setTempType(false);
                            _toRemove.push(c);
                            break;
                        }
                    }

                    if (done) {
                        continue;
                    }

                    if (c._optional) {
                        _toRemove.push(c);
                        continue;
                    }

                    _context.emitError(AnalyserMismatchingEitherType(c.type.getLimits(), c.ofNode));
                }
            }

            if (c.type.isDefined() && !c.mustBe.isDefined()) {
                if (c.mustBe.accepts(c.type)) {
                    c.mustBe.setType(c.type);
                    c.mustBe.setTempType(false);
                    _toRemove.push(c);
                    continue;
                } else {
                    var done: Bool = false;
                    for (l in c.mustBe.getLimits()) {
                        if (this.tryCastType(c.ofNode, c.type, l)) {
                            c.mustBe.setType(l);
                            c.mustBe.setTempType(false);
                            _toRemove.push(c);
                            done = true;
                            break;
                        }
                    }

                    if (done) {
                        continue;
                    }

                    if (c._optional) {
                        _toRemove.push(c);
                        continue;
                    }

                    _context.emitError(AnalyserMismatchingEitherType(c.mustBe.getLimits(), c.ofNode));
                }
            }
        }

        for (c in _toRemove) {
            _constraints.remove(c);
        }

        if (_toRemove.length > 0) {
            return true;
        }

        return false;
    }

    public function tryCastType(node: MNSLNode, from: MNSLType, to: MNSLType): Bool {
        var c: MNSLConstraint = {
            type: from,
            mustBe: to,
            ofNode: node,
        };

        return this.tryCast(c);
    }

    public function tryCast(c: MNSLConstraint): Bool {
        if (c.type.isArray() || c.mustBe.isArray()) {
            // we cannot cast arrays->values or the other way around
            return false;
        }

        if (c.type.isVector() && c.mustBe.isVector()) {
            var componentsOfType = c.type.getVectorComponents();
            var componentsOfMustBe = c.mustBe.getVectorComponents();

            // this will ensure that in the case we *can* cast, we will prefer casting up instead of down (regarding component count)
            if (componentsOfType > componentsOfMustBe && c._isBinaryOp) {
                return true;
            }

            if (componentsOfMustBe < componentsOfType) {
                _context.emitWarning(ImplicitVectorTruncation(c.ofNode, componentsOfType, componentsOfMustBe));
            }

            addReplacement({
                node: c.ofNode,
                to: VectorConversion(c.ofNode, componentsOfType, componentsOfMustBe),
            });

            return true;
        }

        if (c.type.isVector() && c.mustBe.isNumerical() && c._isBinaryOp) return true;
        if (c.type.isNumerical() && c.mustBe.isVector()) {
            var componentsOfMustBe = c.mustBe.getVectorComponents();

            addReplacement({
                node: c.ofNode,
                to: VectorCreation(componentsOfMustBe, [for (i in 0...componentsOfMustBe) c.ofNode], null)
            });

            return true;
        }

        if (c.type.isBool() && c.type.isNumerical() && c._isBinaryOp) return true;
        if (c.type.isNumerical() && c.mustBe.isBool()) {
            addReplacement({
                node: c.ofNode,
                to: BinaryOp(c.ofNode, NotEqual(null), IntegerLiteralNode("0", null), MNSLType.TBool, null)
            });

            return true;
        }

        if (c.type.isNumerical() && c.mustBe.isNumerical()) {
            if (c._isBinaryOp && c.type.isFloat()) {
                return true;
            }

            if (c.type.isFloat() && c.mustBe.isInt()) {
                _context.emitWarning(ImplicitFloatToInt(c.ofNode));
            }

            addReplacement({
                node: c.ofNode,
                to: TypeCast(c.ofNode, c.type, c.mustBe)
            });

            return true;
        }

        if (c.type.isMatrix() && c.mustBe.isNumerical() && c._isBinaryOp) return true;
        if (c.type.isNumerical() && c.mustBe.isMatrix()) {
            addReplacement({
                node: c.ofNode,
                to: MatrixCreation(c.mustBe.getMatrixWidth(), [for (i in 0...c.mustBe.getMatrixWidth()*c.mustBe.getMatrixWidth()) c.ofNode], null)
            });

            return true;
        }

        if (c.type.isVector() && c.mustBe.isMatrix() && c._isBinaryOp) {
            if (c.type.getVectorComponents() != c.mustBe.getMatrixWidth()) {
                addReplacement({
                    node: c.ofNode,
                    to: VectorConversion(c.ofNode, c.type.getVectorComponents(), c.mustBe.getMatrixWidth())
                });
            }

            return true;
        }

        if (c.type.isMatrix() && c.mustBe.isVector() && c._isBinaryOp) {
            addReplacement({
                node: c.ofNode,
                to: ImplicitTypeCast(c.ofNode, MNSLType.fromString('Vec${c.type.getMatrixWidth()}'))
            });

            return true;
        }

        return false;
    }

    public function getUnresolvedConstraints(): Array<MNSLConstraint> {
        var _tmp: Array<MNSLConstraint> = [];

        for (c in _constraints) {
            if (c.type.isUnknown() && c.mustBe.isUnknown()) {
                _tmp.push(c);
            }
        }

        return _tmp;
    }

    public function addReplacement(replacement: MNSLReplaceCmd): Void {
        for (existing in _constraints) {
            // this is a bit of a hack, let me explain.
            // when using multiple contraints to create a "system" of constraints, one of the constraints may be unexpectedly cast causing serious problems.
            // one example of this is binary operators where the left and right type get connected to each other, after which the binop itself connects to the right type.
            // if the right type is cast to another type, the binop itself will not be updated and still assume the old type.
            // this replacement logic makes it so that the "follow up" constraints will correctly use the new type.
            // one thing to note is that this logic may look bug-prone on the surface level, it is actually fine due to the fact that every node contains MNSLNodeInfo which avoids updating the wrong nodes.
            // even if MNSLNodeInfo is null, it may still be unique due to a child node.
            if (EnumValueTools.equals(existing.ofNode, replacement.node)) {
                var newType = MNSLAnalyser.getType(replacement.to);
                existing.ofNode = replacement.to;
                existing.type = newType;
            }

            if (existing._mustBeOfNode != null && EnumValueTools.equals(existing._mustBeOfNode, replacement.node)) {
                var newType = MNSLAnalyser.getType(replacement.to);
                existing._mustBeOfNode = replacement.to;
                existing.mustBe = newType;
            }
        }

        _replacements.push(replacement);
    }

    public function getReplacements(): Array<MNSLReplaceCmd> {
        return _replacements;
    }

    public function solve(): Bool {
        var changed: Bool = true;
        while (changed) {
            changed = iter();
        }

        return getUnresolvedConstraints().length == 0;
    }

}
