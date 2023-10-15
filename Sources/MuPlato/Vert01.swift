//  created by musesum on 2/28/23.

import Foundation

// index ranged  0...1

struct PlatoVertex {
    static let count = 5 // used by updateShader to set stride
    var pos0: SIMD4<Float> // position at lower bound 0...1
    var pos1: SIMD4<Float> // position at upper bound 0...1
    var norm0: SIMD4<Float> // normal at lower bound 0...1
    var norm1: SIMD4<Float> // normal at upper bound 0...1
    var vertId: Float
    var faceId: Float
    var harmonic: Float
    var reserved: Float

    init() {
        pos0 = .zero
        pos1 = .zero
        norm0 = .zero
        norm1 = .zero
        vertId = 0
        faceId = 0
        harmonic = 0
        reserved = 0
    }
}

func logVert01(_ v: PlatoVertex,_ i: Int, normals: Bool = false) {
    var str = "\(i): "

    str += "(\(s(v.pos0.x)),\(s(v.pos0.y)),\(s(v.pos0.z)))…"
    str += "(\(s(v.pos1.x)),\(s(v.pos1.y)),\(s(v.pos1.z)))  "

    let vertId = Int(v.vertId)
    let faceId = Int(v.faceId)
    let harmonic = Int(v.harmonic)
    let hStr = harmonic > 0 ? "h:\(harmonic)" : ""


    if let plato = Plato(rawValue: vertId) {
        str += "f:\(faceId) p:\(plato) h:\(harmonic)"
    } else {
        str +=  "f:\(faceId) v:\(vertId) \(hStr)"
    }
    print(str)

    func s(_ f: Float) -> String {
        return (f < 0 ? "" : " ") + f.digits(1...1)
    }

}
