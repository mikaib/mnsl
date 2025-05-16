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
            if (!c.type.isDefined() && c.mustBe.isDefined()) {
                c.type.setType(c.mustBe);
            }

            if (c.type.isDefined() && !c.mustBe.isDefined()) {
                c.mustBe.setType(c.type);
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
        var changed: Bool = true;
        while (changed) {
            changed = iter();
        }

        return _constraints.length <= 0;
    }

}
