// created by musesum on 12/22/23

import simd

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        SIMD3(x, y, z)
    }
}

extension SIMD3<Float> {
    func hash(_ max: Float) -> Scalar {
        let h = ((x+max) * max * max) + ((y+max) * max) + (z + max)
        return h
    }
    var script: String {
        "(\(x.digits(0...2)),\(y.digits(0...2)),\(z.digits(0...2)))".pad(18)
    }
}
extension SIMD4<Float> {
    func hash(_ max: Float) -> Scalar {
        let h = ((x+max) * max * max) + ((y+max) * max) + (z + max)
        return h
    }
    var script: String {
        "(\(x.digits(0...2)),\(y.digits(0...2)),\(z.digits(0...2)),\(w.digits(0...2)))".pad(18)
    }
}
extension simd_double4x4 {

    var script: String {
        return "\(columns.0.script)\n\(columns.1.script)\n\(columns.2.script)\n\(columns.3.script)\n"
    }
}
