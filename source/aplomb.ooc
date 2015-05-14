
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

    init: func (pos: Vector, points: VectorList) {
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

