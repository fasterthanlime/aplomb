
// A simple library for determining intersections of circles and
// polygons using the Separating Axis Theorem.

// Based on SAT.js: https://github.com/jriecken/sat-js (MIT)
// Original copyright 2012 - 2015 -  Jim Riecken <jimr@jimr.ca>

use math
import math

Vector: cover {
    x, y: Float

    /**
     * Change this vector to be perpendicular to what it was before.
     * (Effectively rotates it 90 degrees in a clockwise direction)
     */
    perp: func -> This {
        (y, -x) as This
    }

    /**
     * Rotate this vector (counter-clockwise) by the specified angle
     * (in radians).
     */
    rotate: func (angle: Float) -> This {
        co := cos(angle)
        si := sin(angle)
        (
            x * co - y * si,
            x * si + y * co
        ) as This
    }

    /**
     * Reverse this vector.
     */
    reverse: func -> This {
        (-x, -y) as This
    }

    /**
     * Normalize this vector (make it have length of `1`)
     */
    normalize: func -> This {
        d := len()
        if (d > 0) {
            (x / d, y / d) as This
        } else {
            this
        }
    }

    /**
     * Add another vector to this one
     */
    add: func (other: This) -> This {
        (x + other x, y + other y) as This
    }

    /**
     * Subtract another vector from this one.
     */
    sub: func (other: This) -> This {
        (x - other x, y - other y) as This
    }

    /**
     * Scale this vector. An independent can be provided
     * for each axis, or a single scaling factor that will scale
     * both `x` and `y`
     */
    scale: func (xs, ys: Float) -> This {
        (x * xs, y * ys) as This
    }

    /**
     * Project this vector onto another vector.
     */
    project: func (other: This) -> This {
        amt := dot(other) / other len2()
        (amt * other x, amt * other y) as This
    }

    /**
     * Project this vector onto a vector of unit length. This
     * is slightly more than `project` when dealing with
     * unit vectors.
     */
    projectN: func (other: This) -> This {
        amt := dot(other)
        (amt * other x, amt * other y) as This
    }

    /**
     * Reflect this vector on an arbitrary axis.
     */
    reflect: func (axis: This) -> This {
        p := project(axis) scale(2, 2)
        (x - p x, y - p y) as This
    }

    /**
     * Reflect this vector on an arbitrary axis (represented
     * by a unit vector). Slightly more efficient than `reflect`
     * when dealing with an axis that is a unit vector.
     */
    reflectN: func (axis: This) -> This {
        p := projectN(axis) scale(2, 2)
        (x - p x, y - p y) as This
    }

    /**
     * Get the dot product of this vector and another.
     */
    dot: func (other: This) -> Float {
        x * other x + y * other y
    }

    /**
     * Get the squared length of this vector.
     */
    len2: func -> Float {
        x * x + y * y
    }

    /**
     * Get the length of this vector.
     */
    len: func -> Float {
        sqrt(x * x + y * y)
    }

    toString: func -> String {
        "(%.2f, %.2f)" format(x, y)
    }
}

VectorList: cover {
    length: Int
    data: Vector*

    new: static func (length: Int) -> This {
        (length, gc_malloc(Vector size * length)) as This
    }
}

/**
 * Represents a *convex* polygon with any number of points
 * (specified in counter-clockwise order).
 */
Polygon: class {

    _angle := 0.0f
    _offset := (0, 0) as Vector
    _points: VectorList

    calcPoints: VectorList
    edges: VectorList
    normals: VectorList

    pos: Vector

    init: func (points: VectorList) {
        this points = points
    }

    points: VectorList {
        get { _points }

        set (points) {
            if (_points data == null || _points length != points length) {
                calcPoints = VectorList new(points length)
                edges = VectorList new(points length)
                normals = VectorList new(points length)
            }
            _points = points
            _recalc()
        }
    }

    angle: Float {
        get { _angle }

        set (angle) {
            _angle = angle
            _recalc()
        }
    }

    offset: Vector {
        get { _offset }

        set (offset) {
            _offset = offset
            _recalc()
        }
    }

    rotate: func (number: Float) {
        for (i in 0.._points length) {
            _points data[i] = _points data[i] rotate(number)
        }
    }

    translate: func (x, y: Float) {
        for (i in 0.._points length) {
            p := _points data[i]
            _points data[i] = (p x + x, p y + y) as Vector
        }
    }

    _recalc: func {
        len := _points length

        for (i in 0..len) {
            p := _points data[i]
            cp := (
                p x + offset x
                p y + offset y
            ) as Vector
            if (angle != 0.0f) {
                cp = cp rotate(angle)
            }
            calcPoints data[i] = cp
        }

        // calculate the edges/normals
        for (i in 0..len) {
            p1 := calcPoints data[i]
            p2 := i < len - 1 ? calcPoints data[i + 1] : calcPoints data[0]
            e := p2 sub(p1)
            edges data[i] = e
            normals data[i] = e perp() normalize()
        }
    }

}

