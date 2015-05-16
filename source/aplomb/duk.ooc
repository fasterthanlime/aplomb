use aplomb
import aplomb

use duktape, nawashi
import duk/tape, nawashi

Aplomb: class {

    collide: static func (duk: DukContext) -> Int {
        a := duk requireOoc(0) as Polygon
        b := duk requireOoc(1) as Polygon

        response: Response
        response clear()
        collides := testPolygonPolygon(a, b, response&)

        if (collides) {
            objIdx := duk pushObject()

            overlapVIdx := duk pushObject()
            duk pushNumber(response overlapV x)
            duk putPropString(overlapVIdx, "x")
            duk pushNumber(response overlapV y)
            duk putPropString(overlapVIdx, "y")
            duk putPropString(objIdx, "overlapV")

            overlapNIdx := duk pushObject()
            duk pushNumber(response overlapN x)
            duk putPropString(overlapNIdx, "x")
            duk pushNumber(response overlapN y)
            duk putPropString(overlapNIdx, "y")
            duk putPropString(objIdx, "overlapN")

            duk pushNumber(response overlap)
            duk putPropString(objIdx, "overlap")
        } else {
            duk pushNull()
        }
        1
    }

}

