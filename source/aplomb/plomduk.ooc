use aplomb
import aplomb

use duktape, nawashi
import duk/tape, nawashi

Aplomb: class {

    newPoly: static func (duk: DukContext) -> Int {
        duk requireObjectCoercible(0)
        duk getPropString(0, "length")
        len := duk requireInt(-1)
        duk pop()

        points := VectorList new(len)
        for (i in 0..len) {
            duk getPropIndex(0, i)

            duk getPropString(-1, "x")
            x := duk requireNumber(-2) as Float
            duk pop()

            duk getPropString(-1, "y")
            y := duk requireNumber(-2) as Float
            duk pop()

            points data[i] = (x, y) as Vector
            duk pop()
        }

        poly := Polygon new(points)
        // duk pushOoc(poly)

        1
    }

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

            overlapNIdx := duk pushObject()
            duk pushNumber(response overlapN x)
            duk putPropString(overlapNIdx, "x")
            duk pushNumber(response overlapN y)
            duk putPropString(overlapNIdx, "y")

            duk pushNumber(response overlap)
            duk putPropString(objIdx, "overlap")
        } else {
            duk pushNull()
        }
        1
    }

}