Response: cover {
    overlapN, overlapV: Vector

    aInB, bInA: Bool
    overlap: Float

    clear: func@ {
        aInB = true
        bInA = true
        overlap = INFINITY
    }
}

FloatTuple: cover {
    a: Float
    b: Float
}

flattenPointsOn: func (points: VectorList, normal: Vector) -> FloatTuple {
    min := INFINITY
    max := -INFINITY
    for (i in 0..points length) {
        dot := points data[i] dot(normal)
        if (dot < min) { min = dot }
        if (dot > max) { max = dot }
    }
    (min, max) as FloatTuple
}

isSeparatingAxis: func (aPos: Vector, bPos: Vector, aPoints: VectorList,
    bPoints: VectorList, axis: Vector, response: Response*) -> Bool {

    offsetV := bPos sub(aPos)
    projectedOffset := offsetV dot(axis)

    rangeA := flattenPointsOn(aPoints, axis)
    rangeB := flattenPointsOn(bPoints, axis)

    rangeB a += projectedOffset
    rangeB b += projectedOffset

    if (rangeA a > rangeB b || rangeB a > rangeA b) {
        return true
    }

    if (response) {
        overlap := 0.0f

        if (rangeA a < rangeB a) {
            // A starts further left than B
            response@ aInB = false

            if (rangeA b < rangeB b) {
                // A ends before B does. We have to pull A out of B
                overlap = rangeA b - rangeB a
                response@ bInA = false
            } else {
                // B is fully inside A. Pick the shortest way out
                option1 := rangeA b - rangeB a
                option2 := rangeB b - rangeA a
                overlap = option1 < option2 ? option1 : -option2
            }
        } else {
            // B starts further left than A
            response@ bInA = false

            if (rangeA b > rangeB b) {
                // B ends before A does. We have to push A out of B
                overlap = rangeA a - rangeB b
                response@ aInB = false
            } else {
                // A is fully inside B. Pick the shortest way out.
                option1 := rangeA b - rangeB a
                option2 := rangeB b - rangeA a
                overlap = option1 < option2 ? option1 : -option2
            }
        }

        // If this is the smallest amount of overlap we've seen so far,
        // set it as the minimum overlap
        absOverlap := overlap > 0 ? overlap : -overlap
        if (absOverlap < response@ overlap) {
            response@ overlap = absOverlap
            if (overlap < 0) {
                response@ overlapN = axis reverse()
            } else {
                response@ overlapN = axis
            }
        }
    }
    return false
}

testPolygonPolygon: func (a: Polygon, b: Polygon, response: Response*) -> Bool {
    aPoints := a calcPoints
    aLen := aPoints length
    bPoints := b calcPoints
    bLen := bPoints length

    for (i in 0..aLen) {
        if (isSeparatingAxis(a pos, b pos, aPoints, bPoints, a normals data[i], response)) {
            return false
        }
    }

    for (i in 0..bLen) {
        if (isSeparatingAxis(a pos, b pos, aPoints, bPoints, b normals data[i], response)) {
            return false
        }
    }

    // Since none of the edge normals of A or B are a separating axis, there
    // is an intersection and we've already calculated the smallest overlap
    // (in isSeparatingAxis). Calculate the final overlap vector.
    if (response) {
        ov := response@ overlap
        response@ overlapV = response@ overlapN scale(ov, ov)
    }
    return true
}

