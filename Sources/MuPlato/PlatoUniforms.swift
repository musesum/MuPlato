// created by musesum on 1/4/24

import simd
struct PlatoUniforms {
    var range        : Float
    var convex       : Float
    var passthru     : Float
    var shadowWhite  : Float
    var shadowDepth  : Float
    var invert       : Float
    var zoom         : Float
    var worldCamera  : vector_float4
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

