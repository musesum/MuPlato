// created by musesum on 1/4/24

import simd
struct PlatoShading {
    var convex  : Float
    var reflect : Float
    var alpha   : Float
    var depth   : Float
    var invert  : Float
    var zoom    : Float
}

enum PlatoStyle: Int {
    case unknown = -1
    case hidden  = 0
    case color   = 1
    case reflect = 2

    public init(_ i: Int) {
        self = PlatoStyle(rawValue: i) ?? .hidden
    }
}

