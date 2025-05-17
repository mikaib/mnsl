package mnsl.analysis;

import mnsl.parser.MNSLNode;

class MNSLSolver {

    private var _constraints: Array<MNSLConstraint> = [];
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
            trace("Solving constraint: " + c.toString());

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
                    _context.emitError(MismatchingType(c));
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

    public function solve(): Bool {
        trace("===== BEGIN SOLVER =====");
        var changed: Bool = true;
        while (changed) {
            changed = iter();
        }

        trace("===== END SOLVER =====");
        return _constraints.length <= 0;
    }

}
