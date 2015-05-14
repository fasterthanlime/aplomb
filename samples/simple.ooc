use aplomb, math
import aplomb, math

main: func {

    points := VectorList new(4)
    x := sqrt(2) * 4
    points data[0] = (0, 0) as Vector
    points data[1] = (x, 0) as Vector
    points data[2] = (x, x) as Vector
    points data[3] = (0, x) as Vector
    poly := Polygon new((0, 0) as Vector, points)
    poly offset = (-0.5 * x, -0.5 * x) as Vector
    poly angle = 3.14159265f * 0.25f

    "Calc points: " println()
    cps := poly calcPoints
    for (i in 0..cps length) {
        cp := cps data[i]
        "(%.2f, %.2f)" printfln(cp x, cp y)
    }

}

