package mnsl.analysis;

import mnsl.parser.MNSLNode;

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
            if (!c.type.isDefined() && c.mustBe.isDefined()) {
                c.type.setType(c.mustBe);
                c.type.setTempType(false);
                _toRemove.push(c);
            }

            if (c.type.isDefined() && !c.mustBe.isDefined()) {
                c.mustBe.setType(c.type);
                c.mustBe.setTempType(false);
                _toRemove.push(c);
            }

            if (c.type.isDefined() && c.mustBe.isDefined()) {
                if (!c.type.equals(c.mustBe)) {
                    if (this.tryCast(c)) {
                        _toRemove.push(c);
                        continue;
                    }

                    _context.emitError(AnalyserMismatchingType(c));
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

    public function tryCast(c: MNSLConstraint): Bool {
        if (c.type.isVector() && c.mustBe.isVector()) {
            var componentsOfType = c.type.getVectorComponents();
            var componentsOfMustBe = c.mustBe.getVectorComponents();

            _replacements.push({
                node: c.ofNode,
                to: VectorConversion(c.ofNode, componentsOfType, componentsOfMustBe),
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
