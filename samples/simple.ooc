use aplomb, math
import aplomb, math

printVector: func (v: Vector) {
    "(%.2f, %.2f)" printfln(v x, v y)
}

printCalcPoints: func (poly: Polygon) {
    cps := poly calcPoints
    for (i in 0..cps length) {
        "#{cps data[i]}" println()
    }
}

printCollision: func (collides: Bool, response: Response) {
    println()
    "==============================" println()
    "Collides? #{collides}" println()
    if (collides) {
        if (response aInB) {
            "A is fully in B" println()
        }
        if (response bInA) {
            "B is fully in A" println()
        }
        "overlap vector: #{response overlapV}" println()
    }
    "==============================" println()
}

main: func {

    points := VectorList new(4)
    x := sqrt(2) * 2
    points data[0] = (0, 0) as Vector
    points data[1] = (x, 0) as Vector
    points data[2] = (x, x) as Vector
    points data[3] = (0, x) as Vector
    poly := Polygon new(points)
    poly offset = (-0.5 * x, -0.5 * x) as Vector
    poly angle = 3.14159265f * 0.25f

    "\nCalc points for poly: " println()
    printCalcPoints(poly)

    points2 := VectorList new(4)
    points2 data[0] = (0, 0) as Vector
    points2 data[1] = (4, 0) as Vector
    points2 data[2] = (4, 4) as Vector
    points2 data[3] = (0, 4) as Vector
    poly2 := Polygon new(points2)
    poly2 offset = (-2, -2) as Vector

    "\nCalc points for poly2: " println()
    printCalcPoints(poly2)

    response: Response

    response clear()
    collides := testPolygonPolygon(poly, poly2, response&)
    printCollision(collides, response)

    poly2 pos = (1, 0) as Vector

    response clear()
    collides = testPolygonPolygon(poly, poly2, response&)
    printCollision(collides, response)

    poly2 pos = (5, 0) as Vector

    response clear()
    collides = testPolygonPolygon(poly, poly2, response&)
    printCollision(collides, response)
}

