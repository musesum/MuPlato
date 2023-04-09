//  Created by warren on 2/28/23.
//  Copyright © 2023 com.deepmuse. All rights reserved.

import Foundation

// index ranged  0...1
struct Vert01 {
    var p0: SIMD4<Float> // position at lower bound 0...1
    var p1: SIMD4<Float> // position at upper bound 0...1
    var extra: SIMD4<Float>
    var color: SIMD4<Float>
    var n0: SIMD4<Float>   // normal at lower bound 0...1
    var n1: SIMD4<Float>   // normal at upper bound 0...1
    init() {
        p0 = .zero
        p1 = .zero
        n0 = .zero
        n1 = .zero
        color = .zero
        extra = .zero
    }
}

func logVert01(_ v: Vert01,_ i: Int, normals: Bool = false) {
    var str = "\(i): "

    str += "(\(s(v.p0.x)),\(s(v.p0.y)),\(s(v.p0.z)))…"
    str += "(\(s(v.p1.x)),\(s(v.p1.y)),\(s(v.p1.z)))  "

    if normals {
        str += "(\(s(v.n0.x)),\(s(v.n0.y)),\(s(v.n0.z)))…"
        str += "(\(s(v.n1.x)),\(s(v.n1.y)),\(s(v.n1.z)))  "
    }

    let vertId = Int(v.extra.x)
    let triId = Int(v.extra.y)
    let harmonic = Int(v.extra.z)
    let hStr = harmonic > 0 ? "h:\(harmonic)" : ""


    if let plato = Plato(rawValue: vertId) {
        str += "t:\(triId) p:\(plato) h:\(harmonic)"
    } else {
        str +=  "t:\(triId) v:\(vertId) \(hStr)"
    }
    print(str)

    func s(_ f: Float) -> String {
        return (f < 0 ? "" : " ") + f.digits(1...1)
    }

}
